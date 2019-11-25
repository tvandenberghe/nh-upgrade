set search_path to darwin2,public;
drop materialized view if exists mv_darwin_ipt_rbins_mof CASCADE;
drop view if exists v_darwin_ipt_rbins_mof;

create view v_darwin_ipt_rbins_mof as 
/*
with marine_collections as select id from collections where name_indexed in ((Asteroidea
Belgian Marine Invertebrates
Belgian Marine Invertebrates Not visible
Brachiopoda
Crinoidea
Echinoidea
Holothuroidea
Ophiuroidea
Pycnogonida
Sipuncula

SELECT count(*), source,dataset_id,measurement_unit,s.collection_name
  FROM darwin_complete_mof m
  left join darwin_complete o on o.occurrence_id=m.occurrence_id
  left join specimens s on s.id::text=replace(m.occurrence_id,'http://collections.naturalsciences.be/specimen/','')
  where measurement_type='sampling_elevation' 
  group by source,dataset_id,measurement_unit,s.collection_name
  order by dataset_id,source
*/

with sampling_depth_range_cte as (
select distinct 'prop_depth_range_'||source as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, null,property_type_id_internal as measurement_type,property_type_id, 
value,value as orig_value, 'm'::text as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='sampling_depth' and value ~ '^\d+-\d+$')

select distinct on (occurrence_id, measurement_type, measurement_type_id,measurement_unit) source, occurrence_id, measurement_type, measurement_type_id, measurement_value,orig_value,measurement_unit,
case measurement_unit
when 'm' then 'http://vocab.nerc.ac.uk/collection/P06/current/ULAA/'
when 'kg' then 'http://vocab.nerc.ac.uk/collection/P06/current/KGXX/'
when 'mm' then 'http://vocab.nerc.ac.uk/collection/P06/current/UXMM/'
when 'cm' then 'http://vocab.nerc.ac.uk/collection/P06/current/ULCM/'
when 'g' then 'http://vocab.nerc.ac.uk/collection/P06/current/UGRM/'
end as measurement_unit_id
 from (

select distinct 'depth_gtu' as source, 'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurrence_id,
'sampling_depth' as measurement_type,'http://vocab.nerc.ac.uk/collection/P01/current/ADEPZZ01/' as measurement_type_id, (-1*g.elevation)::text as measurement_value, g.elevation::text as orig_value, 'm'::text as measurement_unit
from darwin2.gtu g
left join darwin2.specimens s on s.gtu_ref=g.id
where g.elevation is not null and g.elevation <=0 and g.elevation >=-10000
union

select distinct 'elevation_gtu' as source, 'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurrence_id, 
'sampling_elevation' as measurement_type,'https://www.wikidata.org/wiki/Q2633778' as measurement_type_id, g.elevation::text as measurement_value, g.elevation::text as orig_value, 'm'::text as measurement_unit
from darwin2.gtu g
left join darwin2.specimens s on s.gtu_ref=g.id
where g.elevation is not null and g.elevation >=0 and g.elevation <=8000

union

select distinct 'depth_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, 'm'::text as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='sampling_depth' and value ~ '^\d+$' and cast(value as double precision) <=10000

union

select distinct 'elevation_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, 'm'::text as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='sampling_elevation' and value ~ '^\d+$' and cast(value as double precision) <=8000

union

select distinct 'length_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, unit as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='body_length' and unit is not null and value not like '%ha%'

union

select distinct 'weight_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, unit as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='body_weight' and unit is not null

union

select distinct 'sampling_gear_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, unit as measurement_unit
from darwin2.mv_properties
where property_type_id_internal='sampling_gear'

union

select distinct 'else_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, unit as measurement_unit
from darwin2.mv_properties
where property_type_id_internal not in ('sampling_depth','sampling_elevation','body_length','body_weight','sampling_gear') /*already covered*/ and property_type_id_internal not in ('meteorite_fall_or_find','verbatimLocality','core_depth_start','core_depth_end') /*no biota*/

union

select 'depth_range_prop' as source, occurrence_id, 
'sampling_depth_min','http://vocab.nerc.ac.uk/collection/P01/current/MINWDIST/' as measurement_type_id, regexp_replace(value,'-(\d+)$','') as measurement_value, orig_value, measurement_unit
from sampling_depth_range_cte 

union

select 'prop_depth_range_prop' as source, occurrence_id, 
'sampling_depth_max','http://vocab.nerc.ac.uk/collection/P01/current/MAXWDIST/' as measurement_type_id, regexp_replace(value,'^(\d+)-','') as measurement_value, orig_value, measurement_unit
from sampling_depth_range_cte) q --inner join q as q2 on q.occurrence_id=q2.occurrence_id and q.measurement_type_id=q2.measurement_type_id

order by occurrence_id, measurement_type, measurement_type_id,measurement_unit,source desc;

create materialized view mv_darwin_ipt_rbins_mof as 
select * from v_darwin_ipt_rbins_mof where occurrence_id is not null;

--where (measurement_type like '%elevation%' and cast(measurement_value as double precision) <=8800) or (measurement_type like '%depth%' and cast(measurement_value as double precision) <=11000) or measurement_type not like '%elevation%' or measurement_type not like '%depth%'

