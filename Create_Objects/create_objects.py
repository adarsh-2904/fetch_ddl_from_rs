"""
Script Behavior Summary: CREATE_OBJECTS.PY

1. Database Credentials & Connection:
   - Username/password provided via interactive prompt (masked input)
   - Password deleted from memory after connection established
   - Dynamic environment selection from YAML config (test, dev, prod)

2. Interactive Selection & Configuration (2-attempt validation):
   - Target Environment: test, dev, or prod (destination database)
   - Object Type: table, view, or procedure
   - Target Schema Name: where objects will be created
   - Exclusion Table Confirmation: must confirm table is configured
   - Grant Preference (OBJECT TYPE SPECIFIC):
     
     TABLES/VIEWS (3 options):
     1. Both grants: GRANT ALL to mods_bi_writer + GRANT SELECT to mods_bi_reader_vt
     2. Just one: User selects mods_bi_writer OR mods_bi_reader_vt
     3. Skip grants: No permissions granted
     
     PROCEDURES (2 options only, simplified):
     1. Grant EXECUTE to mods_bi_writer
     2. Skip grants: No permissions
   
   - Source environment: Auto-extracted from fetched folder name
   - Safety check: Source and target must be DIFFERENT (automatic validation)

3. Folder Detection & Confirmation:
   - Dynamically finds latest DDL folder: {schema}_{env}_{mode}_{YYYYMMDD_HHMM}/
   - Extracts execution_mode ('all' or 'selected') from folder name
   - Displays folder details and requires explicit Y/N confirmation
   - User can abort before any database changes made

4. Drop & Create Strategy by Object Type:
   
   TABLES:
   - Step 1: Check if exists + capture row count before drop
   - Step 2: DROP TABLE IF EXISTS (required - no CREATE OR REPLACE)
   - Step 3: CREATE new table from DDL script
   - Step 4: Large table check (ONLY 'all' mode, NOT 'selected'):
     • If > 100k rows: Prompt for confirmation
     • User can skip this table without affecting others
     • NOT triggered in 'selected' mode (selection assumed intentional)
   - Drop_status values: Dropped, Not_Found, Failed
   
   VIEWS:
   - Step 1: DROP VIEW IF EXISTS
   - Step 2: CREATE OR REPLACE VIEW from DDL
   - Drop_status: Dropped (views can always be dropped)
   
   PROCEDURES:
   - Step 1: CREATE OR REPLACE PROCEDURE from DDL
   - Drop_status: N/A (procedures use CREATE OR REPLACE natively)

5. Grant Management:
   
   TABLES/VIEWS:
   - 'both': GRANT ALL + GRANT SELECT to two roles
   - 'writer': GRANT ALL to mods_bi_writer
   - 'reader': GRANT SELECT to mods_bi_reader_vt
   - 'none': No grants executed
   
   PROCEDURES:
   - 'both' (yes): GRANT EXECUTE to mods_bi_writer
   - 'none' (no): No grants executed
   
   - Executed immediately after object creation
   - Grant failures logged but don't prevent object creation
   - Grant_status recorded in CSV

6. Validation (TABLES & VIEWS only, NOT procedures):
   
   VIEWS: SELECT * FROM {schema}.{view} LIMIT 0
   TABLES: SELECT 1 FROM {schema}.{table} LIMIT 1
   PROCEDURES: N/A

7. Exclusion Table Filtering:
   - Source: mods_bi.etl_config.fetch_all_objects_exclude_ctl (target DB)
   - Timing: Applied AFTER reading DDL file from fetch output
   - Objects in list: SKIPPED regardless of fetch mode
   - Works for: BOTH 'all' and 'selected' fetch modes

8. Error Categorization & Retry:
   - Error Types: PERMISSION_ERROR, DEPENDENCY_ERROR, ALREADY_EXISTS, SYNTAX_ERROR, OTHER_ERROR
   - Retry: DEPENDENCY_ERROR only (if enabled in config)
   - Retry attempts: Configurable (default: 3)
   - Timing: Separate pass after all initial attempts

9. CSV Output Files:
   
   Created CSV: object_name, schema_name, object_type, status, validation_status,
                validation_error, created_timestamp, drop_status, row_count_before_drop, grant_status
   
   Errored CSV: object_name, schema_name, object_type, error_type, error_message, timestamp
   
   Skipped CSV: object_name, schema_name, object_type, reason

10. Audit Trail (LOAD_ID):
    - Unique identifier per execution run
    - Generated: MAX(load_id) + 1
    - Audit table: mods_bi.etl_config.create_object_audit_log
    - Bulk insert: After ALL processing complete

11. Data Protection & Safety:
    
    Large Table Safeguard (ONLY 'all' mode):
    - Threshold: > 100k rows
    - User can choose to proceed or skip
    - NOT triggered in 'selected' mode
    
    Environment Safety:
    - Source != target validation
    - Prevents accidental same-environment overwrites
    
    Row Count Tracking:
    - Captured BEFORE table drop
    - Allows impact assessment

12. Execution Mode Behavior:
    
    'All' Mode: Large table safeguard ENABLED, Exclusion table APPLIED
    'Selected' Mode: Large table safeguard DISABLED, Exclusion table APPLIED

"""


import os
import psycopg2
import logging
import yaml
import csv
import sys
from datetime import datetime
from pathlib import Path
import pwinput


# Environment and Object Type Mappings (Hardcoded - 3 options each)
ENVIRONMENT_MAP = {
    "1": "test",
    "2": "dev",
    "3": "prod"
}

OBJECT_TYPE_MAP = {
    "1": "table",
    "2": "view",
    "3": "procedure"
}


def prompt_environment_selection(source_type="target"):
    """
    Prompt user to select the environment.
    Returns the environment name (test, dev, prod)
    Exits on 2 invalid attempts.
    source_type: 'source' or 'target' for appropriate messaging
    """
    max_attempts = 2
    attempt = 0
    
    valid_environments = ['test', 'dev', 'prod']
    env_label = "SOURCE" if source_type == "source" else "TARGET"
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print(f"SELECT {env_label} ENVIRONMENT")
        print("=" * 80)
        print("Available environments: test, dev, prod")
        print("=" * 80)
        
        choice = input(f"Enter environment ({', '.join(valid_environments)}): ").strip().lower()
        
        if choice in valid_environments:
            print(f"✓ Selected {env_label} Environment: {choice.upper()}")
            return choice
        else:
            attempt += 1
            if attempt < max_attempts:
                print(f"✗ Invalid choice. Please enter test, dev, or prod. (Attempt {attempt}/{max_attempts})")
            else:
                print(f"✗ Invalid choice. Maximum attempts exceeded. Exiting.")
                sys.exit(1)


def prompt_object_type_selection():
    """
    Prompt user to select the object type.
    Returns the object type (table, view, procedure)
    Exits on 2 invalid attempts.
    """
    max_attempts = 2
    attempt = 0
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print("SELECT OBJECT TYPE")
        print("=" * 80)
        print("1. Table")
        print("2. View")
        print("3. Procedure")
        print("=" * 80)
        
        choice = input("Enter your choice (1-3): ").strip()
        
        if choice in OBJECT_TYPE_MAP:
            object_type = OBJECT_TYPE_MAP[choice]
            print(f"✓ Selected Object Type: {object_type.upper()}")
            return object_type
        else:
            attempt += 1
            if attempt < max_attempts:
                print(f"✗ Invalid choice. Please enter 1, 2, or 3. (Attempt {attempt}/{max_attempts})")
            else:
                print(f"✗ Invalid choice. Maximum attempts exceeded. Exiting.")
                sys.exit(1)


