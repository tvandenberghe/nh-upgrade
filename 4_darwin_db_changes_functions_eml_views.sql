set search_path to darwin2,public;
CREATE OR REPLACE FUNCTION fct_get_tax_hierarchy(
--A function that retrieves the id and the name of the parent levels of the provided taxonomic unit for the provided levels. Eg. get Family and Order of Macusia satyroides = select fct_get_tax_hierarchy(184921, ARRAY[12, 28])
    IN start_id integer,
    IN levels integer[])
  RETURNS TABLE(r_start_id integer, id integer, name text, level_ref integer, parent_ref integer) AS
$BODY$
WITH RECURSIVE select_levels AS (
        SELECT  t.id,t.name,t.level_ref,t.parent_ref
        FROM    darwin2.taxonomy t
        where t.id=start_id
        UNION ALL
        SELECT   tn.id, tn.name,tn.level_ref,tn.parent_ref
        FROM    darwin2.taxonomy tn
        JOIN    select_levels
        ON      tn.id = select_levels.parent_ref
        )
        select start_id,* from select_levels sl where sl.level_ref = ANY(levels);
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION fct_get_tax_hierarchy(integer, integer[])
  OWNER TO darwin2;
  

 --DROP MATERIALIZED VIEW mv_eml_marine;
 --DROP MATERIALIZED VIEW mv_eml;
 
