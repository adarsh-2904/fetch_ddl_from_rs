CREATE TABLE mktg_ops_tbls.users (
    user_id integer NOT NULL identity(1,1) ENCODE az64,
    username character varying(50) NOT NULL ENCODE lzo,
    email character varying(100) NOT NULL ENCODE lzo,
    created_at timestamp without time zone DEFAULT ('now'::text)::timestamp with time zone ENCODE az64,
    PRIMARY KEY (user_id),
    UNIQUE (email)
)
DISTSTYLE AUTO;