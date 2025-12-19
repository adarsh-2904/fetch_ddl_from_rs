CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_arc_biomed_txn()
 LANGUAGE plpgsql
AS $$
	
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_arc_biomed_txn', 'Stored Procedure', 'Inprogress', v_start_time);


begin

/*Execution time: 15m*/
Truncate TABLE mktg_stage_tbls.arc_biomed_txn_stg;

--------------Query 1 working------------------------------------------------

INSERT INTO mktg_stage_tbls.arc_biomed_txn_stg(
cnst_mstr_id, donat_key, nk_donat_num, nk_donat_dt, 
apptmt_dt, nk_supplier, age_band_key, bag_type_key, 
bdr_rev_dt_key, blood_type_key, donat_dt_key, donor_key, 
drive_key, drive_site_key, hold_reason_key, patient_key, 
phleb_key, phleb_status_key, race_key, region_key, site_key, sponsor_key, supplier_key, 
nk_key_donor, nk_legacy_donor_id, nk_drive_id, nk_ep_drive_id, 
nk_drive_site_id, nk_sponsor_id, nk_region_id, nk_site_cd, nk_ep_abo_id, nk_prod_cd, nk_bdr_rev_dt, 
nk_bdr_rev_stat, donat_status_cd, donat_status_dsc, regis_ts, 
phleb_start_ts, phleb_stop_ts, phleb_duration_sec, phleb_duration_tm, draw_to_vol_qty, drawn_vol_qty,
drawn_sample_vol_qty, drawn_rbc_vol_qty, drawn_plasma_vol_qty, 
anticoag_vol_qty, adverse_donor_rxn, adv_donor_rxn_ind, cmv_status, platelet_cnt, height, dbl_rbc_ind, 
weight, blood_pressure, pulse, temp, hemoglobin, questionnaire_typ, lot_num, anticoag_dsc, laptop_num, phleb_ind, med_screen_ind, 
prodctv_proc_ind, prodctv_invalid_proc_ind, prodctv_unit_wb_cnt, prodctv_unit_pltpheresis_cnt, prodctv_unit_red_cell_cnt, prodctv_unit_plspheresis_cnt, prodctv_unit_dbl_red_cell_cnt, 
first_donat_ind, deferral_ind, dbl_vp_ind, discont_ind, finalization_ind, appt_ind, walk_in_ind, apptmt_show_ind, donation_ind, dw_trans_ts, appl_src_cd, load_id,
audit_key,srcsys_ts,row_stat_cd)

