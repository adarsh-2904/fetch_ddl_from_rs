CREATE TABLE mktg_ops_tbls.gms_arc_fr_smry_cbg (
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    cbg_eligblty_cym0_dt date ENCODE az64,
    cbg_eligblty_cym1_dt date ENCODE az64,
    cbg_eligblty_cym2_dt date ENCODE az64
)
DISTSTYLE AUTO;