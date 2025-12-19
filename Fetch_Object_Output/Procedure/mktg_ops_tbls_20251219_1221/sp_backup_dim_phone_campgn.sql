CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_backup_dim_phone_campgn()
 LANGUAGE plpgsql
AS $$
BEGIN
    -- Step 1: Start backup
    RAISE NOTICE 'Starting backup of dim_phone_campgn.';

    -- Step 2: Clear backup table
    RAISE NOTICE 'Deleting from dim_phone_campgn_bkp...';
    DELETE FROM mktg_ops_tbls.dim_phone_campgn_bkp;

    -- Step 3: Insert data into backup table
    RAISE NOTICE 'Inserting into dim_phone_campgn_bkp...';
    INSERT INTO mktg_ops_tbls.dim_phone_campgn_bkp
    SELECT * FROM mktg_ops_tbls.dim_phone_campgn;

    -- Step 4: Confirm completion
    RAISE NOTICE 'Backup of dim_phone_campgn completed successfully.';

    -- EXCEPTION
        -- WHEN OTHERS THEN
            -- RAISE EXCEPTION 'Error occurred during dim_phone_campgn backup.';
END;
$$