def prompt_schema_name():
    """
    Prompt user to enter the target schema name.
    Exits on 2 empty input attempts.
    """
    max_attempts = 2
    attempt = 0
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print("ENTER TARGET SCHEMA NAME")
        print("=" * 80)
        print("Examples: mktg_ops_tbls, mktg_ops_vws")
        print("=" * 80)
        
        schema_name = input("Enter target schema name: ").strip()
        
        if schema_name:
            print(f"✓ Selected Schema: {schema_name}")
            return schema_name
        else:
            attempt += 1
            if attempt < max_attempts:
                print(f"✗ Schema name cannot be empty. Please try again. (Attempt {attempt}/{max_attempts})")
            else:
                print(f"✗ Schema name cannot be empty. Maximum attempts exceeded. Exiting.")
                sys.exit(1)


def prompt_exclusion_table_configured():
    """
    Prompt user to confirm if exclusion table is configured on target DB.
    Returns True if yes, exits if no.
    """
    while True:
        print("\n" + "=" * 80)
        print("EXCLUSION TABLE CONFIGURATION")
        print("=" * 80)
        print("Have you configured the exclusion table on the target DB?")
        print("(Target: mods_bi.etl_config.fetch_all_objects_exclude_ctl)")
        print("=" * 80)
        
        response = input("Type 'yes' or 'no': ").strip().lower()
        
        if response == 'yes':
            print(f"✓ Proceeding with exclusion filtering enabled")
            return True
        elif response == 'no':
            print(f"✗ Exclusion table not configured. Cannot proceed safely.")
            print(f"   Please configure the exclusion table on the target DB and try again.")
            sys.exit(1)
        else:
            print(f"✗ Invalid response. Please type 'yes' or 'no'.")


def prompt_grant_preference():
    """
    Prompt user to select grant preference for tables/views.
    Returns the grant preference: 'both', 'writer', 'reader', or 'none'
    For stored procedures, GRANT EXECUTE is always applied automatically.
    """
    max_attempts = 2
    attempt = 0
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print("SELECT GRANT PREFERENCE FOR TABLES/VIEWS")
        print("=" * 80)
        print("1. Both grants (GRANT ALL to mods_bi_writer + GRANT SELECT to mods_bi_reader_vt)")
        print("2. Just one grant (you will select which role)")
        print("3. SKIP GRANTS (no permissions granted)")
        print("=" * 80)
        print("Note: Stored procedures will always receive GRANT EXECUTE TO ROLE mods_bi_writer")
        print("=" * 80)
        
        choice = input("Enter your choice (1-3): ").strip()
        
        if choice == '1':
            print(f"✓ Selected: BOTH GRANTS")
            return 'both'
        elif choice == '2':
            print(f"✓ Selected: JUST ONE GRANT")
            return prompt_single_grant_role()
        elif choice == '3':
            print(f"✓ Selected: SKIP GRANTS")
            return 'none'
        else:
            attempt += 1
            if attempt < max_attempts:
                print(f"✗ Invalid choice. Please enter 1, 2, or 3. (Attempt {attempt}/{max_attempts})")
            else:
                print(f"✗ Invalid choice. Maximum attempts exceeded. Exiting.")
                sys.exit(1)


def prompt_single_grant_role():
    """
    Prompt user to select which role to grant to when choosing single grant.
    Returns 'writer' or 'reader'
    """
    max_attempts = 2
    attempt = 0
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print("SELECT SINGLE GRANT ROLE")
        print("=" * 80)
        print("1. mods_bi_writer (GRANT ALL)")
        print("2. mods_bi_reader_vt (GRANT SELECT)")
        print("=" * 80)
        
        choice = input("Enter your choice (1-2): ").strip()
        
        if choice == '1':
            print(f"✓ Selected: mods_bi_writer (GRANT ALL)")
            return 'writer'
        elif choice == '2':
            print(f"✓ Selected: mods_bi_reader_vt (GRANT SELECT)")
            return 'reader'
        else:
            attempt += 1
            if attempt < max_attempts:
                print(f"✗ Invalid choice. Please enter 1 or 2. (Attempt {attempt}/{max_attempts})")
            else:
                print(f"✗ Invalid choice. Maximum attempts exceeded. Exiting.")
                sys.exit(1)


def prompt_grant_preference_for_procedure():
    """
    Prompt user for grant preference for procedures.
    Procedures only have GRANT EXECUTE option, so only 2 choices:
    - Grant EXECUTE to mods_bi_writer
    - Skip grants
    Returns 'both' (for writer only) or 'none' (for no grants)
    """
    max_attempts = 2
    attempt = 0
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print("SELECT GRANT PREFERENCE FOR PROCEDURES")
        print("=" * 80)
        print("1. Grant EXECUTE to mods_bi_writer")
        print("2. SKIP GRANTS (no permissions granted)")
        print("=" * 80)
        
        choice = input("Enter your choice (1-2): ").strip()
        
        if choice == '1':
            print(f"✓ Selected: GRANT EXECUTE to mods_bi_writer")
            return 'both'  # Return 'both' to maintain compatibility with existing code
        elif choice == '2':
            print(f"✓ Selected: SKIP GRANTS")
            return 'none'
        else:
            attempt += 1
            if attempt < max_attempts:
                print(f"✗ Invalid choice. Please enter 1 or 2. (Attempt {attempt}/{max_attempts})")
            else:
                print(f"✗ Invalid choice. Maximum attempts exceeded. Exiting.")
                sys.exit(1)


# Load configuration from YAML
def load_config(config_file="create_objects_parameters.yaml"):
    try:
        # Since .py file is now inside Create_Object_Input folder
        # base_path points to Create_Object_Input folder
        base_path = Path(__file__).parent

        # YAML file is in the same folder as the .py file
        yaml_path = base_path / config_file

        with open(yaml_path, "r") as file:
            config = yaml.safe_load(file)

        # Convert relative paths to absolute paths
        # Now we need to go UP one level (parent.parent) to get to project root
        if 'paths' in config:
            project_root = base_path.parent  # Go up to project root
            for key in ['ddl_base_path', 'log_directory', 'output_directory']:
                if key in config['paths']:
                    path_value = config['paths'][key]
                    # If path doesn't start with drive letter or /, treat as relative
                    if not (path_value.startswith('/') or (len(path_value) > 1 and path_value[1] == ':')):
                        config['paths'][key] = str(project_root / path_value)

        return config

    except Exception as e:
        print(f"Error loading configuration file: {e}")
        return None


