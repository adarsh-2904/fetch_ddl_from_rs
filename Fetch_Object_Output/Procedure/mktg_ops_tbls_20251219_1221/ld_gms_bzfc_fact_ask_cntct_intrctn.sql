CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_bzfc_fact_ask_cntct_intrctn()
 LANGUAGE plpgsql
AS $$
/*
Created By: 	Michael Andrien
Create Date:	06/18/2024
Purpose:		Converted the SQL from the original view definition (mktg_ops_vws.gms_bzfc_fact_ask_cntct_intrctn) and created this macro to load a physical table because the view was performing poorly.
The macro SQL links the GMS Fact Ask view (gms_bzfc_fact_ask) to Mktg email and dmail interactions to associate the email subsource
and dmail treatment codes to a Planned Giving ask.  The SQL links the SalesForce (SF) Ask, which is at a SF account grain to the SF account to contact bridge 
table to associate the account ask to each account contact then joins the ask to the interaction views based on the CDI master id associated with each contact.
We created a separate view for this since we are changing the ask view grain from the account down to the contact.  As predicted the original view was too slow due to the interaction joins.
We've created this macro to load a physical table then repointed the view to the table to address performance concerns regarding the PG reports produced by the MODS team.
*/	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_bzfc_fact_ask_cntct_intrctn', 'Stored Procedure', 'Inprogress', v_start_time);

TRUNCATE TABLE mktg_ops_tbls.gms_bzfc_fact_ask_cntct_intrctn;

INSERT INTO mktg_ops_tbls.gms_bzfc_fact_ask_cntct_intrctn
WITH ranked_data AS (
    SELECT
        ask.ask_id,
        ask.ask_src_cd,
        brdg.frf_acct_id,
        brdg.frf_cntct_id,
        brdg.cnst_mstr_id,
        COALESCE(dmtr.treatmnt_cd, aptr.treatmnt_cd) AS treatmnt_cd,
        COALESCE(dmtr.treatmnt_dsc, aptr.treatmnt_dsc) AS treatmnt_dsc,
        COALESCE(dmdlv.delivery_nm, emdlv.delivery_nm) AS delivery_nm,
        COALESCE(dmdlv.delivery_label, emdlv.delivery_label) AS delivery_label,
        CASE
            WHEN emi.subsrc_cd IS NOT NULL THEN emi.subsrc_cd
            WHEN fia.em_interaction_ind = 1 THEN fia.cell_subsrc_cd
            ELSE NULL
        END AS subsrc_cd,
        CURRENT_TIMESTAMP AS dw_trans_ts,
        ROW_NUMBER() OVER (
            PARTITION BY ask.ask_id
            ORDER BY
                CASE WHEN COALESCE(dmi.delivery_key, emi.delivery_key) IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN COALESCE(dmi.treatmnt_key, fia.treatment_id) IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN COALESCE(emi.subsrc_cd, fia.cell_subsrc_cd) IS NOT NULL THEN 1 ELSE 0 END DESC,
                brdg.cnst_mstr_id
        ) AS rn
    FROM mktg_ops_vws.gms_bzfc_fact_ask ask
    LEFT JOIN mktg_ops_vws.gms_sf_acct_contct_brdg brdg 
        ON ask.ask_acct_key = brdg.sf_acct_key
    LEFT JOIN mktg_ops_vws.bzfc_fact_dmail_interaction dmi 
        ON ask.ask_src_key = dmi.src_key 
        AND brdg.cnst_mstr_id = dmi.cnst_mstr_id
    LEFT JOIN mktg_ops_vws.bz_dim_treatmnt dmtr 
        ON dmi.treatmnt_key = dmtr.treatmnt_key
    LEFT JOIN mktg_ops_vws.bz_dim_delivery dmdlv 
        ON dmi.delivery_key = dmdlv.delivery_key
    LEFT JOIN mktg_ops_vws.bzfc_fact_email_interaction emi 
        ON ask.ask_src_key = emi.src_key 
        AND brdg.cnst_mstr_id = emi.cnst_mstr_id
    LEFT JOIN mktg_ops_vws.bz_dim_delivery emdlv 
        ON emi.delivery_key = emdlv.delivery_key
    LEFT JOIN mktg_ops_vws.bzfc_fact_interaction_all fia 
        ON ask.ask_src_key = fia.src_key 
        AND brdg.cnst_mstr_id = fia.cnst_mstr_id
    LEFT JOIN mktg_ops_vws.bz_dim_treatmnt aptr 
        ON fia.treatment_id = aptr.nk_treatmnt_id
    WHERE ask.ask_rec_typ = 'Planned Gift'
      AND ask.ask_src_cd IS NOT NULL
)

SELECT 
    ask_id,
    ask_src_cd,
    frf_acct_id,
    frf_cntct_id,
    cnst_mstr_id,
    treatmnt_cd,
    treatmnt_dsc,
    delivery_nm,
    delivery_label,
    subsrc_cd,
    dw_trans_ts
FROM ranked_data
WHERE rn = 1;

--audit update	
			v_end_time := GETDATE();
            v_ok_message := '';
			
		UPDATE mods_bi.etl_config.audit_log
       	SET 
           status = 'Complete',
           end_time = v_end_time,
           TaskMessage = v_ok_message,
           recs_processed = (  SELECT CAST(COUNT(*) AS INTEGER)   FROM mods_bi.mktg_ops_tbls.gms_bzfc_fact_ask_cntct_intrctn )
       WHERE 
           proc_name = 'ld_gms_bzfc_fact_ask_cntct_intrctn' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_gms_bzfc_fact_ask_cntct_intrctn', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

			
    END;

$$
