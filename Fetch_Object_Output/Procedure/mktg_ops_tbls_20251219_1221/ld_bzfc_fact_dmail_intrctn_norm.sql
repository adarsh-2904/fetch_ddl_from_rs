CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_fact_dmail_intrctn_norm()
 LANGUAGE plpgsql
AS $$
/*
Created By: Michael Andrien
Created Date: 07/09/2019
Purpose: This macro was created to create a normalized version of the bzfc_fact_dmail_interaction table.  The original fact dmail interaciton table contains one row per campaign per person with attributes that reflect the number of times 
		a donor was mailed (mail drops) for a given acquisition campaign.  The original table was useful for reporting distinct donors mailed but did not allow us to built campaign effectiveness reports at the mail drop grain.  The new table allows
		us to measure effectiveness by each mail drop date withing a campaign.  We used the mktg_ops_tbls.ld_bzfc_fact_dmail_interaction macro as a base to build this macro.  For reason, I have included the Creation and Update log history from the macro
		in the header of this macro.
		
Modified By: Michael Andrien
Modified Date: 7/30/2019	
Purpose: Added the where clause below to all the INSERT and DELETE sections to limit the code to run on Saturdays only
where 7 = (select day_of_week  from sys_calendar.calendar where calendar_date = date)

NOTES BELOW THIS LINE ARE FROM THE ORIGINAL FACT DMAIL INTERACTION MACRO - TRACKING LOG FOR THE NORMALIZED VERSION ARE ABOVE
******************************************************************************************************************************************************************************************************
		Created By: Michael Andrien
		Created Date: 5/30/2017
		Purpose: 	This macro combines Abobe direct mail interactions with Espilon Rental Acquisition data stored in mktg_data_tbls.fact_interaction_ff.
						The Epsilon data that we include in the bzfc_fact_dmail_interacton table is saved in the fact interaction ff table with the 'ADBE' source code to distinguish the 
						rental data that is loaded into the fact_interaction_all fact table.

		Modified By: Michael Andrien
		Modified Date: 6/06/2017
		Purpose: Added motivtn_cd from fact_interaction_aprm and fact_interaction_ff 

		Modified By: Michael Andrien
		Modified Date: 7/10/2017
		Purpose: Modified cnst_mstr_id and orig_cnst_mstr_id column mapping.  Added id_map join to the first union query (fact_interaction_aprm) and added case statement for setting cnst_msrt_id value.

		Modified By: Michael Andrien
		Modified Date: 10/19/2017
		Purpose: Modified the logic for the sub-source code output.  I'm now concatenating the segment description to the file code found in the mktg_data_tbls.rr_rqq_rql_file_xref table.

		Modified By: Majeed Mohammad
		Modified Date: 11/24/2017
		Purpose: Added the coalesce statement  in the second union on the column orig_cnst_mstr_id as this column defined as NOT NULL column and is causing the macro to fail *

		Modified By: Michael Andrien
		Modified Date: 01/05/2018
		Purpose:  Added UPDATE Statements.  We forgot to include the update SQL from the fact interaction all macro when we created the fact dmail interaction macro.
						The updates are required to keep the cnst_mstr_id in sync with merged master id activity in CDI.  The static/legacy interaction records need to be updated to reflect merged master activity.

		Modified By: Michael Andrien
		Modified Date: 07/24/2018
		Purpose: Modified the subsrc_cd logic to map the treatmnt_cd to the sub-source code.  This reflects the message variant used in the direct mail and aligns the sub source usage with the email sub source usage.
						Also modified the segmnt_cd logic to map the rpt_cell_src_cd - this reflects the population segment being targeted in the direct mail piece and is based on the RFM metric - recency, model score (rather than frequency) and gift amount range.
						
		Modified By: Majeed Mohammad
		Modified Date: 07/26/2018
		Purpose:  Replaced all the comments from using -- to forward slash * star . This makes it easy in the bteq to replace the code 

		Modified By: Michael Andrien
		Modified Date: 08/17/2018
		Purpose: added logic to the fia join to resolve merged master ids in the aprm table and fact_dmail_interaction tables and to join on the proper new master id.
		LEFT JOIN  
			( 
				select case when d.cnst_mstr_id is not null then d.new_cnst_mstr_id else a.cnst_mstr_id end as cnst_mstr_id, cell_src_cd, max(motivtn_cd), max(finder_number), count(*)
				from mktg_data_tbls.fact_interaction_aprm a
				left join mktg_ops_vws.cnst_mstr_id_map d on a.orig_cnst_mstr_id = d.cnst_mstr_id
				group by 1,2
			) fia (cnst_mstr_id, cell_src_cd, motivtn_cd, finder_number, mail_drop_cnt)  ON (case when id_map.cnst_mstr_id is null then dmi.cnst_mstr_id else id_map.new_cnst_mstr_id end = fia.cnst_mstr_id) AND (dmi.src_cd = fia.cell_src_cd) 

		Modified By: Michael Andrien
		Modified Date: 09/18/2018
		Purpose: Added update statements to ensure the master ids in the fact_dmail_interaction and fact_interaction_aprm tables are properly aligned before 
					joining the tables to insert data into the bzfc_fact_dmail_intrctn_norm table.

		Modified By: Michael Andrien
		Modified Date: 09/24/2018
		Purpose: Added max(chpt_id) to the fia join below and added the dim_unit join to get the unit_key for the chapter id from the fact_interation_aprm table.  We are going the take the chapter code/id, unit key and treatment_id  from the return file, which
						will supercede the nk_ecode, unit_key and treatment details from the original dmail interaction table.  We're making this change because our direct mail vendor sometimes changes the mailing address and associated chapter details from the 
						original file we send to them, which affect the unit and treatment details.
				--------------------------------------------------------------------------------------------------------------------------
				***Added case logic to the attributes below
			case when u.unit_key is not null then u.unit_key else dmi.unit_key end (TITLE 'Chapter/Unit Key' ) as unit_key, 
			case when u.nk_ecode is not null then u.nk_ecode else dmi.nk_ecode end (TITLE 'Chapter Code')  as nk_ecode,
			case when t2.treatmnt_key is not null then t2.treatmnt_key else dmi.treatmnt_key end  (TITLE 'Treatment Key') as treatmnt_key, 
			case when t2.treatmnt_key is not null then t2.nk_treatmnt_id else dmi.nk_treatmnt_id end  (TITLE 'Treatment Id') as nk_treatmnt_id, 
			case 	when t2.treatmnt_cd is not null then t2.treatmnt_cd 
						when t.treatmnt_cd is not null then t.treatmnt_cd 
						else xref.file_cd 
			end  (TITLE 'Sub Source Code') as subsrc_cd,  
				
				*** Added the t2 and u joins and  modified the fia join below
				LEFT JOIN  
					( 
						select case when d.cnst_mstr_id is not null then d.new_cnst_mstr_id else a.cnst_mstr_id end as cnst_mstr_id, cell_src_cd, max(motivtn_cd), max(finder_number), max(chpt_id), count(*)
						from mktg_data_tbls.fact_interaction_aprm a
						left join mktg_ops_vws.cnst_mstr_id_map d on a.orig_cnst_mstr_id = d.cnst_mstr_id
						group by 1,2
					) fia (cnst_mstr_id, cell_src_cd, motivtn_cd, finder_number, chpt_id, mail_drop_cnt)  ON (case when id_map.cnst_mstr_id is null then dmi.cnst_mstr_id else id_map.new_cnst_mstr_id end = fia.cnst_mstr_id) AND (dmi.src_cd = fia.cell_src_cd) 
				LEFT JOIN mktg_ops_vws.bz_dim_unit u on fia.chpt_id = u.nk_ecode
				LEFT JOIN  mktg_ops_vws.bz_dim_treatmnt t2 on fia.treatment_id = t2.nk_treatmnt_id

		Modified By: Michael Andrien
		Modified Date: 12/31/2018
		Purpose: Added logic to the fact_interaction_aprm query section to include 5 drop dates.  Similar logic will be added to the fact_interaction_ff query section after we fully assess the APRM update.

		Modified By: Michael Andrien
		Modified Date: 01/02/2019
		Purpose:  Added the motivation code associated with the mail drop dates added on 12/31/18.

		Modified By: 	Michael Andrien
		Modified Date:	6/21/2019
		Purpose:	Updated the mktg_ops_vws.rr_rqq_rql_file_xref  join attribute from aprm_src_cd/cell_src_cd to src_cd to correspond with the underlying table change.
*************************************************************************************************************************
Start mktg_ops_tbls.ld_bzfc_fact_dmail_intrctn_norm macro update history here:

Modified By:  Majeed Mohammad
Modified Date: 07/16/2019
Purpose:  Replaced the table mktg_data_tbls.stg_fact_interaction_aprm with mktg_stage_tbls.stg_fact_interaction_aprm 

Modified By: 	Michael Andrien
Modified Date:	12/20/2019
Purpose: Updated the macro to run on Fridays versus Saturdays

Modified By: Michael Andrien
Modified Date: 03/25/2020
Purpose: Added the where condition to all the updates to limit the updates to run only on Saterday  ( 6= (select day_of_week  from sys_calendar.calendar where calendar_date = date))

Modified By: Michael Andrien
Modified Date: 04/14/2020
Purpose:	Added logic to include both the src_key and comnictn_src_key so we can use this table in both the DDCOE CE universe and the GSM version of the CE universe.  The GMS universe
references the src_key and joins to mktg_ops_vws.gmpbzal_dim_src and the DDCOE CE universe referencts the mktg_ops_vws.bz_comnictn_src and join on the comnictn_src_key.

Modified By: Michael Andrien
Modified Date: 04/20/2020
Purpose: Added the LEFT JOIN to calculation the first drop_dt to assign to the intrctn_dt.  The original method for setting the interaction date does not work when the first drop does not include the entire campaign population.  The RQQ19110M000 campaign had a test mailing sent
on 10/25/2019 to a test group followed by the full mailing on 11/25.  This led to having 2 interaction dates for the campaign source code.

Modified By: Michael Andrien
Modified Date: 04/24/2020
Purpose:  Added the WHERE clause below to the stg_fact_interaction_aprm INSERT to exclude bad master ids that are causing skewing in the insert.
where fia.cnst_mstr_id not in (25181, 25182, 25611, 50509115, 99999999)

Modified By: Michael Andrien
Modified Date: 04/30/2020
Purpose: Changed the macro to run on Thur nights (day = 5) and added/modified the dd join logic to assign the drop number to each drop date for a source code.

Modified By: Michael Andrien
Modified Date: 01/20/2021
Purpose:  Rearchitected the macro to run separate inserts for the fact_interactiono_aprm and fact_interaction_ff inserts.  Updated the UPDATE SQL for setting the mail drop number to run after each insert
and modified the select and qualify statements for the FF mail drop num update logic.  Updated the mktg_stage_tbls.stg_fact_interaction_aprm table definition to remove unuses attributes.  This was done to optimize spool allocation
Added the mktg_stage_tbls.stg_bzfc_fact_dmail_intrctn_norm table and now insert into this table in the first insert step without the qualify statement to remove dupes - then select from the stage table and insert into the target
bzfc_fact_dmail_intrctn_norm table with the qualify statement to remove dupes.  Again, this was done to optimize spool allocatio requirements.
Added the delete statement below to free up staging table space after the table has been loaded.
	DELETE FROM mktg_stage_tbls.stg_bzfc_fact_dmail_intrctn_norm where 5 = (select day_of_week  from sys_calendar.calendar where calendar_date = date);

Modified By: Michael Andrien
Modified Date: 01/22/2021
Purpose: Added the WHERE clause below the the Adobe Interaction insert query (first insert query) to exclude dmail interactions associated with Adobe deliveries that have been mark with the 'Exclude From Reporting' attribute.
	WHERE dlv.exclude_rptng_ind = 0;  

Modified By: Michael Andrien
Modified Date: 01/25/2021
Purpose:  Updated the code to ensure the date constraint logic to limited the UPDATES, INSERTS and SELECTs to run on the Thursay - the 5th day of the week.  We noticed the logic was missing from some code segments.

Modified By: Michael Andrien
Modified Date: 07/03/2021
Purpose: Added target_tag_scr, vigintile and mods_fr_scr attributes to the table.

Modified By: Michael Andrien
Modified Date: 08/28/2022
Purpose: Teamwork ticket #8823167 - Added dm_locator_addr_key to the partition statement in the insert statement below.  Also added dm_locator_addr_key to the Mail Drop update section.  
This update was required to address the recent changes in our rental match back process for Acquisition campaigns.  Super Dupe rental records get remapped by O&A to our RQL, RQP and RQD segments 
so we now have instances where the orig_cnst_mstr_id is mailed at two different mailing addresses.  The remapped super dupe rental record contains a mailing address that differs from the address in our
preferred profile so we mail them at both location and reclassify the rental records and a super dupe house record.

	insert into mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
	select *
	from  mktg_stage_tbls.stg_bzfc_fact_dmail_intrctn_norm
	qualify row_number() over (partition by  orig_cnst_mstr_id, dm_locator_addr_key, src_cd, intrctn_dt order by intrctn_dt) = 1;


Modified By: Michael Andrien
Modified Date: 10/21/2022
Purpose: Teamwork Ticket #9223522 altered the qualify logic added the join the table 'i' to assign the most recent source key for the campaign source code.  Also, added the where clause to
exclude deliveries where the 'exclude from reporting' indicator is set to 1.


Modified By: Majeed Mohammad
Modified Date: 11/02/2022
Purpose:  Updated the incorrect day to run from 6 to 5 in this portion of the SQL - > DELETE FROM mktg_stage_tbls.stg_fact_interaction_aprm

Modified By: Majeed Mohammad
Modified Date: 06/17/2025
Purpose:  Removed the filter in all the SQLs to run only on Thursday 
*/
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_bzfc_fact_dmail_intrctn_norm', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN
		UPDATE mktg_ops_tbls.fact_interaction_aprm AS fact_interaction_aprm
