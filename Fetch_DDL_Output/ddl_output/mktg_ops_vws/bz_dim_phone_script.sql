CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_phone_script AS 
-- mktg_ops_vws.bz_dim_phone_script source

CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_phone_script AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY script_id) AS script_key,
    script_dsc,
    script_id,
    script_num,
    script_appeal
FROM mods_bi_rep.mktg_ops_tbls.dim_phone_script
WITH NO SCHEMA BINDING
;