CREATE MATERIALIZED VIEW mv_eml AS 
WITH children_geographic_coverage AS (
         SELECT c_1.id,
            string_agg(DISTINCT countries.country_pref_label_gn::text, ', '::text ORDER BY (countries.country_pref_label_gn::text)) AS geographic_coverage,
            min(s.gtu_location[0]) AS min_lat,
            min(s.gtu_location[1]) AS min_lon,
            max(s.gtu_location[0]) AS max_lat,
            max(s.gtu_location[1]) AS max_lon
           FROM darwin2.specimens s
             JOIN darwin2.collections c_1 ON (((s.collection_path::text || '/'::text) || s.collection_ref) || '/'::text) ~~ (('%/'::text || c_1.id) || '/%'::text)
             JOIN darwin2.mv_tag_to_country countries ON countries.gtu_ref = s.gtu_ref
          WHERE c_1.publish_to_gbif = true
          GROUP BY c_1.id
        ), 
     specimen_info AS (
         SELECT c_1.id,
            count(s.*) AS nb_spec,
            array_agg(DISTINCT s.ig_num ORDER BY s.ig_num) AS ig_num,
            string_agg(distinct taxon_level_name, ', ') as ranks
           FROM darwin2.specimens s
             JOIN darwin2.collections c_1 ON (((s.collection_path::text || '/'::text) || s.collection_ref) || '/'::text) ~~ (('%/'::text || c_1.id) || '/%'::text)
          WHERE c_1.publish_to_gbif = true
          GROUP BY c_1.id
        ), 
     children_temporal_coverage AS (
         SELECT c_1.id,
            min(
                CASE
                    WHEN s.gtu_from_date_mask = 0 THEN darwin2.fct_mask_date(s.gtu_to_date, s.gtu_to_date_mask)
                    ELSE darwin2.fct_mask_date(s.gtu_from_date, s.gtu_from_date_mask)
                END) AS date_from,
            replace(max(replace(
                CASE
                    WHEN s.gtu_to_date_mask = 0 THEN darwin2.fct_mask_date(s.gtu_from_date, s.gtu_from_date_mask)
                    ELSE darwin2.fct_mask_date(s.gtu_to_date, s.gtu_to_date_mask)
                END, 'xxxx-xx-xx'::text, '0000-00-00'::text)), '0000-00-00'::text, 'xxxx-xx-xx'::text) AS date_to
           FROM darwin2.specimens s
             JOIN darwin2.collections c_1 ON (((s.collection_path::text || '/'::text) || s.collection_ref) || '/'::text) ~~ (('%/'::text || c_1.id) || '/%'::text) AND c_1.publish_to_gbif = true
          GROUP BY c_1.id, c_1.name
          ORDER BY c_1.id
        ), 
     species_coverage AS (
         SELECT c_1.id,
           count(DISTINCT s.taxon_name) AS nb_species
           FROM darwin2.specimens s
           JOIN darwin2.collections c_1 ON (((s.collection_path::text || '/'::text) || s.collection_ref) || '/'::text) ~~ (('%/'::text || c_1.id) || '/%'::text) AND c_1.publish_to_gbif = true
          GROUP BY c_1.id
        ), 
     classes_orders_coverage AS (
         SELECT c_1.id,
            f.level_ref,
            string_agg(DISTINCT f.name, ', '::text) AS names
           FROM darwin2.specimens s
           JOIN LATERAL darwin2.fct_get_tax_hierarchy(s.taxon_ref, ARRAY[12, 28]) f(r_start_id, id, name, level_ref, parent_ref) ON f.r_start_id = s.taxon_ref
           JOIN darwin2.collections c_1 ON (((s.collection_path::text || '/'::text) || s.collection_ref) || '/'::text) ~~ (('%/'::text || c_1.id) || '/%'::text) AND c_1.publish_to_gbif = true
          GROUP BY c_1.id, f.level_ref
        ), 
     classes_orders_coverage2 AS (
         SELECT classes.id,
           classes.names AS class_taxonomic_coverage,
           orders.names AS order_taxonomic_coverage
           FROM classes_orders_coverage classes
           LEFT JOIN classes_orders_coverage orders ON orders.id = classes.id
          WHERE classes.level_ref = 12 AND orders.level_ref = 28
        )
 SELECT ((((((('The '::text || c.title_en) || ' contains '::text) || si.nb_spec) || ' digitised specimens of '::text) || sc.nb_species) || ' taxa (at '||si.ranks||' level). The following classes are included: '::text) || coc.class_taxonomic_coverage) || '.'::text AS abstract,
    'collection'::text AS scope,
    si.nb_spec,
    sc.nb_species,
    si.ig_num,
    si.ranks,
    c.code AS existing_code,
    c.id,
    c.name,
    c.name_indexed AS code,
    c.title_en,
    c.title_nl,
    c.title_fr,
    c.profile,
    c.path,
    gc.geographic_coverage,
    gc.min_lon,
    gc.max_lon,
    gc.min_lat,
    gc.max_lat,
        CASE
            WHEN tc.date_from = 'xxxx-xx-xx'::text THEN NULL::text
            ELSE tc.date_from
        END AS start_date,
        CASE
            WHEN tc.date_to = 'xxxx-xx-xx'::text THEN NULL::text
            ELSE tc.date_to
        END AS end_date,
    coc.class_taxonomic_coverage,
    coc.order_taxonomic_coverage,
    'natural history collection, RBINS, DaRWIN, '::text || c.name::text AS keywords,
    'Royal Belgian Institute for Natural Sciences'::text AS institute_name,
    'Department of '::text AS institute_dept_abbrev,
    (curator.given_name::text || ' '::text) || curator.family_name::text AS boss,
    uc1.entry AS boss_email,
    'curator'::text AS boss_role,
    (staff.given_name::text || ' '::text) || staff.family_name::text AS subboss,
    uc2.entry AS subboss_email,
    'Collection manager'::text AS subboss_role
   FROM darwin2.collections c
     LEFT JOIN specimen_info si ON c.id = si.id
     LEFT JOIN darwin2.users curator ON c.main_manager_ref = curator.id
     LEFT JOIN darwin2.users_comm uc1 ON uc1.person_user_ref = curator.id AND uc1.comm_type::text = 'e-mail'::text
     LEFT JOIN darwin2.users staff ON c.staff_ref = staff.id
     LEFT JOIN darwin2.users_comm uc2 ON uc2.person_user_ref = staff.id AND uc2.comm_type::text = 'e-mail'::text
     LEFT JOIN children_geographic_coverage gc ON gc.id = c.id
     LEFT JOIN children_temporal_coverage tc ON tc.id = c.id
     LEFT JOIN classes_orders_coverage2 coc ON coc.id = c.id
     LEFT JOIN species_coverage sc ON sc.id = c.id
  WHERE c.publish_to_gbif = true;

ALTER TABLE mv_eml
  OWNER TO darwin2;
  
