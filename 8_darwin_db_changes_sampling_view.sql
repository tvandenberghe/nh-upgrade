set search_path to darwin2,public;
CREATE OR REPLACE FUNCTION darwin2.cleanup_sample_properties(dms_string text)
  RETURNS text AS
$$
BEGIN
	dms_string := trim(dms_string);
	dms_string := trim(dms_string, chr(160));
	dms_string := regexp_replace(dms_string,'^(\d+)?,(\d+)$','\1.\2');
	dms_string := replace(dms_string,' - ','-');
	dms_string := replace(dms_string,' - ','-');
	dms_string := regexp_replace(dms_string,'^(\d+)? to (\d+)$','\1-\2');
	dms_string := regexp_replace(dms_string,'^(\d+)\.0+$','\1');
return dms_string;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE
SECURITY DEFINER
  COST 10;

drop materialized view if exists mv_darwin_ipt_rbins_mof;
drop view if exists v_darwin_ipt_rbins_mof;
drop materialized view if exists mv_properties;
create materialized view mv_properties as (
SELECT distinct record_id as gtu_ref,s.id as specimen_ref, pt.type as property, au.url, cleanup_sample_properties(lower_value) as value
FROM darwin2.properties p
LEFT JOIN property_type pt on pt.id=p.property_type_ref
LEFT JOIN property_tag_authority pau on pt.id=pau.property_type_id
LEFT JOIN tag_authority au on au.id=pau.tag_authority_ref
LEFT JOIN darwin2.gtu on gtu.id=record_id
LEFT JOIN darwin2.specimens s on s.gtu_ref = gtu.id
WHERE referenced_relation = 'gtu' AND lower_value <> 'BLABLA' AND property_type IN (
'altitude',
'Depth',
'depth_bottom',
'Gear ',
'gear_code',
'gear_comments',
'gear_name',
'maxium Depth',
'maxium Elevation',
'minimum Altitute',
'minimum Depth',
'minimum Elevation',
'sampling_depth_end',
'sampling_depth_start',
'sampling_elevation_end',
'sampling_elevation_start',
'trap_bait',
'trap_bait_status',
'trap_comments')
union all
select gtu_ref, specimen_ref, property, url, string_agg(value,'; ' order by property_type) from (
SELECT distinct null::integer as gtu_ref, record_id as specimen_ref, property_type, pt.type as property, au.url, cleanup_sample_properties(lower_value) as value
FROM darwin2.properties p
LEFT JOIN property_type pt on pt.id=p.property_type_ref
LEFT JOIN property_tag_authority pau on pt.id=pau.property_type_id
LEFT JOIN tag_authority au on au.id=pau.tag_authority_ref
LEFT JOIN darwin2.specimens s on s.id=record_id
WHERE  referenced_relation = 'specimens' AND property_type IN (
'Depth',
'einddiepte',
'fall / find',
'fall/find',
'Fall or find',
'Name',
'Preparation',
'Preparation method',
'Preparation Notes',
'Preparator',
'startdiepte')) q group by gtu_ref,specimen_ref,property,url)