# Find the latest timestamped folder for the schema
def find_latest_schema_folder(ddl_base_path, object_type, schema_name):
    """
    Dynamically finds the latest timestamped folder for the given schema and object type.
    Example: Fetch_Object_Output/View/mktg_ops_vws_dev_all_20251212_1628/
    Returns tuple: (full_path, folder_name)
    """
    try:
        # Construct the path to the object type folder
        object_type_path = os.path.join(ddl_base_path, object_type.capitalize())

        if not os.path.exists(object_type_path):
            logging.error(f"Object type path does not exist: {object_type_path}")
            return None, None

        # Find all folders that start with the schema_name
        matching_folders = [
            f for f in os.listdir(object_type_path)
            if os.path.isdir(os.path.join(object_type_path, f)) and f.startswith(schema_name + "_")
        ]

        if not matching_folders:
            logging.error(f"No folders found for schema '{schema_name}' in {object_type_path}")
            return None, None

        # Sort by timestamp (last 9 chars: YYYYMMDD_HHMM format)
        # Extract timestamp from folder name and sort numerically
        def get_timestamp_from_folder(folder_name):
            try:
                # Timestamp is the last part after splitting by underscore
                # Format: schema_env_mode_YYYYMMDD_HHMM
                parts = folder_name.split('_')
                if len(parts) >= 4:
                    # Get the last two parts: date and time
                    date_part = parts[-2]  # YYYYMMDD
                    time_part = parts[-1]  # HHMM
                    return date_part + time_part  # YYYYMMDDHHMM as string for comparison
                return folder_name  # Fallback to folder name
            except:
                return folder_name
        
        matching_folders.sort(key=get_timestamp_from_folder, reverse=True)
        latest_folder = matching_folders[0]

        full_path = os.path.join(object_type_path, latest_folder)

        logging.info("=" * 80)
        logging.info(f"DYNAMIC FOLDER RESOLUTION")
        logging.info("=" * 80)
        logging.info(f"Object Type: {object_type.upper()}")
        logging.info(f"Schema Name: {schema_name}")
        logging.info(f"Base Path: {object_type_path}")
        logging.info(f"Found {len(matching_folders)} matching folder(s)")
        logging.info(f"Latest Folder: {latest_folder}")
        logging.info(f"Full Path: {full_path}")
        logging.info("=" * 80)

        return full_path, latest_folder
    except Exception as e:
        logging.error(f"Error finding latest schema folder: {e}")
        return None, None


def extract_mode_from_folder_name(folder_name):
    """
    Extracts the execution mode ('all' or 'selected') from folder name.
    Folder format: schema_env_mode_timestamp
    Example: mktg_ops_tbls_dev_all_20260121_1314
    Returns: 'all' or 'selected', defaults to 'all' if not found
    """
    try:
        parts = folder_name.split('_')
        # Look for 'all' or 'selected' in the folder name parts
        for part in parts:
            if part in ['all', 'selected']:
                return part
        # Default to 'all' if mode not found (backward compatibility)
        logging.warning(f"Could not extract mode from folder name: {folder_name}. Defaulting to 'all'")
        return 'all'
    except Exception as e:
        logging.error(f"Error extracting mode from folder name: {e}")
        return 'all'
        return 'all'

    except Exception as e:
        logging.error(f"Error finding latest schema folder: {e}")
        return None, None


# Setup logging with dynamic file names and timestamps
def setup_logging(log_directory, run_identifier):
    try:
        os.makedirs(log_directory, exist_ok=True)

        # Add timestamp to log file name
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        log_file = os.path.join(log_directory, f"{run_identifier}_{timestamp}_log.log")

        # Clear any existing handlers
        for handler in logging.root.handlers[:]:
            logging.root.removeHandler(handler)

        logging.basicConfig(
            filename=log_file,
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            filemode='w'  # Each run creates a new file due to timestamp
        )

        # Also log to console
        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
        console.setFormatter(formatter)
        logging.getLogger('').addHandler(console)

        logging.info("=" * 80)
        logging.info(f"Starting DDL Execution Script - {run_identifier}")
        logging.info(f"Timestamp: {timestamp}")
        logging.info("=" * 80)

        return log_file
    except Exception as e:
        print(f"Error setting up logging: {e}")
        return None


# Connect to Redshift - DYNAMIC ENVIRONMENT SELECTION
def connect_to_redshift(config, environment):
    try:
        # Get the selected environment config
        if environment not in config['environments']:
            logging.error(f"Environment '{environment}' not found in configuration")
            print(f"Error: Environment '{environment}' not found in configuration")
            return None, None
        
        env_config = config['environments'][environment]
        
        username = input("Enter Redshift username: ")
        password = pwinput.pwinput(prompt="Enter Redshift password: ", mask="*")
        connection = psycopg2.connect(
            host=env_config['host'],
            port=env_config['port'],
            dbname=env_config['dbname'],
            user=username,
            password=password
        )
        logging.info(f"Successfully connected to Redshift {environment.upper()}: {env_config['host']}")
        logging.info(f"Database: {env_config['dbname']}, User: {username}")
        del password  # Remove password from memory
        return connection, username  # Return both connection and username
    except Exception as e:
        logging.error(f"Error connecting to Redshift: {e}")
        print(f"Error connecting to Redshift: {e}")
        return None, None


# Get all DDL/SQL files from the schema folder
def get_ddl_files(schema_folder_path):
    try:
        if not os.path.exists(schema_folder_path):
            logging.error(f"Schema path does not exist: {schema_folder_path}")
            return []

        ddl_files = [f for f in os.listdir(schema_folder_path) if f.endswith('.sql')]
        logging.info(f"Found {len(ddl_files)} SQL files in {schema_folder_path}")
        return ddl_files
    except Exception as e:
        logging.error(f"Error reading SQL files: {e}")
        return []


# Read DDL/SQL content from file
def read_ddl_file(schema_folder_path, file_name):
    try:
        file_path = os.path.join(schema_folder_path, file_name)

        # Check if file exists
        if not os.path.exists(file_path):
            logging.error(f"File does not exist: {file_path}")
            return None

        # Try different encodings
        encodings = ['utf-8', 'latin-1', 'cp1252', 'iso-8859-1']

        for encoding in encodings:
            try:
                with open(file_path, 'r', encoding=encoding) as file:
                    ddl_content = file.read()
                    if ddl_content.strip():  # If content is not empty
                        logging.debug(f"Successfully read {file_name} with encoding: {encoding}")
                        return ddl_content
            except UnicodeDecodeError:
                continue

        # If all encodings fail, log the error
        logging.error(f"Could not read file {file_name} with any encoding")
        return None

    except Exception as e:
        logging.error(f"Error reading SQL file {file_name}: {e}")
        logging.error(f"Full path attempted: {file_path}")
        return None


