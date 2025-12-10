import os
import psycopg2
import logging
import yaml
import csv
from datetime import datetime
from pathlib import Path


# Load configuration from YAML
def load_config(config_file="create_objects_from_ddl_parameters.yaml"):
    try:
        base_path = Path(__file__).parent
        yaml_path = base_path / "Create_DDL_Input" / config_file

        with open(yaml_path, "r") as file:
            config = yaml.safe_load(file)

        # Convert relative paths to absolute paths
        if 'paths' in config:
            for key in ['ddl_base_path', 'log_directory', 'output_directory']:
                if key in config['paths']:
                    path_value = config['paths'][key]
                    # If path doesn't start with drive letter or /, treat as relative
                    if not (path_value.startswith('/') or (len(path_value) > 1 and path_value[1] == ':')):
                        config['paths'][key] = str(base_path / path_value)

        return config

    except Exception as e:
        print(f"Error loading configuration file: {e}")
        return None


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


# Connect to Redshift
def connect_to_redshift(config):
    try:
        connection = psycopg2.connect(
            host=config['redshift']['host'],
            port=config['redshift']['port'],
            dbname=config['redshift']['dbname'],
            user=config['redshift']['user'],
            password=config['redshift']['password']
        )
        logging.info(f"Successfully connected to Redshift DEV: {config['redshift']['host']}")
        logging.info(f"Database: {config['redshift']['dbname']}, User: {config['redshift']['user']}")
        return connection
    except Exception as e:
        logging.error(f"Error connecting to Redshift: {e}")
        print(f"Error connecting to Redshift: {e}")
        return None


# Get all DDL/SQL files from the schema folder
def get_ddl_files(ddl_base_path, schema_name):
    try:
        schema_path = str(os.path.join(ddl_base_path, schema_name))
        if not os.path.exists(schema_path):
            logging.error(f"Schema path does not exist: {schema_path}")
            return []

        ddl_files = [f for f in os.listdir(schema_path) if f.endswith('.sql')]
        logging.info(f"Found {len(ddl_files)} SQL files in {schema_path}")
        return ddl_files
    except Exception as e:
        logging.error(f"Error reading SQL files: {e}")
        return []


# Read DDL/SQL content from file
def read_ddl_file(ddl_base_path, schema_name, file_name):
    try:
        file_path = os.path.join(ddl_base_path, schema_name, file_name)
        with open(file_path, 'r', encoding='utf-8') as file:
            ddl_content = file.read()
        return ddl_content
    except Exception as e:
        logging.error(f"Error reading SQL file {file_name}: {e}")
        return None


# Execute DDL/SQL and categorize results
def execute_ddl(connection, ddl_content):
    try:
        cursor = connection.cursor()
        cursor.execute(ddl_content)
        connection.commit()
        cursor.close()
        return True, None, None
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

        return False, error_type, error_message
    except Exception as e:
        connection.rollback()
        return False, "UNKNOWN_ERROR", str(e)


# Initialize CSV files with dynamic names and timestamps
def initialize_csv_files(output_directory, run_identifier):
    try:
        os.makedirs(output_directory, exist_ok=True)

        # Add timestamp to CSV file names
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        created_file = os.path.join(output_directory, f"{run_identifier}_{timestamp}_created.csv")
        errored_file = os.path.join(output_directory, f"{run_identifier}_{timestamp}_errored.csv")

        # Created objects CSV
        with open(created_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['object_name', 'schema_name', 'object_type', 'status', 'created_timestamp'])

        # Errored objects CSV
        with open(errored_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['object_name', 'schema_name', 'object_type', 'error_type', 'error_message', 'timestamp'])

        logging.info(f"Initialized CSV files with timestamp: {timestamp}")
        logging.info(f"  - Created: {created_file}")
        logging.info(f"  - Errored: {errored_file}")

        return created_file, errored_file
    except Exception as e:
        logging.error(f"Error initializing CSV files: {e}")
        return None, None


