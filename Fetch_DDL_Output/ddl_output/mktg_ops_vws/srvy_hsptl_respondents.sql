CREATE OR REPLACE VIEW mktg_ops_vws.srvy_hsptl_respondents
AS SELECT srvy_hsptl_respondents.respondent_id, srvy_hsptl_respondents.sf_contact_id, srvy_hsptl_respondents.respondent_nm, srvy_hsptl_respondents.respondent_email, srvy_hsptl_respondents.respondent_role, srvy_hsptl_respondents.hospital_id, srvy_hsptl_respondents.srcsys_trans_ts, srvy_hsptl_respondents.dw_trans_ts, srvy_hsptl_respondents.row_stat_cd, srvy_hsptl_respondents.appl_src_cd, srvy_hsptl_respondents.load_id
   FROM mktg_ops_tbls.srvy_hsptl_respondents
  WHERE srvy_hsptl_respondents.row_stat_cd <> 'L'::bpchar
WITH NO SCHEMA BINDING;