/*drop table if exists mktg_stage_tbls.arc_biomed_txn_stg1;
create table mktg_stage_tbls.arc_biomed_txn_stg1 as */
select 
fact_donation.cnst_mstr_id1 AS cnst_mstr_id
,fact_donation.a_donation_id as donat_key
,fact_donation.a_donation_id as nk_donat_num
,fact_donation.donation_dt as nk_donat_dt
,fact_appointment.apptmt_dt
,fact_donation.supplier_code as nk_supplier
,fact_donation.age_at_donation as age_band_key
,fact_donation.bag_type_id as bag_type_key
, null as bdr_rev_dt_key--field not found in EDA
,fact_donation.a_blood_type_key as blood_type_key
,fact_donation.donation_dt as donat_dt_key  --duplicate data: dt_key not found in eda,bfd
,fact_donation.donor_key 
,fact_donation.drive_external_id as drive_key 
,fact_donation.site_external_id as drive_site_key
,fact_donation.hold_reason_description as hold_reason_key
,null as patient_key
,fact_donation.phleb_type_key as phleb_key
,fact_donation.a_phleb_status_key  as phleb_status_key
,fact_donation.race_id as race_key
,fact_donation.region_key
,null as site_key --field not found in EDA
,fact_donation.mstr_sponsor_key as sponsor_key --repeating twice
,null as supplier_key--field not found in EDA
,fact_donation.donor_id as nk_key_donor
,fact_donation.donor_external_id as nk_legacy_donor_id 
,fact_donation.a_mstr_drive_key as nk_drive_id
,fact_donation.nk_drive_ext_id as nk_ep_drive_id
,fact_donation.a_mstr_drive_site_key as nk_drive_site_id
,fact_donation.sponsor_external_id as nk_sponsor_id
,fact_donation.region_key as nk_region_id
,fact_donation.drive_site_dsc as nk_site_cd
,fact_donation.nk_ep_abo_id
,fact_donation.product_code as nk_prod_cd,	null as nk_bdr_rev_dt, 
	
	null as nk_bdr_rev_stat, 	fact_donation.status as donat_status_cd, 
	
	null as donat_status_dsc, 	fact_donation.registration_start_ts as regis_ts, 	null as phleb_start_ts, 
	
	fact_donation.phleb_stopped_flg as phleb_stop_ts, 	null as phleb_duration_sec, 
	null as phleb_duration_tm, 
	null as draw_to_vol_qty, 	fact_donation.drawn_vol_qty as drawn_vol_qty, 	null as drawn_sample_vol_qty, 
	fact_donation.drawn_rbc_vol_qty as drawn_rbc_vol_qty, 	fact_donation.drawn_plasma_vol_qty as drawn_plasma_vol_qty, 	fact_donation.anticoagulant_volume as anticoag_vol_qty,
	null as adverse_donor_rxn, 	fact_donation.adverse_reaction_ind as adv_donor_rxn_ind, 
	fact_donation.cmv_negative_ind as cmv_status, 
	null as platelet_cnt, 
	fact_donation.height, 
	null as dbl_rbc_ind, 
	fact_donation.weight, 
	fact_donation.blood_pressure, 
	fact_donation.pulse,
	fact_donation.temperature as temp,
	fact_donation.hemoglobin as hemoglobin, 
	null as questionnaire_typ, 
	fact_donation.lot_number as lot_num, 
	fact_donation.anticoagulant as anticoag_dsc,
	fact_donation.laptop_id as laptop_num, 
	fact_donation.phleb_ind as phleb_ind, 
	null as med_screen_ind, 
	fact_donation.productive_proc_ind as prodctv_proc_ind, 
	null as prodctv_invalid_proc_ind, 
	fact_donation.productive_unit_wholeblood_cnt as prodctv_unit_wb_cnt, 
	fact_donation.productive_unit_pltpheresis_cnt as prodctv_unit_pltpheresis_cnt, 
	fact_donation.productive_unit_redcell_cnt as prodctv_unit_red_cell_cnt, 
	fact_donation.productive_unit_plspheresis_cnt as prodctv_unit_plspheresis_cnt, 
	fact_donation.productive_unit_dbl_redcell_cnt as prodctv_unit_dbl_red_cell_cnt,
	fact_donation.first_time_donation_ind as first_donat_ind, 
	fact_donation.deferral_ind, 
	fact_donation.dvp_ind as dbl_vp_ind, 
	fact_donation.discontinue_ind as discont_ind, 
	null as finalization_ind, 	
	
    
	case when fact_appointment.apptmt_dt is not null and  fact_donation.walk_in_ind=0 then 1 else  0 end  as appt_ind, 
	fact_donation.walk_in_ind as walk_in_ind,
	coalesce(fact_appointment.apptmt_show_ind, 0) AS apptmt_show_ind,
	case when fact_donation.phleb_ind=1 then 1 else 0 end as donation_ind,

	CURRENT_TIMESTAMP AS dw_trans_ts,
	'BADW' as appl_src_cd, 0 as load_id ,
		null as audit_key, null as srcsys_ts,null as row_stat_cd
 
