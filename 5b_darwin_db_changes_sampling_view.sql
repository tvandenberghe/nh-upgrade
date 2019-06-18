set search_path to darwin2,public;
CREATE OR REPLACE FUNCTION darwin2.cleanup_sample_properties(dms_string text)
  RETURNS text AS
$$
BEGIN
	if dms_string = '' then
		dms_string=null;
	end if;
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

drop materialized view if exists mv_darwin_ipt_rbins CASCADE;
drop view if exists v_darwin_ipt_rbins;
drop materialized view if exists mv_darwin_ipt_rbins_mof;
drop view if exists v_darwin_ipt_rbins_mof;
drop materialized view if exists mv_properties;
create materialized view mv_properties as (
SELECT distinct 'gtu' as source,  record_id as gtu_ref,s.id as specimen_ref, p.property_type as property_type_id_sloppy, pt.type as property_type_id_internal, au.url as property_type_id, cleanup_sample_properties(lower_value) as value, 
case when pt.type like 'sampling_depth%' then 'm' when pt.type like 'sampling_elevation%' then 'm' when property_unit='' then null else property_unit end as unit
FROM darwin2.properties p
LEFT JOIN property_type pt on pt.id=p.property_type_ref
LEFT JOIN property_tag_authority pau on pt.id=pau.property_type_id
LEFT JOIN tag_authority au on au.id=pau.tag_authority_ref
LEFT JOIN darwin2.gtu on gtu.id=record_id
LEFT JOIN darwin2.specimens s on s.gtu_ref = gtu.id
WHERE referenced_relation = 'gtu' AND lower_value <> 'BLABLA' AND pt.type IN (
'sampling_elevation',
'sampling_depth',
'bottom_depth',
'sampling_gear',
'sampling_elevation_max',
'sampling_elevation_min',
'sampling_elevation_start',
'sampling_elevation_end',
'sampling_depth_max',
'sampling_depth_min',
'sampling_depth_start',
'sampling_depth_end',
'trap_bait',
'trap_bait_status',
'trap_details')
union
select 'specimens' as source, gtu_ref, specimen_ref, property_type_id_sloppy,property_type_id_internal, property_type_id, string_agg(distinct value,'; '), unit from (
SELECT distinct null::integer as gtu_ref, record_id as specimen_ref, p.property_type as property_type_id_sloppy, pt.type as property_type_id_internal, au.url as property_type_id, cleanup_sample_properties(lower_value) as value, 
case when property_unit='' then null when pt.type like 'sampling_depth%' then 'm' else property_unit end as unit
FROM darwin2.properties p
LEFT JOIN property_type pt on pt.id=p.property_type_ref
LEFT JOIN property_tag_authority pau on pt.id=pau.property_type_id
LEFT JOIN tag_authority au on au.id=pau.tag_authority_ref
LEFT JOIN darwin2.specimens s on s.id=record_id
WHERE  referenced_relation = 'specimens' AND pt.type IN (
'sampling_depth',
'core_depth_start',
'core_depth_end',
'meteorite_fall_or_find',
'meteorite_fall_or_find',
'meteorite_fall_or_find',
'verbatimLocality',
'preparation',
'preparator',
'quality',
'body_length', --'physical measurement'
'body_weight')) q group by gtu_ref,specimen_ref,property_type_id_sloppy, property_type_id_internal,property_type_id, unit)

