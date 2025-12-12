CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_delivery
AS SELECT a.delivery_key, a.nk_delivery_id, a.campgn_key, a.campgn_id, a.delivery_label, a.delivery_cd, 
        CASE
            WHEN b.imessagetype = 0 THEN 'Email'::text
            WHEN b.imessagetype = 1 THEN 'SMS'::text
            WHEN b.imessagetype = 2 THEN 'Phone'::text
            WHEN b.imessagetype = 3 THEN 'Direct Mail'::text
            WHEN b.imessagetype = 4 THEN 'Fax'::text
            WHEN b.imessagetype = 5 THEN 'Agency'::text
            WHEN b.imessagetype = 20 THEN 'Facebook'::text
            WHEN b.imessagetype = 25 THEN 'Twitter'::text
            WHEN b.imessagetype = 41 THEN 'iOS Applications'::text
            WHEN b.imessagetype = 42 THEN 'Andriod Application'::text
            WHEN b.imessagetype = 120 THEN 'Other'::text
            ELSE 'Unknown'::text
        END AS channel_dsc, b.sinternalname AS delivery_nm, a.delivery_status_id, a.delivery_status_dsc, a.delivery_state_id, a.delivery_state_dsc, 
        CASE
            WHEN b.scampaignsourcecode IS NOT NULL THEN b.scampaignsourcecode
            ELSE b.sdeliverycode
        END AS src_cd, a.subsrc_cd, b.tsbroadstart::date AS delivery_start_dt, b.tsbroadend::date AS delivery_end_dt, b.isuccesswithoutseeds AS sent_noseed_cnt, b.iseedprocessed AS seed_cnt, a.msg_sent_cnt, a.msg_deliver_cnt, a.msg_procsd_cnt, b.irecipientopen AS msg_open_cnt, a.msg_bounce_cnt, a.msg_unsubscrb_cnt, a.msg_click_cnt, a.msg_success_cnt, a.msg_success_noseed_cnt, a.msg_reject_cnt, a.msg_refused_cnt, a.mailbox_full_cnt, a.invalid_domain_cnt, a.msg_forward_cnt, a.xpromo_ind, a.xpromo_flg, a.xpromo_from, a.xpromo_to, a.exclude_rptng_ind, a.is_trigg_msg_ind, a.scid, a.mail_drop_dt, a.srcsys_trans_ts, a.dw_trans_ts, a.row_stat_cd, a.appl_src_cd, a.load_id
   FROM mktg_ops_tbls.dim_delivery a
   LEFT JOIN mktg_ops_tbls.adb_nmsdelivery b ON a.nk_delivery_id = b.ideliveryid
  WHERE a.row_stat_cd <> 'L'::bpchar
  with no schema binding;