create or replace view mktg_ops_vws.pbi_bzl_fact_show_prodctv_ind 
as
select distinct
donor_id,
contact_id,
donation_dt,
appointment_id,
productive_proc_ind as "prodctv_proc_ind"
from eda.bio_donation_vws.bz_fact_donation
where productive_proc_ind is not null
	and contact_id is not null
	and donation_dt >= dateadd('month',-61, date_trunc('month',current_date))
	AND donation_dt <= dateadd('month',0, date_trunc('month',current_date))
with no schema binding
;