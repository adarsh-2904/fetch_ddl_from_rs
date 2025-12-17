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


# Load configuration
config = load_config()

# Extract configuration values
redshift_config = config['redshift']
paths_config = config['paths']
object_config = config['object_config']

# Set up logging directory (relative to PROJECT_ROOT)
log_dir = PROJECT_ROOT / paths_config['log_directory']
log_dir.mkdir(parents=True, exist_ok=True)
current_timestamp = datetime.now()

print(f"Script started at {current_timestamp}")

# Configure logging
logging.basicConfig(
    filename=log_dir / f"fetch_{object_config['run_identifier']}_{current_timestamp.strftime('%Y%m%d_%H%M')}.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)


# Function to connect to the Redshift database
def connect_to_redshift():
    try:
        username = "adarsh_ram" #input("Enter Redshift username: ")
        password = "3c7liI8myEkEKJUZe4JB" #pwinput.pwinput(prompt="Enter Redshift password: ", mask="*")
        connection = psycopg2.connect(
            host=redshift_config['host'],
            port=redshift_config['port'],
            dbname=redshift_config['dbname'],
            user=username,
            password=password
        )
        logging.info("Successfully connected to Redshift")
        print("Successfully connected to Redshift")
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
        procedures_all = fetch_stored_procedure_names(conn, schema_name)
        if not objects:
            print(f"No {relation_type}s found in the schema.")
            logging.warning(f"No {relation_type}s found in schema {schema_name}")
            return
        for idx, procedure_name in enumerate(procedures_all, 1):
            print(f"Processing {idx}/{len(procedures_all)}: {procedure_name}")
            if f"{schema_name}.{procedure_name}" not in procedures:
                ddl = fetch_stored_procedure_ddl(conn, schema_name, procedure_name)
                if ddl:
                    save_ddl_to_file(base_path, schema_name, procedure_name, ddl)
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
    schema_name = object_config['schema_name']
    relation_type = object_config['object_type']
    mode = object_config['mode']
    # Set base path for DDL files using relative path from PROJECT_ROOT
    base_path = PROJECT_ROOT / "Fetch_Object_Output" / relation_type.capitalize()
    base_path.mkdir(parents=True, exist_ok=True)

    print(f"\n{'=' * 60}")
    print(f"Starting DDL fetch for: {relation_type.upper()}")
    print(f"Schema: {schema_name}")
    print(f"Output Path: {base_path}")
    print(f"{'=' * 60}\n")

    try: 
        conn = connect_to_redshift()

        if mode == "selected":
            selected_objects(conn, schema_name, relation_type, base_path)
            
        if mode == "all":
            fetch_all_objects(conn, schema_name, relation_type, base_path)
            

        print(f"\n{'=' * 60}")
        print("DDL fetch completed successfully!")
        print(f"{'=' * 60}\n")
        logging.info("DDL fetch completed successfully")

    except Exception as e:
        print("Error during test:", e)
    finally:
        if conn:
            conn.close()

    

if __name__ == "__main__":
   main()