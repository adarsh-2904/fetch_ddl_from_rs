CREATE TABLE mktg_ops_tbls.pbi_entrprs_campgn_comnts (
    commnt_dt date ENCODE az64,
    dashbrd_nm character varying(50) ENCODE lzo,
    commnt_typ character varying(25) ENCODE lzo,
    commnt_1 character varying(500) ENCODE lzo,
    commnt_2 character varying(500) ENCODE lzo,
    commnt_3 character varying(500) ENCODE lzo,
    commnt_4 character varying(500) ENCODE lzo
)
DISTSTYLE AUTO;