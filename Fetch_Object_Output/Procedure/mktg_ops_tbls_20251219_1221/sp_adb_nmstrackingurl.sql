CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_nmstrackingurl(OUT inserted_count integer)
 LANGUAGE plpgsql
AS $$
	
	
	
BEGIN
    INSERT INTO mktg_ops_tbls.adb_nmstrackingurl (
        ichecksum,
        ideliveryid,
        ifolderid,
        ioccurrence,
        iofferid,
        istep,
        itrackingurlid,
        itype,
        iwebappid,
        iwithparams,
        scategory,
        sgoal,
        slabel,
        ssource,
        stagid,
        strackername,
        tsvalidity,
        ipurlid,
        row_stat_cd,
        appl_src_cd,
        load_id,
        dw_trans_ts
    )
    SELECT 
        stg.ichecksum,
        stg.ideliveryid,
        stg.ifolderid,
        stg.ioccurrence,
        stg.iofferid,
        stg.istep,
        stg.itrackingurlid,
        stg.itype,
        stg.iwebappid,
        stg.iwithparams,
        stg.scategory,
        stg.sgoal,
        stg.slabel,
        stg.ssource,
        stg.stagid,
        stg.strackername,
        stg.tsvalidity,
        stg.ipurlid,
        stg.row_stat_cd,
        stg.appl_src_cd,
        stg.load_id,
        CURRENT_DATE
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmstrackingurl stg
    LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tgt
        ON stg.itrackingurlid = tgt.itrackingurlid
    WHERE tgt.itrackingurlid IS NULL;

    -- Capture number of rows inserted
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
END;



$$
