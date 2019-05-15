UPDATE taxonomy SET IS_MARINE=FALSE;
update taxonomy set is_marine=true where id in ( select DISTINCT t.id from taxonomy t join taxon_gbif_map g on g.canonical_name=t.name or g.canonical_name||' '||g.authority=t.name);

update taxonomy set is_marine=true where taxonomy.id in (
select t2.id from taxonomy t1 
left join taxonomy t2 on t2.path LIKE '%/'||t1.id||'/%' where t1.level_ref=41 and t1.is_marine=true)
