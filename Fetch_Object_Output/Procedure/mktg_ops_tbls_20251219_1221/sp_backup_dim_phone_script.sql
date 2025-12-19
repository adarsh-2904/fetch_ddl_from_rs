CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_backup_dim_phone_script()
 LANGUAGE plpgsql
AS $$
BEGIN
    -- Step 1: Start backup
    RAISE NOTICE 'Starting backup of dim_phone_script.';

    -- Step 2: Clear backup table
    RAISE NOTICE 'Deleting from dim_phone_script_bkp...';
    DELETE FROM mktg_ops_tbls.dim_phone_script_bkp;

    -- Step 3: Insert data into backup table
    RAISE NOTICE 'Inserting into dim_phone_script_bkp...';
    INSERT INTO mktg_ops_tbls.dim_phone_script_bkp
    SELECT * FROM mktg_ops_tbls.dim_phone_script;

    -- Step 4: Confirm completion
    RAISE NOTICE 'Backup completed successfully.';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error occurred during backup.';
END;
$$