-- DROP MATERIALIZED VIEW mv_eml_marine;

CREATE MATERIALIZED VIEW mv_eml_marine AS 
SELECT  replace(abstract,'(mostly species).', '(mostly species). This dataset only contains the marine species of the collection.'),
scope,
    nb_spec,
    nb_species,
    ig_num,
    id,
    name,
    existing_code,
    code,
    title_en,
    title_nl,
    title_fr,
    profile,
    geographic_coverage,
    min_lon,
    max_lon,
    min_lat,
    max_lat,
    end_date,
    class_taxonomic_coverage,
    order_taxonomic_coverage,
    keywords,
    institute_name,
    institute_dept_abbrev,
    boss,
    boss_email,
    boss_role,
    subboss,
    subboss_email,
    subboss_role from mv_eml where profile @> ARRAY['isMarine'::text];

ALTER TABLE mv_eml_marine
  OWNER TO darwin2;
  
set search_path to darwin2,public;

--drop materialized view mv_darwin_ipt_rbins;
--drop view v_darwin_ipt_rbins;
--DROP FUNCTION DMS2DD(strDegMinSec text);
CREATE OR REPLACE FUNCTION DMS2DD(strDegMinSec text)
	RETURNS double precision
	AS
	$$
	DECLARE
		i				numeric;
		j				numeric;
		intDmsLen		numeric;		  -- Length of original string
		strCompassPoint Char(1);
		strNorm		 varchar(32) = ''; -- Will contain normalized string
		strDegMinSecB	varchar(100);
		blnGotSeparator integer;		  -- Keeps track of separator sequences
		arrDegMinSec	varchar[];		-- TYPE stringarray is table of varchar(2048) ;
		dDeg			numeric := 0;
		dMin			numeric := 0;
		dSec			numeric := 0;
		strChr		  Char(1);
	BEGIN
		if strDegMinSec is null or strDegMinSec='' or strDegMinSec=' ' then 
			return null; 
		elsif  strDegMinSec ~ '^\d+(\.\d+)?$' then
			return trunc(strDegMinSec::numeric,10)::double precision;
		else 
		-- Remove leading and trailing spaces
		strDegMinSecB := REPLACE(strDegMinSec,' ','');
		-- assume no leading and trailing spaces?
		intDmsLen := Length(strDegMinSecB);

		blnGotSeparator := 0; -- Not in separator sequence right now

		-- Loop over string, replacing anything that is not a digit or a
		-- decimal separator with
		-- a single blank
		FOR i in 1..intDmsLen LOOP
		  -- Get current character
		  strChr := SubStr(strDegMinSecB, i, 1);

		  -- either add character to normalized string or replace
		  -- separator sequence with single blank		 
		  If strpos('-0123456789,.', strChr) > 0 Then
			 -- add character but replace comma with point
			 If (strChr <> ',') Then
				strNorm := strNorm || strChr;
			 Else
				strNorm := strNorm || '.';
			 End If;
			 blnGotSeparator := 0;
		  ElsIf strpos('neswNESW',strChr) > 0 Then -- Extract Compass Point if present
			strCompassPoint := strChr;
		  Else
			 -- ensure only one separator is replaced with a blank -
			 -- suppress the rest
			 If blnGotSeparator = 0 Then
				strNorm := strNorm || ' ';
				blnGotSeparator := 0;
			 End If;
		  End If;
		End Loop;

		-- Split normalized string into array of max 3 components
		arrDegMinSec := string_to_array(strNorm, ' ');
--	  raise notice 'array: %',arrDegMinSec;
		--convert specified components to double
		i := array_upper(arrDegMinSec,1);
--	raise notice 'i: %',i;
		j:=1;
		If i >= j and arrDegMinSec[j] <> '' Then
		  dDeg := CAST(arrDegMinSec[j] AS numeric);
		End If;
		j:=2;
		If i >= j and arrDegMinSec[j] <> '' Then
		  dMin := CAST(arrDegMinSec[j] AS numeric);
		End If;
		j:=3;
		If i >= j and arrDegMinSec[j] <> '' Then --if I'm at position 3+
		  dSec := CAST(arrDegMinSec[j] AS numeric);
		End If;

		-- convert components to value
		return trunc(CASE WHEN UPPER(strCompassPoint) IN ('S','W') 
					THEN -1 
					ELSE 1 
				END 
				*
				(dDeg + dMin / 60 + dSec / 3600),10)::double precision;
	end if;
	End 
