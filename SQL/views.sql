﻿----------------------------------------------
-- DYNAMIC VIEWS FOR WGEEL
----------------------------------------------
DROP VIEW IF EXISTS datawg.series_stats CASCADE;
CREATE OR REPLACE VIEW datawg.series_stats AS 
 SELECT ser_id, 
 ser_nameshort AS site,
 ser_namelong AS namelong,
 min(das_year) AS min, max(das_year) AS max, 
 max(das_year) - min(das_year) + 1 AS duration,
 max(das_year) - min(das_year) + 1 - count(*) AS missing
   FROM datawg.t_dataseries_das
   JOIN datawg.t_series_ser ON das_ser_id=ser_id
   LEFT JOIN ref.tr_country_cou ON ser_cou_code=cou_code
  GROUP BY ser_id
  ORDER BY cou_order;

ALTER TABLE datawg.series_stats
  OWNER TO postgres;
 GRANT ALL ON TABLE datawg.series_stats TO wgeel;
    
 --select * from datawg.series_stats
 
 
----------------------------------------------
-- SERIES SUMMARY
----------------------------------------------
DROP VIEW IF EXISTS datawg.series_summary CASCADE;
CREATE OR REPLACE VIEW datawg.series_summary AS 
 SELECT ss.site AS site, 
 ss.namelong, 
 ss.min, 
 ss.max, 
 ss.duration,
 ss.missing,
 ser_lfs_code as life_stage,
 sam_samplingtype as sampling_type,
 ser_uni_code as unit,
 ser_hty_code as habitat_type,
 cou_order as order,
 ser_typ_id,
 ser_qal_id AS series_kept
   FROM datawg.series_stats ss
   JOIN datawg.t_series_ser ser ON ss.ser_id = ser.ser_id
   LEFT JOIN ref.tr_samplingtype_sam on ser_sam_id=sam_id
   LEFT JOIN REF.tr_country_cou ON cou_code=ser_cou_code
  ORDER BY cou_order, ser_y;

ALTER TABLE datawg.series_summary
  OWNER TO postgres;
 GRANT ALL ON TABLE datawg.series_summary TO wgeel;
  
---
-- view with distance to the sargasso
----
drop view if exists  datawg.t_series_ser_dist ;
create view datawg.t_series_ser_dist as
select 
 ser.geom,
 ss.*,
round(cast(st_distance(st_PointFromText('POINT(-61 25)',4326),geom)/1000 as numeric),2) as dist_sargasso 
from
datawg.t_series_ser ser join 
datawg.series_summary ss on ss.site=ser_nameshort
;
GRANT ALL ON TABLE datawg.series_summary TO wgeel;
GRANT ALL ON TABLE datawg.t_series_ser_dist TO wgeel;

-------------------------------------
-- View for landings
-- This view refer to both recreational and commercial landings and to catch (all have been unified as landings
---------------------------------------
DROP VIEW IF EXISTS datawg.landings CASCADE;
CREATE OR REPLACE VIEW datawg.landings AS 
 SELECT 
    t_eelstock_eel.eel_id, 
    case 
    when t_eelstock_eel.eel_typ_id=NULL then NULL
    when t_eelstock_eel.eel_typ_id=5 then 4
    when t_eelstock_eel.eel_typ_id=7 then 6 
    when t_eelstock_eel.eel_typ_id=4 then 4 
    when t_eelstock_eel.eel_typ_id=6 then 6 
    when t_eelstock_eel.eel_typ_id=32 then 32
    when t_eelstock_eel.eel_typ_id=33 then 33
         end as eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id in (4,6,5,7,32,33)) 
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;


-------------------------------------
-- View for stocking
-- This view refer to stocking in kg or number or geel equivalents
---------------------------------------

