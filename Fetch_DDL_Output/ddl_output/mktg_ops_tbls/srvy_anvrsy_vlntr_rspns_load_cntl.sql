CREATE TABLE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_load_cntl (
    iwebappid integer ENCODE az64,
    active_start_dt date ENCODE az64,
    active_end_dt date ENCODE az64,
    active_ind smallint ENCODE az64
)
DISTSTYLE AUTO;