
select  total, worms, georeffed_worms,100.00*georeffed_worms::decimal/worms as georate from (
select 'aves' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='aves'
union all
select 'belgianmarineinvertebrates' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='belgianmarineinvertebrates'
union all
select 'brachiopoda' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='brachiopoda'
union all
select 'bryozoa' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='bryozoa'
union all
select 'cheliceratamarine' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='cheliceratamarine'
union all
select 'cnidaria' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='cnidaria'
union all
select 'crustacea' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='crustacea'
union all
select 'echinodermata' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='echinodermata'
union all
select 'mammalia' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='mammalia'
union all
select 'mollusca' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='mollusca'
union all
select 'pisces' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='pisces'
union all
select 'reptilia' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='reptilia'
union all
select 'rotifera' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='rotifera'
union all
select 'vertebratestypes' as name, count(*) as total, sum(1) FILTER (WHERE scientific_name_id is not null) AS worms, sum(1) FILTER (WHERE scientific_name_id is not null and decimal_latitude is not null) AS georeffed_worms from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='vertebratestypes'
) q order by 4