DROP VIEW IF EXISTS datawg.release CASCADE;
CREATE OR REPLACE VIEW datawg.release AS 
select  
         eel_id,         
         eel_typ_id,
	 tr_typeseries_typ.typ_name, 
	 tr_typeseries_typ.typ_uni_code,
         eel_year ,
         eel_value  ,
         eel_missvaluequal,
         eel_emu_nameshort,
         eel_cou_code,
         tr_country_cou.cou_country, 
	 tr_country_cou.cou_order, 
	 tr_country_cou.cou_iso3code, 
         eel_lfs_code,
	 tr_lifestage_lfs.lfs_name, 
         eel_hty_code,
         tr_habitattype_hty.hty_description, 
         eel_area_division,
         eel_qal_id,
         tr_quality_qal.qal_level, 
	 tr_quality_qal.qal_text, 
         eel_qal_comment,
         eel_comment,
         eel_datasource
FROM 
  datawg.t_eelstock_eel 
LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code = tr_lifestage_lfs.lfs_code 
LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id 
LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code = tr_country_cou.cou_code 
LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id 
LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code = tr_habitattype_hty.hty_code
LEFT JOIN ref.tr_emu_emu ON  (emu_nameshort,emu_cou_code) = (eel_emu_nameshort,eel_cou_code)
WHERE eel_typ_id in (8,9,10)
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
 ;


-------------------------------------
-- View for other landings
-- This view refer to other landing in kg or number 
---------------------------------------

DROP VIEW IF EXISTS datawg.other_landings CASCADE;
CREATE OR REPLACE VIEW datawg.other_landings AS 
select  
         eel_id,         
         eel_typ_id,
	 tr_typeseries_typ.typ_name, 
	 tr_typeseries_typ.typ_uni_code,
         eel_year ,
         eel_value  ,
         eel_missvaluequal,
         eel_emu_nameshort,
         eel_cou_code,
         tr_country_cou.cou_country, 
	 tr_country_cou.cou_order, 
	 tr_country_cou.cou_iso3code, 
         eel_lfs_code,
	 tr_lifestage_lfs.lfs_name, 
         eel_hty_code,
         tr_habitattype_hty.hty_description, 
         eel_area_division,
         eel_qal_id,
         tr_quality_qal.qal_level, 
	 tr_quality_qal.qal_text, 
         eel_qal_comment,
         eel_comment,
         eel_datasource
FROM 
  datawg.t_eelstock_eel 
LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code = tr_lifestage_lfs.lfs_code 
LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id 
LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code = tr_country_cou.cou_code 
LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id 
LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code = tr_habitattype_hty.hty_code
LEFT JOIN ref.tr_emu_emu ON  (emu_nameshort,emu_cou_code) = (eel_emu_nameshort,eel_cou_code)
WHERE eel_typ_id in (32,33)
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
 ;
GRANT ALL ON TABLE datawg.other_landings TO wgeel;

-------------------------------------
-- View for aquaculture
---------------------------------------

DROP VIEW IF EXISTS datawg.aquaculture CASCADE;
CREATE OR REPLACE VIEW datawg.aquaculture AS 
select  
         eel_id,
         eel_typ_id,
	 tr_typeseries_typ.typ_name, 
	 tr_typeseries_typ.typ_uni_code,
         eel_year ,
         eel_value  ,
         eel_missvaluequal,
         eel_emu_nameshort,
         eel_cou_code,
         tr_country_cou.cou_country, 
	 tr_country_cou.cou_order, 
	 tr_country_cou.cou_iso3code, 
         eel_lfs_code,
	 tr_lifestage_lfs.lfs_name, 
         eel_hty_code,
         tr_habitattype_hty.hty_description, 
         eel_area_division,
         eel_qal_id,
         tr_quality_qal.qal_level, 
	 tr_quality_qal.qal_text, 
         eel_qal_comment,
         eel_comment,
         eel_datasource
FROM 
  datawg.t_eelstock_eel 
LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code = tr_lifestage_lfs.lfs_code 
LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id 
LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code = tr_country_cou.cou_code 
LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id 
LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code = tr_habitattype_hty.hty_code
LEFT JOIN ref.tr_emu_emu ON  (emu_nameshort,emu_cou_code) = (eel_emu_nameshort,eel_cou_code)
WHERE (eel_typ_id=11 or eel_typ_id=12)
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;

