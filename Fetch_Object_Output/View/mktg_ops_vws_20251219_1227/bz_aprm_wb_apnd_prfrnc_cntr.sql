CREATE OR REPLACE VIEW mktg_ops_vws.bz_aprm_wb_apnd_prfrnc_cntr
AS
SELECT * FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY audience_mbr_id, hist_rec_id ORDER BY snapshot_ts) AS rn
    FROM mktg_ops_tbls.aprm_wb_apnd_prfrnc_cntr
) 
WHERE rn = 1
with no schema binding;