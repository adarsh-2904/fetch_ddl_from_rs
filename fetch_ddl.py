import os
import re
import psycopg2
import logging
from dotenv import load_dotenv

# Load environment variables from a .env file
load_dotenv()

# Ensure the log file directory exists
log_dir = "C:/Users/Exavalu/OneDrive - exavalu/ARC/ddl"
os.makedirs(log_dir, exist_ok=True)

# Configure logging
logging.basicConfig(
    filename=os.path.join(log_dir, "script_logs.log"),
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# Function to connect to the Redshift database
def connect_to_redshift(host, port, dbname, user, password):
    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            dbname=dbname,
            user=user,
            password=password
        )
        logging.info("Successfully connected to Redshift")
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
                ddl = ddl[0].strip()  # Remove leading/trailing whitespace
                # Ensure the DDL contains 'CREATE OR REPLACE VIEW' or 'CREATE VIEW'
                if "create or replace view" not in ddl.lower() and "create  view" not in ddl.lower():
                    print("DDL does not contain 'CREATE OR REPLACE VIEW' or 'CREATE VIEW'")
                    ddl = f"CREATE OR REPLACE VIEW {schema_name}.{table_name} AS \n" + ddl
                elif "create  view" in ddl.lower():
                    print("DDL contains 'CREATE VIEW', replacing with 'CREATE OR REPLACE VIEW'")
                    ddl = re.sub(r"(?i)create  view", "CREATE OR REPLACE VIEW", ddl, count=1)  # Replace first occurrence of 'CREATE VIEW'

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
def save_ddl_to_file(base_path, schema_name, table_name, ddl):
    try:
        schema_path = os.path.join(base_path, schema_name)
        os.makedirs(schema_path, exist_ok=True)
        file_path = os.path.join(schema_path, f"{table_name}.sql")
        with open(file_path, "w") as file:
            file.write(ddl)
        print(f"Saved DDL for table {table_name} to {file_path}")
        
    except Exception as e:
        print(f"Error saving DDL to file for table {table_name}: {e}")
        logging.error(f"Error saving DDL to file for table {table_name}: {e}")

# Updated main function to fetch all DDLs for a specific relation type (views, tables, or procedures)
def main():
    # Redshift connection details
    host = os.getenv("REDSHIFT_HOST")
    port = int(os.getenv("REDSHIFT_PORT", 5439))
    dbname = os.getenv("REDSHIFT_DBNAME")
    user = os.getenv("REDSHIFT_USER")
    password = os.getenv("REDSHIFT_PASSWORD")

    # Schema name to fetch DDLs for
    schema_name = "mktg_ops_tbls"

    # Relation type e.g., tables/views/procedures
    relation_type = "procedure"  

    # Base path to save DDL files
    base_path = f"C:/Users/Exavalu/OneDrive - exavalu/ARC/ddl/{relation_type}"

    # Connect to Redshift
    connection = connect_to_redshift(host, port, dbname, user, password)
    if not connection:
        return

    try:
        if relation_type == "view" or relation_type == "table":
            tables = fetch_table_names(connection, schema_name)
            if not tables:
                print(f"No {relation_type} found in the schema.")
                return

            for table_name in tables:
                ddl = fetch_table_ddl(connection, schema_name, table_name, relation_type)
                if ddl:
                    save_ddl_to_file(base_path, schema_name, table_name, ddl)
                else:
                    print(f"No DDL found for {relation_type[:-1]} {table_name}.")
        elif relation_type == "procedure":
            procedures = fetch_stored_procedure_names(connection, schema_name)
            if not procedures:
                print("No procedures found in the schema.")
                return

            for procedure_name in procedures:
                ddl = fetch_stored_procedure_ddl(connection, schema_name, procedure_name)
                if ddl:
                    save_ddl_to_file(base_path, schema_name, procedure_name, ddl)
                else:
                    print(f"No DDL found for procedure {procedure_name}.")
        else:
            print("Invalid relation type. Please enter 'views', 'tables', or 'procedures'.")
    finally:
        connection.close()

if __name__ == "__main__":
    main()