FROM       

                (/*Hitansu-Execution time 16mins*/
select coalesce(maps.new_cnst_mstr_id, eb.cnst_mstr_id) as cnst_mstr_id1,
a.donation_id as a_donation_id,a.blood_type_key as a_blood_type_key,
a.phleb_status_key as a_phleb_status_key,a.mstr_drive_key as a_mstr_drive_key,
a.mstr_drive_site_key as a_mstr_drive_site_key,
a.*,bddhr.*,eb.*, bdds.*,bddr.*,bdbt.*,bfi.*,bdps.*,bdbtype.*,bfpe.*,bfdraw.*
  from
(	select donor_id as donor_key,* from eda.bio_donation_vws.bz_fact_donation  where dvp_ind=0 
--limit 2
) a /*3m21s with a,eb,maps,bddhr*/
	left join eda.arc_mdm_vws.bz_cnst_mstr_external_brid as eb on a.donor_external_id = eb.cnst_srcsys_scndry_id and eb.arc_srcsys_cd = 'BADW'
	left outer join eda.dw_stuart_vws.cnst_mstr_id_map maps on eb.cnst_mstr_id=maps.constituent_id /* 6/22/2022: Majeed: Added the join to the maps view and the qualify statement to select one cnst_mstr_id record per nk_donat_num, nk_donat_dt, nk_supplier */  
	left join (select mstr_drive_site_key,drive_site_dsc from eda.bio_donation_vws.bz_dim_drive_site)bdds on bdds.mstr_drive_site_key=a.mstr_drive_site_key
	left join (select donation_id,hold_reason_description from eda.bio_donation_vws.bz_dim_donation_hold_reason)bddhr on bddhr.donation_id = a.donation_id 
	left join (select mstr_drive_key,nk_drive_ext_id,laptop_id from eda.bio_donation_vws.bz_dim_drive)bddr on bddr.mstr_drive_key=a.mstr_drive_key
	left join (select blood_type_key,nk_ep_abo_id from eda.bio_common_vws.bz_dim_blood_type)bdbt on bdbt.blood_type_key=a.blood_type_key
	left join (select donation_id,product_code from eda.bio_manufacturing_vws.bz_fact_inventory)bfi on bfi.donation_id=a.donation_id
	--tbm
	left join (select phleb_stopped_flg,phleb_status_key from eda.bio_donation_vws.bz_dim_phleb_status )bdps on bdps.phleb_status_key=a.phleb_status_key
	left join (select nk_bag_type_id,anticoagulant,anticoagulant_volume from eda.bio_donation_vws.bz_dim_bag_type )bdbtype on bdbtype.nk_bag_type_id=a.bag_type_id
	left join (select donation_id,height,weight,blood_pressure,pulse,temperature,hemoglobin from eda.bio_donation_vws.bz_fact_physical_exam )bfpe on a.donation_id=bfpe.donation_id
	left join (select donation_id,lot_number from eda.bio_donation_vws.bz_fact_draw )bfdraw on a.donation_id=bfdraw.donation_id
	qualify row_number() over (partition by a.donor_id,a.donation_id ,a.donation_dt ,a.supplier_code  order by coalesce(maps.new_cnst_mstr_id, eb.cnst_mstr_id) ) = 1
) fact_donation


left join

(/*Hitansu-Execution time:2mins*/
	SELECT
    COALESCE(eb.cnst_mstr_id, 0) AS cnst_mstr_id,
    cal.calendar_dt as apptmt_dt,
    bfa.apptmt_dt_key,
    bdd.donor_id as donor_key,
    bfa.drive_key,
    COALESCE(bfa.apptmt_show_ind, 0) AS apptmt_show_ind
FROM
    (
    select * from eda.bio_donation_vws.bz_fact_donation /*limit 200*/) bfd
    left join (select donor_id,donor_external_id from eda.bio_donation_vws.bz_dim_donor )bdd on bdd.donor_id=bfd.donor_id
	left join (select cnst_mstr_id,cnst_srcsys_scndry_id,arc_srcsys_cd from eda.arc_mdm_vws.bz_cnst_mstr_external_brid where cnst_mstr_id IS NOT NULL) as eb
	on bdd.donor_external_id = eb.cnst_srcsys_scndry_id and arc_srcsys_cd = 'BADW'
	left join (select appt_id,apptmt_dt_key,apptmt_show_ind,drive_key,apptmt_status_key from eda.bio_appointment_vws.bzl_fact_appointment )bfa on bfa.appt_id = bfd.appointment_id 
	LEFT JOIN (select calendar_dt,calendar_key from eda.dw_common_vws.dim_calendar )cal ON bfa.apptmt_dt_key = cal.calendar_key AND cal.calendar_dt <= CURRENT_DATE
	LEFT JOIN (select status_key,status_typ,status_cd from eda.drms_vws.bz_dim_status )d ON bfa.apptmt_status_key = d.status_key AND d.status_typ = 'Appointment' AND d.status_cd IN ('Confirmed', 'Scheduled', 'Invited')
WHERE
    
     (bdd.donor_id IS NOT NULL OR bfa.apptmt_show_ind = 1)

QUALIFY
    ROW_NUMBER() OVER (PARTITION BY bfa.apptmt_dt_key, bdd.donor_id, bfa.drive_key ORDER BY COALESCE(bfa.apptmt_show_ind, 0) DESC) = 1

                ) fact_appointment /* (cnst_mstr_id, apptmt_dt, apptmt_dt_key, donor_key, drive_key, apptmt_show_ind)
                on fact_donation.donor_key=fact_appointment.donor_key
                and fact_donation.drive_key=fact_appointment.drive_key
                and fact_donation.nk_donat_dt=fact_appointment.apptmt_dt ) AS PM_VEGYCGM2R6MIXXHGWKY4CFFU6VA (donat_key, nk_donat_num, nk_donat_dt, apptmt_dt, nk_supplier, age_band_key, bag_type_key, bdr_rev_dt_key, blood_type_key, donat_dt_key, donor_key, drive_key, drive_site_key, hold_reason_key, patient_key, phleb_key, phleb_status_key, race_key, region_key, site_key, sponsor_key, supplier_key, nk_key_donor, nk_legacy_donor_id, nk_drive_id, nk_ep_drive_id, nk_drive_site_id, nk_sponsor_id, nk_region_id, nk_site_cd, nk_ep_abo_id, nk_prod_cd, nk_bdr_rev_dt, nk_bdr_rev_stat, donat_status_cd, donat_status_dsc, regis_ts, phleb_start_ts, phleb_stop_ts, phleb_duration_sec, phleb_duration_tm, draw_to_vol_qty, drawn_vol_qty, drawn_sample_vol_qty, drawn_rbc_vol_qty, drawn_plasma_vol_qty, anticoag_vol_qty, adverse_donor_rxn, adv_donor_rxn_ind, cmv_status, platelet_cnt, height, dbl_rbc_ind, weight, blood_pressure, pulse, temp, hemoglobin, questionnaire_typ, lot_num, anticoag_dsc, laptop_num, phleb_ind, med_screen_ind, prodctv_proc_ind, prodctv_invalid_proc_ind, prodctv_unit_wb_cnt, prodctv_unit_pltpheresis_cnt, prodctv_unit_red_cell_cnt, prodctv_unit_plspheresis_cnt, prodctv_unit_dbl_red_cell_cnt, first_donat_ind, deferral_ind, dbl_vp_ind, discont_ind, finalization_ind, audit_key, srcsys_ts, row_stat_cd, appl_src_cd, load_id, cnst_mstr_id, appt_ind, walk_in_ind, apptmt_show_ind, Donation_ind, dw_trans_ts) */
