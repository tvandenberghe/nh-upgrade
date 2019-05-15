/*select property_type,lower_value from properties where referenced_relation='gtu' and property_type in (datum,'latitude', 'longitude') and record_id not in (


select record_id from properties where referenced_relation='gtu' and property_type in ('latitude', 'longitude') group by record_id having count(*)=1 or count(*)>2)*/

--create materialized view select_spatial_no_ref as
 WITH coordinates_cte
     AS (SELECT distinct record_id,
                property_type,
                lower_value
         FROM   darwin2.properties
         WHERE  referenced_relation = 'gtu'
                AND property_type IN (
'Accuracy coordinates',
'Accuracy Coordinates',
'coordinates_original',
'datum',
'ellipsoid',
'geo position',
'gis_type',
'km (offset from named place)',
'Lambert',
'latitude',
'latitude1',
'latitude2',
'Latitude DMS (end of operation)',
'Latitude DMS (start of operation)',
'Locality',
'longitude',
'longitude1',
'longitude2',
'Longitude DMS (end of operation)',
'Longitude DMS (start of operation)',
'Named Place',
'utm'
 )
ORDER  BY record_id, property_type),
WITH sampling_gtu_cte
     AS (SELECT distinct record_id,
                property_type,
                lower_value
         FROM   darwin2.properties
         WHERE  referenced_relation = 'gtu'
                AND property_type IN (
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
'trap_comments'
 ),
 WITH sampling_specimens_cte
     AS (SELECT distinct record_id,
                property_type,
                lower_value
         FROM   darwin2.properties
         WHERE  referenced_relation = 'specimens'
                AND property_type IN (
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
'startdiepte'
 ) order by record_id,property_type)

SELECT coordinates_cte.record_id,
       coordinates_cte.lower_value AS prop_latitude_start,
       case when cte.lower_value <>cte2.lower_value then cte2.lower_value  end AS prop_latitude_end,
       cte3.lower_value AS prop_longitude_start,
       case when cte3.lower_value <>cte4.lower_value then cte4.lower_value  end AS prop_longitude_end,
       gtu.*
FROM   coordinates_cte
       left JOIN coordinates_cte AS cte2 ON cte.record_id = cte2.record_id
       left JOIN coordinates_cte AS cte3 ON cte.record_id = cte3.record_id
       left JOIN coordinates_cte AS cte4 ON cte.record_id = cte4.record_id

       right JOIN GTU ON GTU.id=coordinates_cte.record_id
	
WHERE  cte.property_type = 'Latitude DMS (start of operation)'
       AND cte2.property_type = 'Latitude DMS (end of operation)'  
       AND cte3.property_type = 'Longitude DMS (start of operation)' 
       AND cte4.property_type = 'Longitude DMS (end of operation)' 
       and gtu.location is null
