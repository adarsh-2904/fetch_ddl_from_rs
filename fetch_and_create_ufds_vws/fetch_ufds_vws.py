import uuid
import psycopg2
import os
import re
from datetime import datetime
import yaml
from pathlib import Path
import csv
import time

SCRIPT_DIR = Path(__file__).parent

# Get the project root directory (one level up from Fetch_Object_Input)
PROJECT_ROOT = SCRIPT_DIR.parent

ROOT = project_root = os.path.dirname(PROJECT_ROOT)

def save_ddl_to_file1(base_path, schema_name, object_name, ddl):
    current_timestamp = datetime.now()
    try:
        # Create schema-specific folder with timestamp
        schema_path = base_path / f"{schema_name}"
        schema_path.mkdir(parents=True, exist_ok=True)
        file_path = schema_path / f"{object_name}_{current_timestamp.strftime('%Y%m%d_%H%M')}.sql"
        with open(file_path, "w") as file:
            file.write(ddl)
        print(f"Saved DDL for {object_name} to {file_path}")
       # logging.info(f"Saved DDL for {object_name} to {file_path}")

    except Exception as e:
        print(f"Error saving DDL to file for {object_name}: {e}")
        #logging.error(f"Error saving DDL to file for {object_name}: {e}")

# Load configuration from YAML file
def load_config():

    # YAML is in the same folder as the script
    config_path = SCRIPT_DIR / "input_parameter_file.yaml"
    try:
        with open(config_path, 'r') as file:
            config = yaml.safe_load(file)
        print(f"Configuration loaded successfully from {config_path}")
        return config
    except Exception as e:
        print(f"Error loading configuration: {e}")
        raise

def read_control_table(conn, control_table):
    """
    Reads the control table to fetch the list of views to be migrated.

    Args:
        conn: Connection object to the target database.
        control_table: The name of the control table.

    Returns:
        A list of dictionaries containing control table data.
    """
    query = f"SELECT * FROM {control_table}"
    with conn.cursor() as cursor:
        cursor.execute(query)
        rows = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        return [dict(zip(columns, row)) for row in rows]

def fetch_view_ddl(conn, view_name):
    """
    Fetches the DDL of a view from the source database.

    Args:
        conn: Connection object to the source database.
        view_name: The name of the view to fetch the DDL for.

    Returns:
        The DDL of the view as a string.
    """
    query = f"SELECT pg_get_viewdef('{view_name}'::regclass, true) AS view_sql;"
    print(f"Executing query to fetch DDL: {query}")
    with conn.cursor() as cursor:
        cursor.execute(query)
        result = cursor.fetchone()
        if result:
            return result[0]
        else:
            raise ValueError(f"View {view_name} not found in source database.")

def save_ddl_to_file(ddl, output_dir, view_name):
    """
    Saves the DDL to a SQL file.

    Args:
        ddl: The DDL string to save.
        output_dir: The directory to save the SQL file.
        view_name: The name of the view (used for the file name).
    """
    os.makedirs(output_dir, exist_ok=True)
    file_path = os.path.join(output_dir, f"{view_name}.sql")
    with open(file_path, 'w') as file:
        file.write(ddl)
    return file_path

def modify_ddl(ddl, target_schema, source_schema,view_name):
    """
    Modifies the DDL according to the specified rules.

    Args:
        ddl: The original DDL string.
        target_schema: The target schema name.
        source_schema: The source schema name.

    Returns:
        The modified DDL string.
    """
    print(f"Modifying DDL for target schema: {target_schema} and source schema: {source_schema}")

    # Replace the schema name after "CREATE OR REPLACE VIEW" with target database and schema name
    ddl = re.sub(r'CREATE OR REPLACE VIEW \w+\.\w+', 
                 lambda match: f"CREATE OR REPLACE VIEW {target_schema}.{match.group(0).split('.')[-1]}", 
                 ddl)

    # Modify the FROM clause
    def replace_from_clause(match):
        table_ref = match.group(1)
        print(f"Original table reference in FROM clause: {table_ref}")
        if '_rep.' in table_ref or 'eda.' in table_ref:
            print("No schema prefix needed for this table reference.")
            return f'FROM {table_ref}'
        elif '_tbls.' in table_ref:
            return f'FROM eda.{source_schema}.{view_name}'
        elif source_schema in table_ref:
            return f'FROM mods_bi.{table_ref}'
        else:
            print("Adding source schema prefix: eda.")
            return f'FROM eda.{table_ref}'
           

    ddl = re.sub(r'FROM\s+([a-zA-Z0-9_\.]+)', replace_from_clause, ddl, flags=re.IGNORECASE)




    # Add GRANT commands
    grant_commands = f"\nGRANT ALL ON {target_schema}.{view_name} TO role mods_bi_writer;\n"
    grant_commands += f"GRANT SELECT ON {target_schema}.{view_name} TO role mods_bi_reader_vt;\n"
    ddl += grant_commands

    return ddl