on fact_donation.donor_key=fact_appointment.donor_key
and fact_donation.drive_external_id=fact_appointment.drive_key
and fact_donation.donation_dt=fact_appointment.apptmt_dt;


commit;

-------------------------------------------------Query 2 working-------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------


/* Group 2 query
Execution time with limit 5: 1m23s
Executed date: 3/18 */

INSERT INTO mktg_stage_tbls.arc_biomed_txn_stg(
cnst_mstr_id, donat_key, nk_donat_num, nk_donat_dt, apptmt_dt, nk_supplier, age_band_key, bag_type_key, 
bdr_rev_dt_key, blood_type_key, donat_dt_key, donor_key, drive_key, drive_site_key, hold_reason_key, patient_key, --
phleb_key, phleb_status_key, race_key, region_key, site_key, sponsor_key, supplier_key, nk_key_donor, nk_legacy_donor_id,nk_drive_id, nk_ep_drive_id, 
nk_drive_site_id, nk_sponsor_id, nk_region_id, nk_site_cd, nk_ep_abo_id, nk_prod_cd, nk_bdr_rev_dt,nk_bdr_rev_stat, donat_status_cd, donat_status_dsc, regis_ts, --
phleb_start_ts, phleb_stop_ts, phleb_duration_sec, phleb_duration_tm, draw_to_vol_qty, drawn_vol_qty,drawn_sample_vol_qty, drawn_rbc_vol_qty, 
drawn_plasma_vol_qty, 

anticoag_vol_qty, adverse_donor_rxn, adv_donor_rxn_ind, cmv_status, platelet_cnt, height, dbl_rbc_ind, weight, blood_pressure, pulse, temp, hemoglobin, questionnaire_typ, lot_num, anticoag_dsc, laptop_num, phleb_ind, med_screen_ind, 
prodctv_proc_ind, prodctv_invalid_proc_ind, prodctv_unit_wb_cnt, prodctv_unit_pltpheresis_cnt, prodctv_unit_red_cell_cnt, prodctv_unit_plspheresis_cnt, prodctv_unit_dbl_red_cell_cnt, 
first_donat_ind, deferral_ind, dbl_vp_ind, discont_ind, finalization_ind, appt_ind, walk_in_ind, apptmt_show_ind, donation_ind, dw_trans_ts, appl_src_cd, load_id,
audit_key,srcsys_ts,row_stat_cd)

