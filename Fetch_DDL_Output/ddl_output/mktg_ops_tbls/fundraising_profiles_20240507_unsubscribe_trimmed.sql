CREATE TABLE mktg_ops_tbls.fundraising_profiles_20240507_unsubscribe_trimmed (
    id integer ENCODE raw distkey,
    phone_number bigint ENCODE az64,
    opted_out_at timestamp without time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( id );