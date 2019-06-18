select count(*), ndwc_gtu_identifier, verbatim_location from darwin2.darwin_belgianmarineinvertebrates where location_id is null and taxon_id is not null and verbatim_location is not null group by ndwc_gtu_identifier, verbatim_location having count(*)>1 order by 1 desc

/*set search_path to darwin2;
with step1 as (INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label) values ((select id from authority_domain where name='geonames.org'),null,'http://www.geonames.org/2802361',null,'2802361',ARRAY['PCLI'],'Belgium') on conflict on constraint tag_authority_uq do UPDATE SET pref_label = excluded.pref_label returning id) 
select id from step1*/
--INSERT INTO PROPERTIES (referenced_relation,record_id,property_type,lower_value,upper_value) select 'tag_authority',step1.id,'latitude_wgs_84','50.75','50.75' from step1 union select 'tag_authority',step1.id,'longitude_wgs_84','4.5','4.5' from step1;


/*select * from darwin2.tag_groups tg 
left join darwin2.tag_group_distinct tgd on tg.tag_group_distinct_ref=tgd.id 
left join darwin2.tag_tag_authority ttg on ttg.tag_group_distinct_ref=tgd.id 
left join darwin2.tag_authority ta on ttg.tag_authority_ref=ta.id 
left join darwin2.properties p on p.record_id =ta.id and p.referenced_relation='tag_authority'
where tg.sub_group_name_indexed = 'country' and tg.tag_value='Australia' limit 500;
*/

--select * from darwin2.mv_darwin_ipt_rbins where verbatim_location='Australia'
--select * from darwin2.mv_tag_to_locations where original_location='Australia'

--select * from darwin2.tag_group_distinct where tag_value = 'Australia'

/*
select name, total as nb_specimens, worms as nb_specimens_worms, 100*worms::decimal/total as wormsrate, georeffed_worms,100.00*georeffed_worms::decimal/worms as georate, nb_species,ranks from (
select 'aves' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='aves'
union all
select 'belgianmarineinvertebrates' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='belgianmarineinvertebrates'
union all
select 'brachiopoda' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='brachiopoda'
union all
select 'bryozoa' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='bryozoa'
union all
select 'cheliceratamarine' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='cheliceratamarine'
union all
select 'cnidaria' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='cnidaria'
union all
select 'crustacea' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='crustacea'
union all
select 'echinodermata' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='echinodermata'
union all
select 'mammalia' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='mammalia'
union all
select 'mollusca' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='mollusca'
union all
select 'pisces' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='pisces'
union all
select 'reptilia' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='reptilia'
union all
select 'rotifera' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='rotifera'
union all
select 'vertebratestypes' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='vertebratestypes'
) q order by 1
*/

/*
select  * from darwin2.mv_darwin_ipt_rbins where verbatim_location in(
'Colombia'
,'Angola, Parc Carrisso'
,'Bogor, Djakarta, Indonesia, West Java'
,'Belgium, Dongen'
,'Angola, Dundo'
,'Belgium, Dongen'
,'Bretagne, France, Roscoff'
,'Astrida, Butare, Rwanda'
,'Belgium ; België ; Belgique ; Belgien'
,'Ecuador  ; Équateur'
,'Belgium'
,'Australia')
*/

--select * from darwin2.mv_darwin_ipt_rbins where information_withheld is null limit 1000