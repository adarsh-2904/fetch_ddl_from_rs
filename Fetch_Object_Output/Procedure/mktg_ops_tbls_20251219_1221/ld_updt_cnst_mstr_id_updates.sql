CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_updt_cnst_mstr_id_updates()
 LANGUAGE plpgsql
AS $$
	
/*
Created by: Michael Andrien
Create Date:01/14/2019
Purpose:  This macro runs cnst_mstr_id updates across all static tables where cnst_mstr_id exists.  The updates are run to keep the cnst_mstr_id 
				attribute current with cnst_mstr_id merge activity.  The orig_cnst_mstr_id in the tables preserves the original cnst_mstr_id that existed 
				when the record was first recorded.
				
Modified by: Michael Andrien
Modified Date:02/04/2019
Purpose:  Added update query to update the master id in the mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy table.  This is the Bio Donor Satisfaction Survey table that is loaded from Adobe responses 

Modified by: Michael Andrien
Modified Date:03/01/2019
Purpose:  Added updated for the fact_response_aprm and bz_fact_respons_pg tables

Modified by: 	Michael Andrien
Modified Date:	04/25/2019
Purpose:			Added new section to aooly master id updates to the Planned Giving (PG) response survey (mktg_ops_tbls.srvy_vlntr_p2p_rfrl )

Modified by: 	Michael Andrien
Modified Date:	05/24/2019
Purpose:	Added master id updates to the PG survey response table.

Modified by: 	Michael Andrien
Modified Date:	05/24/2019
Purpose: Added srvy_new_vlntr_rspns_v21 to the update list.  The new vol survey has two target table and we were only updating srvy_new_vlntr_rspns.

Modified by: 	Michael Andrien
Modified Date: 3/4/2020
Purpose: Added a section for the blood sponsor journey survey recipient and email interaction.  Applied master id updates for the biomed sponsor journey survey recipients.  These are sent to the sponsor contacts or coordinators, who are not mastered in CDI.  We are creating a dummy cnst_mstr_id for these recipients and for 
	cooresponding email interaction records so they flow properly into our email interactio summary table and view (mktg_ops_vws, bzfc_fact_email_intrctn_smry), which is used in our CE Reporting universe.  This allows the MODS team
	to delivery automated reportings regarding the email send stats for the Blood Sponsor Journey survey.  To keep the cnst_mstr_id unique and to avoid any conflicts with the master ids generated within CDI, we add 50 billion to the recipient id.

Modified By: Michael Andrien
Modified Date: 7/7/2020
Purpose: Replaced the WHERE clause in the fact_interaction_ff update statement below
	update mktg_data_tbls.fact_interaction_ff
	set cnst_mstr_id = mktg_ops_vws.bzl_cnst_fsa_acqstn.primary_cnst_mstr_id
	OLD WHERE - where mktg_data_tbls.fact_interaction_ff.finder_number = mktg_ops_vws.bzl_cnst_fsa_acqstn.acqstn_id and mktg_data_tbls.fact_interaction_ff.cnst_mstr_id = 0 and mktg_data_tbls.fact_interaction_ff.finder_number <> '0';
	NEW WHERE - where mktg_data_tbls.fact_interaction_ff.finder_number = mktg_ops_vws.bzl_cnst_fsa_acqstn.acqstn_id and mktg_data_tbls.fact_interaction_ff.cnst_mstr_id <> mktg_ops_vws.bzl_cnst_fsa_acqstn.primary_cnst_mstr_id

Also, added new fact_interaction_ff update based on finder number in GMS Giftran Dim - added comment to the inserted update in SQL below.  This update addresses master id updates for the GMS txn finder numbers where the gift is linked to only one person.
We still need to add an update for instances where the finder number is linked to more than one person.  We might leverage the gift ranking rule table to choose one the ranking master id.

Modified By: Michael Andrien
Modified Date: 03/01/2021
Purpose: Added update section for the  mktg_ops_tbls.srvy_gplg_rspns_ss table.

Modified By: Majeed Mohammad
Modified Date: 05/19/2021
Purpose: Updated the SQL for the mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy to use the updated column name of hstry_rcrd_id

Modified By: Michael Andrien
Modified Date: 05/28/2021
Purpose:  Added the new vol and vol anniversary tables listed below:
	mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy21
	mktg_ops_tbls.srvy_new_vlntr_rspns_fy21
	mktg_ops_tbls.srvy_anvrsy_vlntr_rspns

Modified By: Michael Andrien
Modified Date: 06/02/2021
Purpose:  Added the new vol and vol anniversary tables listed below:
	mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_all
	mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt
	
Modified By: Michael Andrien
Modified Date: 06/28/2021
Purpose:  Added the Regional Leadership survey table below.
	mktg_ops_tbls.srvy_rgnl_ldrshp_fy21

Modified By: Michael Andrien
Modified Date: 08/02/2021
Purpose: Added updates for the srvy_new_vlntr_rspns_fy22 and srvy_anvrsy_vlntr_rspns_fy22 volunteer survey tables

Modified By: Majeed Mohammad
Modified Date: 01/28/2022
Purpose: Added update section for the mktg_data_tbls.bzf_cnst_scr  table.

Modified By: Michael Andrien
Modified Date: 05/26/2022
Purpose: Added sections for the fresh address and pacific east email append table updates.

Modified By: Michael Andrien
Modified Date: 08/25/2022
Purpose: Added master id update for the PG Response Log data (mktg_stage_tbls.dm_response_gplg_stg)

Modified By: Michael Andrien
Modified Date: 06/13/2023
Purpose: Added master id update for the PG Response Log data (mktg_stage_tbls.dm_response_gplg_stg_hist)

Modified By: Michael Andrien
Modified Date: 06/26/2023
Purpose: Added mktg_ops_tbls.phone_interaction_eoc to master id updates process.

Modified By: Michael Andrien
Modified Date: 09/28/2023
Purpose: Added mktg_ops_tbls.bzf_cnst_scr_simio to master id updates process. 

Modified By: Michael Andrien
Modified Date: 01/08/2024
Purpose:  Added the mktg_data_tbls.dm_campaign_pg_hist table to the update process.

Modified By: Michael Andrien
Modified Date: 04/26/2024
Purpose:  Added the PG phone interaction eoc and phone sustainer upgrade tables to the macro (phone_interaction_pg_eoc,phone_interaction_sustnr_upgr)
*/	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
	total_updated int :=0;
	tmp_count INT;

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_updt_cnst_mstr_id_updates', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		UPDATE mktg_ops_tbls.dm_campaign_hist 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.dm_campaign_hist.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;
		
		UPDATE mktg_ops_tbls.dm_campaign_hist
		SET cnst_mstr_id = bzl_cnst_fsa_acqstn.primary_cnst_mstr_id
		from mktg_ops_vws.bzl_cnst_fsa_acqstn
		WHERE mktg_ops_tbls.dm_campaign_hist.finder_number = mktg_ops_vws.bzl_cnst_fsa_acqstn.acqstn_id AND mktg_ops_tbls.dm_campaign_hist.cnst_mstr_id = 0 AND mktg_ops_tbls.dm_campaign_hist.finder_number <> '0';
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the interaction table in mktg_ops_tbls.  */
		
		UPDATE mktg_ops_tbls.fact_interaction_ff 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fact_interaction_ff.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;
		
		UPDATE mktg_ops_tbls.fact_interaction_ff
		SET cnst_mstr_id = mktg_ops_vws.bzl_cnst_fsa_acqstn.primary_cnst_mstr_id
		from mktg_ops_vws.bzl_cnst_fsa_acqstn
		WHERE mktg_ops_tbls.fact_interaction_ff.finder_number = mktg_ops_vws.bzl_cnst_fsa_acqstn.acqstn_id AND mktg_ops_tbls.fact_interaction_ff.cnst_mstr_id <> mktg_ops_vws.bzl_cnst_fsa_acqstn.primary_cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;
		
		/* Added the next fact_interaction_ff update to apply GMS Finder updates - Mike Andrien 7-7-2020 */
		UPDATE mktg_ops_tbls.fact_interaction_ff
		SET cnst_mstr_id = a.cnst_mstr_id
		FROM
		(
			SELECT b.finder_num, a.cnst_mstr_id, a.gift_src_cd
			FROM mktg_ops_vws.gms_arc_fr_txn a
			LEFT JOIN mktg_ops_vws.gmpbz_dim_giftran b ON a.nk_gift_id = b.nk_gift_id
			LEFT JOIN mktg_ops_tbls.fact_interaction_ff c ON c.finder_number = b.finder_num AND c.motivtn_cd = a.gift_src_cd
			WHERE Substring(a.gift_src_cd,1,3) = 'RQQ' AND b.finder_num IS NOT NULL AND a.cnst_mstr_id <>  c.cnst_mstr_id
			AND b.finder_num IN 
			(
			SELECT b.finder_num
			FROM mktg_ops_vws.gms_arc_fr_txn a
			LEFT JOIN mktg_ops_vws.gmpbz_dim_giftran b ON a.nk_gift_id = b.nk_gift_id
			LEFT JOIN mktg_ops_tbls.fact_interaction_ff c ON c.finder_number = b.finder_num AND c.motivtn_cd = a.gift_src_cd
			WHERE Substring(a.gift_src_cd,1,3) = 'RQQ' AND b.finder_num IS NOT NULL 
			GROUP BY 1
			HAVING Count(a.cnst_mstr_id) = 1
			)
		) a (finder_num, cnst_mstr_id, src_cd)
		WHERE mktg_ops_tbls.fact_interaction_ff.motivtn_cd = a.src_cd AND mktg_ops_tbls.fact_interaction_ff.finder_number = a.finder_num AND mktg_ops_tbls.fact_interaction_ff.cnst_mstr_id <> a.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.fact_interaction_aprm 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fact_interaction_aprm.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.fact_interaction_bb
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fact_interaction_bb.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the response tables in mktg_ops_tbls.  */
		UPDATE mktg_ops_tbls.fact_response_aprm 
		SET cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fact_response_aprm.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.bz_fact_response_pg
		SET cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bz_fact_response_pg.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the fact_dmail_interaction table.  */
		UPDATE mktg_ops_tbls.fact_dmail_interaction 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fact_dmail_interaction.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the fact_email_interaction table.  */
		UPDATE mktg_ops_tbls.fact_email_interaction 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fact_email_interaction.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the fact_phone_interaction table.  */
		UPDATE mktg_ops_tbls.fact_phone_interaction 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fact_phone_interaction.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the campgn_prospct_list table.  */
		UPDATE mktg_ops_tbls.campgn_prospct_list
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.campgn_prospct_list.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the bzfc_active_cnst_multi_snpsht table.  */
		UPDATE mktg_ops_tbls.bzfc_active_cnst_multi_snpsht
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bzfc_active_cnst_multi_snpsht.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the bzfc_active_cnst_snpsht table.  */
		UPDATE mktg_ops_tbls.bzfc_active_cnst_snpsht
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bzfc_active_cnst_snpsht.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the bzfc_fact_donation table.  */
		UPDATE mktg_ops_tbls.bzfc_fact_donation 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bzfc_fact_donation.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the bzfc_fact_intrctn_em_smry table.  */
		UPDATE mktg_ops_tbls.bzfc_fact_intrctn_em_smry 
		SET primary_cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bzfc_fact_intrctn_em_smry.primary_cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the bzfc_fact_interaction_all table.  */
		UPDATE mktg_ops_tbls.bzfc_fact_interaction_all 
		SET primary_cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bzfc_fact_interaction_all.primary_cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the bz_fact_interaction_pg table.  */
		UPDATE mktg_ops_tbls.bz_fact_interaction_pg 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bz_fact_interaction_pg.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the bzfc_fact_interaction table.  */
		UPDATE mktg_ops_tbls.bzfc_fact_interaction 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bzfc_fact_interaction.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the bzfc_fact_interaction table.  */
		UPDATE mktg_ops_tbls.bzfc_fact_surv_resp 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.bzfc_fact_surv_resp.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the srvy_new_vlntr_rspns table.  */
		UPDATE mktg_ops_tbls.srvy_new_vlntr_rspns 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_new_vlntr_rspns.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.srvy_new_vlntr_rspns_v21
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_new_vlntr_rspns_v21.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.srvy_new_vlntr_rspns_fy21
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_new_vlntr_rspns_fy21.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.srvy_new_vlntr_rspns_fy22
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_new_vlntr_rspns_fy22.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_all
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_all.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update to the srvy_new_vlntr_rspns table.  */
		UPDATE mktg_ops_tbls.fact_vs_surv_resp 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fact_vs_surv_resp.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy21 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy21.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy22 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy22.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update to the srvy_rgnl_ldrshp_fy21table.  This table supports the Regional Leadership survey  */
		UPDATE mktg_ops_tbls.srvy_rgnl_ldrshp_fy21 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_rgnl_ldrshp_fy21.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update to the mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy table.  This is the Bio Donor Satisfaction Survey table that is loaded from Adobe responses   The first update addresses records where the original cnst_mstr_id is null.  This keeps the record in synce with Adobe recipient details.*/
		UPDATE mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy
		SET cnst_mstr_id = a.cnst_mstr_id
		FROM
		(
		SELECT c.bicnst_mstr_id, a.hstry_rcrd_id
		FROM mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy a
		LEFT JOIN mktg_ops_tbls.adb_nmswebapplogrcp b ON a.hstry_rcrd_id = b.iwebapplogrcpid
		LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient c  ON b.irecipientid = c.irecipientid
		WHERE a.cnst_mstr_id IS NULL
		) a (cnst_mstr_id, hstry_rcrd_id)
		
		WHERE mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy.hstry_rcrd_id = a.hstry_rcrd_id AND mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy.cnst_mstr_id IS NULL ;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy table.  */
		UPDATE mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.adb_bio_dnr_stsfctn_srvy.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id updates to mktg_ops_tbls.srvy_vlntr_p2p_rfrl  - We'll apply these updates in 3 statements.  The first 2 passes apply new volunteer friends and family referral response records where cnst_mstr_id = 0.  The first pass matches on the dim_volunteer email address and the second update
			matches dim_volunteer records on the secondary email address.  The 3rd pass applies master id updates to the previously mapped records to account for merged master id activity.
		*/
		/*  Vol Friends and Referral Match on email address */
		UPDATE mktg_ops_tbls.srvy_vlntr_p2p_rfrl 
		SET cnst_mstr_id = a.cnst_mstr_id,
				orig_cnst_mstr_id = a.cnst_mstr_id
		FROM
		(
			SELECT 
		    cnst_mstr_id,
			adnc_mbr_id,
			history_record_id,
			history_record_ts,
			dw_updt_ts,
			dw_trans_ts
			from (
				SELECT 
			    c.cnst_mstr_id,
				a.adnc_mbr_id,
				a.history_record_id,
				a.history_record_ts,
				a.dw_updt_ts,
				b.dw_trans_ts,
				Row_Number() Over (PARTITION BY a.history_record_id  ORDER BY  a.cnst_mstr_id, a.dw_updt_ts DESC, b.dw_trans_ts DESC) as rn
				FROM mktg_ops_tbls.srvy_vlntr_p2p_rfrl a
				LEFT JOIN eda.vms_vws.dim_volunteer b ON collate(a.email::text,'CASE_INSENSITIVE') = collate(b.email::text,'CASE_INSENSITIVE') -- and a.adnc_mbr_id = b.nk_account_id
				LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge c ON b.vol_key = c.cnst_mstr_subj_area_id AND c.cnst_mstr_subj_area_cd = 'VMS'
				WHERE a.cnst_mstr_id = 0
			
			) as subqry
			
			where subqry.rn=1
			
			
		)  a (cnst_mstr_id, adnc_mbr_id, history_record_id, history_record_ts, dw_updt_ts,dw_trans_ts)
		
		WHERE mktg_ops_tbls.srvy_vlntr_p2p_rfrl.history_record_id = a.history_record_id AND mktg_ops_tbls.srvy_vlntr_p2p_rfrl.adnc_mbr_id = a.adnc_mbr_id AND mktg_ops_tbls.srvy_vlntr_p2p_rfrl.dw_updt_ts = a.dw_updt_ts;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/*  Pass 2: Vol Friends and Referral Match on secondary email address */
		UPDATE mktg_ops_tbls.srvy_vlntr_p2p_rfrl 
		SET cnst_mstr_id = a.cnst_mstr_id,
				orig_cnst_mstr_id = a.cnst_mstr_id
		FROM
		(
		
			SELECT 
		    cnst_mstr_id,
			adnc_mbr_id,
			history_record_id,
			history_record_ts,
			dw_updt_ts,
			dw_trans_ts
			from(
					SELECT 
				    c.cnst_mstr_id,
					a.adnc_mbr_id,
					a.history_record_id,
					a.history_record_ts,
					a.dw_updt_ts,
					b.dw_trans_ts,
					Row_Number() Over (PARTITION BY a.history_record_id  ORDER BY  a.cnst_mstr_id, a.dw_updt_ts DESC, b.dw_trans_ts DESC) as rn 
					FROM mktg_ops_tbls.srvy_vlntr_p2p_rfrl a
					LEFT JOIN eda.vms_vws.dim_volunteer b ON collate(a.email::text,'CASE_INSENSITIVE') = collate(b.second_email::text,'CASE_INSENSITIVE') 
					LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge c ON b.vol_key = c.cnst_mstr_subj_area_id AND c.cnst_mstr_subj_area_cd = 'VMS'
					WHERE a.cnst_mstr_id = 0
			
			) as subqry
			
			where subqry.rn=1
		
			
		)  a (cnst_mstr_id, adnc_mbr_id, history_record_id, history_record_ts, dw_updt_ts,dw_trans_ts)
		
		WHERE mktg_ops_tbls.srvy_vlntr_p2p_rfrl.history_record_id = a.history_record_id AND mktg_ops_tbls.srvy_vlntr_p2p_rfrl.adnc_mbr_id = a.adnc_mbr_id AND mktg_ops_tbls.srvy_vlntr_p2p_rfrl.dw_updt_ts = a.dw_updt_ts;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Pass3:  Now apply merged master id updates to static records that have been loaded and mapped to master ids in the past. */
		UPDATE mktg_ops_tbls.srvy_vlntr_p2p_rfrl 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_vlntr_p2p_rfrl.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the PG Survey Response table.  */
		UPDATE mktg_ops_tbls.srvy_gplg_rspns 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_gplg_rspns.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the PG Survey Response SS table.  */
		UPDATE mktg_ops_tbls.srvy_gplg_rspns_ss 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.srvy_gplg_rspns_ss.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* 
			Apply master id updates for the biomed sponsor journey survey recipients.  These are sent to the sponsor contacts or coordinators, who are not mastered in CDI.  We are creating a dummy cnst_mstr_id for these recipients and for 
			cooresponding email interaction records so they flow properly into our email interactio summary table and view (mktg_ops_vws, bzfc_fact_email_intrctn_smry), which is used in our CE Reporting universe.  This allows the MODS team
			to delivery automated reportings regarding the email send stats for the Blood Sponsor Journey survey.  To keep the cnst_mstr_id unique and to avoid any conflicts with the master ids generated within CDI, we add 50 billion to the recipient id.
		*/
		UPDATE mktg_ops_tbls.adb_nmsrecipient
		SET bicnst_mstr_id = a.cnst_mstr_id
		FROM 
		(
			SELECT DISTINCT a.irecipientid, c.bicnst_mstr_id, 50000000000 + a.irecipientid AS cnst_mstr_id
			FROM mktg_ops_tbls.adb_nmsbroadlogrcp a
			LEFT JOIN mktg_ops_tbls.adb_nmsdelivery b ON a.ideliveryid = b.ideliveryid
			LEFT JOIN mktg_ops_tbls.adb_nmsrecipient c ON a.irecipientid = c.irecipientid
			WHERE scampaignsourcecode = 'blood_journey_email' AND bicnst_mstr_id = 0
		) a (irecipientid, bicnst_mstr_id, cnst_mstr_id)
		
		WHERE mktg_ops_tbls.adb_nmsrecipient.irecipientid = a.irecipientid AND mktg_ops_tbls.adb_nmsrecipient.bicnst_mstr_id = 0;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		UPDATE mktg_ops_tbls.fact_email_interaction
		SET cnst_mstr_id = a.cnst_mstr_id,
			orig_cnst_mstr_id = a.cnst_mstr_id
		FROM 
		(
		SELECT a.nk_recipient_id, 50000000000 + a.nk_recipient_id AS cnst_mstr_id, a.nk_delivery_id, a.nk_intrctn_id, a.delivery_key, intrctn_dt
		FROM mktg_ops_tbls.fact_email_interaction a
		LEFT JOIN mktg_ops_vws.bz_dim_delivery b ON a.delivery_key = b.delivery_key
		WHERE b.src_cd  = 'blood_journey_email' AND cnst_mstr_id = 0 
		) a (nk_recipient_id, cnst_mstr_id, nk_delivery_id, nk_intrctn_id, delivery_key, intrctn_dt)
		
		WHERE mktg_ops_tbls.fact_email_interaction.nk_recipient_id = a.nk_recipient_id AND mktg_ops_tbls.fact_email_interaction.nk_intrctn_id = a.nk_intrctn_id 
			AND mktg_ops_tbls.fact_email_interaction.intrctn_dt = a.intrctn_dt AND mktg_ops_tbls.fact_email_interaction.delivery_key = a.delivery_key AND mktg_ops_tbls.fact_email_interaction.cnst_mstr_id = 0; 
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;
	
		/* Apply master id update the the bzf_cnst_scr table.  */
		UPDATE mktg_ops_tbls.bzf_cnst_scr 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE  mktg_ops_tbls.bzf_cnst_scr.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply merged master id updates to static records that have been loaded in the Pacific East Email Append table */
		UPDATE mktg_ops_tbls.pacific_east_email_append  
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.pacific_east_email_append.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;
	
		/* Apply merged master id updates to static records that have been loaded in the Pacific East Email Append table */
		UPDATE mktg_ops_tbls.fresh_address_email_append  
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.fresh_address_email_append.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply merged master id updates to static records that have been loaded in the PG response stage table (mktg_stage_tbls.dm_response_gplg_stg) table */
		UPDATE mktg_stage_tbls.dm_response_gplg_stg  
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_stage_tbls.dm_response_gplg_stg.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply merged master id updates to static records that have been loaded in the PG response stage table (mktg_stage_tbls.dm_response_gplg_stg_hist) table */
		UPDATE mktg_stage_tbls.dm_response_gplg_stg_hist  
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_stage_tbls.dm_response_gplg_stg_hist.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply merged master id updates to static records that have been loaded in the phone interaction eoc table (mktg_ops_tbls.phone_interaction_eoc) table */
		UPDATE mktg_ops_tbls.phone_interaction_eoc  
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.phone_interaction_eoc.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply merged master id updates to static records that have been loaded in the PG phone interaction eoc table (mktg_ops_tbls.phone_interaction_pg_eoc) table */
		UPDATE mktg_ops_tbls.phone_interaction_pg_eoc  
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE mktg_ops_tbls.phone_interaction_pg_eoc.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the phone sustainer upgrade table (phone_interaction_sustnr_upgr).*/
		UPDATE mktg_ops_tbls.phone_interaction_sustnr_upgr 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE  mktg_ops_tbls.phone_interaction_sustnr_upgr.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;

		/* Apply master id update the the dm_campaign_pg_hist table.  */
		UPDATE mktg_ops_tbls.dm_campaign_pg_hist 
		SET cnst_mstr_id = cnst_mstr_id_map.new_cnst_mstr_id
		from mktg_ops_vws.cnst_mstr_id_map
		WHERE  mktg_ops_tbls.dm_campaign_pg_hist.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;



		
		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records updated.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = total_updated
			WHERE proc_name = 'ld_updt_cnst_mstr_id_updates' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
	    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('ld_updt_cnst_mstr_id_updates', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