with fact_appointment AS(
/*Hitansu- RS Query validated limit 5 execution 1m 5s*/
    select
                                COALESCE(eb.cnst_mstr_id, 0) AS cnst_mstr_id,cal.calendar_dt as apptmt_date, bfa.apptmt_dt_key, 
                                bfa.apptmt_show_ind ,eb.cnst_srcsys_scndry_id as ep_donor_key, bfa.drive_key as drive_key,bfa.drive_site_key,bfd.donor_id,
								bdd.donor_external_id,bfa.appt_id,bfa.apptmt_dt,bfa.apptmt_dt_key,bfa.apptmt_status_key,bfa.mstr_drive_key as mstr_drive_key,bfa.mstr_drive_site_key 
                FROM
    (select apptmt_dt_key,apptmt_show_ind,drive_key,drive_site_key,appt_id,apptmt_dt
,apptmt_status_key,mstr_drive_key,mstr_drive_site_key from eda.bio_appointment_vws.bzl_fact_appointment )bfa
	left join (select donor_id, appointment_id from eda.bio_donation_vws.bz_fact_donation )bfd on bfd.appointment_id=bfa.appt_id
    
    left join (select donor_id,donor_external_id from eda.bio_donation_vws.bz_dim_donor )bdd on bdd.donor_id=bfd.donor_id
	left join (select cnst_mstr_id,cnst_srcsys_scndry_id,arc_srcsys_cd from eda.arc_mdm_vws.bz_cnst_mstr_external_brid  )eb on bdd.donor_external_id = eb.cnst_srcsys_scndry_id and arc_srcsys_cd = 'BADW'
left join  (select calendar_dt,calendar_key from  eda.dw_common_vws.dim_calendar )cal on bfa.apptmt_dt_key=cal.calendar_key
	
	LEFT JOIN (select status_cd,status_key,status_typ from eda.drms_vws.bz_dim_status )d ON bfa.apptmt_status_key = d.status_key AND d.status_typ = 'Appointment'
	where cal. calendar_dt<=CURRENT_DATE   /* MTA - changed this to pick up all appointments with an appt date less than or equal to today's date.  I'm not sure why the earliier query used date-2. */
	and (eb.cnst_srcsys_scndry_id is null or apptmt_show_ind = 0 or bfa.apptmt_show_ind is null) and eb.cnst_mstr_id is not null
	and d.status_cd in ('Confirmed', 'Scheduled', 'Invited')

),
fact_donation as 
(
		select * from eda.bio_donation_vws.bz_fact_donation where dvp_ind=0

)
SELECT  
	 fact_appointment.cnst_mstr_id, 0 as donat_key, fact_donation.donation_id,fact_donation.donation_dt,fact_appointment.apptmt_dt,
     fact_donation.supplier_code,0 as age_band_key, '0' as bag_type_key,'0' as bdr_rev_dt_key, 0 as blood_type_key, 
	 NULL as donat_dt_key,---Hitansu:using null as teradata 0 is not supported for datetype
	 fact_appointment.donor_id as donor_key,fact_appointment.drive_key::VARCHAR as drive_key, fact_appointment.drive_site_key::VARCHAR as drive_site_key,
     '0' as hold_reason_key, '0' as patient_key,0 as phleb_key,
     0 as phleb_status_key, 0 as race_key, 0 as region_key,'0' as site_key, 0 as sponsor_key, '0' as supplier_key,
     fact_donation.donor_id as nk_key_donor, fact_donation.donor_external_id as nk_legacy_donor_id,
     fact_donation.mstr_drive_key::INTEGER, fact_donation.drive_external_id, fact_donation.mstr_drive_site_key::INTEGER,
     fact_donation.sponsor_external_id, fact_donation.region_key as nk_region_id, null as nk_site_cd,
 bdbt.nk_ep_abo_id,bfi.product_code as nk_prod_cd, null as nk_bdr_rev_dt,null as nk_bdr_rev_stat, fact_donation.status as donat_status_cd,null as donat_status_dsc, 
 fact_donation.registration_start_ts as regis_ts,null as phleb_start_ts,bdps.phleb_stopped_flg as phleb_stop_ts, 
 null as phleb_duration_tm, null as phleb_duration_sec,
 null as draw_to_vol_qty,fact_donation.drawn_vol_qty as drawn_vol_qty,null as drawn_sample_vol_qty,
 fact_donation.drawn_rbc_vol_qty, 
 cast(fact_donation.drawn_plasma_vol_qty as integer),
 bdbtype.anticoagulant_volume as anticoag_vol_qty, null as adverse_donor_rxn,
 fact_donation.adverse_reaction_ind as adv_donor_rxn_ind, fact_donation.cmv_negative_ind as cmv_status, null as platelet_cnt,
 bfpe.height, null as dbl_rbc_ind, bfpe.weight,bfpe.blood_pressure, bfpe.pulse, bfpe.temperature,
 bfpe.hemoglobin, null as questionnaire_typ, bfdraw.lot_number as lot_num,bdbtype.anticoagulant as anticoag_dsc,bddr.laptop_id as laptop_num, fact_donation.phleb_ind,
 null as med_screen_ind,fact_donation.productive_proc_ind as prodctv_proc_ind, null as prodctv_invalid_proc_ind,
 fact_donation.productive_unit_wholeblood_cnt as prodctv_unit_wb_cnt, fact_donation.productive_unit_pltpheresis_cnt as prodctv_unit_pltpheresis_cnt,
 fact_donation.productive_unit_redcell_cnt as prodctv_unit_red_cell_cnt, fact_donation.productive_unit_plspheresis_cnt as prodctv_unit_plspheresis_cnt,
 fact_donation.productive_unit_dbl_redcell_cnt as prodctv_unit_dbl_red_cell_cnt, fact_donation.first_time_donation_ind as first_donat_ind,
 fact_donation.deferral_ind, fact_donation.dvp_ind as dbl_vp_ind, fact_donation.discontinue_ind as discont_ind,
 null as finalization_ind,1  as apptmt_ind, 0 as walk_in_ind,
