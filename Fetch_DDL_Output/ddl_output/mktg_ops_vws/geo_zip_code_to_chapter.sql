CREATE OR REPLACE VIEW mktg_ops_vws.geo_zip_code_to_chapter 
AS
SELECT * FROM eda.dw_common_vws.geo_zip_code_to_chapter
WITH NO SCHEMA BINDING
;