# Apply grants to created objects
def apply_grants(connection, schema_name, object_name, object_type, grant_preference):
    """
    Apply grants to tables, views, or procedures based on preference.
    grant_preference: 'both', 'writer', 'reader', or 'none'
    For procedures: always applies GRANT EXECUTE
    For tables/views: applies based on grant_preference
    Returns: (success, error_message, detailed_grant_status)
    """
    try:
        cursor = connection.cursor()
        grant_status = ""
        
        if object_type.lower() == 'procedure':
            # Check grant_preference for procedures
            if grant_preference == 'both':
                # Grant EXECUTE to mods_bi_writer
                grant_sql = f"GRANT EXECUTE ON PROCEDURE {schema_name}.{object_name}() TO ROLE mods_bi_writer;"
                cursor.execute(grant_sql)
                connection.commit()
                grant_status = "GRANT EXECUTE (mods_bi_writer)"
                logging.info(f"✓ Granted EXECUTE on procedure: {object_name}")
            elif grant_preference == 'none':
                # Skip grants for procedure
                logging.info(f"⊘ Skipped grants for procedure: {object_name}")
                grant_status = "N/A"
            
            cursor.close()
            return True, None, grant_status
        
        elif object_type.lower() in ('table', 'view'):
            if grant_preference == 'both':
                # Grant ALL to mods_bi_writer and SELECT to mods_bi_reader_vt
                grant_all_sql = f"GRANT ALL ON TABLE {schema_name}.{object_name} TO ROLE mods_bi_writer;"
                grant_select_sql = f"GRANT SELECT ON TABLE {schema_name}.{object_name} TO ROLE mods_bi_reader_vt;"
                
                cursor.execute(grant_all_sql)
                connection.commit()
                logging.info(f"✓ Granted ALL on {object_type}: {object_name} to mods_bi_writer")
                
                cursor.execute(grant_select_sql)
                connection.commit()
                logging.info(f"✓ Granted SELECT on {object_type}: {object_name} to mods_bi_reader_vt")
                grant_status = "GRANT ALL (mods_bi_writer), SELECT (mods_bi_reader_vt)"
                
            elif grant_preference == 'writer':
                # Grant ALL only to mods_bi_writer
                grant_all_sql = f"GRANT ALL ON TABLE {schema_name}.{object_name} TO ROLE mods_bi_writer;"
                cursor.execute(grant_all_sql)
                connection.commit()
                logging.info(f"✓ Granted ALL on {object_type}: {object_name} to mods_bi_writer")
                grant_status = "GRANT ALL (mods_bi_writer)"
            
            elif grant_preference == 'reader':
                # Grant SELECT only to mods_bi_reader_vt
                grant_select_sql = f"GRANT SELECT ON TABLE {schema_name}.{object_name} TO ROLE mods_bi_reader_vt;"
                cursor.execute(grant_select_sql)
                connection.commit()
                logging.info(f"✓ Granted SELECT on {object_type}: {object_name} to mods_bi_reader_vt")
                grant_status = "SELECT (mods_bi_reader_vt)"
            
            elif grant_preference == 'none':
                logging.info(f"⊘ Skipped grants for {object_type}: {object_name}")
                grant_status = "N/A"
            
            cursor.close()
            return True, None, grant_status
        else:
            cursor.close()
            return False, f"Unknown object type: {object_type}", "N/A"
    
    except psycopg2.Error as e:
        connection.rollback()
        error_message = str(e).strip()
        logging.warning(f"✗ Failed to grant permissions on {object_type} {object_name}: {error_message}")
        # Capture error in grant_status for audit trail
        error_status = f"ERROR: {error_message[:200]}"  # Truncate if too long
        return False, error_message, error_status
    except Exception as e:
        connection.rollback()
        logging.warning(f"✗ Unexpected error granting permissions on {object_type} {object_name}: {str(e)}")
        # Capture error in grant_status for audit trail
        error_status = f"ERROR: {str(e)[:200]}"  # Truncate if too long
        return False, str(e), error_status


# Drop table if exists (for tables only)
def drop_table_if_exists(connection, schema_name, table_name):
    """
    Drops a table if it exists before creating it
    Only used for TABLE object type
    Returns: (drop_status, row_count_before_drop)
    drop_status: 'Dropped' (existed & dropped), 'Failed' (existed but drop failed), 'Not_Found' (didn't exist)
    row_count_before_drop: numeric count or None if not found
    """
    try:
        cursor = connection.cursor()
        
        # First check if table exists and get row count
        check_sql = f"SELECT COUNT(*) FROM {schema_name}.{table_name};"
        try:
            cursor.execute(check_sql)
            row_count = cursor.fetchone()[0]
            cursor.close()
            
            # Table exists, now drop it
            cursor = connection.cursor()
            drop_sql = f"DROP TABLE IF EXISTS {schema_name}.{table_name};"
            cursor.execute(drop_sql)
            connection.commit()
            cursor.close()
            logging.info(f"  Dropped existing table: {table_name} (had {row_count} rows)")
            return "Dropped", row_count
        except psycopg2.Error as e:
            cursor.close()
            # Table doesn't exist
            if "does not exist" in str(e).lower():
                logging.info(f"  Table does not exist: {table_name}")
                connection.rollback()  # CRITICAL: Rollback failed transaction
                return "Not_Found", None
            else:
                # Some other error checking the table
                logging.warning(f"  Error checking if table exists: {str(e).strip()}")
                connection.rollback()  # CRITICAL: Rollback failed transaction
                return "Failed", None
    
    except Exception as e:
        logging.warning(f"  Unexpected error in drop_table_if_exists {table_name}: {str(e)}")
        try:
            connection.rollback()  # Try to rollback
        except:
            pass
        return "Failed", None


# Execute DDL/SQL and categorize results
def execute_ddl(connection, ddl_content, schema_name, object_name, object_type):
    """
    Execute DDL content and track drop/create status
    Returns: (success, error_type, error_message, drop_status, row_count_before_drop)
    """
    drop_status = "N/A"
    row_count_before_drop = None
    
    try:
        # For tables, drop first and capture drop_status and row count
        if object_type.lower() == 'table':
            drop_status, row_count_before_drop = drop_table_if_exists(connection, schema_name, object_name)

        # For views, drop if exists (no row count for views)
        if object_type.lower() == 'view':
            drop_view_sql = f"DROP VIEW IF EXISTS {schema_name}.{object_name};"
            cursor = connection.cursor()
            cursor.execute(drop_view_sql)
            connection.commit()
            cursor.close()
            drop_status = "Dropped"

        # For procedures, no drop needed - use CREATE OR REPLACE PROCEDURE
        if object_type.lower() == 'procedure':
            drop_status = "N/A"  # Procedures use CREATE OR REPLACE, not drop/create

        # Now create the object
        cursor = connection.cursor()
        cursor.execute(ddl_content)
        connection.commit()
        cursor.close()
        return True, None, None, drop_status, row_count_before_drop
    
    except psycopg2.Error as e:
        connection.rollback()
        error_message = str(e).strip()

        # Categorize errors
        if "permission denied" in error_message.lower() or "must be owner" in error_message.lower():
            error_type = "PERMISSION_ERROR"
        elif "does not exist" in error_message.lower():
            error_type = "DEPENDENCY_ERROR"
        elif "already exists" in error_message.lower():
            error_type = "ALREADY_EXISTS"
        elif "syntax error" in error_message.lower():
            error_type = "SYNTAX_ERROR"
        else:
            error_type = "OTHER_ERROR"

        return False, error_type, error_message, drop_status, row_count_before_drop
    except Exception as e:
        connection.rollback()
        return False, "UNKNOWN_ERROR", str(e), drop_status, row_count_before_drop


# Validate a single view
def validate_view(connection, schema_name, view_name):
    """
    Validates a view by executing SELECT * LIMIT 0
    Returns (success: bool, error_message: str or None)
    """
    try:
        cursor = connection.cursor()
        validation_query = f"SELECT * FROM {schema_name}.{view_name} LIMIT 0;"
        cursor.execute(validation_query)
        cursor.close()
        connection.commit()  # Commit successful validation
        return True, None
    except psycopg2.Error as e:
        connection.rollback()  # CRITICAL: Rollback failed transaction
        error_message = str(e).strip()
        # Truncate error message if too long
        error_msg_short = error_message[:500] if len(error_message) > 500 else error_message
        return False, error_msg_short
    except Exception as e:
        connection.rollback()  # CRITICAL: Rollback failed transaction
        return False, str(e)