-------------------------------------
-- View for B0
---------------------------------------
DROP VIEW IF EXISTS datawg.b0 CASCADE;
CREATE OR REPLACE VIEW datawg.b0 AS
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id = 13) 
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;

-------------------------------------
-- View for Bbest
---------------------------------------
DROP VIEW IF EXISTS datawg.bbest CASCADE;
CREATE OR REPLACE VIEW datawg.bbest AS 
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id = 14) 
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;


-------------------------------------
-- View for Bcurrent
---------------------------------------
DROP VIEW IF EXISTS datawg.bcurrent CASCADE;
CREATE OR REPLACE VIEW datawg.bcurrent AS 
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id = 15) 
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;

-------------------------------------
-- View for bcurrent_without_stocking
---------------------------------------
DROP VIEW IF EXISTS datawg.bcurrent_without_stocking CASCADE;
CREATE OR REPLACE VIEW datawg.bcurrent_without_stocking AS 
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id = 34) 
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;
GRANT SELECT ON datawg.bcurrent_without_stocking TO wgeel_read;
ALTER VIEW datawg.bcurrent_without_stocking OWNER TO wgeel;
-------------------------------------
-- View for SigmaA
---------------------------------------
DROP VIEW IF EXISTS datawg.sigmaa CASCADE;
CREATE OR REPLACE VIEW datawg.sigmaa AS 
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id = 17) 
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;

-------------------------------------
-- View for SigmaF
---------------------------------------
DROP VIEW IF EXISTS datawg.sigmaf CASCADE;
CREATE OR REPLACE VIEW datawg.sigmaf AS 
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id = 18) 
  AND t_eelstock_eel.eel_qal_id in (1,2,4);

-------------------------------------
-- View for SigmaF (all category)
---------------------------------------
DROP VIEW IF EXISTS datawg.sigmafallcat CASCADE;
CREATE OR REPLACE VIEW datawg.sigmafallcat AS 
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id IN (18, 20, 21)) 
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;

-------------------------------------
-- View for SigmaH
---------------------------------------
DROP VIEW IF EXISTS datawg.sigmah CASCADE;
CREATE OR REPLACE VIEW datawg.sigmah AS 
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id = 19) 
  AND t_eelstock_eel.eel_qal_id in (1,2,4);

-------------------------------------
-- View for SigmaH all categroy
---------------------------------------
DROP VIEW IF EXISTS datawg.sigmahallcat CASCADE;
CREATE OR REPLACE VIEW datawg.sigmahallcat AS 
 SELECT 
    eel_id,
    t_eelstock_eel.eel_typ_id,
    tr_typeseries_typ.typ_name,
    tr_typeseries_typ.typ_uni_code,
    t_eelstock_eel.eel_year,
    t_eelstock_eel.eel_value,
    t_eelstock_eel.eel_missvaluequal,
    t_eelstock_eel.eel_emu_nameshort,
    t_eelstock_eel.eel_cou_code,
    tr_country_cou.cou_country,
    tr_country_cou.cou_order,
    tr_country_cou.cou_iso3code,
    t_eelstock_eel.eel_lfs_code,
    tr_lifestage_lfs.lfs_name,
    t_eelstock_eel.eel_hty_code,
    tr_habitattype_hty.hty_description,
    t_eelstock_eel.eel_area_division,
    t_eelstock_eel.eel_qal_id,
    tr_quality_qal.qal_level,
    tr_quality_qal.qal_text,
    t_eelstock_eel.eel_qal_comment,
    t_eelstock_eel.eel_comment,
    t_eelstock_eel.eel_datasource
   FROM datawg.t_eelstock_eel
     LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code::text = tr_lifestage_lfs.lfs_code::text
     LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id
     LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code::text = tr_country_cou.cou_code::text
     LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id
     LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code::text = tr_habitattype_hty.hty_code::text
     LEFT JOIN ref.tr_emu_emu ON tr_emu_emu.emu_nameshort::text = t_eelstock_eel.eel_emu_nameshort::text AND tr_emu_emu.emu_cou_code = t_eelstock_eel.eel_cou_code::text
  WHERE (t_eelstock_eel.eel_typ_id IN (19, 22, 23, 24, 25)) 
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;

