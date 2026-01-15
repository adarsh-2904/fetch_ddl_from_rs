CREATE TABLE mktg_ops_tbls.srvy_new_vlntr_load_cntl (
    srvy_id smallint ENCODE az64,
    active_start_dt date ENCODE az64,
    active_end_dt date ENCODE az64,
    active_ind smallint ENCODE az64
)
DISTSTYLE AUTO;