import psycopg2
import os
import re
from datetime import datetime
import yaml

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

def modify_ddl(ddl, target_schema, source_schema):
    """
    Modifies the DDL according to the specified rules.

    Args:
        ddl: The original DDL string.
        target_schema: The target schema name.
        source_schema: The source schema name.

    Returns:
        The modified DDL string.
    """
    # Append target schema to the view name
    ddl = re.sub(r'CREATE OR REPLACE VIEW (\w+\.\w+)', f'CREATE OR REPLACE VIEW {target_schema}.\\1', ddl)

    # Modify the FROM clause
    def replace_from_clause(match):
        table_ref = match.group(1)
        if table_ref.startswith('*_rep.') or table_ref.startswith(f'{source_schema}.'):
            return f'FROM {table_ref}'
        else:
            return f'FROM {source_schema}.{table_ref}'

    ddl = re.sub(r'FROM\s+([a-zA-Z0-9_\.]+)', replace_from_clause, ddl, flags=re.IGNORECASE)
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

def main():
    # Load parameters from YAML file
    # with open('fetch_and_create_ufds_vws/input_parameter_file.yaml', 'r') as file:
    #     params = yaml.safe_load(file)

    # source_conn_params = params['source_db']
    # target_conn_params = params['target_db']
    control_table = 'mktg_ops_tbls.extvws_create_ctl_tbl'
    output_dir = 'C:\\Users\\Exavalu\\OneDrive - exavalu\\ARC\\ddl\\ufds_vws'

    # Connect to source and target databases
    target_conn = psycopg2.connect(
            host= 'redshift.test.datahub.redcross.net',
            port=5439,
            dbname='mods_bi',
            user='adarsh_ram',
            password='3c7liI8myEkEKJUZe4JB'
            )
    source_conn = psycopg2.connect(
            host='redshift.test.datahub.redcross.net',
            port=5439,
            dbname='eda',
            user='adarsh_ram',
            password='3c7liI8myEkEKJUZe4JB'
            )

    try:
        # Step 1: Read control table
        control_data = read_control_table(target_conn, control_table)

        for row in control_data:
            print(f"Processing view: {row}")
            src_view = row['view_name']
            tgt_schema = row['tgt_db_schema']
            src_schema = row['src_db_schema']

            src_view_name = f"ufds_vws.gmpbz_dim_gift_stg"
            # Step 2: Fetch view DDL from source
            ddl = fetch_view_ddl(source_conn, src_view_name)

            save_ddl_to_file(ddl, output_dir, src_view_name)

            # Step 3: Modify the DDL
            modified_ddl = modify_ddl(ddl, tgt_schema, src_schema)

            print(f"Modified DDL for view {src_view}:\n{modified_ddl}\n")

            # Step 4: Save the modified DDL to a file
            #save_ddl_to_file(modified_ddl, output_dir, src_view)

            # Step 5: Create the view in the target database
            #create_view_in_target(target_conn, modified_ddl)

    finally:
        source_conn.close()
        target_conn.close()

if __name__ == "__main__":
    main()