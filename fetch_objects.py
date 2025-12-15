import os
import re
import psycopg2
import logging
import yaml
from datetime import datetime

# Get the project root directory (where the script is located)
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))


# Load configuration from YAML file
def load_config():
    config_path = os.path.join(PROJECT_ROOT, "Fetch_Object_Input", "fetch_objects_parameters.yaml")
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

# Set up logging directory
log_dir = os.path.join(PROJECT_ROOT, paths_config['log_directory'])
os.makedirs(log_dir, exist_ok=True)
current_timestamp = datetime.now()

print(f"Script started at {current_timestamp}")

# Configure logging
logging.basicConfig(
    filename=os.path.join(log_dir,
                          f"fetch_{object_config['run_identifier']}_{current_timestamp.strftime('%Y%m%d_%H%M')}.log"),
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)


# Function to connect to the Redshift database
def connect_to_redshift():
    try:
        connection = psycopg2.connect(
            host=redshift_config['host'],
            port=redshift_config['port'],
            dbname=redshift_config['dbname'],
            user=redshift_config['user'],
            password=redshift_config['password']
        )
        logging.info("Successfully connected to Redshift")
        print("Successfully connected to Redshift")
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
        schema_path = os.path.join(base_path, f"{schema_name}_{current_timestamp.strftime('%Y%m%d_%H%M')}")
        os.makedirs(schema_path, exist_ok=True)
        file_path = os.path.join(schema_path, f"{object_name}.sql")
        with open(file_path, "w") as file:
            file.write(ddl)
        print(f"Saved DDL for {object_name} to {file_path}")
        logging.info(f"Saved DDL for {object_name} to {file_path}")

    except Exception as e:
        print(f"Error saving DDL to file for {object_name}: {e}")
        logging.error(f"Error saving DDL to file for {object_name}: {e}")


# Main function
def main():
    # Get configuration values
    schema_name = object_config['schema_name']
    relation_type = object_config['object_type']

    # Set base path for DDL files using relative path
    base_path = os.path.join(PROJECT_ROOT, "Fetch_Object_Output", relation_type.capitalize())
    os.makedirs(base_path, exist_ok=True)

    print(f"\n{'=' * 60}")
    print(f"Starting DDL fetch for: {relation_type.upper()}")
    print(f"Schema: {schema_name}")
    print(f"Output Path: {base_path}")
    print(f"{'=' * 60}\n")

    # Connect to Redshift
    connection = connect_to_redshift()
    if not connection:
        return

    try:
        if relation_type == "view" or relation_type == "table":
            objects = fetch_table_names(connection, schema_name)
            if not objects:
                print(f"No {relation_type}s found in the schema.")
                logging.warning(f"No {relation_type}s found in schema {schema_name}")
                return

            print(f"Found {len(objects)} {relation_type}(s) to process\n")

            for idx, object_name in enumerate(objects, 1):
                print(f"Processing {idx}/{len(objects)}: {object_name}")
                ddl = fetch_table_ddl(connection, schema_name, object_name, relation_type)
                if ddl:
                    save_ddl_to_file(base_path, schema_name, object_name, ddl)
                else:
                    print(f"No DDL found for {relation_type} {object_name}.")
                    logging.warning(f"No DDL found for {relation_type} {object_name}")

        elif relation_type == "procedure":
            procedures = fetch_stored_procedure_names(connection, schema_name)
            if not procedures:
                print("No procedures found in the schema.")
                logging.warning(f"No procedures found in schema {schema_name}")
                return

            print(f"Found {len(procedures)} procedure(s) to process\n")

            for idx, procedure_name in enumerate(procedures, 1):
                print(f"Processing {idx}/{len(procedures)}: {procedure_name}")
                ddl = fetch_stored_procedure_ddl(connection, schema_name, procedure_name)
                if ddl:
                    save_ddl_to_file(base_path, schema_name, procedure_name, ddl)
                else:
                    print(f"No DDL found for procedure {procedure_name}.")
                    logging.warning(f"No DDL found for procedure {procedure_name}")
        else:
            print(
                "Invalid object type. Please set 'object_type' to 'view', 'table', or 'procedure' in the YAML config.")
            logging.error(f"Invalid object type: {relation_type}")

        print(f"\n{'=' * 60}")
        print("DDL fetch completed successfully!")
        print(f"{'=' * 60}\n")
        logging.info("DDL fetch completed successfully")

    finally:
        connection.close()
        print("Database connection closed.")


if __name__ == "__main__":
    main()