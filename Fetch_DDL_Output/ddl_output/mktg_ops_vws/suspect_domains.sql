CREATE OR REPLACE VIEW mktg_ops_vws.suspect_domains AS 
SELECT suspect_domains.bad_domain FROM mktg_ops_tbls.suspect_domains WITH NO SCHEMA BINDING;