$$
	LANGUAGE 'plpgsql' IMMUTABLE;

CREATE OR REPLACE FUNCTION darwin2.cleanupDMS(dms_string text)
  RETURNS text AS
$$
BEGIN
if  dms_string ~ '^\d+(\.\d+)?$' then
	return dms_string;
end if;
	dms_string := replace(dms_string,'’','''');
	dms_string := replace(dms_string,',','.');
	dms_string := replace(dms_string,'º','°');
	dms_string := replace(dms_string,' ','');
	dms_string := replace(dms_string,'''''','"');
	dms_string := regexp_replace(dms_string,'^0','');
	dms_string := regexp_replace(dms_string,'^°(\d*)?\.','\1°');
	dms_string := regexp_replace(dms_string,'(\d*)?°(\d*)?''([NEWS])$','\1°\2''00"\3');
	dms_string := trim(dms_string);
	dms_string := trim(dms_string, chr(160));
return dms_string;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE
SECURITY DEFINER
  COST 10;



drop materialized view if exists mv_spatial;
create materialized view mv_spatial as
 WITH 
property_mess_cte as (
select * from (values
	('Accuracy coordinates','coordinatePrecision'),
	('Accuracy Coordinates','coordinatePrecision'),
	('coordinates_original','verbatimCoordinates'),
	('datum','datum'),
	('ellipsoid','ellipsoid'),
	('geo position','verbatimCoordinates'),
('gis_type','spatial_type'),
('km (offset from named place)','offset_from_location'),
	('Lambert','lambert_coordinates_x_y'),
	('latitude','decimal_latitude'),
	('latitude1','decimal_start_latitude'),
	('latitude2','decimal_end_latitude'),
	('Latitude DMS (end of operation)','end_latitude'),
	('Latitude DMS (start of operation)','start_latitude'),
('Locality','verbatimLocality'),
	('longitude','decimal_longitude'),
	('longitude1','decimal_start_longitude'),
	('longitude2','decimal_end_longitude'),
	('Longitude DMS (end of operation)','end_longitude'),
	('Longitude DMS (start of operation)','start_longitude'),
('Named Place','verbatimLocality'),
('utm','utm_grid')
) as map(orig_property,mapped_property)
),
 coordinates_cte
	 AS (SELECT distinct record_id,
				mapped_property as property,
				lower_value as value,
				applies_to
		 FROM	darwin2.properties
	 LEFT JOIN property_mess_cte cte on cte.orig_property=properties.property_type
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
'utm') ORDER  BY record_id, mapped_property)
select distinct on (gtu_ref) gtu_ref,source, decimal_start_latitude,decimal_start_longitude,decimal_end_latitude,decimal_end_longitude,datum,ellipsoid,verbatim_coordinates,coordinate_precision,lambert_coordinates_x_y from (
SELECT distinct gtu.id as gtu_ref,
'1_prop_start_end_dms' as source,
		case when start_longitude.value is null then null else DMS2DD(cleanupDMS(start_latitude.value)) end AS decimal_start_latitude,
		case when start_latitude.value is null then null else DMS2DD(cleanupDMS(start_longitude.value)) end AS decimal_start_longitude,
		case when end_longitude.value is null or end_latitude.value = start_latitude.value then null else DMS2DD(cleanupDMS(end_latitude.value)) end as decimal_end_latitude,
		case when end_latitude.value is null or end_longitude.value = start_longitude.value then null else DMS2DD(cleanupDMS(end_longitude.value)) end as decimal_end_longitude,
		datum.value as datum,
		ellipsoid.value as ellipsoid,
		verbatim_coordinates.value as verbatim_coordinates,
		coordinate_precision.value as coordinate_precision, 
		lambert_coordinates_x_y.value as lambert_coordinates_x_y
FROM	gtu
		left join coordinates_cte AS start_latitude ON gtu.id=start_latitude.record_id and start_latitude.property = 'start_latitude'
		left join coordinates_cte AS end_latitude ON gtu.id = end_latitude.record_id AND end_latitude.property = 'end_latitude'  
		left join coordinates_cte AS start_longitude ON gtu.id = start_longitude.record_id AND start_longitude.property = 'start_longitude' 
		left join coordinates_cte AS end_longitude ON gtu.id = end_longitude.record_id AND end_longitude.property = 'end_longitude' 	
		left join coordinates_cte AS datum ON gtu.id = datum.record_id AND datum.property = 'datum' 
		left join coordinates_cte AS ellipsoid ON gtu.id = ellipsoid.record_id AND ellipsoid.property = 'ellipsoid' 	
		left join coordinates_cte AS verbatim_coordinates ON gtu.id = verbatim_coordinates.record_id AND verbatim_coordinates.property = 'verbatimCoordinates' 
		left join coordinates_cte AS coordinate_precision ON gtu.id = coordinate_precision.record_id AND coordinate_precision.property = 'coordinatePrecision'
		left join coordinates_cte AS lambert_coordinates_x_y ON gtu.id = lambert_coordinates_x_y.record_id AND lambert_coordinates_x_y.property = 'lambert_coordinates_x_y'
WHERE start_latitude.value is not null
union
SELECT distinct gtu.id as gtu_ref,
'1_prop_start_end' as source,
		case when decimal_start_longitude.value is null then null else DMS2DD(cleanupDMS(decimal_start_latitude.value)) end as decimal_start_latitude,
		case when decimal_start_latitude.value is null then null else DMS2DD(cleanupDMS(decimal_start_longitude.value)) end as decimal_start_longitude,
		case when decimal_end_longitude.value is null or decimal_end_latitude.value = decimal_start_latitude.value then null else DMS2DD(cleanupDMS(decimal_end_latitude.value)) end as decimal_end_latitude,
		case when decimal_end_latitude.value is null or decimal_end_longitude.value = decimal_start_longitude.value then null else DMS2DD(cleanupDMS(decimal_end_longitude.value)) end as decimal_end_longitude,
		datum.value as datum,
		ellipsoid.value as ellipsoid,
		verbatim_coordinates.value as verbatim_coordinates,
		coordinate_precision.value as coordinate_precision, 
		lambert_coordinates_x_y.value as lambert_coordinates_x_y 
FROM	gtu		
		left join coordinates_cte AS decimal_start_latitude ON gtu.id = decimal_start_latitude.record_id AND decimal_start_latitude.property = 'decimal_start_latitude' 
		left join coordinates_cte AS decimal_start_longitude ON gtu.id = decimal_start_longitude.record_id AND decimal_start_longitude.property = 'decimal_start_longitude' 
		left join coordinates_cte AS decimal_end_latitude ON gtu.id = decimal_end_latitude.record_id AND decimal_end_latitude.property = 'decimal_end_latitude' 
		left join coordinates_cte AS decimal_end_longitude ON gtu.id = decimal_end_longitude.record_id AND decimal_end_longitude.property = 'decimal_end_longitude' 	
		left join coordinates_cte AS datum ON gtu.id = datum.record_id AND datum.property = 'datum' 	
		left join coordinates_cte AS ellipsoid ON gtu.id = ellipsoid.record_id AND ellipsoid.property = 'ellipsoid' 
		left join coordinates_cte AS verbatim_coordinates ON gtu.id = verbatim_coordinates.record_id AND verbatim_coordinates.property = 'verbatimCoordinates' 
		left join coordinates_cte AS coordinate_precision ON gtu.id = coordinate_precision.record_id AND coordinate_precision.property = 'coordinatePrecision' 
		left join coordinates_cte AS lambert_coordinates_x_y ON gtu.id = lambert_coordinates_x_y.record_id AND lambert_coordinates_x_y.property = 'lambert_coordinates_x_y'
WHERE decimal_start_latitude.value is not null
union
SELECT distinct gtu.id as gtu_ref,
'2_prop_lat_long' as source,
		case when decimal_longitude.value is null then null else DMS2DD(cleanupDMS(decimal_latitude.value)) end as decimal_latitude,
		case when decimal_latitude.value is null then null else DMS2DD(cleanupDMS(decimal_longitude.value)) end as decimal_longitude,
		null::numeric,
		null::numeric,
		datum.value as datum,
		ellipsoid.value as ellipsoid,
		verbatim_coordinates.value as verbatim_coordinates,
		coordinate_precision.value as coordinate_precision, 
		lambert_coordinates_x_y.value as lambert_coordinates_x_y
FROM	gtu		
		left join coordinates_cte AS decimal_latitude ON gtu.id = decimal_latitude.record_id AND decimal_latitude.property = 'decimal_latitude' 
		left join coordinates_cte AS decimal_longitude ON gtu.id = decimal_longitude.record_id AND decimal_longitude.property = 'decimal_longitude' 
		left join coordinates_cte AS datum ON gtu.id = datum.record_id AND datum.property = 'datum' 	
		left join coordinates_cte AS ellipsoid ON gtu.id = ellipsoid.record_id AND ellipsoid.property = 'ellipsoid' 
		left join coordinates_cte AS verbatim_coordinates ON gtu.id = verbatim_coordinates.record_id AND verbatim_coordinates.property = 'verbatimCoordinates'
		left join coordinates_cte AS coordinate_precision ON gtu.id = coordinate_precision.record_id AND coordinate_precision.property = 'coordinatePrecision' 
		left join coordinates_cte AS lambert_coordinates_x_y ON gtu.id = lambert_coordinates_x_y.record_id AND lambert_coordinates_x_y.property = 'lambert_coordinates_x_y'
WHERE decimal_latitude.value is not null
union
SELECT distinct gtu.id as gtu_ref,
'3_gtu_lat_long' as source,
		trunc(gtu.latitude::numeric,10)::double precision,
		trunc(gtu.longitude::numeric,10)::double precision,
		null::numeric,
		null::numeric,
		datum.value as datum,
		ellipsoid.value as ellipsoid,
		string_agg(verbatim_coordinates.value,', ') as verbatim_coordinates,
		string_agg(coordinate_precision.value,', ') as coordinate_precision, 
		string_agg(lambert_coordinates_x_y.applies_to||': '||lambert_coordinates_x_y.value,', ' order by lambert_coordinates_x_y.applies_to) as lambert_coordinates_x_y 
FROM	gtu 
		left join coordinates_cte AS datum ON gtu.id = datum.record_id AND datum.property = 'datum' 	
		left join coordinates_cte AS ellipsoid ON gtu.id = ellipsoid.record_id AND ellipsoid.property = 'ellipsoid' 
		left join coordinates_cte AS verbatim_coordinates ON gtu.id = verbatim_coordinates.record_id AND verbatim_coordinates.property = 'verbatimCoordinates'
		left join coordinates_cte AS coordinate_precision ON gtu.id = coordinate_precision.record_id AND coordinate_precision.property = 'coordinatePrecision' 
		left join coordinates_cte AS lambert_coordinates_x_y ON gtu.id = lambert_coordinates_x_y.record_id AND lambert_coordinates_x_y.property = 'lambert_coordinates_x_y' 
where gtu.latitude is not null or verbatim_coordinates is not null
group by id,trunc(gtu.latitude::numeric,10), trunc(gtu.longitude::numeric,10), datum.value,ellipsoid.value

) q
order by gtu_ref,source, decimal_start_latitude,decimal_start_longitude, decimal_end_latitude asc,decimal_end_longitude asc --this ensures that preference is taken for gtus that have an end coordinate, and that locational info from gtu is not considered if there is locational information found in the properties

/*
Rationale for not including the gtu location information if ot is different from the locations calculated from the infortmation in properties:

set search_path to darwin2,public;

select gtu.id,gtu.code,p.lower_value, gtu.location, mv_spatial.source,mv_spatial.decimal_start_latitude, gtu.latitude, mv_spatial.decimal_start_longitude, gtu.longitude from 
mv_spatial left join gtu on id=gtu_ref 
left join properties p on p.record_id=gtu.id
where mv_spatial.decimal_start_latitude <> gtu.latitude
order by gtu.id

The query returns many wrong coordinates being stored in gtu
*/
