CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_gift_stg AS 
-- mktg_ops_vws.gmpbz_dim_gift_stg source

--------------------------------------------------------------------------------

 
create or replace view mktg_ops_vws.gmpbz_dim_gift_stg 
/*
Modified By: 	Michael Andrien
Modified Date:	9/12/2019
Purpose:	This view references the GMS Gift Stage reference view, which reflects where in the gift processing process the gift resides.
The MODS team needs the view definition in the mktg_ops_vws database, which is the source for the Adobe Campaign application. 
*/
AS

SELECT
gift_stg_key ,
gift_stg_cd ,
gift_stg_dsc ,
active_ind,
CAST(srcsys_create_ts AS TIMESTAMP)  AS srcsys_create_ts,
CAST(srcsys_update_ts AS TIMESTAMP)  AS srcsys_update_ts,
srcsys_created_by ,
srcsys_modified_by ,
row_status_cd ,
CAST(dw_trans_ts AS TIMESTAMP)  AS dw_trans_ts,
load_id ,
appl_src_cd 
FROM eda.ufds_vws.gmpbz_dim_gift_stg
WHERE row_status_cd <> 'L'
WITH NO SCHEMA BINDING
;