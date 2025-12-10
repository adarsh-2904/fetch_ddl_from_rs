CREATE OR REPLACE VIEW mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref
AS
SELECT  
    question_id, 
    srvy_id, 
    iwebappid, 
    src_attrbt_nm,
    srvy_question_num,
    adobe_path_var
FROM mktg_ops_tbls.srvy_new_vlntr_questn_2_srvy_xref
with no schema binding;