"""
Script Behavior Summary:

1. Database Credentials:
   - The database username and password for `fetchobjects.py` are provided at runtime
     through an interactive prompt.
   - The password input is masked (not visible on the screen).
   - Once the database connection is established, the password is not stored or reused
     anywhere in the code.

2. Runtime Fetch Options:
   - The script supports two runtime modes for fetching database objects:
     
     a) Selected Mode:
        - When the fetch option is set to 'selected', the list of tables to be fetched
          is dynamically pulled from the database using control tables.
        - The following SQL files are used:
            • etl_config/fetch_selected_objects_ctl.sql
            • etl_config/fetch_all_objects_exclude_ctl.sql

     b) All Mode:
        - When the fetch option is set to 'all', the script fetches all database objects
          except those explicitly listed in the exclude control table.
        - Objects present in the exclusion list are skipped during the fetch process.

3. Interactive Environment & Object Type Selection:
   - Users are prompted at runtime to select the environment (test, staging, prod, dev)
   - Users are prompted to select the object type (table, view, procedure)
   - Users are prompted to enter the schema name
"""

import os
import re
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


def prompt_environment_selection():
    """
    Prompt user to select the environment.
    Returns the environment name (test, dev, prod)
    Reprompts on invalid input.
    """
    while True:
        print("\n" + "=" * 80)
        print("SELECT ENVIRONMENT")
        print("=" * 80)
        print("1. Test")
        print("2. Dev")
        print("3. Prod")
        print("=" * 80)
        
        choice = input("Enter your choice (1-3): ").strip()
        
        if choice in ENVIRONMENT_MAP:
            environment = ENVIRONMENT_MAP[choice]
            print(f"✓ Selected Environment: {environment.upper()}")
            return environment
        else:
            print("✗ Invalid choice. Please enter 1, 2, or 3.")


def prompt_object_type_selection():
    """
    Prompt user to select the object type.
    Returns the object type (table, view, procedure)
    Reprompts on invalid input.
    """
    while True:
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
            print("✗ Invalid choice. Please enter 1, 2, or 3.")


def prompt_schema_name():
    """
    Prompt user to enter the schema name.
    Reprompts on empty input.
    """
    while True:
        print("\n" + "=" * 80)
        print("ENTER SCHEMA NAME")
        print("=" * 80)
        print("Examples: mktg_ops_tbls, mktg_ops_vws, mktg_ops_procs")
        print("=" * 80)
        
        schema_name = input("Enter schema name: ").strip()
        
        if schema_name:
            print(f"✓ Selected Schema: {schema_name}")
            return schema_name
        else:
            print("✗ Schema name cannot be empty. Please try again.")


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
        query = f"""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = '{schema_name}'
        """
        cursor.execute(query)
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
        return None


# Function to fetch stored procedure names from a specific schema
def fetch_stored_procedure_names(connection, schema_name):
    try:
        cursor = connection.cursor()
        query = f"""
            SELECT routine_name
            FROM information_schema.routines
            WHERE routine_schema = '{schema_name}'
            AND routine_type = 'PROCEDURE';
        """
        cursor.execute(query)
        procedures = cursor.fetchall()
        logging.info(f"Fetched {len(procedures)} stored procedures from schema {schema_name}")
        return [procedure[0] for procedure in procedures]
    except Exception as e:
        print(f"Error fetching stored procedure names: {e}")
        logging.error(f"Error fetching stored procedure names: {e}")
        return []


# Function to fetch DDL for a specific stored procedure
def fetch_stored_procedure_ddl(connection, schema_name, procedure_name):
    try:
        cursor = connection.cursor()
        query = f"""
            SELECT pg_get_functiondef(p.oid)
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = '{schema_name}'
            AND p.proname = '{procedure_name}';
        """
        cursor.execute(query)
        ddl = cursor.fetchone()
        return ddl[0] if ddl else None
    except Exception as e:
        print(f"Error fetching DDL for stored procedure {procedure_name}: {e}")
        logging.error(f"Error fetching DDL for stored procedure {procedure_name}: {e}")
        return None


# Function to save DDL to a file
def save_ddl_to_file(base_path, schema_name, object_name, ddl):
    try:
        # Create schema-specific folder with timestamp
        schema_path = base_path / f"{schema_name}_{current_timestamp.strftime('%Y%m%d_%H%M')}"
        schema_path.mkdir(parents=True, exist_ok=True)
        file_path = schema_path / f"{object_name}.sql"
        with open(file_path, "w") as file:
            file.write(ddl)
        print(f"Saved DDL for {object_name} to {file_path}")
        logging.info(f"Saved DDL for {object_name} to {file_path}")

    except Exception as e:
        print(f"Error saving DDL to file for {object_name}: {e}")
        logging.error(f"Error saving DDL to file for {object_name}: {e}")


def get_object_lists(conn, TABLE_NAME):
    
    tables = []
    views = []
    procedures = []
    
    SQL = f"""
    SELECT
    schema_name,
    object_name,
    object_type
    FROM {TABLE_NAME};
    """

    with conn.cursor() as cur:
        cur.execute(SQL)
        for schema_name, object_name, object_type in cur.fetchall():
            qualified = f"{schema_name}.{object_name}"
            t = (object_type or "").strip().lower()
            if t == "table":
                tables.append(qualified)
            elif t == "view":
                views.append(qualified)
            elif t == "procedure":
                procedures.append(qualified)
            else:
                # Unknown types can be logged or handled here if needed
                pass

    return tables, views, procedures

    


