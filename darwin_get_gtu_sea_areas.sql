/*select  * from gtu where id in (SELECT record_id
         FROM   properties
         WHERE  referenced_relation = 'gtu'
                AND property_type IN ('Latitude DMS (end of operation)',
'Latitude DMS (start of operation)',
'Longitude DMS (end of operation)',
'Longitude DMS (start of operation)'
 )
                
         ORDER  BY record_id,
                   property_type)*/

                   --select distinct property_type from properties where referenced_relation = 'gtu' order by property_type

select * from gtu l 
left join properties p on l.id=p.record_id 
left join tags t on t.gtu_ref=l.id
where property_type='bras de mer' or sub_group_type in ('fishing village', 'wreck', 'Small island', 'dock(s)', 'narrows', 'trench', 'wharf', 'harbor(s)', 
'harbour', 'inlet', 'jetty ; steiger ; jetée', 'Pier', 'port', 'Port', 'seaside resort', 'Seaside Resort', 'section of harbor', 'seep', 'shipwreck', 'shoal(s)', 
'shore', 'stream mouth(s)', 'viskwekerij; pisciculture; hatchery', 'boat', 'channel', 'Dive site', 'fishery', 'fish farm', 'fishing area', 'deep', 'gulf', 
'estuary', 'fjord', 'tidal creek', 'tidal creek(s)', 'tidal flat(s)', 'bassin de chasse', 'bassin de chasse; spuikom', 'cliff', 'cliff(s)', 'archipel', 
'archipelago', 'Archipelago', 'atol', 'atoll', 'cape', 'Fischerdorf ; vissersdorp', 'headlands', 'island', 'Island', 'island country', 'Island country', 
'islands', 'island station', 'isle', 'islet', 'isthmus', 'banc', 'bank(s)', 'bar', 'bay', 'Bay', 'beach', 'between islands', 'bight(s)', 'blue hole', 'cay', 
'cay ; zandbank ; banc de sable', 'coast', 'Coast', 'coast ; kust ; côte', 'coral reef', 'cove(s)', 'intertidal zone', 'lagoon', 'lagoons', 'laguna', 
'littoral vegetation', 'littoral zone', 'mangrove', 'mangrove swamp', 'marina', 'Marine and coastal protected area', 'marine channel', 'marine region', 
'mussel beds', 'ocean', 'Ocean', 'Ocean Current', 'paalwering ; pile resistance', 'reef', 'reef unit', 'sandbank', 'sea', 'Sea', 'sea area', 'sea loch', 
'sea mark; navigation mark', 'seamount', 'seaplane landing area', 'seaport', 'section of reef', 'subamrine canyon', 'submarine volcano', 'Trawl', 'undersea plateau', 'undersea valley', 'sea valley')
and location is null order by sub_group_type,tag