SET cnst_mstr_id = b.primary_cnst_mstr_id
FROM (
    SELECT cnst_mstr_id, primary_cnst_mstr_id, nk_ta_acct_id
    FROM (
        SELECT 
            cnst_mstr_id, 
            primary_cnst_mstr_id, 
            nk_ta_acct_id,
            ROW_NUMBER() OVER (
                PARTITION BY cnst_mstr_id, nk_ta_acct_id 
                ORDER BY nk_ta_nm_id ASC
            ) AS rn
        FROM mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary
    ) AS subqry
    WHERE rn = 1
) b
WHERE fact_interaction_aprm.cnst_mstr_id = b.cnst_mstr_id
  AND fact_interaction_aprm.fr_last_ta_acct_id = b.nk_ta_acct_id
  AND b.cnst_mstr_id <> b.primary_cnst_mstr_id;

UPDATE mktg_ops_tbls.fact_dmail_interaction as fact_dmail_interaction
SET cnst_mstr_id = b.primary_cnst_mstr_id
FROM  
            (select cnst_mstr_id, primary_cnst_mstr_id, nk_ta_acct_id
            	from (
            		SELECT  cnst_mstr_id, primary_cnst_mstr_id, nk_ta_acct_id,ROW_NUMBER() OVER ( PARTITION BY cnst_mstr_id, nk_ta_acct_id ORDER BY  nk_ta_nm_id ASC) as rn
					FROM  mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary
            	) as subqry
			 where subqry.rn=1) b 

