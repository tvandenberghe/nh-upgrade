
drop MATERIALIZED view select_eml;
create MATERIALIZED VIEW select_eml as
with specimen_country_tags as (select distinct s.id,unnest(string_to_array(replace(string_agg( s.gtu_country_tag_value,','),',',';'),'; ')) as tag 
from specimens s group by s.id),

children_geographic_coverage as (
SELECT c.id, string_agg(DISTINCT tg.preferredlabel, ', ' ORDER BY tg.preferredlabel) as GEOGRAPHIC_COVERAGE,
min(gtu_location[0]) as min_lat, min(gtu_location[1]) as min_lon, max(gtu_location[0]) as max_lat, max(gtu_location[1]) as max_lon
FROM specimens s
join collections c on collection_path||'/'||collection_ref||'/' LIKE '%/'||c.id||'/%'
join specimen_country_tags sct on s.id=sct.id
join tags_authority tg on tg.tag =lower(sct.tag)
where c.publish_to_gbif=true-- and s.is_marine=true
group by c.id
),
specimen_info as (
select c.id,count(s) as nb_spec, array_agg(distinct s.ig_num order by s.ig_num) as ig_num 
FROM specimens s
join collections c on collection_path||'/'||collection_ref||'/' LIKE '%/'||c.id||'/%'
where c.publish_to_gbif=true-- and s.is_marine=true
group by c.id
),
children_temporal_coverage as (

 SELECT c.id,min(       CASE
              WHEN gtu_from_date_mask=0 THEN Fct_mask_date( gtu_to_date , gtu_to_date_mask )
              ELSE Fct_mask_date( gtu_from_date , gtu_from_date_mask )
       END ) as date_from,
       replace(Max(
       replace(CASE
              WHEN gtu_to_date_mask=0 THEN Fct_mask_date( gtu_from_date , gtu_from_date_mask )
              ELSE Fct_mask_date( gtu_to_date , gtu_to_date_mask )
       END ,'xxxx-xx-xx','0000-00-00')),'0000-00-00','xxxx-xx-xx') AS date_to
FROM specimens s
join collections c on collection_path||'/'||collection_ref||'/' LIKE '%/'||c.id||'/%'
and c.publish_to_gbif=true-- and s.is_marine=true
group by c.id,c.name order by c.id
),
species_coverage as (
select c.id,count(distinct s.taxon_path) as nb_species
from specimens s
join collections c on collection_path||'/'||collection_ref||'/' LIKE '%/'||c.id||'/%'
and c.publish_to_gbif=true and s.is_marine=true 
group by c.id),
classes_orders_coverage as (select c.id,level_ref, string_agg(distinct f.name,', ') as names 
from specimens s join fct_get_tax_hierarchy(s.taxon_ref,array[12,28]) as f on f.r_start_id=s.taxon_ref 
join collections c on collection_path||'/'||collection_ref||'/' LIKE '%/'||c.id||'/%'
and c.publish_to_gbif=true-- and s.is_marine=true 
group by c.id,level_ref),
classes_orders_coverage2 as (select classes.id,classes.names as CLASS_TAXONOMIC_COVERAGE,orders.names as order_TAXONOMIC_COVERAGE from classes_orders_coverage classes left join classes_orders_coverage orders on orders.id=classes.id where classes.level_ref=12 and orders.level_ref=28)

select 'The '||c.title_en || ' contains ' || si.nb_spec ||' digitised specimens over '||sc.nb_species||' taxa (mostly species). The following classes are included: '||coc.CLASS_TAXONOMIC_COVERAGE||'.' as abstract, 'collection' as scope, si.nb_spec,sc.nb_species,si.ig_num, c.id,c.name, c.name_indexed as code,c.title_en,c.title_nl,c.title_fr, gc.GEOGRAPHIC_COVERAGE,gc.min_lon,gc.max_lon,gc.min_lat,gc.max_lat,case when tc.date_from='xxxx-xx-xx' then null else tc.date_from end as START_DATE, case when tc.date_to='xxxx-xx-xx' then null else tc.date_to end as end_DATE, coc.CLASS_TAXONOMIC_COVERAGE, coc.order_TAXONOMIC_COVERAGE, 'natural history collection, RBINS, DaRWIN, '||name as keywords, 'Royal Belgian Institute for Natural Sciences' as institute_name, 'Department of ' institute_dept_abbrev, curator.given_name ||' '||curator.family_name as boss,uc1.entry as boss_email, 'curator' as boss_role,staff.given_name ||' '||staff.family_name as subboss,uc2.entry as subboss_email, 'Collection manager' as subboss_role from collections c
left join specimen_info si on c.id=si.id
left join users curator on c.main_manager_ref=curator.id 
left join users_comm uc1 on uc1.person_user_ref = curator.id and uc1.comm_type='e-mail'
left join users staff on c.staff_ref=staff.id 
left join users_comm uc2 on uc2.person_user_ref = staff.id and uc2.comm_type='e-mail'
left join children_geographic_coverage gc on gc.id=c.id
left join children_temporal_coverage tc on tc.id=c.id
left join classes_orders_coverage2 coc on coc.id=c.id
left join species_coverage sc on sc.id=c.id
where c.publish_to_gbif=true
--group by c.id,c.name,u.given_name,u.family_name,uc.entry