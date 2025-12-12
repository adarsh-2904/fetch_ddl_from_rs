import os
import psycopg2
import logging
import yaml
import csv
from datetime import datetime
from pathlib import Path
import glob


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


# Find the latest created CSV file
def find_latest_created_csv(output_directory, run_identifier):
    try:
        # Pattern to match: run_identifier_TIMESTAMP_created.csv
        pattern = os.path.join(output_directory, f"{run_identifier}_*_created.csv")
        created_files = glob.glob(pattern)

        if not created_files:
            print(f"No created CSV files found matching pattern: {pattern}")
            return None

        # Sort by modification time (most recent first)
        latest_file = max(created_files, key=os.path.getmtime)

        # Extract timestamp from filename for display
        filename = os.path.basename(latest_file)
        timestamp_part = filename.replace(f"{run_identifier}_", "").replace("_created.csv", "")

        print(f"\n✓ Found latest created file: {filename}")
        print(f"  Timestamp: {timestamp_part}")

        return latest_file

    except Exception as e:
        print(f"Error finding latest created CSV: {e}")
        return None


# Setup logging with dynamic file names and timestamps
def setup_logging(log_directory, run_identifier):
    try:
        os.makedirs(log_directory, exist_ok=True)

        # Add timestamp to log file name
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        log_file = os.path.join(log_directory, f"{run_identifier}_{timestamp}_drop_log.log")

        # Clear any existing handlers
        for handler in logging.root.handlers[:]:
            logging.root.removeHandler(handler)

        logging.basicConfig(
            filename=log_file,
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            filemode='w'
        )

        # Also log to console
        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
        console.setFormatter(formatter)
        logging.getLogger('').addHandler(console)

        logging.info("=" * 80)
        logging.info(f"Starting DROP Objects Script - {run_identifier}")
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


