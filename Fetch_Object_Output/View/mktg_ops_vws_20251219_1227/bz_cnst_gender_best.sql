CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.bz_cnst_gender_best
AS
SELECT	
	cnst_mstr_id, 
	pid as simio_pid,
	substring(pid, 1, 1) as simio_high_confdnc_match_flg,
	cnst_srcsys_id, arc_srcsys_cd, cnst_gender,
	cnst_gender_strt_ts, cnst_gender_end_dt, 
	experian_gender_cd,
	predctd_gender_first_nm as ssa_gender_first_nm,
	predctd_gender as ssa_gender, 
	predctd_gender_problty as ssa_gender_distrbtn,
	simio_gender_cd,
	case when cnst_gender = 'F' then cnst_gender
		when cnst_gender = 'M' then cnst_gender
		when substring(pid, 1, 1) = 'Y' and simio_gender_cd = 'F' then simio_gender_cd
		when substring(pid, 1, 1) = 'Y' and simio_gender_cd = 'M' then simio_gender_cd
		when experian_gender_cd = 'F' then experian_gender_cd
		when experian_gender_cd = 'M' then experian_gender_cd
		when predctd_gender = 'F' and cast(predctd_gender_problty as float) >= 0.7 then predctd_gender
		when predctd_gender = 'M' and cast(predctd_gender_problty as float) >= 0.7 then predctd_gender
		when substring(pid, 1, 1) = 'N' and simio_gender_cd = 'F' then simio_gender_cd
		when substring(pid, 1, 1) = 'N' and simio_gender_cd = 'M' then simio_gender_cd
		else 'U' /* Unknown */
	end as gender_best_cd, 
	dw_srcsys_trans_ts, row_stat_cd, appl_src_cd, load_id
FROM mods_bi.mktg_ops_tbls.bz_cnst_gender_best
WITH NO SCHEMA BINDING;