# Write to created CSV
def write_to_created_csv(created_file, object_name, schema_name, object_type):
    try:
        with open(created_file, 'a', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow([object_name, schema_name, object_type, 'SUCCESS',
                             datetime.now().strftime('%Y-%m-%d %H:%M:%S')])
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


# Process all DDL files
def process_ddl_files(connection, config):
    ddl_base_path = config['paths']['ddl_base_path']
    schema_name = config['object_config']['schema_name']
    object_type = config['object_config']['object_type']
    run_identifier = config['object_config']['run_identifier']
    output_directory = config['paths']['output_directory']

    retry_enabled = config['execution']['retry_failed_objects']
    max_retries = config['execution']['max_retries']
    batch_size = config['execution']['batch_size']

    # Initialize CSV files
    created_file, errored_file = initialize_csv_files(output_directory, run_identifier)
    if not created_file or not errored_file:
        logging.error("Failed to initialize CSV files. Exiting.")
        return

    # Get all DDL files
    ddl_files = get_ddl_files(ddl_base_path, schema_name)
    if not ddl_files:
        logging.warning("No SQL files found to process")
        return

    # Statistics
    total_objects = len(ddl_files)
    created_count = 0
    errored_count = 0
    dependency_errors = []

    logging.info("=" * 80)
    logging.info(f"Processing Configuration:")
    logging.info(f"  - Schema: {schema_name}")
    logging.info(f"  - Object Type: {object_type.upper()}")
    logging.info(f"  - Total Objects: {total_objects}")
    logging.info(f"  - Run Identifier: {run_identifier}")
    logging.info("=" * 80)

    # First pass: Try to create all objects
    for idx, file_name in enumerate(ddl_files, 1):
        object_name = file_name.replace('.sql', '')

        # Log progress every batch_size objects
        if idx % batch_size == 0:
            logging.info(f"Progress: {idx}/{total_objects} {object_type}s processed")

        # Read DDL content
        ddl_content = read_ddl_file(ddl_base_path, schema_name, file_name)
        if not ddl_content:
            logging.error(f"Skipping {object_name} - Could not read SQL file")
            write_to_errored_csv(errored_file, object_name, schema_name, object_type,
                                 "FILE_READ_ERROR", "Could not read SQL file")
            errored_count += 1
            continue

        # Execute DDL
        success, error_type, error_message = execute_ddl(connection, ddl_content)

        if success:
            logging.info(f"✓ Successfully created {object_type}: {object_name}")
            write_to_created_csv(created_file, object_name, schema_name, object_type)
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
                ddl_content = read_ddl_file(ddl_base_path, schema_name, file_name)
                if not ddl_content:
                    still_failing.append((object_name, file_name))
                    continue

                success, error_type, error_message = execute_ddl(connection, ddl_content)

                if success:
                    logging.info(f"✓ Successfully created {object_type} on retry: {object_name}")
                    write_to_created_csv(created_file, object_name, schema_name, object_type)
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

    # Final summary
    success_rate = (created_count / total_objects * 100) if total_objects > 0 else 0

    logging.info("=" * 80)
    logging.info("EXECUTION SUMMARY")
    logging.info("=" * 80)
    logging.info(f"Object Type: {object_type.upper()}")
    logging.info(f"Schema: {schema_name}")
    logging.info(f"Total Objects: {total_objects}")
    logging.info(f"Successfully Created: {created_count}")
    logging.info(f"Failed: {errored_count}")
    logging.info(f"Success Rate: {success_rate:.2f}%")
    logging.info(f"Created objects saved to: {created_file}")
    logging.info(f"Errored objects saved to: {errored_file}")
    logging.info("=" * 80)

    print("\n" + "=" * 80)
    print("EXECUTION COMPLETED")
    print("=" * 80)
    print(f"Object Type: {object_type.upper()}")
    print(f"Schema: {schema_name}")
    print(f"✓ Successfully created: {created_count} {object_type}s")
    print(f"✗ Failed: {errored_count} {object_type}s")
    print(f"Success Rate: {success_rate:.2f}%")
    print(f"\nCreated objects: {created_file}")
    print(f"Errored objects: {errored_file}")
    print("=" * 80)


# Main function
def main():
    # Load configuration
    config = load_config()
    if not config:
        print("Failed to load configuration. Exiting.")
        return

    # Setup logging
    run_identifier = config['object_config']['run_identifier']
    log_directory = config['paths']['log_directory']
    log_file = setup_logging(log_directory, run_identifier)

    if not log_file:
        print("Failed to setup logging. Exiting.")
        return

    logging.info(f"Configuration loaded successfully")
    logging.info(f"Log file: {log_file}")

    # Connect to Redshift
    connection = connect_to_redshift(config)
    if not connection:
        logging.error("Failed to connect to Redshift. Exiting.")
        return

    try:
        # Process all DDL files
        process_ddl_files(connection, config)
    except Exception as e:
        logging.error(f"Unexpected error in main execution: {e}")
        print(f"Unexpected error: {e}")
    finally:
        # Close connection
        connection.close()
        logging.info("Connection closed. Script execution completed.")


if __name__ == "__main__":
    main()