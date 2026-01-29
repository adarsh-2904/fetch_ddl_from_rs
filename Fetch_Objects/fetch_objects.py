"""
Script Behavior Summary: FETCH_OBJECTS.PY

1. Database Credentials & Connection:
   - Username/password provided via interactive prompt (masked input)
   - Password deleted from memory after connection established
   - Dynamic environment selection from YAML config (test, dev, prod)
   - Connection used only for DDL extraction, then closed

2. Interactive Selection Prompts (2-attempt validation):
   - Environment: test, dev, or prod (source database)
   - Object Type: table, view, or procedure
   - Schema Name: source schema to fetch objects from
   - Fetch Mode: 'all' or 'selected'

3. Fetch Modes:
   
   a) 'All' Mode:
      - Fetches ALL database objects from specified schema and type
      - NO exclusion filtering during fetch
      - Uses system catalogs: information_schema (tables/views), pg_proc (procedures)
      - All objects processed and DDL scripts generated
   
   b) 'Selected' Mode:
      - Fetches ONLY objects specified in control table: mods_bi.etl_config.fetch_selected_objects_ctl
      - Filters by: object_type AND schema_name
      - Requires manual control table setup with object selections

4. Object Type Specific Behavior:
   
   Tables:
   - Extracted via: SHOW TABLE {schema}.{table}
   - Includes: structure, constraints, indexes
   
   Views:
   - Extracted via: SHOW VIEW {schema}.{view}
   - Automatically adds 'WITH NO SCHEMA BINDING' if missing
   - Converts to 'CREATE OR REPLACE VIEW' format for consistency
   - Fallback: uses pg_get_viewdef if SHOW fails
   
   Procedures:
   - Extracted via: pg_proc system catalog + pg_get_functiondef
   - Filename format: {procedure_name}.sql

5. DDL Script Generation & Storage:
   - Output folder: {output}/{objecttype}/{schema}_{environment}_{mode}_{YYYYMMDD_HHMM}/
   - Example paths:
     • Fetch_Object_Output/Table/mktg_ops_tbls_dev_all_20260128_1430/
     • Fetch_Object_Output/View/mktg_ops_vws_test_selected_20260128_1430/
     • Fetch_Object_Output/Procedure/saba_tbls_procedures_prod_all_20260128_1430/
   - Filenames: {object_name}.sql for all object types
   - Generated scripts immediately ready for create_objects.py

6. Logging:
   - Log file: {log_directory}/fetch_{run_identifier}_{YYYYMMDD_HHMM}.log
   - Includes: environment/schema selections, fetch mode, object counts, success/failure per object
   - Transaction rollbacks logged when errors occur
   - All timestamps in YYYYMMDD_HHMM format

7. Error Handling:
   - Transaction rollback on DDL fetch errors
   - Errors logged but don't stop execution
   - Failed object fetches don't block subsequent ones
   - Connection closed gracefully at end

8. Critical Notes:
   - FETCH does NOT apply exclusion table filtering (filtering happens in CREATE phase on target DB)
   - Folder naming includes mode ('all' vs 'selected') for clarity
   - Single procedure per name guaranteed; no overloaded procedures supported

"""

import os
import re
import sys
import psycopg2
import logging
import yaml
from datetime import datetime
from pathlib import Path
import pwinput

# Since .py file is now inside Fetch_Object_Input folder
# Get the Fetch_Object_Input directory
SCRIPT_DIR = Path(__file__).parent

# Get the project root directory (one level up from Fetch_Object_Input)
PROJECT_ROOT = SCRIPT_DIR.parent

ROOT = project_root = os.path.dirname(PROJECT_ROOT)

# Global variable to store current timestamp (set in main())
current_timestamp = None


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

MODE_MAP = {
    "1": "all",
    "2": "selected"
}


