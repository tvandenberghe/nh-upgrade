set search_path to darwin2,public;
drop materialized view if exists ipt.mv_darwin_ipt_rbins_mof CASCADE;
drop view if exists ipt.v_darwin_ipt_rbins_mof;

CREATE SCHEMA IF NOT EXISTS ipt;

create view ipt.v_darwin_ipt_rbins_mof as 
with sampling_depth_range_cte as (
select distinct 'prop_depth_range_'||source as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, null,property_type_id_internal as measurement_type,property_type_id, 
value,value as orig_value, 'm'::text as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='sampling_depth' and value ~ '^\d+-\d+$')

select distinct on (occurrence_id, measurement_type, measurement_type_id, measurement_unit) source, occurrence_id, measurement_type, measurement_type_id, measurement_value, measurement_value_id, orig_value, measurement_unit,
case measurement_unit
when 'm' then 'http://vocab.nerc.ac.uk/collection/P06/current/ULAA/'
when 'kg' then 'http://vocab.nerc.ac.uk/collection/P06/current/KGXX/'
when 'mm' then 'http://vocab.nerc.ac.uk/collection/P06/current/UXMM/'
when 'cm' then 'http://vocab.nerc.ac.uk/collection/P06/current/ULCM/'
when 'g' then 'http://vocab.nerc.ac.uk/collection/P06/current/UGRM/'
end as measurement_unit_id
 from (

SELECT DISTINCT 'specimen_sex'::text AS source,'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurrence_id,
'sex'::text AS measurement_type,'vocab.nerc.ac.uk/collection/P01/current/ENTSEX01'::text AS measurement_type_id,
s.sex::text AS measurement_value,
	    case 
		when s.sex='female' then 'http://vocab.nerc.ac.uk/collection/S10/current/S102' 
		when s.sex='male' then 'http://vocab.nerc.ac.uk/collection/S10/current/S103'
		when s.sex='undefined' then 'http://vocab.nerc.ac.uk/collection/S10/current/S105'
		when s.sex='unknown' then 'http://vocab.nerc.ac.uk/collection/S10/current/S104'
		when s.sex='not stated' then 'http://vocab.nerc.ac.uk/collection/S10/current/S104'
		when s.sex='mixed' then 'http://vocab.nerc.ac.uk/collection/S10/current/S108'
		when s.sex='female & male' then 'http://vocab.nerc.ac.uk/collection/S10/current/S108'
		when s.sex='non applicable' then 'http://vocab.nerc.ac.uk/collection/S10/current/S104'
		else s.sex 
end AS measurement_value_id,
null::text as orig_value,
null::text AS measurement_unit
from specimens s
where s.sex is not null

union

SELECT DISTINCT 'specimen_stage'::text AS source, 'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurrence_id,
'lifestage'::text AS measurement_type,'vocab.nerc.ac.uk/collection/P01/current/LSTAGE01'::text AS measurement_type_id,
s.stage::text AS measurement_value,
	    case 
		when s.stage='adult' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1116' 
		when s.stage='juvenile' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1127'
		when s.stage='subadult' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1171'
		when s.stage='immature' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1171'
		when s.stage='neonatus' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1172'
		when s.stage='larva' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1128'
		when s.stage='egg' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1122'
		when s.stage='undefined' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1152'
		when s.stage='unknown' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1152'
		when s.stage='not stated' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1152'
		when s.stage='hypope' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1171'
		when s.stage='nymph' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1171'
		when s.stage='tritonymph' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1171'
		when s.stage='chick' then 'http://vocab.nerc.ac.uk/collection/S11/current/S1171'
		else s.stage 
end AS measurement_value_id,
null::text as orig_value,
null::text AS measurement_unit
from specimens s
where s.stage is not null
union

SELECT DISTINCT 'specimen_count'::text AS source, 'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurrence_id,
'count' AS measurement_type,'vocab.nerc.ac.uk/collection/P01/current/OCOUNT01'::text AS measurement_type_id,
CASE COALESCE(s.specimen_count_max, s.specimen_count_min, 1) WHEN 0 THEN '1' ELSE COALESCE(s.specimen_count_max, s.specimen_count_min, 1)::text end AS measurement_value, null::text as measurement_value_id,
null::text as orig_value,'Number of individuals in container' AS measurement_unit
from specimens s

union

select distinct 'depth_gtu' as source, 'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurrence_id,
'sampling_depth' as measurement_type,'http://vocab.nerc.ac.uk/collection/P01/current/ADEPZZ01/' as measurement_type_id, (-1*g.elevation)::text as measurement_value, null::text as measurement_value_id,
g.elevation::text as orig_value, 'm'::text as measurement_unit
from darwin2.gtu g
left join darwin2.specimens s on s.gtu_ref=g.id
where g.elevation is not null and g.elevation <=0 and g.elevation >=-10000
union

select distinct 'elevation_gtu' as source, 'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurrence_id, 
'sampling_elevation' as measurement_type,'https://www.wikidata.org/wiki/Q2633778' as measurement_type_id, g.elevation::text as measurement_value, null::text as measurement_value_id,
g.elevation::text as orig_value, 'm'::text as measurement_unit
from darwin2.gtu g
left join darwin2.specimens s on s.gtu_ref=g.id
where g.elevation is not null and g.elevation >=0 and g.elevation <=8000

union

select distinct 'depth_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, null::text as measurement_value_id,
value as orig_value, 'm'::text as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='sampling_depth' and value ~ '^\d+$' and cast(value as double precision) <=10000

union

select distinct 'elevation_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, null::text as measurement_value_id,
value as orig_value, 'm'::text as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='sampling_elevation' and value ~ '^\d+$' and cast(value as double precision) <=8000

union

select distinct 'length_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, null::text as measurement_value_id,
value as orig_value, unit as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='body_length' and unit is not null and value not like '%ha%'

union

select distinct 'weight_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, null::text as measurement_value_id,
value as orig_value, unit as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='body_weight' and unit is not null

union

select distinct 'sampling_gear_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, null::text as measurement_value_id,
value as orig_value, unit as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='sampling_gear'

union

select distinct 'else_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, null::text as measurement_value_id,
value as orig_value, unit as measurement_unit
from darwin2.mv_properties
where property_type_id_internal not in ('sampling_depth','sampling_elevation','body_length','body_weight','sampling_gear') and property_type_id_internal not in ('meteorite_fall_or_find','verbatimLocality','core_depth_start','core_depth_end') /*no biota*/

union

select 'depth_range_prop' as source, occurrence_id, 
'sampling_depth_min','http://vocab.nerc.ac.uk/collection/P01/current/MINWDIST/' as measurement_type_id, regexp_replace(value,'-(\d+)$','') as measurement_value, null::text as measurement_value_id,
orig_value, measurement_unit
from sampling_depth_range_cte 

union

select 'prop_depth_range_prop' as source, occurrence_id, 
'sampling_depth_max','http://vocab.nerc.ac.uk/collection/P01/current/MAXWDIST/' as measurement_type_id, regexp_replace(value,'^(\d+)-','') as measurement_value, null::text as measurement_value_id,
orig_value, measurement_unit
from sampling_depth_range_cte) q --inner join q as q2 on q.occurrence_id=q2.occurrence_id and q.measurement_type_id=q2.measurement_type_id
where occurrence_id is not null and (measurement_value_id is null or measurement_value_id like 'http%')
order by occurrence_id, measurement_type, measurement_type_id,measurement_unit,source desc;

create materialized view ipt.mv_darwin_ipt_rbins_mof as 
select * from ipt.v_darwin_ipt_rbins_mof
