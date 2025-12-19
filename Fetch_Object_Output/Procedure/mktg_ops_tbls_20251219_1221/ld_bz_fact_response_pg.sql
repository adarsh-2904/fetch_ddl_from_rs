CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_fact_response_pg()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 2015-01-124
Purpose: This macro populates legacy ARC Planned Giving (PG) constituent communication response records into
				the bz_fact_response_pg table.  The Marketing Business Intelligence team will continue to 
				load PG response data returned from BKV, the PG direct mail fullfillment vendor, and
				from email response data.  A view for the table can be found in the mktg_ops_vws 
				database and will be included in the Campaign Effectiveness Webi universe for reporting

Modified by: Michael Andrien
Modified date: 9/30/2015
Purpose:  Replace the bz_arcpg_comnictn_src table join with bz_comnictn_src after PG source codes
				were added to the TA source code table.  Also, added an additional arcpg_comnictn_src_key column to track the
				original ARCPG interaction source key.
Modified by: Michael Andrien
Modified date: 7/1/2016
Purpose:  Added orig_cnst_mstr_id to track the original master id from the legacy PG response row.  Also added logic for the cnst_mstr_id
				to reflect the CDI merged master id.  A supplemental macro will be run daily to update the cnst_mstr_id to ensure it reflects the most
				recent CDI merge value.

Modified by: Michael Andrien
Modified date: 4/24/2017
Purpose: Change the aprimo_wrk_tbls database view references to drms_vws now that our mktg data is on the EDW server.

Modified by: Michael Andrien
Modified date: 09/06/2019
Purpose: Converted view def to reference the GMS ARCPG view rather than DDCOE views

Modified By: Michael Andrien
Modified Date: 04/14/2020
Purpose:	Added logic to include both the src_key and comnictn_src_key so we can use this table in both the DDCOE CE universe and the GSM version of the CE universe.  The GMS universe
references the src_key and joins to mktg_ops_vws.gmpbzal_dim_src and the DDCOE CE universe referencts the mktg_ops_vws.bz_comnictn_src and join on the comnictn_src_key.
------------------------------------------------------------------------------------------------------------------------------------ */
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_fact_response_pg', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN
		-- Truncate staging table
		TRUNCATE TABLE mktg_stage_tbls.bz_fact_response_pg_stg;
	
		-- Insert transformed data
		INSERT INTO mktg_stage_tbls.bz_fact_response_pg_stg
		WITH src_ranked AS (
			SELECT 
				src_key, 
				src_cd,
				ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
			FROM eda.ufds_vws.gmpbzal_dim_src
		),
		filtered_src AS (
			SELECT src_key, src_cd
			FROM src_ranked
			WHERE rn = 1
		)
		SELECT
			a.cnst_mstr_id, 
			CASE WHEN d.cnst_mstr_id IS NULL THEN a.cnst_mstr_id ELSE d.new_cnst_mstr_id END AS orig_cnst_mstr_id,
			0 AS cnst_hsld_id,
			a.cnst_comnictn_key,
			COALESCE(b2.src_key, 0) AS src_key, 
			COALESCE(b3.comnictn_src_key, 0) AS comnictn_src_key, 
			a.src_key AS arcpg_comnictn_src_key,  
			a.comnictn_typ_key,
			a.response_typ_key,
			a.chan_typ_key,
			a.lctn_key AS unit_key,
			a.amt_typ_key,
			COALESCE(c.calendar_key, 0) AS response_dt_key,
			a.nk_tapg_acct_id AS fr_last_ta_acct_id, 
			a.nk_tapg_comnictn_dt AS nk_response_dt,
			a.nk_tapg_comnictn_seq, 
			a.nk_tapg_comnictn_seq_page, 
			a.comnictn_dsc,
			0 AS offer_id,
			0 AS treatment_id,
			0 AS activity_id,
			0 AS segmntn_id,
			0 AS segmnt_id,
			0 AS outbnd_id, 
			0 AS email_id,
			0 AS cell_id,
			b.src_cd AS cell_src_cd, 
			NULL AS cell_subsrc_cd,
			a.nk_tapg_comnictn_dt AS run_dt,
			0 AS run_id,
			COALESCE(CASE WHEN a.amt_typ_key = 1 THEN a.amt END, 0) AS lead_amt,
			COALESCE(CASE WHEN a.amt_typ_key = 2 THEN a.amt END, 0) AS closed_amt,
			CURRENT_DATE AS update_dt,
			a.comnictn_note_txt AS note_txt, 
			a.row_status_cd,
			a.appl_src_cd, 
			a.load_id, 
			a.srcsys_update_ts AS srcsys_trans_ts, 
			a.dw_trans_ts
		FROM eda.ufds_vws.gmpbz_fact_arcpg_cnst_comnictn a
		LEFT JOIN eda.ufds_vws.gmpbz_dim_arcpg_src b ON a.src_key = b.src_key 
		LEFT JOIN filtered_src b2 ON b.src_cd = b2.src_cd
		LEFT JOIN mktg_ops_vws.bz_comnictn_src b3 ON b.src_cd = b3.nk_comnictn_src_cd
		LEFT JOIN eda.dw_common_vws.dim_calendar c ON a.nk_tapg_comnictn_dt = c.calendar_dt
		LEFT JOIN mktg_ops_vws.cnst_mstr_id_map d ON a.cnst_mstr_id = d.cnst_mstr_id
		WHERE a.response_typ_key <> 0;
		
		TRUNCATE TABLE mktg_ops_tbls.bz_fact_response_pg;

		-- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.bz_fact_response_pg
        SELECT * FROM mods_bi.mktg_stage_tbls.bz_fact_response_pg_stg;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bz_fact_response_pg) as INTEGER)
        WHERE proc_name = 'ld_bz_fact_response_pg' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bz_fact_response_pg: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bz_fact_response_pg', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
