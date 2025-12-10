CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fact_interaction
AS SELECT fi.cnst_mstr_id, fi.orig_cnst_mstr_id, fi.cnst_hsld_id, fi.cell_id, fi.cell_src_cd, fi.cell_subsrc_cd, fi.fr_last_ta_acct_id, 
        CASE
            WHEN fia.finder_number IS NOT NULL THEN fia.finder_number::character varying
            ELSE '0'::character varying::character varying(45)
        END AS finder_number, fi.offer_id, fi.treatment_id, fi.activity_id, fi.segementation_id, fi.segment_id, fi.outbnd_id, fi.email_id, fi.email_sent_dt, fi.to_domain, fi.drop_dt, fi.update_dt, fi.last_dntn_dt, fi.last_dntn_amt, fi.chpt_affl, fi.submitter_nm, fi.chpt_id, fi.cntct_dt, fi.run_dt, fi.run_id, 
        CASE
            WHEN fia.cnst_mstr_id IS NULL THEN 0
            ELSE 1
        END AS mailed_ind, 
        CASE
            WHEN fia.cnst_mstr_id IS NULL THEN 1
            ELSE 0
        END AS supressed_ind, COALESCE(fia.mail_drop_cnt, 0::bigint) AS "coalesce", fi.row_stat_cd, fi.appl_src_cd, fi.load_id, fi.dw_trans_ts
   FROM mktg_ops_tbls.bzfc_fact_interaction fi
   LEFT JOIN ( SELECT fact_interaction_aprm.cnst_mstr_id, fact_interaction_aprm.cell_src_cd, "max"(fact_interaction_aprm.finder_number::text) AS finder_number, count(*) AS mail_drop_cnt
           FROM mktg_ops_tbls.fact_interaction_aprm
          GROUP BY fact_interaction_aprm.cnst_mstr_id, fact_interaction_aprm.cell_src_cd) fia ON fi.cnst_mstr_id = fia.cnst_mstr_id AND fi.cell_src_cd::text = fia.cell_src_cd::text
WITH NO SCHEMA BINDING;