def prompt_environment_selection():
    """
    Prompt user to select the environment.
    Returns the environment name (test, dev, prod)
    Exits on 2 invalid attempts.
    """
    max_attempts = 2
    attempt = 0
    
    valid_environments = ['test', 'dev', 'prod']
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print("SELECT SOURCE ENVIRONMENT")
        print("=" * 80)
        print("Available environments: test, dev, prod")
        print("=" * 80)
        
        choice = input(f"Enter environment ({', '.join(valid_environments)}): ").strip().lower()
        
        if choice in valid_environments:
            print(f"✓ Selected Source Environment: {choice.upper()}")
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
    Prompt user to enter the source schema name.
    Exits on 2 empty input attempts.
    """
    max_attempts = 2
    attempt = 0
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print("ENTER SOURCE SCHEMA NAME")
        print("=" * 80)
        print("Examples: mktg_ops_tbls, mktg_ops_vws")
        print("=" * 80)
        
        schema_name = input("Enter source schema name: ").strip()
        
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


def prompt_fetch_mode_selection():
    """
    Prompt user to select the fetch mode.
    Returns the mode (all, selected)
    Exits on 2 invalid attempts.
    """
    max_attempts = 2
    attempt = 0
    
    while attempt < max_attempts:
        print("\n" + "=" * 80)
        print("SELECT FETCH MODE")
        print("=" * 80)
        print("1. All (fetch all objects except excluded)")
        print("2. Selected (fetch only selected objects from control table)")
        print("=" * 80)
        
        choice = input("Enter your choice (1-2): ").strip()
        
        if choice in MODE_MAP:
            mode = MODE_MAP[choice]
            print(f"✓ Selected Mode: {mode.upper()}")
            return mode
        else:
            attempt += 1
            if attempt < max_attempts:
                print(f"✗ Invalid choice. Please enter 1 or 2. (Attempt {attempt}/{max_attempts})")
            else:
                print(f"✗ Invalid choice. Maximum attempts exceeded. Exiting.")
                sys.exit(1)


# Load configuration from YAML file
def load_config():

    # YAML is in the same folder as the script
    config_path = SCRIPT_DIR / "fetch_objects_parameters.yaml"
    try:
        with open(config_path, 'r') as file:
            config = yaml.safe_load(file)
        print(f"Configuration loaded successfully from {config_path}")
        return config
    except Exception as e:
        print(f"Error loading configuration: {e}")
        raise


# Function to connect to the Redshift database - DYNAMIC ENVIRONMENT SELECTION
def connect_to_redshift(config, environment):
    try:
        # Get the selected environment config
        if environment not in config['environments']:
            print(f"Error: Environment '{environment}' not found in configuration")
            return None
        
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
        print(f"Successfully connected to Redshift {environment.upper()}")
        del password  # Remove password from memory
        return connection
    except Exception as e:
        print(f"Error connecting to Redshift: {e}")
        logging.error(f"Error connecting to Redshift: {e}")
        return None


# Function to fetch table names from a specific schema
def fetch_table_names(connection, schema_name):
    try:
        cursor = connection.cursor()
        query = """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = %s
        """
        cursor.execute(query, (schema_name,))
        tables = cursor.fetchall()
        logging.info(f"Fetched {len(tables)} relations from schema {schema_name}")
        return [table[0] for table in tables]
    except Exception as e:
        print(f"Error fetching table names: {e}")
        logging.error(f"Error fetching table names: {e}")
        return []


# Function to fetch DDL for a specific table or view
def fetch_table_ddl(connection, schema_name, table_name, relation_type):
    try:
        cursor = connection.cursor()
        if relation_type == "view":
            query = f"""
                show {relation_type} {schema_name}.{table_name};
            """
            cursor.execute(query)
            ddl = cursor.fetchone()

            if ddl:
                ddl = ddl[0].strip()
                # Ensure the DDL contains 'CREATE OR REPLACE VIEW' or 'CREATE VIEW'
                if "create or replace view" not in ddl.lower() and "create  view" not in ddl.lower():
                    print("DDL does not contain 'CREATE OR REPLACE VIEW' or 'CREATE VIEW'")
                    ddl = f"CREATE OR REPLACE VIEW {schema_name}.{table_name} AS \n" + ddl
                elif "create  view" in ddl.lower():
                    print("DDL contains 'CREATE VIEW', replacing with 'CREATE OR REPLACE VIEW'")
                    ddl = re.sub(r"(?i)create  view", "CREATE OR REPLACE VIEW", ddl, count=1)

                # Check if 'WITH NO SCHEMA BINDING' is already present
                if "with no schema binding" not in ddl.lower():
                    ddl = ddl.rstrip(";") + " WITH NO SCHEMA BINDING;"

                return ddl

            # If 'CREATE OR REPLACE VIEW' is not in the DDL, fetch the full view DDL
            query = f"""
                SELECT
                    'CREATE OR REPLACE VIEW ' ||
                    nc.nspname || '.' ||
                    c.relname ||
                    ' AS ' ||
                    pg_get_viewdef(c.oid)::information_schema.character_data
                AS full_view_ddl
                FROM
                    pg_namespace nc
                JOIN
                    pg_class c ON c.relnamespace = nc.oid
                WHERE
                    c.relkind = 'v'
                    AND nc.nspname = '{schema_name}'
                    AND c.relname = '{table_name}';
            """
            cursor.execute(query)
            full_view_ddl = cursor.fetchone()

            if full_view_ddl:
                ddl = full_view_ddl[0].strip()
                ddl = ddl.rstrip(";") + " WITH NO SCHEMA BINDING;"
                return ddl

            return None
        elif relation_type == "table":
            query = f"""
                show {relation_type} {schema_name}.{table_name};
            """
            cursor.execute(query)
            ddl = cursor.fetchone()
            return ddl[0] if ddl else None

    except Exception as e:
        print(f"Error fetching DDL for {relation_type} {table_name}: {e}")
        logging.error(f"Error fetching DDL for {relation_type} {table_name}: {e}")
        # Rollback transaction to reset state for next operation
        try:
            connection.rollback()
            logging.info(f"Transaction rolled back after error fetching {relation_type} {table_name}")
        except Exception as rollback_error:
            logging.error(f"Error during rollback: {rollback_error}")
        return None


# Function to fetch stored procedure names from a specific schema
def fetch_stored_procedure_names(connection, schema_name):
    try:
        cursor = connection.cursor()
        # Fetch procedure names from pg_proc
        # No OID tracking needed since no overloaded procedures per requirements
        query = """
            SELECT DISTINCT
                p.proname
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = %s
            ORDER BY p.proname;
        """
        cursor.execute(query, (schema_name,))
        procedures = cursor.fetchall()
        logging.info(f"Fetched {len(procedures)} stored procedures from schema {schema_name}")
        # Return list of procedure names (extract from tuples)
        return [proc[0] for proc in procedures]
    except Exception as e:
        print(f"Error fetching stored procedure names: {e}")
        logging.error(f"Error fetching stored procedure names: {e}")
        return []


# Function to fetch DDL for a specific stored procedure
def fetch_stored_procedure_ddl(connection, schema_name, procedure_name):
    try:
        cursor = connection.cursor()
        # Fetch procedure DDL by name only (no OID tracking needed)
        query = """
            SELECT pg_get_functiondef(p.oid)
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = %s
            AND p.proname = %s;
        """
        cursor.execute(query, (schema_name, procedure_name))
        ddl = cursor.fetchone()
        return ddl[0] if ddl else None
    except Exception as e:
        print(f"Error fetching DDL for stored procedure {procedure_name}: {e}")
        logging.error(f"Error fetching DDL for stored procedure {procedure_name}: {e}")
        # Rollback transaction to reset state for next operation
        try:
            connection.rollback()
            logging.info(f"Transaction rolled back after error fetching procedure {procedure_name}")
        except Exception as rollback_error:
            logging.error(f"Error during rollback: {rollback_error}")
        return None


# Function to save DDL to a file
def save_ddl_to_file(base_path, schema_name, object_name, ddl, source_environment, mode):
    try:
        # Create schema-specific folder with timestamp, environment AND mode
        # Format: schema_env_mode_timestamp
        schema_path = base_path / f"{schema_name}_{source_environment}_{mode}_{current_timestamp.strftime('%Y%m%d_%H%M')}"
        schema_path.mkdir(parents=True, exist_ok=True)
        file_path = schema_path / f"{object_name}.sql"
        with open(file_path, "w") as file:
            file.write(ddl)
        print(f"Saved DDL for {object_name} to {file_path}")
        logging.info(f"Saved DDL for {object_name} to {file_path}")

    except Exception as e:
        print(f"Error saving DDL to file for {object_name}: {e}")
        logging.error(f"Error saving DDL to file for {object_name}: {e}")


# Function to get list of objects from control table (for 'selected' mode)
def get_object_lists(conn, control_table_path, schema_name, relation_type):
    """
    Fetch list of objects from the control table for the specified schema and object type.
    Returns a list of objects in 'schema.object_name' format for the given relation_type
    """
    try:
        cursor = conn.cursor()
        
        # Query the control table to get objects for the specific schema and type
        query = f"""
            SELECT schema_name || '.' || object_name as full_object_name
            FROM {control_table_path}
            WHERE object_type = %s AND schema_name = %s
        """
        
        cursor.execute(query, (relation_type.lower(), schema_name))
        results = cursor.fetchall()
        cursor.close()
        
        # Extract object names from results
        objects = [row[0] for row in results]
        logging.info(f"Retrieved {len(objects)} {relation_type}s from control table for schema {schema_name}")
        
        return objects
        
    except Exception as e:
        logging.error(f"Error fetching object lists from control table: {e}")
        print(f"Error fetching object lists from control table: {e}")
        return []


def fetch_all_objects(conn, schema_name, relation_type, base_path, source_environment, mode):
    # Fetch all objects WITHOUT exclusion filtering
    if relation_type == "view":
        objects = fetch_table_names(conn, schema_name)
        if not objects:
            print(f"No {relation_type}s found in the schema.")
            logging.warning(f"No {relation_type}s found in schema {schema_name}")
            return

        for idx, object_name in enumerate(objects, 1):
            print(f"Processing {idx}/{len(objects)}: {object_name}")
            ddl = fetch_table_ddl(conn, schema_name, object_name, "view")
            if ddl:
                save_ddl_to_file(base_path, schema_name, object_name, ddl, source_environment, mode)
            else:
                print(f"No DDL found for {relation_type} {object_name}.")
                logging.warning(f"No DDL found for {relation_type} {object_name}")
    elif relation_type == "table":
        objects = fetch_table_names(conn, schema_name)
        if not objects:
            print(f"No {relation_type}s found in the schema.")
            logging.warning(f"No {relation_type}s found in schema {schema_name}")
            return
        for idx, object_name in enumerate(objects, 1):
            print(f"Processing {idx}/{len(objects)}: {object_name}")
            ddl = fetch_table_ddl(conn, schema_name, object_name, "table")
            if ddl:
                save_ddl_to_file(base_path, schema_name, object_name, ddl, source_environment, mode)
            else:
                print(f"No DDL found for {relation_type} {object_name}.")
                logging.warning(f"No DDL found for {relation_type} {object_name}")
    elif relation_type == "procedure":
        objects = fetch_stored_procedure_names(conn, schema_name)
        if not objects:
            print(f"No {relation_type}s found in the schema.")
            logging.warning(f"No {relation_type}s found in schema {schema_name}")
            return
        for idx, procedure_name in enumerate(objects, 1):
            print(f"Processing {idx}/{len(objects)}: {procedure_name}")
            # Fetch procedure DDL
            ddl = fetch_stored_procedure_ddl(conn, schema_name, procedure_name)
            if ddl:
                # Save DDL file with procedure name (no OID suffix)
                save_ddl_to_file(base_path, schema_name, procedure_name, ddl, source_environment, mode)
            else:
                print(f"No DDL found for {relation_type} {procedure_name}.")
                logging.warning(f"No DDL found for {relation_type} {procedure_name}")
    else:
        print(
            "Invalid object type. Please set 'object_type' to 'view', 'table', or 'procedure' in the YAML config.")
        logging.error(f"Invalid object type: {relation_type}")

def selected_objects(conn, schema_name, relation_type, base_path, source_environment, mode):
    # Fetch only selected objects for the specific relation_type (no exclusion filtering)
    objects = get_object_lists(conn, "mods_bi.etl_config.fetch_selected_objects_ctl", schema_name, relation_type)
    
    if not objects:
        print(f"No {relation_type}s found in selected objects control table.")
        logging.warning(f"No {relation_type}s found in selected objects control table")
        return
    
    if relation_type == "view":
        for idx, view in enumerate(objects, 1):
            print(f"Processing {idx}/{len(objects)}: {view}")
            schema, object_name = view.split('.')
            ddl = fetch_table_ddl(conn, schema, object_name, "view")
            if ddl:
                save_ddl_to_file(base_path, schema, object_name, ddl, source_environment, mode)
            else:
                print(f"No DDL found for {relation_type} {object_name}.")
                logging.warning(f"No DDL found for {relation_type} {object_name}")
    elif relation_type == "table":
        for idx, table in enumerate(objects, 1):
            print(f"Processing {idx}/{len(objects)}: {table}")
            schema, object_name = table.split('.')
            ddl = fetch_table_ddl(conn, schema, object_name, "table")
            if ddl:
                save_ddl_to_file(base_path, schema, object_name, ddl, source_environment, mode)
            else:
                print(f"No DDL found for {relation_type} {object_name}.")
                logging.warning(f"No DDL found for {relation_type} {object_name}")
    elif relation_type == "procedure":
        objects = get_object_lists(conn, "mods_bi.etl_config.fetch_selected_objects_ctl", schema_name, relation_type)
        
        if not objects:
            print(f"No {relation_type}s found in selected objects control table.")
            logging.warning(f"No {relation_type}s found in selected objects control table")
            return
        
        # For procedures, get the OID for uniqueness with overloaded procedures
        for idx, procedure in enumerate(objects, 1):
            print(f"Processing {idx}/{len(objects)}: {procedure}")
            schema, object_name = procedure.split('.')
            
            # Fetch procedure DDL
            ddl = fetch_stored_procedure_ddl(conn, schema, object_name)
            if ddl:
                # Save DDL file with procedure name (no OID suffix)
                save_ddl_to_file(base_path, schema, object_name, ddl, source_environment, mode)
            else:
                print(f"No DDL found for {relation_type} {object_name}.")
                logging.warning(f"No DDL found for {relation_type} {object_name}")
    else:
        print(
            "Invalid object type. Please set 'object_type' to 'view', 'table', or 'procedure' in the YAML config.")
        logging.error(f"Invalid object type: {relation_type}")


def main():
    # Load configuration
    config = load_config()
    
    # Get user selections via interactive prompts
    source_environment = prompt_environment_selection()
    object_type = prompt_object_type_selection()
    schema_name = prompt_schema_name()
    mode = prompt_fetch_mode_selection()
    
    # Update config with user selections
    config['object_config']['source_environment'] = source_environment
    config['object_config']['object_type'] = object_type
    config['object_config']['schema_name'] = schema_name
    config['object_config']['mode'] = mode
    config['object_config']['run_identifier'] = f"{schema_name}_{object_type}s_{source_environment}"
    
    paths_config = config['paths']
    object_config = config['object_config']
    
    # Set up logging directory (relative to PROJECT_ROOT)
    log_dir = PROJECT_ROOT / paths_config['log_directory']
    log_dir.mkdir(parents=True, exist_ok=True)
    
    # Set global current_timestamp for use in other functions
    global current_timestamp
    current_timestamp = datetime.now()

    print(f"\nScript started at {current_timestamp}")

    # Configure logging
    logging.basicConfig(
        filename=log_dir / f"fetch_{object_config['run_identifier']}_{current_timestamp.strftime('%Y%m%d_%H%M')}.log",
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s"
    )
    
    # Log the user selections
    logging.info(f"User selected source environment: {source_environment.upper()}")
    logging.info(f"User selected object type: {object_type.upper()}")
    logging.info(f"User selected schema: {schema_name}")
    logging.info(f"User selected mode: {mode.upper()}")
    
    schema_name = object_config['schema_name']
    relation_type = object_config['object_type']
    mode = object_config['mode']
    # Set base path for DDL files using relative path from PROJECT_ROOT
    base_path = PROJECT_ROOT / "Fetch_Object_Output" / relation_type.capitalize()
    base_path.mkdir(parents=True, exist_ok=True)

    print(f"\n{'=' * 60}")
    print(f"Starting DDL fetch for: {relation_type.upper()}")
    print(f"Schema: {schema_name}")
    print(f"Source Environment: {source_environment.upper()}")
    print(f"Output Path: {base_path}")
    print(f"{'=' * 60}\n")

    conn = None
    try: 
        conn = connect_to_redshift(config, source_environment)
        
        if not conn:
            logging.error("Failed to connect to Redshift")
            return

        if mode == "selected":
            selected_objects(conn, schema_name, relation_type, base_path, source_environment, mode)
            
        if mode == "all":
            fetch_all_objects(conn, schema_name, relation_type, base_path, source_environment, mode)
            

        print(f"\n{'=' * 60}")
        print("DDL fetch completed successfully!")
        print(f"{'=' * 60}\n")
        logging.info("DDL fetch completed successfully")

    except Exception as e:
        print(f"Error during execution: {e}")
        logging.error(f"Error during execution: {e}")
    finally:
        if conn:
            conn.close()

    

if __name__ == "__main__":
   main()