# Validate a table
def validate_table(connection, schema_name, table_name):
    """
    Validates a table by executing a lightweight query that returns at most one row.
    Returns (success: bool, error_message: str or None)
    """
    try:
        cursor = connection.cursor()
        validation_query = f"SELECT 1 FROM {schema_name}.{table_name} LIMIT 1;"
        cursor.execute(validation_query)
        cursor.close()
        connection.commit()
        return True, None
    except psycopg2.Error as e:
        connection.rollback()
        error_message = str(e).strip()
        error_msg_short = error_message[:500] if len(error_message) > 500 else error_message
        return False, error_msg_short
    except Exception as e:
        connection.rollback()
        return False, str(e)


# Validate all created objects for a specific object type (VIEW or TABLE)
def validate_all_objects(connection, created_file, schema_name, object_type):
    """
    Reads created.csv, validates each object of object_type, and updates the CSV with validation results
    Runs for VIEW and TABLE
    """
    try:
        logging.info("=" * 80)
        logging.info(f"STARTING {object_type.upper()} VALIDATION")
        logging.info("=" * 80)

        # Read the created CSV
        rows = []
        with open(created_file, 'r', newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                rows.append(row)

        if not rows:
            logging.info(f"No {object_type.lower()}s to validate")
            return 0, 0

        # Filter rows for the requested object type
        to_validate = [r for r in rows if r['object_type'].lower() == object_type.lower()]

        if not to_validate:
            logging.info(f"No {object_type.lower()}s to validate")
            return 0, 0

        logging.info(f"Found {len(to_validate)} {object_type.lower()}(s) to validate")

        validated_ok = 0
        validation_failed = 0

        # Validate each object
        for obj in to_validate:
            name = obj['object_name']

            if object_type.lower() == 'view':
                success, error_message = validate_view(connection, schema_name, name)
            else:  # table
                success, error_table = validate_table(connection, schema_name, name)

            if success:
                logging.info(f"✓ Validation successful: {name}")
                obj['validation_status'] = 'VALIDATED_OK'
                obj['validation_error'] = ''
                validated_ok += 1
            else:
                logging.warning(f"✗ Validation failed: {name} - {error_message}")
                obj['validation_status'] = 'VALIDATION_FAILED'
                obj['validation_error'] = error_message
                validation_failed += 1

        # Merge updated rows back and write CSV
        updated_rows = []
        validated_names = {r['object_name'] for r in to_validate}
        for original in rows:
            if original['object_name'] in validated_names and original['object_type'].lower() == object_type.lower():
                # find updated row
                updated = next((r for r in to_validate if r['object_name'] == original['object_name']), original)
                updated_rows.append(updated)
            else:
                updated_rows.append(original)

        # Rewrite the CSV with validation columns and all audit columns
        with open(created_file, 'w', newline='', encoding='utf-8') as f:
            fieldnames = ['object_name', 'schema_name', 'object_type', 'status',
                          'validation_status', 'validation_error', 'created_timestamp',
                          'drop_status', 'row_count_before_drop', 'grant_status']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(updated_rows)

        logging.info("=" * 80)
        logging.info(f"{object_type.upper()} VALIDATION SUMMARY")
        logging.info("=" * 80)
        logging.info(f"Total {object_type.capitalize()}s Validated: {len(to_validate)}")
        logging.info(f"✓ Validated Successfully: {validated_ok}")
        logging.info(f"✗ Validation Failed: {validation_failed}")
        logging.info(f"Validation Success Rate: {(validated_ok / len(to_validate) * 100):.2f}%")
        logging.info("=" * 80)

        return validated_ok, validation_failed

    except Exception as e:
        logging.error(f"Error during {object_type.lower()} validation: {e}")
        return 0, 0


# Initialize CSV files with dynamic names and timestamps
def initialize_csv_files(output_directory, run_identifier, object_type):
    try:
        # Create object-type specific output directory
        object_output_dir = os.path.join(output_directory, object_type.capitalize())
        os.makedirs(object_output_dir, exist_ok=True)

        # Add timestamp to CSV file names
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        created_file = os.path.join(object_output_dir, f"{run_identifier}_{timestamp}_created.csv")
        errored_file = os.path.join(object_output_dir, f"{run_identifier}_{timestamp}_errored.csv")

        # Created objects CSV - with validation columns and audit columns for all types
        with open(created_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['object_name', 'schema_name', 'object_type', 'status',
                             'validation_status', 'validation_error', 'created_timestamp',
                             'drop_status', 'row_count_before_drop', 'grant_status'])

        # Errored objects CSV
        with open(errored_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['object_name', 'schema_name', 'object_type', 'error_type', 'error_message', 'timestamp'])

        logging.info(f"Initialized CSV files with timestamp: {timestamp}")
        logging.info(f"  - Output Directory: {object_output_dir}")
        logging.info(f"  - Created: {created_file}")
        logging.info(f"  - Errored: {errored_file}")

        return created_file, errored_file
    except Exception as e:
        logging.error(f"Error initializing CSV files: {e}")
        return None, None


# Write to created CSV
def write_to_created_csv(created_file, object_name, schema_name, object_type, 
                         drop_status="N/A", row_count_before_drop=None, grant_status="N/A"):
    try:
        with open(created_file, 'a', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            # Format row count for CSV
            row_count_str = str(row_count_before_drop) if row_count_before_drop is not None else "N/A"
            
            if object_type.lower() in ('view', 'table'):
                writer.writerow([object_name, schema_name, object_type, 'SUCCESS',
                                 'PENDING', '', datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                                 drop_status, row_count_str, grant_status])
            else:
                writer.writerow([object_name, schema_name, object_type, 'SUCCESS',
                                 'N/A', '', datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                                 drop_status, "N/A", grant_status])
    except Exception as e:
        logging.error(f"Error writing to created CSV: {e}")


# Write to errored CSV
def write_to_errored_csv(errored_file, object_name, schema_name, object_type, error_type, error_message):
    try:
        with open(errored_file, 'a', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            # Truncate error message if too long
            error_msg_short = error_message[:500] if len(error_message) > 500 else error_message
            writer.writerow([object_name, schema_name, object_type, error_type, error_msg_short,
                             datetime.now().strftime('%Y-%m-%d %H:%M:%S')])
    except Exception as e:
        logging.error(f"Error writing to errored CSV: {e}")


# Get exclusion list from target database
def get_exclusion_list_from_target(connection, object_type):
    """
    Fetch list of excluded objects from target DB exclusion table
    Returns a set of ("schema_name", "object_name") tuples for fast lookup
    """
    try:
        cursor = connection.cursor()
        
        # Query the exclusion table to get excluded objects
        query = """
            SELECT schema_name, object_name 
            FROM mods_bi.etl_config.fetch_all_objects_exclude_ctl
            WHERE object_type = %s
        """
        
        cursor.execute(query, (object_type.lower(),))
        results = cursor.fetchall()
        cursor.close()
        
        # Convert to set of tuples for O(1) lookup
        exclusion_set = set(results)
        logging.info(f"Retrieved {len(exclusion_set)} exclusion entries for {object_type} from target DB")
        
        return exclusion_set
        
    except Exception as e:
        logging.error(f"Error fetching exclusion list from target DB: {e}")
        print(f"Warning: Could not fetch exclusion list from target DB: {e}")
        # Return empty set if query fails - safer to proceed without filtering
        return set()


# Initialize skipped CSV file
def initialize_skipped_csv(skipped_file):
    try:
        with open(skipped_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['object_name', 'schema_name', 'object_type', 'reason'])
        logging.info(f"Initialized skipped CSV file: {skipped_file}")
        return True
    except Exception as e:
        logging.error(f"Error initializing skipped CSV: {e}")
        return False


# Write to skipped CSV
def write_to_skipped_csv(skipped_file, object_name, schema_name, object_type, reason):
    try:
        with open(skipped_file, 'a', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow([object_name, schema_name, object_type, reason])
        logging.info(f"Skipped {object_type}: {schema_name}.{object_name} - Reason: {reason}")
    except Exception as e:
        logging.error(f"Error writing to skipped CSV: {e}")


# Get next LOAD_ID from audit table
def get_next_load_id(connection):
    """
    Query the audit table to get the maximum LOAD_ID and return the next one.
    If table is empty, returns 1.
    """
    try:
        cursor = connection.cursor()
        query = "SELECT MAX(load_id) FROM mods_bi.etl_config.create_object_audit_log;"
        cursor.execute(query)
        result = cursor.fetchone()
        cursor.close()
        
        max_load_id = result[0] if result and result[0] is not None else 0
        next_load_id = max_load_id + 1
        logging.info(f"Generated next LOAD_ID: {next_load_id}")
        return next_load_id
    except Exception as e:
        logging.warning(f"Could not fetch next LOAD_ID from audit table: {e}. Starting with LOAD_ID=1")
        return 1


# Update audit record with validation results
def update_audit_validation_status(connection, load_id, object_name, validation_status, validation_error=None):
    """
    Update an existing audit record with validation results after validation is complete
    """
    try:
        cursor = connection.cursor()
        
        update_query = """
            UPDATE mods_bi.etl_config.create_object_audit_log 
            SET validation_status = %s, validation_error = %s
            WHERE load_id = %s AND object_name = %s;
        """
        
        cursor.execute(update_query, (validation_status, validation_error, load_id, object_name))
        connection.commit()
        cursor.close()
        logging.debug(f"Updated audit record for {object_name} with validation status: {validation_status}")
        
    except Exception as e:
        logging.error(f"Error updating audit record for {object_name}: {e}")
        try:
            connection.rollback()
        except:
            pass


# Bulk insert audit records from CSV files
def bulk_insert_audit_records(connection, created_file, errored_file, skipped_file, 
                             load_id, schema_name, object_type, execution_mode, 
                             source_env, target_env, username):
    """
    Read all 3 CSV files (created, errored, skipped) and insert all records into audit_log
    This is done at the end after processing and validation
    """
    try:
        logging.info("=" * 80)
        logging.info("BULK INSERTING AUDIT RECORDS FROM CSV FILES")
        logging.info("=" * 80)
        
        cursor = connection.cursor()
        total_inserted = 0
        
        # Read and insert from created.csv
        if os.path.exists(created_file):
            with open(created_file, 'r', newline='', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    obj_name = row['object_name']
                    validation_status = row.get('validation_status', 'PENDING')
                    validation_error = row.get('validation_error', '')
                    drop_status = row.get('drop_status', 'N/A')
                    row_count_before_drop = row.get('row_count_before_drop', 'N/A')
                    grant_status = row.get('grant_status', 'N/A')
                    
                    insert_query = """
                        INSERT INTO mods_bi.etl_config.create_object_audit_log 
                        (load_id, object_name, schema_name, object_type, execution_mode, create_status,
                         validation_status, validation_error, drop_status, row_count_before_drop, grant_status,
                         source_environment, target_environment, updated_by)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                    """
                    # Convert row_count_before_drop to int or None
                    row_count_val = None
                    if row_count_before_drop and row_count_before_drop != 'N/A':
                        try:
                            row_count_val = int(row_count_before_drop)
                        except:
                            row_count_val = None
                    
                    cursor.execute(insert_query, (
                        load_id, obj_name, schema_name, object_type, execution_mode,
                        'CREATED', validation_status, validation_error if validation_error else None,
                        drop_status, row_count_val, grant_status,
                        source_env, target_env, username
                    ))
                    total_inserted += 1
            
            connection.commit()
            logging.info(f"Inserted {total_inserted} created records from CSV")
        
        # Read and insert from errored.csv
        if os.path.exists(errored_file):
            errored_count = 0
            with open(errored_file, 'r', newline='', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    obj_name = row['object_name']
                    error_type = row.get('error_type', '')
                    error_message = row.get('error_message', '')
                    
                    insert_query = """
                        INSERT INTO mods_bi.etl_config.create_object_audit_log 
                        (load_id, object_name, schema_name, object_type, execution_mode, create_status,
                         create_error_type, create_error_message, source_environment, target_environment, updated_by)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                    """
                    cursor.execute(insert_query, (
                        load_id, obj_name, schema_name, object_type, execution_mode,
                        'FAILED', error_type, error_message if error_message else None,
                        source_env, target_env, username
                    ))
                    errored_count += 1
                    total_inserted += 1
            
            connection.commit()
            logging.info(f"Inserted {errored_count} errored records from CSV")
        
        # Read and insert from skipped.csv
        if os.path.exists(skipped_file):
            skipped_count = 0
            with open(skipped_file, 'r', newline='', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    obj_name = row['object_name']
                    reason = row.get('reason', '')
                    
                    insert_query = """
                        INSERT INTO mods_bi.etl_config.create_object_audit_log 
                        (load_id, object_name, schema_name, object_type, execution_mode, create_status,
                         skip_reason, source_environment, target_environment, updated_by)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                    """
                    cursor.execute(insert_query, (
                        load_id, obj_name, schema_name, object_type, execution_mode,
                        'SKIPPED', reason if reason else None,
                        source_env, target_env, username
                    ))
                    skipped_count += 1
                    total_inserted += 1
            
            connection.commit()
            logging.info(f"Inserted {skipped_count} skipped records from CSV")
        
        cursor.close()
        logging.info("=" * 80)
        logging.info(f"TOTAL AUDIT RECORDS INSERTED: {total_inserted}")
        logging.info("=" * 80)
        
    except Exception as e:
        logging.error(f"Error bulk inserting audit records: {e}")
        try:
            connection.rollback()
        except:
            pass


# Process all DDL files
def process_ddl_files(connection, config, grant_preference, db_username):
    ddl_base_path = config['paths']['ddl_base_path']
    schema_name = config['object_config']['schema_name']
    object_type = config['object_config']['object_type']
    run_identifier = config['object_config']['run_identifier']
    output_base_directory = config['paths']['output_directory']

    # Check if source and target environments are the same
    source_env = config['object_config'].get('source_environment')
    target_env = config['object_config'].get('target_environment')
    if source_env is not None and target_env is not None and source_env == target_env:
        print("\n" + "=" * 80)
        print("ERROR: SOURCE AND TARGET ENVIRONMENTS ARE THE SAME. OPERATION TERMINATED.")
        print("PLEASE CONFIGURE DIFFERENT ENVIRONMENTS BEFORE PROCEEDING.")
        print("=" * 80)
        logging.error("Source and target environments are the same. Operation terminated.")
        return

    retry_enabled = config['execution']['retry_failed_objects']
    max_retries = config['execution']['max_retries']
    batch_size = config['execution']['batch_size']

    # Find the latest timestamped folder dynamically
    schema_folder_path, latest_folder_name = find_latest_schema_folder(ddl_base_path, object_type, schema_name)
    if not schema_folder_path or not latest_folder_name:
        logging.error("Could not find schema folder. Exiting.")
        return

    # Extract execution mode from folder name (e.g., 'all' or 'selected' from folder like schema_env_all_timestamp)
    execution_mode = extract_mode_from_folder_name(latest_folder_name)
    logging.info(f"Extracted execution mode from folder: {execution_mode}")

    # USER CONFIRMATION
    print("\n" + "=" * 80)
    print("FOLDER CONFIRMATION")
    print("=" * 80)
    print(f"I am going to use this folder: {latest_folder_name}")
    print(f"Execution Mode: {execution_mode.upper()}")
    print(f"Full path: {schema_folder_path}")
    print("=" * 80)
    confirmation = input("\nIs this correct? (Y/N): ").strip().upper()

    if confirmation != 'Y':
        print("\n❌ Operation cancelled by user.")
        logging.info("User cancelled operation - folder not confirmed")
        return

    print("\n✓ Confirmed. Proceeding with object creation...\n")
    logging.info("User confirmed folder selection")

    # Initialize CSV files in object-type specific directory
    created_file, errored_file = initialize_csv_files(
        output_base_directory, run_identifier, object_type
    )
    if not created_file or not errored_file:
        logging.error("Failed to initialize CSV files. Exiting.")
        return

    # Initialize skipped CSV file (for excluded objects)
    skipped_file = created_file.replace('_created.csv', '_skipped.csv')
    initialize_skipped_csv(skipped_file)

    # Get exclusion list from target DB
    exclusion_list = get_exclusion_list_from_target(connection, object_type)

    # Get next LOAD_ID for audit logging
    load_id = get_next_load_id(connection)
    
    # Get all DDL files
    ddl_files = get_ddl_files(schema_folder_path)
    if not ddl_files:
        logging.warning("No SQL files found to process")
        return

    # Statistics
    total_objects = len(ddl_files)
    created_count = 0
    errored_count = 0
    skipped_count = 0
    dependency_errors = []

    logging.info("=" * 80)
    logging.info(f"Processing Configuration:")
    logging.info(f"  - Schema: {schema_name}")
    logging.info(f"  - Object Type: {object_type.upper()}")
    logging.info(f"  - Execution Mode: {execution_mode.upper()}")
    logging.info(f"  - Total Objects in Folder: {total_objects}")
    logging.info(f"  - Run Identifier: {run_identifier}")
    logging.info("=" * 80)

    # First pass: Try to create all objects
    for idx, file_name in enumerate(ddl_files, 1):
        object_name = file_name.replace('.sql', '')

        # Log progress every batch_size objects
        if idx % batch_size == 0:
            logging.info(f"Progress: {idx}/{total_objects} {object_type}s processed")

        # Read DDL content
        ddl_content = read_ddl_file(schema_folder_path, file_name)
        if not ddl_content:
            logging.error(f"Skipping {object_name} - Could not read SQL file")
            write_to_errored_csv(errored_file, object_name, schema_name, object_type,
                                 "FILE_READ_ERROR", "Could not read SQL file")
            errored_count += 1
            continue

        # Check if object is in exclusion list (skip if excluded)
        if (schema_name, object_name) in exclusion_list:
            write_to_skipped_csv(skipped_file, object_name, schema_name, object_type,
                                "Excluded via target DB exclusion table")
            skipped_count += 1
            continue

        # For tables, check record count for BOTH 'all' and 'selected' modes
        row_count_captured = None
        if object_type.lower() == 'table':
            try:
                cursor = connection.cursor()
                count_sql = f"SELECT COUNT(*) FROM {schema_name}.{object_name};"
                cursor.execute(count_sql)
                row_count_captured = cursor.fetchone()[0]
                cursor.close()
                
                # ONLY prompt user if mode is 'all' AND count > 100k
                if execution_mode == 'all' and row_count_captured > 100000:
                    msg = f"Have you configured the exclusion table? Data found: {row_count_captured} records in {schema_name}.{object_name}. Override/Proceed (Yes/No)? "
                    user_input = input(msg).strip().lower()
                    if user_input != 'yes':
                        # Skip only this table, continue with others (not all remaining)
                        skip_reason = f"Data was over 100k ({row_count_captured} records) and user said to skip the table."
                        write_to_skipped_csv(skipped_file, object_name, schema_name, object_type,
                                            skip_reason)
                        skipped_count += 1
                        continue
                # If mode is 'selected', count is captured but no prompt shown
            except psycopg2.Error as e:
                error_msg = str(e).lower()
                if "does not exist" in error_msg:
                    # Table doesn't exist - this is expected, proceed to create
                    logging.info(f"Table does not exist yet (expected): {object_name} - will proceed with creation")
                    row_count_captured = None
                    connection.rollback()  # Rollback the failed transaction
                else:
                    logging.warning(f"Could not check record count for {object_name}: {str(e)}")
                    connection.rollback()  # Rollback any failed transaction
            except Exception as e:
                logging.warning(f"Could not check record count for {object_name}: {str(e)}")
                connection.rollback()  # Rollback any failed transaction

        # Execute DDL (returns drop_status and row_count_before_drop)
        success, error_type, error_message, drop_status, row_count_before_drop = execute_ddl(connection, ddl_content, schema_name, object_name, object_type)

        if success:
            logging.info(f"✓ Successfully created {object_type}: {object_name}")
            # Apply grants after successful creation (returns detailed grant_status)
            grant_success, grant_error, grant_status = apply_grants(connection, schema_name, object_name, object_type, grant_preference)
            if not grant_success and grant_error:
                logging.warning(f"  Grant error: {grant_error}")
            
            # For tables, use captured row count; for others use returned row count (N/A)
            if object_type.lower() == 'table':
                row_count_for_csv = row_count_before_drop
            else:
                row_count_for_csv = None
            
            write_to_created_csv(created_file, object_name, schema_name, object_type, 
                               drop_status, row_count_for_csv, grant_status)
            created_count += 1
        else:
            logging.warning(f"✗ Failed to create {object_type}: {object_name} - Error Type: {error_type}")
            write_to_errored_csv(errored_file, object_name, schema_name, object_type, error_type, error_message)
            errored_count += 1

            # Track dependency errors for retry
            if error_type == "DEPENDENCY_ERROR" and retry_enabled:
                dependency_errors.append((object_name, file_name))

    # Retry logic for dependency errors
    if retry_enabled and dependency_errors:
        logging.info("=" * 80)
        logging.info(f"Starting retry logic for {len(dependency_errors)} dependency errors")
        logging.info("=" * 80)

        retry_count = 0
        while dependency_errors and retry_count < max_retries:
            retry_count += 1
            logging.info(f"Retry attempt {retry_count}/{max_retries} for {len(dependency_errors)} {object_type}s")

            still_failing = []

            for object_name, file_name in dependency_errors:
                ddl_content = read_ddl_file(schema_folder_path, file_name)
                if not ddl_content:
                    still_failing.append((object_name, file_name))
                    continue

                success, error_type, error_message, drop_status, row_count_before_drop = execute_ddl(
                    connection, ddl_content, schema_name, object_name, object_type)

                if success:
                    logging.info(f"✓ Successfully created {object_type} on retry: {object_name}")
                    # Apply grants for retry case
                    grant_success, grant_error, grant_status = apply_grants(connection, schema_name, object_name, object_type, grant_preference)
                    
                    if object_type.lower() == 'table':
                        row_count_for_csv = row_count_before_drop
                    else:
                        row_count_for_csv = None
                    
                    write_to_created_csv(created_file, object_name, schema_name, object_type,
                                       drop_status, row_count_for_csv, grant_status)
                    created_count += 1
                    errored_count -= 1
                elif error_type == "DEPENDENCY_ERROR":
                    still_failing.append((object_name, file_name))
                # If it's a different error now, it stays in the errored file

            if not still_failing:
                logging.info("All dependency errors resolved!")
                break

            if len(still_failing) == len(dependency_errors):
                logging.warning(f"No progress made in retry {retry_count}. Stopping retries.")
                break

            dependency_errors = still_failing

    # OBJECT VALIDATION - Run for VIEW and TABLE
    validated_ok = 0
    validation_failed = 0
    if object_type.lower() in ('view', 'table') and created_count > 0:
        validated_ok, validation_failed = validate_all_objects(connection, created_file, schema_name, object_type)

    # Final summary
    success_rate = (created_count / total_objects * 100) if total_objects > 0 else 0

    logging.info("=" * 80)
    logging.info("EXECUTION SUMMARY")
    logging.info("=" * 80)
    logging.info(f"Object Type: {object_type.upper()}")
    logging.info(f"Schema: {schema_name}")
    logging.info(f"Total Objects in Folder: {total_objects}")
    logging.info(f"Successfully Created: {created_count}")
    logging.info(f"Skipped (Excluded): {skipped_count}")
    logging.info(f"Failed: {errored_count}")
    logging.info(f"Success Rate: {success_rate:.2f}%")

    # Add validation summary for views/tables
    if object_type.lower() in ('view', 'table') and created_count > 0:
        overall_success = validated_ok
        overall_total = created_count
        overall_rate = (overall_success / overall_total * 100) if overall_total > 0 else 0
        logging.info("")
        logging.info(f"{object_type.upper()} VALIDATION RESULTS:")
        logging.info(f"✓ Validated Successfully: {validated_ok}")
        logging.info(f"✗ Validation Failed: {validation_failed}")
        logging.info(f"Overall Success Rate (Created + Validated): {overall_rate:.2f}%")

    logging.info(f"Created objects saved to: {created_file}")
    logging.info(f"Skipped objects saved to: {skipped_file}")
    logging.info(f"Errored objects saved to: {errored_file}")
    logging.info("=" * 80)

    print("\n" + "=" * 80)
    print("EXECUTION COMPLETED")
    print("=" * 80)
    print(f"Object Type: {object_type.upper()}")
    print(f"Schema: {schema_name}")
    print(f"Total Objects in Folder: {total_objects}")
    print(f"✓ Successfully created: {created_count} {object_type}s")
    print(f"⊘ Skipped (Excluded): {skipped_count} {object_type}s")
    print(f"✗ Failed: {errored_count} {object_type}s")
    print(f"Success Rate: {success_rate:.2f}%")

    # Add validation summary for views/tables
    if object_type.lower() in ('view','table') and created_count > 0:
        overall_rate = (validated_ok / created_count * 100) if created_count > 0 else 0
        print(f"\n{object_type.upper()} VALIDATION:")
        print(f"✓ Validated OK: {validated_ok} {object_type.lower()}s")
        print(f"✗ Validation Failed: {validation_failed} {object_type.lower()}s")
        print(f"Overall Success Rate (Created + Validated): {overall_rate:.2f}%")

    print(f"\nCreated objects: {created_file}")
    if skipped_count > 0:
        print(f"Skipped objects: {skipped_file}")
    print(f"Errored objects: {errored_file}")
    print("=" * 80)

    # Bulk insert all audit records from CSV files
    bulk_insert_audit_records(connection, created_file, errored_file, skipped_file,
                             load_id, schema_name, object_type, execution_mode,
                             source_env, target_env, db_username)


# Main function
def main():
    # Load configuration
    config = load_config()
    if not config:
        print("Failed to load configuration. Exiting.")
        return

    # Get user selections via interactive prompts
    target_environment = prompt_environment_selection(source_type="target")
    object_type = prompt_object_type_selection()
    schema_name = prompt_schema_name()
    
    # Prompt to confirm exclusion table is configured on target DB
    prompt_exclusion_table_configured()
    
    # Prompt for grant preference based on object type
    if object_type.lower() == 'procedure':
        grant_preference = prompt_grant_preference_for_procedure()
    else:
        grant_preference = prompt_grant_preference()

    # Extract source environment from the fetched files by looking at folder names
    ddl_base_path = config['paths']['ddl_base_path']
    schema_folder_path, latest_folder_name = find_latest_schema_folder(ddl_base_path, object_type, schema_name)
    
    if not schema_folder_path:
        print("❌ Could not find any fetched DDL files for this schema and object type.")
        print(f"   Please run fetch_objects.py first to extract DDL files.")
        logging.error("Could not find fetched DDL files")
        return
    
    # Extract source environment from folder name (format: schema_tables_test_20260119_1234)
    # The folder name contains the environment as the last part before timestamp
    source_environment = None
    folder_parts = latest_folder_name.split('_')
    # Look for environment indicator (test, dev, prod) in the folder name
    for part in folder_parts:
        if part in ['test', 'dev', 'prod']:
            source_environment = part
            break
    
    if not source_environment:
        print("❌ Could not determine source environment from fetched files.")
        print(f"   Folder name: {latest_folder_name}")
        print(f"   Expected format: schema_objecttype_environment_timestamp")
        logging.error(f"Could not extract source environment from folder: {latest_folder_name}")
        return
    
    # Check if source and target environments are the same
    if source_environment == target_environment:
        print("\n" + "=" * 80)
        print("ERROR: SOURCE AND TARGET ENVIRONMENTS ARE THE SAME. OPERATION TERMINATED.")
        print("PLEASE CONFIGURE DIFFERENT ENVIRONMENTS BEFORE PROCEEDING.")
        print("=" * 80)
        logging.error("Source and target environments are the same. Operation terminated.")
        sys.exit(1)

    # Update config with user selections
    config['object_config']['target_environment'] = target_environment
    config['object_config']['source_environment'] = source_environment
    config['object_config']['object_type'] = object_type
    config['object_config']['schema_name'] = schema_name
    config['object_config']['run_identifier'] = f"{schema_name}_{object_type}s_{target_environment}"

    # Setup logging with the finalized run_identifier
    run_identifier = config['object_config']['run_identifier']
    log_directory = config['paths']['log_directory']
    log_file = setup_logging(log_directory, run_identifier)

    if not log_file:
        print("Failed to setup logging. Exiting.")
        return

    logging.info(f"Configuration loaded successfully")
    logging.info(f"Log file: {log_file}")
    logging.info(f"Source Environment: {source_environment.upper()}")
    logging.info(f"Target Environment: {target_environment.upper()}")
    logging.info(f"Object Type: {object_type.upper()}")
    logging.info(f"Schema Name: {schema_name}")
    logging.info(f"Grant Preference: {grant_preference.upper()}")
    logging.info(f"Exclusion table configured on target DB")

    # Connect to Redshift with the target environment
    connection, db_username = connect_to_redshift(config, target_environment)
    if not connection or not db_username:
        logging.error("Failed to connect to Redshift. Exiting.")
        return

    try:
        # Process all DDL files with grant preference and database username
        process_ddl_files(connection, config, grant_preference, db_username)
    except Exception as e:
        logging.error(f"Unexpected error in main execution: {e}")
        print(f"Unexpected error: {e}")
    finally:
        # Close connection
        connection.close()
        logging.info("Connection closed. Script execution completed.")


if __name__ == "__main__":
    main()