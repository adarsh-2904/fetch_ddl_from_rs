CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.fact_atg_order_line
AS
SELECT * FROM eda.atg_vws.fact_atg_order_line
with no schema BINDING;