-------------------------------------
-- View for potential_available_habitat
---------------------------------------

DROP VIEW IF EXISTS datawg.potential_available_habitat CASCADE;
CREATE OR REPLACE VIEW datawg.potential_available_habitat AS 
 select  
         eel_id,
         eel_typ_id,
	 tr_typeseries_typ.typ_name, 
	 tr_typeseries_typ.typ_uni_code,
         eel_year ,
         eel_value  ,
         eel_missvaluequal,
         eel_emu_nameshort,
         eel_cou_code,
         tr_country_cou.cou_country, 
	 tr_country_cou.cou_order, 
	 tr_country_cou.cou_iso3code, 
         eel_lfs_code,
	 tr_lifestage_lfs.lfs_name, 
         eel_hty_code,
         tr_habitattype_hty.hty_description, 
         eel_area_division,
         eel_qal_id,
         tr_quality_qal.qal_level, 
	 tr_quality_qal.qal_text, 
         eel_qal_comment,
         eel_comment,
         eel_datasource
FROM 
  datawg.t_eelstock_eel 
LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code = tr_lifestage_lfs.lfs_code 
LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id 
LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code = tr_country_cou.cou_code 
LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id 
LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code = tr_habitattype_hty.hty_code
LEFT JOIN ref.tr_emu_emu ON  (emu_nameshort,emu_cou_code) = (eel_emu_nameshort,eel_cou_code)
WHERE (eel_typ_id=16)
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;


-------------------------------------
-- View for silver eel equivalent (mortality)
---------------------------------------
DROP VIEW IF EXISTS datawg.silver_eel_equivalents CASCADE;
CREATE OR REPLACE VIEW datawg.silver_eel_equivalents AS 
 select  
         eel_id,
         eel_typ_id,
	 tr_typeseries_typ.typ_name, 
	 tr_typeseries_typ.typ_uni_code,
         eel_year ,
         eel_value  ,
         eel_missvaluequal,
         eel_emu_nameshort,
         eel_cou_code,
         tr_country_cou.cou_country, 
	 tr_country_cou.cou_order, 
	 tr_country_cou.cou_iso3code, 
         eel_lfs_code,
	 tr_lifestage_lfs.lfs_name, 
         eel_hty_code,
         tr_habitattype_hty.hty_description, 
         eel_area_division,
         eel_qal_id,
         tr_quality_qal.qal_level, 
	 tr_quality_qal.qal_text, 
         eel_qal_comment,
         eel_comment,
         eel_datasource
FROM 
  datawg.t_eelstock_eel 
LEFT JOIN ref.tr_lifestage_lfs ON t_eelstock_eel.eel_lfs_code = tr_lifestage_lfs.lfs_code 
LEFT JOIN ref.tr_quality_qal ON t_eelstock_eel.eel_qal_id = tr_quality_qal.qal_id 
LEFT JOIN ref.tr_country_cou ON t_eelstock_eel.eel_cou_code = tr_country_cou.cou_code 
LEFT JOIN ref.tr_typeseries_typ ON t_eelstock_eel.eel_typ_id = tr_typeseries_typ.typ_id 
LEFT JOIN ref.tr_habitattype_hty ON t_eelstock_eel.eel_hty_code = tr_habitattype_hty.hty_code
LEFT JOIN ref.tr_emu_emu ON  (emu_nameshort,emu_cou_code) = (eel_emu_nameshort,eel_cou_code)
WHERE eel_typ_id in (26,27,28,29,30,31)
  --AND (t_eelstock_eel.eel_qal_id in (1,2,4))
  ;

