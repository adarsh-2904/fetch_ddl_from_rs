create or REPLACE VIEW mktg_ops_vws.bz_cnst_mstr AS
SELECT * FROM eda.ARC_MDM_VWS.bz_cnst_mstr
with no schema binding;