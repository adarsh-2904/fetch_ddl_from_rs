CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_dim_unit_merged AS
SELECT
    orig_chap.unit_key AS orig_unit_key,
    orig_chap.nk_ecode AS orig_nk_ecode,
    orig_chap.nk_branch_cd AS orig_nk_branch_cd,
    orig_chap.unit_nm AS orig_unit_nm,

    prim_chap.unit_key AS unit_key,
    prim_chap.nk_ecode AS nk_ecode,
    prim_chap.nk_branch_cd AS nk_branch_cd,
    prim_chap.branch_cd,
    prim_chap.branch_typ,
    prim_chap.branch_short_dsc,
    prim_chap.branch_long_dsc,
    prim_chap.hcms_co_cd,
    prim_chap.unit_typ_cd,
    prim_chap.unit_typ_dsc,
    prim_chap.unit_nm,
    prim_chap.sd_region_cd,
    prim_chap.sd_region_nm,
    prim_chap.srvc_area_cd,
    prim_chap.srvc_area_nm,
    prim_chap.hq_cd,
    prim_chap.hq_nm,
    prim_chap.state_grp_cd,
    prim_chap.state_grp_nm,
    prim_chap.peer_grp_cd,
    prim_chap.unit_addr,
    prim_chap.unit_city_nm,
    prim_chap.unit_state_cd,
    prim_chap.unit_state_nm,
    prim_chap.unit_zip,
    prim_chap.accntng_dsc,
    prim_chap.status_dsc,
    prim_chap.status_dt,
    prim_chap.status2_dsc,
    prim_chap.status2_dt,
    prim_chap.merged_cd,
    prim_chap.prin_chapt,
    prim_chap.prim_chapt,
    prim_chap.active_flg,
    prim_chap.scope_cd,
    prim_chap.metro_flg,
    prim_chap.UIN_flg,
    prim_chap.BCD_flg,
    prim_chap.size_fld,
    prim_chap.srvc_area_city_nm,
    prim_chap.srvc_area_phone_num,
    prim_chap.srvc_area_exec_nm,
    prim_chap.main_unit_city_nm,
    prim_chap.main_unit_state_cd,
    prim_chap.main_unit_state_nm,
    prim_chap.cs_region_cd,
    prim_chap.cs_region_nm,
    prim_chap.cs_region_typ_dsc,
    prim_chap.division_cd,
    prim_chap.division_dsc,
    prim_chap.coe_cd,
    prim_chap.coe_typ,
    prim_chap.coe_nm,
    prim_chap.hster_div_cd,
    prim_chap.hster_cd,
    prim_chap.hster_nm,
    prim_chap.prreg_cd,
    prim_chap.prreg_typ,
    prim_chap.prreg_nm,
    prim_chap.gl_loc_cd,
    prim_chap.gl_phss_loc_cd,
    prim_chap.row_stat_cd,
    prim_chap.dw_srcsys_ts,
    prim_chap.appl_src_cd,
    prim_chap.load_id
FROM eda.dw_common_vws.dim_unit AS orig_chap
JOIN eda.dw_common_vws.dim_unit AS prim_chap
    ON orig_chap.prim_chapt = prim_chap.nk_ecode
    AND prim_chap.nk_branch_cd = '000'
    AND orig_chap.unit_typ_cd = prim_chap.unit_typ_cd
    AND orig_chap.appl_src_cd = prim_chap.appl_src_cd
WITH NO SCHEMA BINDING;