# Read created objects from CSV
def read_created_objects(created_file):
    try:
        if not os.path.exists(created_file):
            logging.error(f"Created objects file not found: {created_file}")
            print(f"Error: File not found - {created_file}")
            return []

        objects_to_drop = []
        with open(created_file, 'r', newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                objects_to_drop.append({
                    'object_name': row['object_name'],
                    'schema_name': row['schema_name'],
                    'object_type': row['object_type']
                })

        logging.info(f"Found {len(objects_to_drop)} objects to drop from {created_file}")
        return objects_to_drop

    except Exception as e:
        logging.error(f"Error reading created objects CSV: {e}")
        print(f"Error reading created objects CSV: {e}")
        return []


# Drop a single object (view, table, or procedure)
def drop_object(connection, schema_name, object_name, object_type):
    try:
        cursor = connection.cursor()

        # Build appropriate DROP statement based on object type
        if object_type.lower() == 'view':
            drop_sql = f"DROP VIEW IF EXISTS {schema_name}.{object_name} CASCADE;"
        elif object_type.lower() == 'table':
            drop_sql = f"DROP TABLE IF EXISTS {schema_name}.{object_name} CASCADE;"
        elif object_type.lower() == 'procedure':
            drop_sql = f"DROP PROCEDURE IF EXISTS {schema_name}.{object_name} CASCADE;"
        else:
            logging.warning(f"Unknown object type: {object_type}. Skipping {object_name}")
            return False, f"Unknown object type: {object_type}"

        cursor.execute(drop_sql)
        connection.commit()
        cursor.close()
        return True, None

    except psycopg2.Error as e:
        connection.rollback()
        error_message = str(e).strip()
        return False, error_message
    except Exception as e:
        connection.rollback()
        return False, str(e)


# Initialize drop summary CSV
def initialize_drop_summary_csv(summary_file):
    try:
        summary_dir = os.path.dirname(summary_file)
        os.makedirs(summary_dir, exist_ok=True)

        with open(summary_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['object_name', 'schema_name', 'object_type', 'status', 'error_message', 'timestamp'])
        logging.info(f"Initialized drop summary CSV: {summary_file}")
    except Exception as e:
        logging.error(f"Error initializing drop summary CSV: {e}")


# Write to drop summary CSV
def write_to_drop_summary_csv(summary_file, object_name, schema_name, object_type, status, error_message=None):
    try:
        with open(summary_file, 'a', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            error_msg = error_message if error_message else ""
            # Truncate error message if too long
            error_msg_short = error_msg[:500] if len(error_msg) > 500 else error_msg
            writer.writerow([object_name, schema_name, object_type, status, error_msg_short,
                             datetime.now().strftime('%Y-%m-%d %H:%M:%S')])
    except Exception as e:
        logging.error(f"Error writing to drop summary CSV: {e}")


# Drop all objects from the created CSV
def drop_all_objects(connection, objects_to_drop, summary_file):
    total_objects = len(objects_to_drop)
    dropped_count = 0
    failed_count = 0

    # Get object type from first object (all should be same type from one run)
    object_type = objects_to_drop[0]['object_type'] if objects_to_drop else 'object'

    logging.info(f"Starting to drop {total_objects} {object_type}(s)")
    print(f"\nStarting to drop {total_objects} {object_type}(s)...")
    print("-" * 80)

    # Initialize summary CSV
    initialize_drop_summary_csv(summary_file)

    for idx, obj_info in enumerate(objects_to_drop, 1):
        object_name = obj_info['object_name']
        schema_name = obj_info['schema_name']
        obj_type = obj_info['object_type']

        # Log progress every 50 objects
        if idx % 50 == 0:
            logging.info(f"Progress: {idx}/{total_objects} {object_type}(s) processed")
            print(f"Progress: {idx}/{total_objects} {object_type}(s) processed")

        # Drop the object
        success, error_message = drop_object(connection, schema_name, object_name, obj_type)

        if success:
            logging.info(f"✓ Successfully dropped {obj_type}: {object_name}")
            write_to_drop_summary_csv(summary_file, object_name, schema_name, obj_type, "DROPPED")
            dropped_count += 1
        else:
            logging.warning(f"✗ Failed to drop {obj_type}: {object_name} - Error: {error_message}")
            write_to_drop_summary_csv(summary_file, object_name, schema_name, obj_type, "FAILED", error_message)
            failed_count += 1

    # Final summary
    success_rate = (dropped_count / total_objects * 100) if total_objects > 0 else 0

    logging.info("=" * 80)
    logging.info("DROP OPERATION SUMMARY")
    logging.info("=" * 80)
    logging.info(f"Object Type: {object_type.upper()}")
    logging.info(f"Total Objects: {total_objects}")
    logging.info(f"Successfully Dropped: {dropped_count}")
    logging.info(f"Failed: {failed_count}")
    logging.info(f"Success Rate: {success_rate:.2f}%")
    logging.info(f"Drop summary saved to: {summary_file}")
    logging.info("=" * 80)

    print("\n" + "=" * 80)
    print("DROP OPERATION COMPLETED")
    print("=" * 80)
    print(f"Object Type: {object_type.upper()}")
    print(f"✓ Successfully dropped: {dropped_count} {object_type}(s)")
    print(f"✗ Failed: {failed_count} {object_type}(s)")
    print(f"Success Rate: {success_rate:.2f}%")
    print(f"\nDrop summary: {summary_file}")
    print("=" * 80)


# Main function
def main():
    print("\n" + "=" * 80)
    print("DROP CREATED OBJECTS - CLEANUP SCRIPT FOR TESTING")
    print("=" * 80)

    # Load configuration
    config = load_config()
    if not config:
        print("Failed to load configuration. Exiting.")
        return

    run_identifier = config['object_config']['run_identifier']
    object_type = config['object_config']['object_type']
    output_directory = config['paths']['output_directory']

    print(f"\nConfiguration:")
    print(f"  Run Identifier: {run_identifier}")
    print(f"  Object Type: {object_type.upper()}")

    # Find the latest created CSV file
    created_file = find_latest_created_csv(output_directory, run_identifier)

    if not created_file:
        print("\n❌ No created CSV file found. Nothing to drop.")
        return

    print("\n" + "=" * 80)
    print(f"⚠️  WARNING: This script will DROP all {object_type}(s) listed in:")
    print(f"   {created_file}")
    print("This action CANNOT be undone!")
    print("=" * 80)

    # Ask for confirmation
    confirmation = input(f"\nType 'YES' to proceed with dropping {object_type}(s) (or anything else to cancel): ")

    if confirmation.strip().upper() != 'YES':
        print(f"\n❌ Operation cancelled by user. No {object_type}(s) were dropped.")
        return

    print(f"\n✓ Confirmed. Starting drop operation...\n")

    # Setup logging
    log_directory = config['paths']['log_directory']
    log_file = setup_logging(log_directory, run_identifier)

    if not log_file:
        print("Failed to setup logging. Exiting.")
        return

    logging.info(f"Configuration loaded successfully")
    logging.info(f"Log file: {log_file}")
    logging.info(f"Source file: {created_file}")

    # Connect to Redshift
    connection = connect_to_redshift(config)
    if not connection:
        logging.error("Failed to connect to Redshift. Exiting.")
        return

    try:
        # Read created objects CSV
        objects_to_drop = read_created_objects(created_file)

        if not objects_to_drop:
            logging.warning("No objects found to drop. Exiting.")
            print("\nNo objects found to drop. Exiting.")
            return

        # Prepare summary file path with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        summary_file = os.path.join(output_directory, f"{run_identifier}_{timestamp}_dropped_summary.csv")

        # Drop all objects
        drop_all_objects(connection, objects_to_drop, summary_file)

    except Exception as e:
        logging.error(f"Unexpected error in main execution: {e}")
        print(f"Unexpected error: {e}")
    finally:
        # Close connection
        connection.close()
        logging.info("Connection closed. Drop script execution completed.")


if __name__ == "__main__":
    main()