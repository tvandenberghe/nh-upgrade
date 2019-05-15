set search_path to darwin2,public;
drop materialized view if exists mv_darwin_ipt_rbins_mof;
drop view if exists v_darwin_ipt_rbins_mof;

create view v_darwin_ipt_rbins_mof as 

with sampling_depth_range_cte as (
select 'prop_depth_range' as source, value, 'http://collections.naturalsciences.be/specimen/'::text || props.specimen_ref::character varying::text AS occurence_id, null,null
from darwin2.mv_properties props
where props.property='sampling_depth' and props.value ~ '^\d+-\d+$')

select * from(
select 'gtu_depth' as source, null as orig_value, 'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurence_id,'sampling_depth' as property,'http://vocab.nerc.ac.uk/collection/P01/current/ADEPZZ01/',
(-1*g.elevation)::text as value
from darwin2.gtu g
left join darwin2.specimens s on s.gtu_ref=g.id
where g.elevation is not null and g.elevation <=0

union

select 'prop_depth' as source, value as orig_value, 'http://collections.naturalsciences.be/specimen/'::text || props.specimen_ref::character varying::text AS occurence_id, 'sampling_depth_max','http://vocab.nerc.ac.uk/collection/P01/current/ADEPZZ01/',
value
from darwin2.mv_properties props
where props.property='sampling_depth' and props.value ~ '^\d+$'

union

select 'prop_depth_range' as source, value as orig_value, occurence_id, 'sampling_depth_min','http://vocab.nerc.ac.uk/collection/P01/current/ADEPZZ01/',
regexp_replace(value,'-(\d+)$','') as value
from sampling_depth_range_cte 

union all

select 'prop_depth_range' as source, value as orig_value, occurence_id, 'sampling_depth_max','http://vocab.nerc.ac.uk/collection/P01/current/ADEPZZ01/',
regexp_replace(value,'^(\d+)-','') as value
from sampling_depth_range_cte 

union

select 'prop_else' as source, value as orig_value, 'http://collections.naturalsciences.be/specimen/'::text || props.specimen_ref::character varying::text AS occurence_id, property,url,
value
from darwin2.mv_properties props
where props.property<>'sampling_depth'

union

select 'gtu' as source, null as orig_value, 'http://collections.naturalsciences.be/specimen/'::text || s.id::character varying::text AS occurence_id, 'elevation' as property,'https://www.wikidata.org/wiki/Q2633778' as url,
g.elevation::text as value
from darwin2.gtu g
left join darwin2.specimens s on s.gtu_ref=g.id
where g.elevation is not null and g.elevation >=0
)q
where property not like '%sampling%' and property <> 'elevation' order by property;

create materialized view mv_darwin_ipt_rbins_mof as select * from v_darwin_ipt_rbins_mof;