WHERE  fact_dmail_interaction.cnst_mstr_id =  b.cnst_mstr_id 
and b.cnst_mstr_id <> b.primary_cnst_mstr_id 
and fact_dmail_interaction.fr_last_ta_acct_id =  b.nk_ta_acct_id; 


truncate table mktg_stage_tbls.stg_fact_interaction_aprm;




 INSERT INTO  mktg_stage_tbls.stg_fact_interaction_aprm
SELECT	
				cnst_mstr_id, 
				orig_cnst_mstr_id,
				fia.cell_src_cd as src_cd, 
				fia.cell_subsrc_cd,
				motivtn_cd, 
				finder_number, 
				chpt_id, 
				treatment_id,
				drop_dt,
				file_cd,
				target_tag_scr, 
				vigintile, 
				mods_fr_scr
/*
	cnst_mstr_id, orig_cnst_mstr_id, cnst_hsld_id, finder_number,
	fia.cell_src_cd, cell_subsrc_cd, motivtn_cd, fr_last_ta_acct_id,
	offer_id, treatment_id, activity_id, segementation_id, segment_id,
	fia.segmnt_dsc, outbnd_id, email_id, email_sent_dt, to_domain, drop_dt,
	update_dt, last_dntn_dt, last_dntn_amt, chpt_affl, submitter_nm,
	chpt_id, cntct_dt, run_dt, run_id, mailed_ind, supressed_ind,
	call_ind, call_result, do_not_call_ind, null as file_cd,
	row_stat_cd, appl_src_cd,load_id, dw_trans_ts
*/
FROM mktg_ops_tbls.fact_interaction_aprm fia
 LEFT JOIN 
