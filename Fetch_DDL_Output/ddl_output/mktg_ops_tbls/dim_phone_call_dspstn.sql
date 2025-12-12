CREATE TABLE mktg_ops_tbls.dim_phone_call_dspstn (
    dspstn_key integer ENCODE zstd distkey,
    dspstn_id smallint ENCODE zstd,
    dspstn1_cd character(2) ENCODE zstd,
    dspstn2_cd character(2) ENCODE zstd,
    dspstn_dsc character varying(50) ENCODE zstd,
    dspstn_ctg_cd character varying(1) ENCODE zstd,
    dspstn_ctg_dsc character varying(40) ENCODE zstd,
    is_std_ind smallint ENCODE zstd,
    is_actv_ind smallint ENCODE zstd,
    is_cmplt_ind smallint ENCODE zstd,
    is_gift_ind smallint ENCODE zstd,
    is_no_ind smallint ENCODE zstd,
    is_rght_prty_cntct_ind smallint ENCODE zstd,
    is_sys_wrng_num_ind smallint ENCODE zstd,
    is_agnt_wrng_num_ind smallint ENCODE zstd,
    is_callbl_ind smallint ENCODE zstd,
    is_fnl_ind smallint ENCODE zstd,
    is_sys_ind smallint ENCODE zstd,
    is_elctrnc_pmt_ind smallint ENCODE zstd,
    is_agnt_hndld_ind smallint ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( dspstn_key );