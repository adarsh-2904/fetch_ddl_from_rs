CREATE TABLE mktg_ops_tbls.audit_log (
    id bigint NOT NULL identity(1,1) ENCODE az64,
    proc_name character varying(255) ENCODE lzo,
    task_name character varying(255) ENCODE lzo,
    status character varying(50) ENCODE lzo,
    start_time timestamp without time zone ENCODE az64,
    end_time timestamp without time zone ENCODE az64,
    taskmessage character varying(500) ENCODE lzo,
    recs_processed bigint DEFAULT 0 ENCODE az64,
    PRIMARY KEY (id)
)
DISTSTYLE AUTO;