(
	SELECT 
		DISTINCT src_cd, 
		segmnt_cd, 
		segmnt_dsc,
		file_cd
	FROM  mktg_ops_tbls.rr_rqq_rql_file_xref
) xref (cell_src_cd, segmnt_cd, segmnt_dsc, file_cd) on fia.cell_src_cd = xref.cell_src_cd and substring(fia.motivtn_cd, 10, 3) = xref.segmnt_cd 
where fia.cnst_mstr_id not in (25181, 25182, 25611, 50509115, 99999999)  and appl_src_cd in ('ADBE', 'ENGR');


 /* Apply master id merge updates to the stage table */
 UPDATE mktg_stage_tbls.stg_fact_interaction_aprm
SET cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.new_cnst_mstr_id
from mktg_ops_vws.cnst_mstr_id_map
WHERE mktg_stage_tbls.stg_fact_interaction_aprm.cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id;


/* Truncate the normalized Fact Interaction table before loading the new data */
truncate table mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm;


/* Now insert the new rows */
INSERT INTO mktg_stage_tbls.stg_bzfc_fact_dmail_intrctn_norm
SELECT	
	--case when id_map.new_cnst_mstr_id is null then dmi.cnst_mstr_id else id_map.new_cnst_mstr_id end (TITLE 'Constituent Master Identifier') as cnst_mstr_id,\
	dmi.cnst_mstr_id ,
	dmi.orig_cnst_mstr_id ,
	recipient_key , 
	nk_recipient_id,
	recipient_zip_cd, 
	cnst_hsld_id, 
	nk_intrctn_id, 
	dmi.delivery_key,
	dmi.nk_delivery_id, 
	campaign_key, 
	nk_operation_id , 
	COALESCE(i.src_key,0)  as src_key,
	src.comnictn_src_key  as comnictn_src_key, 	
	comnictn_typ_key ,
	chan_typ_key  as channel_key, 
	chan_typ_dsc  as channel_dsc, 
	case when u.unit_key is not null then u.unit_key else dmi.unit_key end  as unit_key, 
	case when u.nk_ecode is not null then u.nk_ecode else dmi.nk_ecode end   as nk_ecode,
	intrctn_status_key , 
	nk_intrctn_status_dsc , 
	case when t2.treatmnt_key is not null then t2.treatmnt_key else dmi.treatmnt_key end   as treatmnt_key, /* Use the return file treatment key before the key from our original interation file */
	case when t2.treatmnt_key is not null then t2.nk_treatmnt_id else dmi.nk_treatmnt_id end   as nk_treatmnt_id, /* Use the return file nk_treatmnt_id before the nk_treatmnt_id from our original interation file */
	dmi.src_cd , 
	case 	--when t2.treatmnt_cd is not null then t2.treatmnt_cd 
				when t.treatmnt_cd is not null then t.treatmnt_cd 
				else file_cd 
	end   as subsrc_cd,   /*  This is synonymous with treatment for direct mail - the messag variant for the mailing - treatment code should be mapped here. */
	 /* case when rc.rpt_cell_cd is null then xref.file_cd || '_' || trim(xref.segmnt_dsc) else rc.rpt_cell_cd end (TITLE 'Sub-Source Code') as subsrc_cd,  7/24/2018 - MTA Commented out this line  */
	file_cd  as file_cd,
	case when fia.motivtn_cd is not null then fia.motivtn_cd else dmi.src_cd end  as motivtn_cd,
	rpt_cell_cd_key ,   /*  NOTE: I mapped the reportcell_code_id col from dmail interaction to the rpt_cell_cd_key because the value are the same.  */
	reportcell_code_id  as rpt_cell_cd_id,
	dc.calendar_key  as intrctn_dt_key, 
	fia.drop_dt  as intrctn_dt, 
	list_run_dt_key , 
	list_run_dt , 
	rc.rpt_cell_cd_key  as segmnt_key,
	case when rc.rpt_cell_cd is not null then rc.rpt_cell_cd else dmi.nk_segmnt_cd end   as nk_segmnt_cd,  /*  report cell code and segment code are synonymous - MODS team prefers report cell code */
	gen_segmnt_key , 
	fr_last_ta_acct_id , 
	offer_key ,
	NULL   as dm_locator_prsn_nm_key,
	dm_locator_addr_key   as dm_locator_addr_key,
	case when fia.cnst_mstr_id is null then 0 else 1 end  as mailed_ind,
	case when fia.cnst_mstr_id is null then 1 else 0 end as supressed_ind,
	 fia.finder_number, /*Select the finder_number. This is needed in the RR extracts */
	dd.drop_num  as mail_drop_num,
	last_dntn_dt ,
	last_dntn_amt , 
	dm_intrctn_ind , 
	fia.target_tag_scr, 
	fia.vigintile, 
	fia.mods_fr_scr,
	dmi.srcsys_trans_ts , 
	dmi.dw_trans_ts ,
	dmi.row_stat_cd , 
	dmi.appl_src_cd , 
	dmi.load_id