coalesce(fact_appointment.apptmt_show_ind,0) as apptmt_show_ind,0  as Donation_ind,current_timestamp as dw_trans_ts,'BADW' as appl_src_cd, 0 as load_id ,
null as audit_key, null as srcsys_ts,null as row_stat_cd/**/
        from fact_appointment
		left join fact_donation	on
			        fact_donation.donor_id=fact_appointment.donor_id  and fact_donation.mstr_drive_key=fact_appointment.mstr_drive_key
			        and fact_donation.donation_dt=fact_appointment.apptmt_dt and fact_donation.mstr_drive_site_key=fact_appointment.mstr_drive_site_key
			         and fact_donation.donor_id is null and fact_donation.mstr_drive_key is null and fact_donation.donation_dt is null
		left join (select blood_type_key,nk_ep_abo_id from eda.bio_common_vws.bz_dim_blood_type)bdbt on fact_donation.blood_type_key=bdbt.blood_type_key
		left join (select donation_id,product_code from eda.bio_manufacturing_vws.bz_fact_inventory )bfi on bfi.donation_id=fact_donation.donation_id
		left join (select phleb_stopped_flg,phleb_status_key from eda.bio_donation_vws.bz_dim_phleb_status)bdps on bdps.phleb_status_key=fact_donation.phleb_status_key
		left join ( select nk_bag_type_id,anticoagulant_volume,anticoagulant from eda.bio_donation_vws.bz_dim_bag_type )bdbtype on bdbtype.nk_bag_type_id=fact_donation.bag_type_id
		left join (select donation_id,height,weight,blood_pressure,pulse,temperature,hemoglobin from eda.bio_donation_vws.bz_fact_physical_exam )bfpe on fact_donation.donation_id=bfpe.donation_id
		left join (select donation_id,lot_number from eda.bio_donation_vws.bz_fact_draw )bfdraw on fact_donation.donation_id=bfdraw.donation_id
		left join (select mstr_drive_key,nk_drive_ext_id,laptop_id from eda.bio_donation_vws.bz_dim_drive)bddr on bddr.mstr_drive_key=fact_donation.mstr_drive_key;
							 
commit;							 

truncate table mktg_ops_tbls.arc_biomed_txn;
insert into mktg_ops_tbls.arc_biomed_txn select * from mktg_stage_tbls.arc_biomed_txn_stg;


	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.arc_biomed_txn) as nvarchar)+ ' Records inserted.';
        UPDATE mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_cnst_cdi_arc_biomed_txn' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_cnst_cdi_arc_biomed_txn', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;

$$
