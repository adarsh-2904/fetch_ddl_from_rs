CREATE TABLE mktg_ops_tbls.pbi_model_perf_auc (
    src_cd character varying(20) ENCODE raw distkey,
    src_key integer ENCODE az64,
    pctile_file numeric(15,2) ENCODE az64,
    scr_mods numeric(16,4) ENCODE az64,
    pctile_mail_qty_mods numeric(15,4) ENCODE az64,
    fpr_mods numeric(15,4) ENCODE az64,
    tpr_mods numeric(15,4) ENCODE az64,
    cumu_amt_pct_mods numeric(15,4) ENCODE az64,
    lift_mods numeric(15,4) ENCODE az64,
    lift_amt_mods numeric(15,4) ENCODE az64,
    auc_mods numeric(15,8) ENCODE az64,
    scr_sm smallint ENCODE az64,
    pctile_mail_qty_sm numeric(15,4) ENCODE az64,
    fpr_sm numeric(15,4) ENCODE az64,
    tpr_sm numeric(15,4) ENCODE az64,
    cumu_amt_pct_sm numeric(15,4) ENCODE az64,
    lift_sm numeric(15,4) ENCODE az64,
    lift_amt_sm numeric(15,4) ENCODE az64,
    auc_sm numeric(15,8) ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( src_cd );