FROM	mktg_ops_tbls.fact_dmail_interaction dmi
LEFT JOIN mktg_ops_vws.bz_dim_delivery dlv on dmi.delivery_key = dlv.delivery_key
--LEFT JOIN mktg_ops_vws.cnst_mstr_id_map id_map on dmi.cnst_mstr_id = id_map.cnst_mstr_id
LEFT JOIN  
	( 
  select 
				cnst_mstr_id, 
				orig_cnst_mstr_id,
				cell_src_cd as src_cd, 
				motivtn_cd, 
				finder_number, 
				chpt_id, 
				treatment_id,
				drop_dt,
				file_cd,
				target_tag_scr, 
				vigintile, 
				mods_fr_scr
		from mktg_stage_tbls.stg_fact_interaction_aprm a
) fia (cnst_mstr_id, orig_cnst_mstr_id, src_cd, motivtn_cd, finder_number, chpt_id, nk_treatmnt_id,  drop_dt, file_cd, target_tag_scr, vigintile, mods_fr_scr) 
	--	ON (case when id_map.cnst_mstr_id is null then dmi.cnst_mstr_id else id_map.new_cnst_mstr_id end = fia.cnst_mstr_id) AND (dmi.src_cd = fia.src_cd) 
		ON (dmi.orig_cnst_mstr_id  = fia.orig_cnst_mstr_id) AND (dmi.src_cd = fia.src_cd) 
		--	ON (dmi.cnst_mstr_id  = fia.cnst_mstr_id) AND (dmi.src_cd = fia.src_cd) 
LEFT JOIN mktg_ops_vws.bz_dim_unit u on fia.chpt_id = u.nk_ecode and u.unit_typ_cd = 'C'
LEFT JOIN mktg_ops_vws.bz_dim_rpt_cell_cd rc on dmi.reportcell_code_id = rc.rpt_cell_cd_id
LEFT JOIN mktg_ops_vws.bz_dim_treatmnt t on dmi.treatmnt_key = t.treatmnt_key
LEFT JOIN  mktg_ops_vws.bz_dim_treatmnt t2 on fia.nk_treatmnt_id = t2.nk_treatmnt_id
LEFT JOIN eda.dw_common_vws.dim_calendar dc on fia.drop_dt = dc.calendar_dt
LEFT JOIN mktg_ops_vws.bz_comnictn_src src on dmi.src_cd = src.nk_comnictn_src_cd
LEFT JOIN 
(
	select 
		cell_src_cd,
		drop_dt,
		row_number() over (partition by cell_src_cd order by drop_dt) as drop_num
	from 
	(
		SELECT cell_src_cd, drop_dt, count(*) 
		FROM mktg_stage_tbls.stg_fact_interaction_aprm --mktg_data_tbls.fact_interaction_aprm
		WHERE substring(cell_src_cd,1,3) in ('RQQ', 'RQL', 'RQD', 'RQP')
		group by 1,2
	) a (cell_src_cd, drop_dt, drop_num)
) dd (cell_src_cd, drop_dt, drop_num) on dd.cell_src_cd = fia.src_cd and dd.drop_dt = fia.drop_dt
LEFT JOIN eda.dw_common_vws.dim_calendar cal on dd.drop_dt = cal.calendar_dt
LEFT JOIN 
(
	select  src_key ,  src_cd 
	from (
		    SELECT  src_key , src_cd, ROW_NUMBER() OVER ( PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) as rn
	        FROM mktg_ops_vws.gmpbzal_dim_src
	) as subqry
where subqry.rn=1
) i (src_key, src_cd) 
on dlv.src_cd = i.src_cd
WHERE dlv.exclude_rptng_ind = 0;

/*
Now move the data from the staging table to the normalized table and remove duplicate record.  We had to take these interim steps to avoid spool error during the load process.
*/
insert into mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
select cnst_mstr_id, orig_cnst_mstr_id, recipient_key, nk_recipient_id, recipient_zip_cd, cnst_hsld_id, nk_intrctn_id, delivery_key, nk_delivery_id, campaign_key, nk_operation_id, src_key, comnictn_src_key, comnictn_typ_key, chan_typ_key, chan_typ_dsc, unit_key, nk_ecode, intrctn_status_key, nk_intrctn_status_dsc, treatmnt_key, nk_treatmnt_id, src_cd, subsrc_cd, file_cd, motivtn_cd, rpt_cell_cd_key, rpt_cell_cd_id, intrctn_dt_key, intrctn_dt, list_run_dt_key, list_run_dt, segmnt_key, nk_segmnt_cd, gen_segmnt_key, fr_last_ta_acct_id, offer_key, dm_locator_prsn_nm_key, dm_locator_addr_key, mailed_ind, supressed_ind, finder_num, mail_drop_num, last_dntn_dt, last_dntn_amt, dm_intrctn_ind, target_tag_scr, vigintile, mods_fr_scr, srcsys_trans_ts, dw_trans_ts, row_stat_cd, appl_src_cd, load_id

		from(
			select *, row_number() over (partition by  orig_cnst_mstr_id, dm_locator_addr_key, src_cd, intrctn_dt order by intrctn_dt, src_key desc) as rn
			from  mktg_stage_tbls.stg_bzfc_fact_dmail_intrctn_norm
		) as subqry
	where subqry.rn=1;

