CREATE OR REPLACE VIEW mktg_ops_vws.gms_bzf_cnst_cnstcy_curnt AS
SELECT
    cnst_mstr_id,
    one_k_ind,
    five_k_ind,
    adgp_ind,
    arc_ldrshp_scty_ind,
    blood_dnr_ind,
    bmh_slvr_dnr_ind,
    bog_ind,
    cb_scty_bronze_ind,
    cb_scty_slvr_ind,
    cb_scty_gold_ind,
    cb_scty_pltnm_ind,
    cb_scty_ind,
    chairman_cncl_ind,
    chpt_board_chair_ind,
    chpt_board_mmbr_ind,
    corp_advsry_cncl_ind,
    distr_respndr_ind,
    gp_dnr_spotlight_ind,
    hon_board_mmbr_ind,
    hmntrn_crcle_ind,
    hmntrn_crcle_distr_respndr_ind,
    hmntrn_crcle_distr_suprtr_ind,
    leg_scty_ind,
    ldrshp_scty_ind,
    ldrshp_scty_gold_ind,
    mission_ldr_ind,
    npt_board_ind,
    president_cncl_ind,
    ready_365_scty_gold_ind,
    ready_365_scty_bronze_ind,
    ready_365_scty_slvr_ind,
    ready_365_scty_pltnm_ind,
    ready_rating_ind,
    saf_advsry_board_ind,
    saf_ldrshp_ind,
    saf_gvng_prog_ind,
    staff_ind,
    tifny_crcle_bmh_mmbr_ind,
    tifny_crcle_bmh_slvr_mmbr_ind,
    tifny_crcle_bmh_gold_mmbr_ind,
    tifny_crcle_bmh_pltnm_mmbr_ind,
    tifny_crcle_lftm_mmbr_ind,
    tifny_crcle_mmbr_ind,
    tifny_crcle_ntnl_cncl_ind,
    volntr_ind,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
FROM mktg_ops_tbls.gms_bzf_cnst_cnstcy_curnt
WITH NO SCHEMA BINDING;