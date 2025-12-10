create or replace view mods_bi.mktg_ops_vws.bz_dim_appt_typ
as
select * from eda.bio_appointment_vws.bz_dim_appt_typ
with no schema binding;