/* Now apply updates to set the mail drop num for the records loaded from the mktg_data_tbls.fact_interaction_aprm table */

UPDATE mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
set mail_drop_num = a.mail_drop_num
from
(
select
orig_cnst_mstr_id, 
src_cd,
intrctn_dt,
dm_locator_addr_key,
ROW_NUMBER() OVER (PARTITION BY  orig_cnst_mstr_id, dm_locator_addr_key, src_cd ORDER BY intrctn_dt)  as mail_drop_num
from mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
) a (orig_cnst_mstr_id, src_cd, intrctn_dt, dm_locator_addr_key, mail_drop_num)

where a.orig_cnst_mstr_id = mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.orig_cnst_mstr_id 
			and a.src_cd = mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.src_cd
			and a.intrctn_dt = mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.intrctn_dt
			and a.dm_locator_addr_key = mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.dm_locator_addr_key
			and  mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.mail_drop_num is null;


/*
Now insert and dedupe the Finder File interaction directly into the mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm  this data set is small enough to run the insert directly to the table without getting spool errors.
*/			
INSERT INTO mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm

select cnst_mstr_id,
			orig_cnst_mstr_id, /*Majeed: 11/24/2017: Added the coalesce statement as this is defined as NOT NULL column and is causing the macro to fail */
			recipient_key , 
			nk_recipient_id ,
		    recipient_zip_cd , 
			cnst_hsld_id, 
			nk_intrctn_id, 
			delivery_key ,
			nk_delivery_id , 
			campaign_key , 
			nk_operation_id , 
			src_key,
			comnictn_src_key,
			comnictn_typ_key,
			channel_key,
			channel_dsc, 
			unit_key  , 
			nk_ecode ,
			intrctn_status_key, 
			nk_intrctn_status_dsc, 
			treatmnt_key,
			nk_treatmnt_id,
			src_cd , 
			subsrc_cd ,
			file_cd ,
			motivtn_cd,
			rpt_cell_cd_key,
			rpt_cell_cd_id,
			intrctn_dt_key, 
			intrctn_dt, 
			list_run_dt_key, 
			list_run_dt, 
			segmnt_key,
			nk_segmnt_cd, 
			gen_segmnt_key, 
			fr_last_ta_acct_id , 
			offer_key,
			dm_locator_prsn_nm_key,
			dm_locator_addr_key,
			mailed_ind,
			supressed_ind,
			finder_number, /*Select the finder_number. This is needed in the RR extracts */
			mail_drop_num,
			last_dntn_dt ,
			last_dntn_amt , 
			dm_intrctn_ind, 
			target_tag_scr,
			vigintile,
			mods_fr_scr,
			srcsys_trans_ts, 
			dw_trans_ts ,
			row_stat_cd , 
			appl_src_cd , 
			load_id

