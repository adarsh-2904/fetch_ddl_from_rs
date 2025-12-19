CREATE OR REPLACE VIEW mktg_ops_vws.bz_cnst_birth_pg as

-- ---------------------------------------------------------------------------------------------------------------------------
-- Created by: Michael Andrien
-- Created date: 18-Mar-2015
-- Purpose: This view was built to provide a single row for the Planned Giving Segmentation and reporting lists.  
--          The view is based on the bz_cnst_birth view, but added the QUALIFY statement to select the 
--          best birth date based on the source system prioritization rules provided by the Planned Giving team. 
--          Includes 6 derived columns to build the complete birth date in DATE format and reflect constituent age.
--
-- Modified by: Michael Andrien
-- Modified date: 9-July-2015
-- Purpose: Added CAST to derived age (bzd_derived_age) to cast the value as an integer.
--
-- Modified by: Michael Andrien
-- Modified date: 04/5/2016
-- Purpose: Added Generation Segment columns based on Blackbaud cohort definitions.
--
-- Modified by: Michael Hall
-- Modified date: 03/13/2017
-- Purpose: Updated Generation Segment Descriptions to MODS team preferred descriptions.
-- ---------------------------------------------------------------------------------------------------------------------------
SELECT
  a.cnst_mstr_id,
  a.arc_srcsys_cd,
  a.cnst_birth_dy_num,
  a.cnst_birth_mth_num,
  a.cnst_birth_yr_num,

  LPAD(CAST(COALESCE(a.cnst_birth_mth_num, 1) AS VARCHAR), 2, '0') AS bzd_char_month,
  LPAD(CAST(COALESCE(a.cnst_birth_dy_num, 1) AS VARCHAR), 2, '0') AS bzd_char_day,
  LPAD(CAST(a.cnst_birth_yr_num AS VARCHAR), 4, '0') AS bzd_char_yr,

  TO_DATE(
    LPAD(CAST(COALESCE(a.cnst_birth_mth_num, 1) AS VARCHAR), 2, '0') || '/' ||
    LPAD(CAST(COALESCE(a.cnst_birth_dy_num, 1) AS VARCHAR), 2, '0') || '/' ||
    LPAD(CAST(a.cnst_birth_yr_num AS VARCHAR), 4, '0'),
    'MM/DD/YYYY'
  ) AS bzd_birth_dt,

  CASE
    WHEN COALESCE(a.cnst_birth_dy_num, 0) = 0 OR COALESCE(a.cnst_birth_mth_num, 0) = 0 THEN 'Y'
    ELSE 'N'
  END AS bzd_altered_dt_flg,

  DATEDIFF(year,
    TO_DATE(
      LPAD(CAST(COALESCE(a.cnst_birth_mth_num, 1) AS VARCHAR), 2, '0') || '/' ||
      LPAD(CAST(COALESCE(a.cnst_birth_dy_num, 1) AS VARCHAR), 2, '0') || '/' ||
      LPAD(CAST(a.cnst_birth_yr_num AS VARCHAR), 4, '0'),
      'MM/DD/YYYY'
    ),
    CURRENT_DATE
  ) AS bzd_derived_age,

  a.cnst_birth_strt_ts,
  a.cnst_birth_end_dt,

  CASE
    WHEN a.cnst_birth_yr_num >= 1996 THEN 'Z'
    WHEN a.cnst_birth_yr_num BETWEEN 1981 AND 1995 THEN 'Y'
    WHEN a.cnst_birth_yr_num BETWEEN 1965 AND 1980 THEN 'X'
    WHEN a.cnst_birth_yr_num BETWEEN 1946 AND 1964 THEN 'B'
    WHEN a.cnst_birth_yr_num BETWEEN 1928 AND 1945 THEN 'S'
    WHEN a.cnst_birth_yr_num < 1928 THEN 'G'
    ELSE 'U'
  END AS generation_segmnt_cd,

  CASE
    WHEN a.cnst_birth_yr_num >= 1996 THEN 'Gen Z'
    WHEN a.cnst_birth_yr_num BETWEEN 1981 AND 1995 THEN 'Millennials'
    WHEN a.cnst_birth_yr_num BETWEEN 1965 AND 1980 THEN 'Gen X'
    WHEN a.cnst_birth_yr_num BETWEEN 1946 AND 1964 THEN 'Baby Boomers'
    WHEN a.cnst_birth_yr_num BETWEEN 1928 AND 1945 THEN 'The Silent Generation'
    WHEN a.cnst_birth_yr_num < 1928 THEN 'The Greatest Generation'
    ELSE 'Unknown'
  END AS generation_segmnt_dsc,

  a.dw_srcsys_trans_ts,
  a.row_stat_cd,
  a.appl_src_cd,
  a.load_id,
  a.cnst_birth_best_los_ind,
  a.trans_key,
  a.user_id

FROM eda.arc_mdm_vws.bz_cnst_birth a
LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys b 
  ON a.arc_srcsys_cd = b.arc_srcsys_cd

QUALIFY ROW_NUMBER() OVER (
  PARTITION BY a.cnst_mstr_id
  ORDER BY
    CASE
      WHEN a.arc_srcsys_cd = 'BADW' THEN 1
      WHEN a.arc_srcsys_cd = 'DRMS' THEN 2
      WHEN a.arc_srcsys_cd = 'PHSS' THEN 3
      WHEN a.arc_srcsys_cd = 'VMS' THEN 4
      WHEN a.arc_srcsys_cd = 'SFFS' THEN 5
      WHEN a.arc_srcsys_cd = 'CDIM' THEN 6
      WHEN b.line_of_service_cd = 'FR' AND a.arc_srcsys_cd NOT IN ('SFFS','ATG','ATGO','CNVO','TAFS') THEN 7
      WHEN a.arc_srcsys_cd = 'ATG' THEN 8
      WHEN a.arc_srcsys_cd = 'TAFS' THEN 9
      ELSE 10
    END
) = 1 with no schema binding;