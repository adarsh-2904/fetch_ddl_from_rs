CREATE OR REPLACE VIEW mktg_ops_vws.cnvo_cnst AS 
-- mktg_ops_vws.cnvo_cnst source

CREATE OR REPLACE VIEW mktg_ops_vws.cnvo_cnst
AS
SELECT 
    B.cnst_mstr_id,
    A.* 
FROM convio_tbls.cnvo_cnst A
LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_external_brid B
    ON A.cnvo_cnst_id = CAST(B.cnst_srcsys_id AS INTEGER) 
    AND B.arc_srcsys_cd = 'CNVO'
with no schema BINDING;