from (
		SELECT	
			case when d.new_cnst_mstr_id is null then a.cnst_mstr_id else d.new_cnst_mstr_id end  as cnst_mstr_id,
			coalesce(a.orig_cnst_mstr_id,a.cnst_mstr_id)   as orig_cnst_mstr_id, /*Majeed: 11/24/2017: Added the coalesce statement as this is defined as NOT NULL column and is causing the macro to fail */
			cast(0 as INTEGER)  as recipient_key , 
			cast(0 as INTEGER)  as nk_recipient_id ,
			cast(NULL as CHAR(5))as recipient_zip_cd , 
			cast(cnst_hsld_id as VARCHAR(18))   as cnst_hsld_id, 
			cast(0 as INTEGER)  as nk_intrctn_id, 
			cast(0 as INTEGER)  as delivery_key ,
			cast(0 as INTEGER)  as nk_delivery_id , 
			cast(0 as INTEGER)  as campaign_key , 
			cast(0 as INTEGER)  as nk_operation_id , 
			coalesce(i.src_key,0)  as src_key,
			coalesce(c.comnictn_src_key,0)  as comnictn_src_key,
			cast (0 as BIGINT)  as comnictn_typ_key,
			cast(4 as INTEGER)   as channel_key,
			cast('Direct Mail' as VARCHAR(100))   as channel_dsc, 
			unit_key  , 
			nk_ecode ,
			cast(0 as INTEGER) as intrctn_status_key, 
			cast(NULL as varchar(200))  as nk_intrctn_status_dsc, 
			cast(0 as INTEGER)  as treatmnt_key,
			treatment_id   as nk_treatmnt_id,
			a.cell_src_cd  as src_cd , 
			h.file_cd || '_' || trim(h.segmnt_dsc)  as subsrc_cd ,
			h.file_cd ,
			case when a.motivtn_cd is not null then a.motivtn_cd else src_cd end  as motivtn_cd,
			cast(0 as INTEGER)  as rpt_cell_cd_key,
			cast(0 as INTEGER)   as rpt_cell_cd_id,
			e.calendar_key   as intrctn_dt_key, 
			a.drop_dt  as intrctn_dt, 
			f.calendar_key as  list_run_dt_key, 
			run_dt  as list_run_dt, 
			cast(0 as INTEGER)  as segmnt_key,
			h.file_cd || '_' || trim(h.segmnt_dsc)   as nk_segmnt_cd, 
			cast(0 as INTEGER)  gen_segmnt_key, 
			fr_last_ta_acct_id , 
			cast(0 as INTEGER)   offer_key,
			cast(NULL as INTEGER)  as dm_locator_prsn_nm_key,
			cast(NULL as INTEGER)  as dm_locator_addr_key,
			case when a.cnst_mstr_id is null then 0 else 1 end  as mailed_ind,
			case when a.cnst_mstr_id is null then 1 else 0 end as supressed_ind,
			 a.finder_number, /*Select the finder_number. This is needed in the RR extracts */
			dd.drop_num as mail_drop_num,
			a.last_dntn_dt ,
			a.last_dntn_amt , 
			cast(1 as SMALLINT)   as dm_intrctn_ind, 
			NULL as target_tag_scr,
			0 as vigintile,
			NULL as mods_fr_scr,
			cast(a.drop_dt as TIMESTAMP)  as srcsys_trans_ts, 
			a.dw_trans_ts ,
			a.row_stat_cd , 
			a.appl_src_cd , 
			a.load_id,
		ROW_NUMBER() OVER (PARTITION BY  a.finder_number, a.cell_src_cd, a.drop_dt ORDER BY a.drop_dt) as rn
		FROM mktg_ops_tbls.fact_interaction_ff a  /*  Chapter Finder File interactions from Russ Reid */
		LEFT JOIN mktg_ops_vws.dim_unit b on a.chpt_id = b.nk_ecode and b.unit_typ_cd = 'C'
		LEFT JOIN mktg_ops_vws.bz_comnictn_src c on a.cell_src_cd = c.nk_comnictn_src_cd
		LEFT JOIN mktg_ops_vws.cnst_mstr_id_map d on a.cnst_mstr_id = d.cnst_mstr_id
		LEFT JOIN eda.dw_common_vws.dim_calendar f on a.run_dt = f.calendar_dt  /*  list run date join  */
		LEFT JOIN 
		(
			select finder_number, cell_src_cd, max(motivtn_cd), count(*) as mail_drop_cnt
			from mktg_ops_tbls.fact_interaction_ff
			WHERE appl_src_cd = 'ADBE'
			group by 1,2
		) g (finder_number, cell_src_cd, motivtn_cd, mail_drop_cnt) on a.finder_number = g.finder_number and a.cell_src_cd = g.cell_src_cd
		
		LEFT JOIN 
		(
			SELECT 
				DISTINCT src_cd, 
				segmnt_cd, 
				segmnt_dsc,
				file_cd
			FROM  mktg_ops_tbls.rr_rqq_rql_file_xref
		) h (cell_src_cd, segmnt_cd,segmnt_dsc, file_cd) on g.cell_src_cd = h.cell_src_cd and substring(g.motivtn_cd, 10, 3) = h.segmnt_cd
		LEFT JOIN 
		(
			select  src_key,  src_cd
			from (
					SELECT src_key,src_cd, ROW_NUMBER() OVER ( PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) as rn
						FROM mktg_ops_vws.gmpbzal_dim_src
			) as subqry
			
			where subqry.rn=1
		) i (src_key, src_cd) on a.cell_src_cd = i.src_cd
		/*
		LEFT JOIN 
		(
			SELECT cell_src_cd, min(drop_dt)
			FROM mktg_data_tbls.fact_interaction_ff
			group by 1
		) dd (cell_src_cd, drop_dt) on dd.cell_src_cd = a.cell_src_cd
		*/
		LEFT JOIN 
		(
			select 
				cell_src_cd,
				drop_dt,
				row_number() over (partition by cell_src_cd order by drop_dt) as drop_num
			from 
			(
				SELECT cell_src_cd, drop_dt, count(*) 
				FROM mktg_ops_tbls.fact_interaction_ff
				WHERE substring(cell_src_cd,1,3) in ('RQQ', 'RQL', 'RQD', 'RQP')
				group by 1,2
			) a (cell_src_cd, drop_dt, drop_num)
		) dd (cell_src_cd, drop_dt, drop_num) on dd.cell_src_cd = a.cell_src_cd and dd.drop_dt = a.drop_dt
		LEFT JOIN eda.dw_common_vws.dim_calendar e on a.drop_dt = e.calendar_dt  /*  interaction date join */
		WHERE a.appl_src_cd = 'ADBE'  

) as subqry

where subqry.rn = 1;




/* and 5 = (select day_of_week  from sys_calendar.calendar where calendar_date = date) */ 





/* Now apply updates to set the mail drop num for the records loaded from the mktg_data_tbls.fact_interaction_ff table */
UPDATE mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
set mail_drop_num = a.mail_drop_num
from
(
select
finder_num, 
src_cd,
intrctn_dt,
dm_locator_addr_key,
ROW_NUMBER() OVER (PARTITION BY  finder_num, src_cd ORDER BY intrctn_dt)  as mail_drop_num
from mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
where finder_num is not null
) a (finder_num, src_cd, intrctn_dt, dm_locator_addr_key, mail_drop_num)

where a.finder_num is not null
			and a.finder_num = mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.finder_num 
			and a.src_cd = mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.src_cd
			and a.intrctn_dt = mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.intrctn_dt
			and a.dm_locator_addr_key = mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.dm_locator_addr_key
			and  mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.mail_drop_num is null;
			
			

