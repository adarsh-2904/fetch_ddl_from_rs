CREATE TABLE mktg_ops_tbls.agent (
    agent_id integer NOT NULL ENCODE az64,
    agent_first_nm character varying(50) ENCODE lzo,
    agent_last_nm character varying(50) ENCODE lzo,
    UNIQUE (agent_id)
)
DISTSTYLE ALL;