def fetch_all_objects(conn, schema_name, relation_type, base_path):
    tables, views, procedures = get_object_lists(conn, "mods_bi.etl_config.fetch_all_objects_exclude_ctl")
    if relation_type == "view":
        objects = fetch_table_names(conn, schema_name)
        if not objects:
            print(f"No {relation_type}s found in the schema.")
            logging.warning(f"No {relation_type}s found in schema {schema_name}")
            return

        for idx, object_name in enumerate(objects, 1):
            print(f"Processing {idx}/{len(objects)}: {object_name}")
            if f"{schema_name}.{object_name}" not in views:
                ddl = fetch_table_ddl(conn, schema_name, object_name, "view")
                if ddl:
                    save_ddl_to_file(base_path, schema_name, object_name, ddl)
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
            if f"{schema_name}.{object_name}" not in tables:
                ddl = fetch_table_ddl(conn, schema_name, object_name, "table")
                if ddl:
                    save_ddl_to_file(base_path, schema_name, object_name, ddl)
                else:
                    print(f"No DDL found for {relation_type} {object_name}.")
                    logging.warning(f"No DDL found for {relation_type} {object_name}")
    elif relation_type == "procedure":
        objects = fetch_stored_procedure_names(conn, schema_name)
        if not objects:
            print(f"No {relation_type}s found in the schema.")
            logging.warning(f"No {relation_type}s found in schema {schema_name}")
            return
        for idx, object_name in enumerate(objects, 1):
            print(f"Processing {idx}/{len(objects)}: {object_name}")
            if f"{schema_name}.{object_name}" not in procedures:
                ddl = fetch_stored_procedure_ddl(conn, schema_name, object_name)
                if ddl:
                    save_ddl_to_file(base_path, schema_name, object_name, ddl)
                else:
                    print(f"No DDL found for {relation_type} {object_name}.")
                    logging.warning(f"No DDL found for {relation_type} {object_name}")
    else:
        print(
            "Invalid object type. Please set 'object_type' to 'view', 'table', or 'procedure' in the YAML config.")
        logging.error(f"Invalid object type: {relation_type}")

def selected_objects(conn, schema_name, relation_type, base_path):
    tables, views, procedures = get_object_lists(conn, "mods_bi.etl_config.fetch_selected_objects_ctl")
    if relation_type == "view":
        for idx, view in enumerate(views,1):
            print(f"Processing {idx}/{len(views)}: {view}")
            schema, object_name = view.split('.')
            ddl = fetch_table_ddl(conn, schema, object_name, "view")
            if ddl:
                save_ddl_to_file(base_path, schema, object_name, ddl)
            else:
                    print(f"No DDL found for {relation_type} {object_name}.")
                    logging.warning(f"No DDL found for {relation_type} {object_name}")
    elif relation_type == "table":
        for idx, table in enumerate(tables, 1):
            print(f"Processing {idx}/{len(tables)}: {table}")
            schema, object_name = table.split('.')
            ddl = fetch_table_ddl(conn, schema, object_name, "table")
            if ddl:
                save_ddl_to_file(base_path, schema, object_name, ddl)
            else:
                    print(f"No DDL found for {relation_type} {object_name}.")
                    logging.warning(f"No DDL found for {relation_type} {object_name}")
    elif relation_type == "procedure":
        for idx, procedure in enumerate(procedures, 1):
            print(f"Processing {idx}/{len(procedures)}: {procedure}")
            schema, object_name = procedure.split('.')
            ddl = fetch_stored_procedure_ddl(conn, schema, object_name)
            if ddl:
                save_ddl_to_file(base_path, schema, object_name, ddl)
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
    environment = prompt_environment_selection()
    object_type = prompt_object_type_selection()
    schema_name = prompt_schema_name()
    
    # Update config with user selections
    config['object_config']['environment'] = environment
    config['object_config']['object_type'] = object_type
    config['object_config']['schema_name'] = schema_name
    config['object_config']['run_identifier'] = f"{schema_name}_{object_type}s"
    
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
    logging.info(f"User selected environment: {environment.upper()}")
    logging.info(f"User selected object type: {object_type.upper()}")
    logging.info(f"User selected schema: {schema_name}")
    
    schema_name = object_config['schema_name']
    relation_type = object_config['object_type']
    mode = object_config['mode']
    # Set base path for DDL files using relative path from PROJECT_ROOT
    base_path = PROJECT_ROOT / "Fetch_Object_Output" / relation_type.capitalize()
    base_path.mkdir(parents=True, exist_ok=True)

    print(f"\n{'=' * 60}")
    print(f"Starting DDL fetch for: {relation_type.upper()}")
    print(f"Schema: {schema_name}")
    print(f"Environment: {environment.upper()}")
    print(f"Output Path: {base_path}")
    print(f"{'=' * 60}\n")

    conn = None
    try: 
        conn = connect_to_redshift(config, environment)
        
        if not conn:
            logging.error("Failed to connect to Redshift")
            return

        if mode == "selected":
            selected_objects(conn, schema_name, relation_type, base_path)
            
        if mode == "all":
            fetch_all_objects(conn, schema_name, relation_type, base_path)
            

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