/* Apply primary_cnst_mstr_id updates - this set the primary master id for accounts that have more than one CDI master id */
UPDATE mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
SET cnst_mstr_id = b.primary_cnst_mstr_id
FROM  
            (
            
            select cnst_mstr_id, primary_cnst_mstr_id, nk_ta_acct_id 
            
            from (
					SELECT  cnst_mstr_id, primary_cnst_mstr_id, nk_ta_acct_id,row_number() OVER (PARTITION BY cnst_mstr_id, nk_ta_acct_id ORDER BY  nk_ta_nm_id ASC) as rn
					FROM  mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary            
            ) as subqry 
            where subqry.rn=1) b (cnst_mstr_id, primary_cnst_mstr_id, nk_ta_acct_id) 

WHERE   mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.cnst_mstr_id =  b.cnst_mstr_id and b.cnst_mstr_id <> b.primary_cnst_mstr_id and mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.fr_last_ta_acct_id =  b.nk_ta_acct_id;			

/* and 5 = (select day_of_week  from sys_calendar.calendar where calendar_date = date) */ 

/*  Added 1/19/2916 by Mike Andrien
Apply cnst_mstr_id and primary_cnst_mstr_id updates for acquisition interactions for which donations have been made and the finder number (Acquistion ID) is found in the FSA acquisition table
*/

UPDATE mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
SET 
	orig_cnst_mstr_id = b.cnst_mstr_id,
	cnst_mstr_id = b.primary_cnst_mstr_id
FROM  
            ( select subqry.acqstn_id, subqry.cnst_mstr_id, subqry.primary_cnst_mstr_id, subqry.nk_ta_acct_id, subqry.nk_ta_nm_id 
            
            	from (
            			select b.acqstn_id, c.cnst_mstr_id, c.primary_cnst_mstr_id, c.nk_ta_acct_id, c.nk_ta_nm_id,ROW_NUMBER() OVER ( PARTITION BY b.acqstn_id ORDER BY c.nk_ta_acct_id DESC, c.nk_ta_nm_id ASC) as rn
							from mktg_ops_vws.bz_cnst_fsa_acqstn b
							left join mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary c on b.cnst_fsa_key = c.bzd_acct_fsa_key and b.nk_ta_acct_id = c.nk_ta_acct_id
            	)  as subqry
            
            where subqry.rn =1
            
			) b (acqstn_id, cnst_mstr_id, primary_cnst_mstr_id, nk_ta_acct_id, nk_ta_nm_id) 

WHERE   
	mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.finder_num =  b.acqstn_id and mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.cnst_mstr_id >= 1000000000 
	and b.cnst_mstr_id is not null 
	and b.primary_cnst_mstr_id is not null;

	/* and 5 = (select day_of_week  from sys_calendar.calendar where calendar_date = date) */ 
	
/*  Added 1/26/2016 by Mike Andrien
Apply primary_cnst_mstr_id updates for interactions with finder numbers where the primary_cnst_mstr_id in the interaction does not match the primary_cnst_mstr_id 
in the bzl_cnst_fsa_acqstn table.  Use the finder number in the interaction table to join to the acqstn_id in the blz acquisition link table.  We found instances where the master id
we interacted with does not align with the master id that gets assigned when we link the gift from Team Approach to the CDI bzl_cnst_fsa table to assign the master id to the gift transaction.
*/	
	
UPDATE mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm
SET cnst_mstr_id = b.acqstn_primary_cnst_mstr_id 
FROM 
(
/*02-22-2017: Majeeed (Copied from Bteq script ) . Added the distinct to avoid the error - Failure 7547 Target row updated by multiple source rows. */
	select distinct a.finder_num, a.cnst_mstr_id, a.orig_cnst_mstr_id, b.acqstn_id, b.nk_ta_acct_id, b.acct_fsa_key, b.acq_cnst_mstr_id, b.acq_primary_cnst_mstr_id
	 from mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm a
	    join 
	    (select acqstn_id, nk_ta_acct_id, acct_fsa_key, cnst_mstr_id as acq_cnst_mstr_id, primary_cnst_mstr_id as acq_primary_cnst_mstr_id, intrctn_primary_cnst_mstr_id
	    from mktg_ops_vws.bzl_cnst_fsa_acqstn
	    where primary_cnst_mstr_id <> intrctn_primary_cnst_mstr_id
	    and intrctn_primary_cnst_mstr_id is not null) b (acqstn_id, nk_ta_acct_id, acct_fsa_key, acq_cnst_mstr_id, acq_primary_cnst_mstr_id, intrctn_primary_cnst_mstr_id) on a.finder_num = b.acqstn_id
	    where a.finder_num is not null and a.finder_num <>'0'
) b (finder_num, intrctn_cnst_mstr_id, intrctn_primary_cnst_mstr_id, acqstn_id, nk_ta_acct_id, acct_fsa_key, acqstn_cnst_mstr_id,acqstn_primary_cnst_mstr_id)
   
WHERE  mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.finder_num =  b.acqstn_id and mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.finder_num <> '0' 
					and mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.cnst_mstr_id <> b.acqstn_primary_cnst_mstr_id
					and mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm.cnst_mstr_id = b.intrctn_cnst_mstr_id;
					

/* Truncate the staging table to free space for next load process */					
truncate table mktg_stage_tbls.stg_fact_interaction_aprm;
truncate table mktg_stage_tbls.stg_bzfc_fact_dmail_intrctn_norm;


		---audit_log update------
        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE mods_bi.etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bzfc_fact_dmail_intrctn_norm) as INTEGER)
        WHERE proc_name = 'ld_bzfc_fact_dmail_intrctn_norm' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bzfc_fact_dmail_intrctn_norm: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bzfc_fact_dmail_intrctn_norm', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