def create_view_in_target(conn, ddl):
    """
    Creates the view in the target database using the modified DDL.

    Args:
        conn: Connection object to the target database.
        ddl: The modified DDL string.
    """
    with conn.cursor() as cursor:
        cursor.execute(ddl)
        conn.commit()

def validate_views(conn, views, output_csv):
    """
    Validates the created views by executing SELECT * queries and logs the results/errors to a CSV file.

    Args:
        conn: Connection object to the target database.
        views: List of views to validate. Each view is a dictionary with keys 'db_name', 'schema_name', and 'view_name'.
        output_csv: Path to the CSV file where results/errors will be logged.
    """
    with open(output_csv, mode='w', newline='') as csvfile:
        csv_writer = csv.writer(csvfile)
        csv_writer.writerow(["View Name", "Status", "Message", "Execution Time (seconds)"])  # Added column for execution time

        for view in views:
            view_name = f"{view['db_name']}.{view['schema_name']}.{view['view_name']}"
            query = f"SELECT * FROM {view_name} LIMIT 200;"
            
            try:
                with conn.cursor() as cursor:
                    
                    cursor.execute("BEGIN;")  # Start a new transaction
                    start_time = time.time()  # Start the timer
                    cursor.execute(query)
                    cursor.fetchall()  # Fetch results to ensure the query runs successfully
                    end_time = time.time()  # End the timer
                    conn.commit()  # Commit the transaction if successful
                    
                    execution_time = end_time - start_time  # Calculate the duration
                    #convert execution_time to min and seconds
                    minutes = int(execution_time // 60)
                    seconds = int(execution_time % 60)  
                    
                    csv_writer.writerow([view_name, "Success", "Query executed successfully", f"{minutes} minutes and {seconds} seconds"])
                    print(f"Validation successful for view: {view_name}. Execution time: {minutes} minutes and {seconds} seconds")
            except Exception as e:
                conn.rollback()  # Rollback the transaction in case of an error
                error_message = str(e).replace("\n", " ")  # Replace newlines in error message
                csv_writer.writerow([view_name, "Error", error_message, "N/A"])  # Log "N/A" for execution time in case of error
                print(f"Validation failed for view: {view_name}. Error: {error_message}")

def main():
    # Load parameters from YAML file
    config = load_config()
    # with open('fetch_and_create_ufds_vws/input_parameter_file.yaml', 'r') as file:
    #     params = yaml.safe_load(file)

    # source_conn_params = params['source_db']
    # target_conn_params = params['target_db']
    base_path = PROJECT_ROOT / "ext_vws_ddl" 
    base_path.mkdir(parents=True, exist_ok=True)
    modified_ddl_path = base_path / "modified_ddls"
    modified_ddl_path.mkdir(parents=True, exist_ok=True)

    print("Loaded configuration:", config)
    control_table = config['control_table']
    

    # Connect to source and target databases
    target_conn = psycopg2.connect(
            host=config['tgt_redshift']['host'],
            port=config['tgt_redshift']['port'],
            dbname=config['tgt_redshift']['dbname'],
            user='adarsh_ram',
            password='3c7liI8myEkEKJUZe4JB',
            connect_timeout=600
            )
    source_conn = psycopg2.connect(
            host=config['src_redshift']['host'],
            port=config['src_redshift']['port'],
            dbname=config['src_redshift']['dbname'],
            user='adarsh_ram',
            password='3c7liI8myEkEKJUZe4JB',
            connect_timeout=600
            )

    try:
        # Step 1: Read control table
        control_data = read_control_table(target_conn, control_table)

        # for row in control_data:
        #     if row['need_to_create_ind'] == 1:
        #         print(f"Processing view: {row}")
        #         view_name = row['view_name']
        #         src_db = row['src_db']
        #         src_schema = row['src_schema']
        #         tgt_db = row['tgt_db']
        #         tgt_schema = row['tgt_schema']

        #         src_view_name = f"{src_schema}.{view_name}"
        #         # Step 2: Fetch view DDL from source
        #         ddl = fetch_view_ddl(source_conn, src_view_name)

        #         save_ddl_to_file1(base_path, src_schema, view_name, ddl)

        #         # Step 3: Modify the DDL
        #         modified_ddl = modify_ddl(ddl, f"{tgt_db}.{tgt_schema}", src_schema,view_name)

        #         print(f"Modified DDL for view {view_name}:\n{modified_ddl}\n")

        #         # Step 4: Save the modified DDL to a file
        #         save_ddl_to_file1(modified_ddl_path, src_schema, view_name, modified_ddl)

                # Step 5: Create the view in the target database
                #create_view_in_target(target_conn, modified_ddl)

       # Step 6: Validate the created views and log results/errors to a CSV file
        output_csv = f"{base_path}\\validation_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        views_to_validate = [
            {
                "db_name": row['tgt_db'],
                "schema_name": row['tgt_schema'],
                "view_name": row['view_name']
            }
            for row in control_data if row['need_to_create_ind'] == 1
        ]
        validate_views(target_conn, views_to_validate, output_csv)
        print(f"Validation results saved to {output_csv}")

    finally:
        source_conn.close()
        target_conn.close()

if __name__ == "__main__":
    main()