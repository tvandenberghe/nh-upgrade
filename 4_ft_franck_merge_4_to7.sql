set search_path to darwin2,public;
set search_path to darwin2,public;
CREATE TABLE IF NOT EXISTS property_type (
id serial NOT NULL, --
type character varying NOT NULL,
CONSTRAINT property_type_pk PRIMARY KEY (id),
CONSTRAINT type_uq UNIQUE (type)
);

CREATE TABLE IF NOT EXISTS property_tag_authority (
tag_authority_ref bigint NOT NULL, 
property_type_id bigint NOT NULL,
tag_authority_match_predicate text NOT NULL,
CONSTRAINT property_tag_authority_pk PRIMARY KEY (tag_authority_ref, property_type_id, tag_authority_match_predicate),
CONSTRAINT fk_property_authority_auth FOREIGN KEY (tag_authority_ref)
      REFERENCES darwin2.tag_authority (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT fk_property_authority_prop FOREIGN KEY (property_type_id)
      REFERENCES darwin2.tag_group_distinct (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT chk_predicate_onto CHECK (tag_authority_match_predicate ~~ '%skos:%'::text OR tag_authority_match_predicate ~~ '%owl:%'::text)
);

ALTER TABLE darwin2.properties ADD COLUMN property_type_ref bigint, 
ADD CONSTRAINT fk_property_type_id FOREIGN KEY (property_type_ref) REFERENCES property_type(id);

insert into authority_domain (name, website_url, webservice_root, webservice_format) values ('nerc.ac.uk', 'http://vocab.nerc.ac.uk','http://vocab.nerc.ac.uk/sparql/','text, json, xml, csv, tsv') on conflict (name) do nothing;
insert into authority_domain (name, website_url, webservice_root, webservice_format) values ('wikidata.org', 'https://www.wikidata.org','https://query.wikidata.org/','text, json, xml, csv, tsv') on conflict (name) do nothing;
insert into authority_domain (name, website_url, webservice_root, webservice_format) values ('obolibrary.org', 'https://www.obolibrary.org','http://www.ontobee.org/sparql','text, json, xml, csv, tsv') on conflict (name) do nothing;

insert into property_type (type) values('sampling_elevation') on conflict (type) do nothing; --
insert into property_type (type) values('bottom_depth') on conflict (type) do nothing;
insert into property_type (type) values('core_depth_end') on conflict (type) do nothing;
insert into property_type (type) values('core_depth_start') on conflict (type) do nothing;
insert into property_type (type) values('sampling_gear') on conflict (type) do nothing;
insert into property_type (type) values('meteorite_fall_or_find') on conflict (type) do nothing;
insert into property_type (type) values('preparation') on conflict (type) do nothing; --
insert into property_type (type) values('preparator') on conflict (type) do nothing;
insert into property_type (type) values('sampling_depth') on conflict (type) do nothing; --
insert into property_type (type) values('sampling_depth_end') on conflict (type) do nothing; --
insert into property_type (type) values('sampling_depth_max') on conflict (type) do nothing; --
insert into property_type (type) values('sampling_depth_min') on conflict (type) do nothing; --
insert into property_type (type) values('sampling_depth_start') on conflict (type) do nothing; --
insert into property_type (type) values('sampling_elevation_end') on conflict (type) do nothing;
insert into property_type (type) values('sampling_elevation_max') on conflict (type) do nothing;
insert into property_type (type) values('sampling_elevation_min') on conflict (type) do nothing;
insert into property_type (type) values('sampling_elevation_start') on conflict (type) do nothing;
insert into property_type (type) values('trap_bait') on conflict (type) do nothing;
insert into property_type (type) values('trap_bait_status') on conflict (type) do nothing;
insert into property_type (type) values('trap_details') on conflict (type) do nothing;
insert into property_type (type) values('verbatimLocality') on conflict (type) do nothing;
insert into property_type (type) values('quality') on conflict (type) do nothing;
insert into property_type (type) values('body_length') on conflict (type) do nothing;
insert into property_type (type) values('body_weight') on conflict (type) do nothing;


INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label,definition) values ((select id from authority_domain where name='nerc.ac.uk'),null,'http://vocab.nerc.ac.uk/collection/P01/current/ADEPZZ01/','SDN:P01::ADEPZZ01','DepBelowSurf',ARRAY['P01'],'Depth (spatial coordinate) relative to water surface in the water body','The distance of a sensor or sampling point below the sea surface') on conflict (domain_ref, url) do nothing returning id; 
INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label,definition) values ((select id from authority_domain where name='nerc.ac.uk'),null,'http://vocab.nerc.ac.uk/collection/P01/current/MAXWDIST/','SDN:P01::MAXWDIST','MaxDepBelowSeaSurf',ARRAY['P01'],'Depth (spatial coordinate) maximum relative to water surface in the water body','The maximum distance between an underwater sampling or measuring activity and the sea surface.') on conflict (domain_ref, url) do nothing returning id; 
INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label,definition) values ((select id from authority_domain where name='nerc.ac.uk'),null,'http://vocab.nerc.ac.uk/collection/P01/current/MINWDIST/','SDN:P01::MINWDIST','MinDepBelowSeaSurf',ARRAY['P01'],'Depth (spatial coordinate) minimum relative to water surface in the water body','The minimum distance between an underwater sampling or measuring activity and the sea surface.') on conflict (domain_ref, url) do nothing returning id; 
INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label,definition) values ((select id from authority_domain where name='nerc.ac.uk'),null,'http://vocab.nerc.ac.uk/collection/Q01/current/Q0100004/','SDN:Q01::Q0100004',null,ARRAY['Q01'],'Sample preservation method','The name or description of the method used to preserve the sample after collection and prior to the analysis.') on conflict (domain_ref, url) do nothing returning id; 
INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label,definition) values ((select id from authority_domain where name='nerc.ac.uk'),null,'http://vocab.nerc.ac.uk/collection/Q01/current/Q0100002/','SDN:Q01::Q0100002',null,ARRAY['Q01'],'Sampling instrument name','The name of the gear or instrument used to collect the sample or make the in-situ measurement or observation.') on conflict (domain_ref, url) do nothing returning id; 
INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label,definition) values ((select id from authority_domain where name='wikidata.org'),null,'https://www.wikidata.org/wiki/Q2633778',null,'Q2633778',null,'elevation','height above a fixed reference point') on conflict (domain_ref, url) do nothing returning id; 
INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label,definition) values ((select id from authority_domain where name='obolibrary.org'),null,'http://purl.obolibrary.org/obo/PATO_0000128',null,'PATO_0000128',null,'weight','A physical quality inhering in a bearer that has mass near a gravitational body.') on conflict (domain_ref, url) do nothing returning id; 
INSERT INTO TAG_AUTHORITY (domain_ref,source,url,urn,code,type,pref_label,definition) values ((select id from authority_domain where name='obolibrary.org'),null,'http://purl.obolibrary.org/obo/PATO_0000122',null,'PATO_0000122',null,'length','A 1-D extent quality which is equal to the distance between two points.') on conflict (domain_ref, url) do nothing returning id; 

insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:exactMatch', pt.id from tag_authority ta,property_type pt where ta.urn='SDN:P01::ADEPZZ01' and pt.type='sampling_depth' ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;
insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:exactMatch', pt.id from tag_authority ta, property_type pt where ta.urn='SDN:Q01::Q0100004' and pt.type='preparation' ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;
insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:exactMatch', pt.id from tag_authority ta, property_type pt where ta.urn='SDN:Q01::Q0100002' and pt.type='sampling_gear' ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;
insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:exactMatch', pt.id from tag_authority ta, property_type pt where ta.code='Q2633778' and pt.type='sampling_elevation' ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;
insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:broadMatch', pt.id from tag_authority ta, property_type pt where ta.urn='SDN:P01::ADEPZZ01' and pt.type in ('sampling_depth_end', 'sampling_depth_start') ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;
insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:exactMatch', pt.id from tag_authority ta, property_type pt where ta.urn='SDN:P01::MAXWDIST' and pt.type = 'sampling_depth_max' ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;
insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:exactMatch', pt.id from tag_authority ta, property_type pt where ta.urn='SDN:P01::MINWDIST' and pt.type = 'sampling_depth_min' ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;
insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:exactMatch', pt.id from tag_authority ta, property_type pt where ta.code='PATO_0000128' and pt.type = 'body_weight' ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;
insert into property_tag_authority (tag_authority_ref, tag_authority_match_predicate, property_type_id) select ta.id, 'skos:exactMatch', pt.id from tag_authority ta, property_type pt where ta.code='PATO_0000122' and pt.type = 'body_length' ON CONFLICT (tag_authority_ref, property_type_id, tag_authority_match_predicate) DO NOTHING;


ALTER TABLE darwin2.properties DISABLE TRIGGER fct_cpy_trg_del_dict_properties;
ALTER TABLE darwin2.properties DISABLE TRIGGER fct_cpy_trg_ins_update_dict_properties;
ALTER TABLE darwin2.properties DISABLE TRIGGER trg_chk_ref_record_properties;
ALTER TABLE darwin2.properties DISABLE TRIGGER trg_cpy_fulltoindex_properties;
ALTER TABLE darwin2.properties DISABLE TRIGGER trg_cpy_unified_values;
ALTER TABLE darwin2.properties DISABLE TRIGGER trg_trk_log_table_properties;

update properties set property_type_ref=(select id from property_type where type='sampling_elevation') where property_type='altitude';
update properties set property_type_ref=(select id from property_type where type='bottom_depth') where property_type='depth_bottom';
update properties set property_type_ref=(select id from property_type where type='core_depth_end') where property_type='einddiepte';
update properties set property_type_ref=(select id from property_type where type='core_depth_start') where property_type='startdiepte';
update properties set property_type_ref=(select id from property_type where type='sampling_gear') where property_type='Gear ';
update properties set property_type_ref=(select id from property_type where type='sampling_gear') where property_type='gear_code';
update properties set property_type_ref=(select id from property_type where type='sampling_gear') where property_type='gear_comments';
update properties set property_type_ref=(select id from property_type where type='sampling_gear') where property_type='gear_name';
update properties set property_type_ref=(select id from property_type where type='meteorite_fall_or_find') where property_type='fall / find';
update properties set property_type_ref=(select id from property_type where type='meteorite_fall_or_find') where property_type='fall/find';
update properties set property_type_ref=(select id from property_type where type='meteorite_fall_or_find') where property_type='Fall or find';
update properties set property_type_ref=(select id from property_type where type='preparation') where property_type='Preparation';
update properties set property_type_ref=(select id from property_type where type='preparation') where property_type='Preparation method';
update properties set property_type_ref=(select id from property_type where type='preparation') where property_type='Preparation Notes';
update properties set property_type_ref=(select id from property_type where type='preparator') where property_type='Preparator';
update properties set property_type_ref=(select id from property_type where type='sampling_depth') where property_type='Depth';
update properties set property_type_ref=(select id from property_type where type='sampling_depth') where property_type='Depth';
update properties set property_type_ref=(select id from property_type where type='sampling_depth_end') where property_type='sampling_depth_end';
update properties set property_type_ref=(select id from property_type where type='sampling_depth_max') where property_type='maxium Depth';
update properties set property_type_ref=(select id from property_type where type='sampling_depth_min') where property_type='minimum Depth';
update properties set property_type_ref=(select id from property_type where type='sampling_depth_start') where property_type='sampling_depth_start';
update properties set property_type_ref=(select id from property_type where type='sampling_elevation_end') where property_type='sampling_elevation_end';
update properties set property_type_ref=(select id from property_type where type='sampling_elevation_max') where property_type='maxium Elevation';
update properties set property_type_ref=(select id from property_type where type='sampling_elevation_min') where property_type='minimum Altitute';
update properties set property_type_ref=(select id from property_type where type='sampling_elevation_min') where property_type='minimum Elevation';
update properties set property_type_ref=(select id from property_type where type='sampling_elevation_start') where property_type='sampling_elevation_start';
update properties set property_type_ref=(select id from property_type where type='trap_bait') where property_type='trap_bait';
update properties set property_type_ref=(select id from property_type where type='trap_bait_status') where property_type='trap_bait_status';
update properties set property_type_ref=(select id from property_type where type='trap_details') where property_type='trap_comments';
update properties set property_type_ref=(select id from property_type where type='verbatimLocality') where property_type='Name';
update properties set property_type_ref=(select id from property_type where type='quality') where property_type='freshness level';
update properties set property_type_ref=(select id from property_type where type='body_length') where property_type='length';
update properties set property_type_ref=(select id from property_type where type='body_length') where property_type='Size';
update properties set property_type_ref=(select id from property_type where type='body_weight') where property_type='weight';

ALTER TABLE darwin2.properties ENABLE TRIGGER fct_cpy_trg_del_dict_properties;
ALTER TABLE darwin2.properties ENABLE TRIGGER fct_cpy_trg_ins_update_dict_properties;
ALTER TABLE darwin2.properties ENABLE TRIGGER trg_chk_ref_record_properties;
ALTER TABLE darwin2.properties ENABLE TRIGGER trg_cpy_fulltoindex_properties;
ALTER TABLE darwin2.properties ENABLE TRIGGER trg_cpy_unified_values;
ALTER TABLE darwin2.properties ENABLE TRIGGER trg_trk_log_table_properties;

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
create materialized view ipt.mv_spatial as
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

order by gtu_ref,source asc, decimal_start_latitude,decimal_start_longitude, decimal_end_latitude asc,decimal_end_longitude asc 
;
--this ensures that preference is taken for gtus that have an end coordinate, and that locational info from gtu is not considered if there is locational information found in the properties

/*
Rationale for not including the gtu location information if ot is different from the locations calculated from the infortmation in properties:

set search_path to darwin2,public;

select gtu.id,gtu.code,p.lower_value, gtu.location, mv_spatial.source,mv_spatial.decimal_start_latitude, gtu.latitude, mv_spatial.decimal_start_longitude, gtu.longitude from 
mv_spatial left join gtu on id=gtu_ref 
left join properties p on p.record_id=gtu.id
where mv_spatial.decimal_start_latitude <> gtu.latitude
order by gtu.id

set search_path to darwin2,public;

select gtu.id,gtu.code,p.lower_value, gtu.location, mv_spatial.source,round(mv_spatial.decimal_start_latitude::numeric,7), round(gtu.latitude::numeric,7) as gtu_latitude, round(mv_spatial.decimal_start_longitude::numeric,7), round(gtu.longitude::numeric,7) as gtu_longitude from 
mv_spatial left join gtu on id=gtu_ref 
left join properties p on p.record_id=gtu.id
where round(mv_spatial.decimal_start_latitude::numeric,1) <> round(gtu.latitude::numeric,1)
order by gtu.id

The query returns many wrong coordinates being stored in gtu
*/

set search_path to darwin2,public;
CREATE OR REPLACE FUNCTION darwin2.cleanup_sample_properties(dms_string text)
  RETURNS text AS
$$
BEGIN
	if dms_string = '' then
		dms_string=null;
	end if;
	dms_string := trim(dms_string);
	dms_string := trim(dms_string, chr(160));
	dms_string := regexp_replace(dms_string,'^(\d+)?,(\d+)$','\1.\2');
	dms_string := replace(dms_string,' - ','-');
	dms_string := replace(dms_string,' - ','-');
	dms_string := regexp_replace(dms_string,'^(\d+)? to (\d+)$','\1-\2');
	dms_string := regexp_replace(dms_string,'^(\d+)\.0+$','\1');
return dms_string;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE
SECURITY DEFINER
  COST 10;

drop materialized view if exists ipt.mv_darwin_ipt_rbins CASCADE;
drop view if exists ipt.v_darwin_ipt_rbins;
drop materialized view if exists ipt.mv_darwin_ipt_rbins_mof;
drop view if exists ipt.v_darwin_ipt_rbins_mof;
drop materialized view if exists ipt.mv_properties;
create materialized view ipt.mv_properties as (
SELECT distinct 'gtu' as source,  record_id as gtu_ref,s.id as specimen_ref, p.property_type as property_type_id_sloppy, pt.type as property_type_id_internal, au.url as property_type_id, cleanup_sample_properties(lower_value) as value, 
case when pt.type like 'sampling_depth%' then 'm' when pt.type like 'sampling_elevation%' then 'm' when property_unit='' then null else property_unit end as unit
FROM darwin2.properties p
LEFT JOIN property_type pt on pt.id=p.property_type_ref
LEFT JOIN property_tag_authority pau on pt.id=pau.property_type_id
LEFT JOIN tag_authority au on au.id=pau.tag_authority_ref
LEFT JOIN darwin2.gtu on gtu.id=record_id
LEFT JOIN darwin2.specimens s on s.gtu_ref = gtu.id
WHERE referenced_relation = 'gtu' AND lower_value <> 'BLABLA' AND pt.type IN (
'sampling_elevation',
'sampling_depth',
'bottom_depth',
'sampling_gear',
'sampling_elevation_max',
'sampling_elevation_min',
'sampling_elevation_start',
'sampling_elevation_end',
'sampling_depth_max',
'sampling_depth_min',
'sampling_depth_start',
'sampling_depth_end',
'trap_bait',
'trap_bait_status',
'trap_details')
union
select 'specimens' as source, gtu_ref, specimen_ref, property_type_id_sloppy,property_type_id_internal, property_type_id, string_agg(distinct value,'; '), unit from (
SELECT distinct null::integer as gtu_ref, record_id as specimen_ref, p.property_type as property_type_id_sloppy, pt.type as property_type_id_internal, au.url as property_type_id, cleanup_sample_properties(lower_value) as value, 
case when property_unit='' then null when pt.type like 'sampling_depth%' then 'm' else property_unit end as unit
FROM darwin2.properties p
LEFT JOIN property_type pt on pt.id=p.property_type_ref
LEFT JOIN property_tag_authority pau on pt.id=pau.property_type_id
LEFT JOIN tag_authority au on au.id=pau.tag_authority_ref
LEFT JOIN darwin2.specimens s on s.id=record_id
WHERE  referenced_relation = 'specimens' AND pt.type IN (
'sampling_depth',
'core_depth_start',
'core_depth_end',
'meteorite_fall_or_find',
'meteorite_fall_or_find',
'meteorite_fall_or_find',
'verbatimLocality',
'preparation',
'preparator',
'quality',
'body_length', --'physical measurement'
'body_weight')) q group by gtu_ref,specimen_ref,property_type_id_sloppy, property_type_id_internal,property_type_id, unit)
;

drop materialized view if exists ipt.mv_darwin_ipt_rbins_mof;
drop view if exists ipt.v_darwin_ipt_rbins_mof;

create view ipt.v_darwin_ipt_rbins_mof as 

with sampling_depth_range_cte as (
select distinct 'prop_depth_range_'||source as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, null,property_type_id_internal as measurement_type,property_type_id, 
value,value as orig_value, 'm'::text as measurement_unit
from ipt.mv_properties
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
from ipt.mv_properties
where property_type_id_internal='sampling_depth' and value ~ '^\d+$' and cast(value as double precision) <=10000

union

select distinct 'elevation_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, 'm'::text as measurement_unit
from ipt.mv_properties
where property_type_id_internal='sampling_elevation' and value ~ '^\d+$' and cast(value as double precision) <=8000

union

select distinct 'length_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, unit as measurement_unit
from ipt.mv_properties
where property_type_id_internal='body_length' and unit is not null and value not like '%ha%'

union

select distinct 'weight_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, unit as measurement_unit
from ipt.mv_properties
where property_type_id_internal='body_weight' and unit is not null

union

select distinct 'sampling_gear_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, unit as measurement_unit
from ipt.mv_properties
where property_type_id_internal='sampling_gear'

union

select distinct 'else_'||source||'_prop' as source, 'http://collections.naturalsciences.be/specimen/'::text || specimen_ref::character varying::text AS occurrence_id, 
property_type_id_internal as measurement_type,property_type_id as measurement_type_id, value as measurement_value, value as orig_value, unit as measurement_unit
from ipt.mv_properties
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

create materialized view ipt.mv_darwin_ipt_rbins_mof as select * from ipt.v_darwin_ipt_rbins_mof;

--where (measurement_type like '%elevation%' and cast(measurement_value as double precision) <=8800) or (measurement_type like '%depth%' and cast(measurement_value as double precision) <=11000) or measurement_type not like '%elevation%' or measurement_type not like '%depth%'


CREATE OR REPLACE FUNCTION darwin2.fct_mask_date(
    date_fld timestamp without time zone,
    mask_fld integer)
  RETURNS text AS
$BODY$

  SELECT
CASE WHEN ($2 & 32)!=0 THEN date_part('year',$1)::text ELSE 'xxxx' END || '-' ||
CASE WHEN ($2 & 16)!=0 THEN lpad(date_part('month',$1)::text, 2, '0') ELSE 'xx' END || '-' ||
CASE WHEN ($2 & 8)!=0 THEN lpad(date_part('day',$1)::text, 2, '0') ELSE 'xx' END;
$BODY$
  LANGUAGE sql IMMUTABLE
  COST 100;
ALTER FUNCTION darwin2.fct_mask_date(timestamp without time zone, integer)
  OWNER TO darwin2;
  
--ALTER VIEW v_darwin_ipt_rbins RENAME TO v_darwin_ipt_rbins_old;

DROP MATERIALIZED VIEW IF EXISTS ipt.mv_darwin_ipt_rbins CASCADE;
DROP VIEW IF EXISTS ipt.v_darwin_ipt_rbins;
CREATE VIEW ipt.v_darwin_ipt_rbins AS 
 WITH taxonomy_authority_cte AS (
SELECT 	t.id AS taxonomy_ref,
        t.name,
        t.status as taxonomic_status,
        tp.name as parent_name_usage,
        taxa_gbif.url AS gbif_id,
        taxa_worms.urn AS worms_id,
        kingdom.name as kingdom,
        phylum.name as phylum,
        class.name as class,
        ordo.name as ordo,
        family.name as family,
        genus.name as genus,
        subgenus.name as subgenus,
        t2.specific_epithet,
        t2.infra_specific_epithet,
        case when t2.specific_epithet is not null then trim(substring(t.name from strpos(t.name, t2.specific_epithet)+char_length(t2.specific_epithet)+1)) else trim(substring(t.name from strpos(t.name, t2.infra_specific_epithet)+char_length(t2.infra_specific_epithet)+1)) end as scientific_name_authorship
        FROM taxonomy t
        LEFT JOIN taxonomy tp on tp.id=t.parent_ref
        LEFT JOIN (select t.id, case t.level_ref when 48 then split_part(t.name, ' ', 2) end as specific_epithet, case t.level_ref when 49 then split_part(t.name, ' ', 3) end as infra_specific_epithet from darwin2.taxonomy t) as t2 on t2.id=t.id
        LEFT JOIN taxonomy_authority taxa_gbif ON taxa_gbif.taxonomy_ref = t.id AND taxa_gbif.domain_ref = (( 
                  SELECT authority_domain.id
                  FROM authority_domain
                  WHERE authority_domain.name::text = 'gbif.org'::text))
        LEFT JOIN taxonomy_authority taxa_worms ON taxa_worms.taxonomy_ref = t.id AND taxa_worms.domain_ref = ((
                  SELECT authority_domain.id
                  FROM authority_domain
                  WHERE authority_domain.name::text = 'marinespecies.org'::text))
        LEFT JOIN darwin2.fct_get_tax_hierarchy(t.id, ARRAY[2]) kingdom on kingdom.r_start_id=t.id
        LEFT JOIN darwin2.fct_get_tax_hierarchy(t.id, ARRAY[4]) phylum on phylum.r_start_id=t.id
        LEFT JOIN darwin2.fct_get_tax_hierarchy(t.id, ARRAY[12]) class on class.r_start_id=t.id           
        LEFT JOIN darwin2.fct_get_tax_hierarchy(t.id, ARRAY[28]) ordo on ordo.r_start_id=t.id
        LEFT JOIN darwin2.fct_get_tax_hierarchy(t.id, ARRAY[34]) family on family.r_start_id=t.id
        LEFT JOIN darwin2.fct_get_tax_hierarchy(t.id, ARRAY[41]) genus on genus.r_start_id=t.id     
        LEFT JOIN darwin2.fct_get_tax_hierarchy(t.id, ARRAY[42]) subgenus on subgenus.r_start_id=t.id     
where t.level_ref = 48
order by 1
),
location_cte as (
select *,
case when ndwc_gtu_decimal_latitude is not null then 
	ndwc_gtu_decimal_latitude 
	else case when ndwc_tag_decimal_latitude is not null then ndwc_tag_decimal_latitude end
end as decimal_latitude,
case when ndwc_gtu_decimal_longitude is not null then 
	ndwc_gtu_decimal_longitude 
	else case when ndwc_tag_decimal_longitude is not null then ndwc_tag_decimal_longitude end
end as decimal_longitude,
case when ndwc_gtu_decimal_latitude is not null then 
	'Coordinates are based on original information found on the label or publication.' 
	else case when ndwc_tag_decimal_latitude is not null then 'No accurate coordinate information on the label. The coordinates have been geocoded from the location (see verbatimLocation) on the label by automated mapping+human verification to GeoNames.org ('||location||' maps to '||location_id||'). The mapping is done constrained by type and by country (if available), and assessed by probability. When multiple locations have been mapped for this specimen, the most precise is taken.' end 
end as georeference_remarks  
from (
select 
	gtu.id as gtu_ref,
	string_agg(DISTINCT tags.tag_value::text, ', '::text) AS verbatim_location,
	(array_agg(tag_geoname.gazetteer_pref_label::text ORDER BY tag_geoname.priority DESC, tag_geoname.geonames_type_mapped, tag_geoname.gazetteer_pref_label))[1] as location,--first the gazetteer labels with the highest priority
	string_agg(DISTINCT tag_geoname.gazetteer_pref_label::text, ', '::text) AS ndwc_nice_verbatim_location,
	(array_agg(tag_geoname.gazetteer_url ORDER BY tag_geoname.priority DESC, tag_geoname.geonames_type_mapped, tag_geoname.gazetteer_pref_label))[1] as location_id,--first the gazetteer urls with the highest priority
	array_agg(tag_geoname.geonames_type_mapped ORDER BY tag_geoname.priority ASC, tag_geoname.geonames_type_mapped, tag_geoname.gazetteer_pref_label) as ndwc_geotypes,
	string_agg(DISTINCT tag_geoname.country_pref_label,', ') as country,
	string_agg(DISTINCT tag_geoname.country_iso,', ') as country_code,
	string_agg(DISTINCT case when tag_geoname.geonames_type_mapped in ('CHN','CHNL','CNL','CNLD','CNLI','CNLSB','DLTA','ESTY','FJD','GULF','ISTH','LGN','LK','LKC','LKI','LKN','LKO','LKS','OCN','RSV','SBED','SD','SEA','STM','STMA','STMD','STMI','STMM','STMS','STMSB','STRT','WTRC') then coalesce (tag_geoname.gazetteer_pref_label, tag_geoname.original_location) end,', ') as water_body,
	string_agg(DISTINCT case when tag_geoname.geonames_type_mapped in ('ISLS') then coalesce (tag_geoname.gazetteer_pref_label, tag_geoname.original_location) end,', ') as island_group,
	string_agg(DISTINCT case when tag_geoname.geonames_type_mapped in ('ATOL','ISL','ISLET') then coalesce (tag_geoname.gazetteer_pref_label, tag_geoname.original_location) end,', ') as island,
	(array_agg(tag_geoname.latitude ORDER BY tag_geoname.priority DESC, tag_geoname.geonames_type_mapped, tag_geoname.gazetteer_pref_label))[1] as ndwc_tag_decimal_latitude,--first the location latitude with the highest priority
	(array_agg(tag_geoname.longitude ORDER BY tag_geoname.priority DESC, tag_geoname.geonames_type_mapped, tag_geoname.gazetteer_pref_label))[1] as ndwc_tag_decimal_longitude,--first the location longitude with the highest priority
	coordinates.decimal_start_latitude as ndwc_gtu_decimal_latitude,
	coordinates.decimal_start_longitude as ndwc_gtu_decimal_longitude,
	case coordinates.datum when 'ED50' then 'EPSG:4230' when 'WGS84' then 'EPSG:4326' end as geodetic_datum,
	coordinates.datum||' ('||coordinates.ellipsoid||')' as verbatim_SRS, 
	case when coordinates.decimal_start_longitude is not null then gtu.lat_long_accuracy else case when (array_agg(tag_geoname.longitude ORDER BY tag_geoname.priority DESC))[1] is not null then 999999 end end AS coordinate_uncertainty_in_meters,
	case when coordinates.decimal_start_longitude is not null and coordinates.decimal_start_latitude is not null and coordinates.decimal_end_longitude is not null and coordinates.decimal_end_latitude is not null then
	'LINESTRING('||coordinates.decimal_start_longitude||' '||coordinates.decimal_start_latitude||', '||coordinates.decimal_end_longitude||' '||coordinates.decimal_end_latitude||')' 
	end as footprint_wkt
from gtu 
	LEFT JOIN tag_groups tags ON gtu.id = tags.gtu_ref
	LEFT JOIN ipt.mv_tag_to_locations tag_geoname on tag_geoname.tag_identifier = tags.id and tag_geoname.geonames_type_mapped is not null --ONLY GeoNames!
	LEFT JOIN ipt.mv_spatial coordinates ON coordinates.gtu_ref = gtu.id
where tag_geoname.geonames_type_mapped is not null 
	group by gtu.id,
	coordinates.decimal_start_latitude,
	coordinates.decimal_start_longitude,
	coordinates.decimal_end_latitude, 
	coordinates.decimal_end_longitude, 
	coordinates.datum,
	coordinates.ellipsoid,
	gtu.lat_long_accuracy 
order by gtu.id) q

)

 SELECT distinct string_agg(DISTINCT specimens.id::character varying::text, ','::text) AS ids,
    'PhysicalObject' as type,
    'http://collections.naturalsciences.be/specimen/'::text || specimens.id::text AS occurrence_id,
    min(specimens.specimen_creation_date) as ndwc_created,
    max(GREATEST(specimen_auditing.modification_date_time, gtu_auditing.modification_date_time)) as modified,
    case when collections.code in ('paleo','IST','PalBot') then 'FossilSpecimen'::text else 'PreservedSpecimen'::text end AS basis_of_record,
    'present'::text AS occurrence_status,
    'Royal Belgian Institute of Natural Sciences' as rights_holder,
    'https://www.wikidata.org/wiki/Q222297'::text AS institution_id,
    'http://biocol.org/urn:lsid:biocol.org:col:35271' as old_institution_id,
    'RBINS-Scientific Heritage'::text AS institution_code,
    'RBINS' as owner_institution_code,
    collections.name_indexed as dataset_id,
    collections.name AS dataset_name,
    'urn:catalog:RBINS:'::text || collections.code::text AS collection_code,
    collections.name AS collection_name,
    'http://collections.naturalsciences.be/'::text || collections.id AS collection_id,
    collections.path||collections.id||'/' AS ndwc_collection_path,
    string_agg(distinct (((COALESCE(codes.code_prefix, ''::character varying)::text || COALESCE(codes.code_prefix_separator, ''::character varying)::text) || COALESCE(codes.code, ''::character varying)::text) || COALESCE(codes.code_suffix_separator, ''::character varying)::text) || COALESCE(codes.code_suffix, ''::character varying)::text, ','::text) AS catalog_number,
    'en' as language,
    'https://creativecommons.org/licenses/by-nc/4.0'::text AS license,
    specimens.taxon_name AS scientific_name,
    taxa.taxonomy_ref AS ndwc_local_taxon_id,
    taxa.worms_id AS scientific_name_id,
    taxa.gbif_id AS taxon_id,
    taxa.parent_name_usage,
    taxa.kingdom,
    taxa.phylum,
    taxa.class,
    taxa.ordo,
    taxa.family,
    taxa.genus,
    taxa.subgenus,
    taxa.specific_epithet,
    taxa.infra_specific_epithet,
    taxa.scientific_name_authorship,
    'ICZN' as nomenclatural_code,
    taxa.taxonomic_status,
    taxon_remarks.comment as taxon_remarks,
    specimens.taxon_level_name AS taxon_rank,
    trim(substring(specimens.taxon_name from ' spp\.+$| sp\.| aff\.+| cfr\.+| cf\.+')) as identification_qualifier,
    specimens.type AS type_status,
    specimens.taxon_path AS ndwc_taxon_path,
    specimens.taxon_ref AS ndwc_taxon_ref,
    ( SELECT string_agg(people.formated_name::text, ', '::text ORDER BY people.id) AS string_agg
           FROM people
          WHERE people.id = ANY (specimens.spec_coll_ids)) AS recorded_by,
    max(identifications.notion_date) as date_identified,
    COALESCE(specimens.specimen_count_max, specimens.specimen_count_min, 1) AS organism_quantity,
    'SpecimensInContainer'::text AS organism_quantity_type,
    specimens.sex,
    specimens.stage AS life_stage,
    coalesce('container type: '::text||specimens.container_type,'') || coalesce('; sample preparator: '::text||string_agg(mof_preparator.measurement_value,', '),'') || coalesce('; sample preparation: '::text||string_agg(mof_preparation.measurement_value,', '),'') || coalesce('; preservation method: '::text||specimens.container_storage,'') AS preparations,
    specimens.specimen_status::text AS disposition,
    'urn:catalog:RBINS:IG:'::text || specimens.ig_num::text AS other_catalog_numbers,
    coalesce(string_agg(DISTINCT b.title,', '),'')||coalesce(' '||string_agg(DISTINCT b.abstract,', '),'') as associated_references,
    CASE when specimens.station_visible THEN null else 'Precise location information withheld - country only' end as information_withheld,
    CASE when specimens.station_visible THEN locations.verbatim_location else NULL end as verbatim_location,
    CASE when specimens.station_visible THEN locations.location else NULL end as location,
    CASE when specimens.station_visible THEN locations.ndwc_nice_verbatim_location else NULL end as ndwc_nice_verbatim_location,
    CASE when specimens.station_visible THEN locations.location_id else NULL end as location_id,
    CASE when specimens.station_visible THEN locations.ndwc_geotypes else NULL end as ndwc_geotypes,
    specimens.gtu_country_tag_value AS ndwc_verbatim_country,
    specimens.gtu_ref as ndwc_gtu_identifier,
    locations.country,
    locations.country_code,
    CASE when specimens.station_visible THEN locations.water_body else NULL end as water_body,
    CASE when specimens.station_visible THEN locations.island_group else NULL end as island_group,
    CASE when specimens.station_visible THEN locations.island else NULL end as island,
    CASE when specimens.station_visible THEN locations.decimal_latitude else NULL end as decimal_latitude,
    CASE when specimens.station_visible THEN locations.decimal_longitude else NULL end as decimal_longitude,
    CASE when specimens.station_visible THEN locations.ndwc_tag_decimal_latitude else NULL end as ndwc_tag_decimal_latitude,
    CASE when specimens.station_visible THEN locations.ndwc_tag_decimal_longitude else NULL end as ndwc_tag_decimal_longitude,
    CASE when specimens.station_visible THEN locations.ndwc_gtu_decimal_latitude else NULL end as ndwc_gtu_decimal_latitude,
    CASE when specimens.station_visible THEN locations.ndwc_gtu_decimal_longitude else NULL end as ndwc_gtu_decimal_longitude,
    CASE when specimens.station_visible THEN locations.geodetic_datum else NULL end as geodetic_datum,
    CASE when specimens.station_visible THEN locations.verbatim_SRS else NULL end as verbatim_SRS, 
    CASE when specimens.station_visible THEN locations.coordinate_uncertainty_in_meters else NULL end as coordinate_uncertainty_in_meters,
    CASE when specimens.station_visible THEN locations.footprint_wkt else NULL end as footprint_wkt,
    elevation.measurement_value as minimum_elevation_in_meters,
    elevation.measurement_value as maximum_elevation_in_meters,
    case 
        when sampling_depth.measurement_value is not null then sampling_depth.measurement_value 
        when (sampling_depth_max.measurement_value IS NOT NULL AND sampling_depth_min.measurement_value is NULL) then sampling_depth_max.measurement_value
        else sampling_depth_min.measurement_value
    end as minimum_depth_in_meters, 
    case 
        when sampling_depth.measurement_value is not null then sampling_depth.measurement_value
        when (sampling_depth_min.measurement_value IS NOT NULL AND sampling_depth_max.measurement_value is NULL) then sampling_depth_min.measurement_value
        else sampling_depth_max.measurement_value
    end as maximum_depth_in_meters,
    (SELECT string_agg(people.formated_name::text, ', '::text ORDER BY people.id) AS string_agg
      FROM people
      WHERE people.id = ANY (specimens.spec_ident_ids)) AS identified_by,
    CASE WHEN specimens.gtu_from_date_mask = 0 THEN 
		CASE WHEN specimens.gtu_to_date_mask <> 0 then replace(specimens.gtu_to_date::text,'-xx','') 
		ELSE null
		END
    ELSE replace(fct_mask_date(specimens.gtu_from_date, specimens.gtu_from_date_mask),'-xx','') end
    ||
		CASE WHEN specimens.gtu_from_date = specimens.gtu_to_date or specimens.gtu_to_date_mask = 0 THEN ''
		ELSE '/'||replace(fct_mask_date(specimens.gtu_to_date, specimens.gtu_to_date_mask),'-xx','')
    END  AS event_date,
    specimens.gtu_code as field_number,
    null as habitat
   FROM specimens
     LEFT JOIN users_tracking specimen_auditing on specimen_auditing.record_id = specimens.id and specimen_auditing.referenced_relation='specimens'
     LEFT JOIN collections ON specimens.collection_ref = collections.id
     LEFT JOIN codes ON codes.referenced_relation::text = 'specimens'::text AND codes.code_category::text = 'main'::text AND specimens.id = codes.record_id
     LEFT JOIN identifications ON identifications.referenced_relation::text = 'specimens'::text AND specimens.id = identifications.record_id AND identifications.notion_concerned::text = 'taxonomy'::text and extract(year from identifications.notion_date) > 1800
     LEFT JOIN gtu ON specimens.gtu_ref = gtu.id
     LEFT JOIN users_tracking gtu_auditing on gtu_auditing.record_id = gtu.id and gtu_auditing.referenced_relation='gtu'
     left join location_cte locations on locations.gtu_ref=gtu.id
     LEFT JOIN taxonomy_authority_cte taxa ON taxa.taxonomy_ref = specimens.taxon_ref
     left join catalogue_bibliography cb on cb.record_id = specimens.id and cb.referenced_relation='specimens'
     left join bibliography b on b.id = cb.bibliography_ref
     left join comments taxon_remarks on taxon_remarks.record_id=taxa.taxonomy_ref and taxon_remarks.referenced_relation='taxonomy' and taxon_remarks.notion_concerned='taxon information'
     left join ipt.mv_darwin_ipt_rbins_mof elevation on elevation.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and elevation.measurement_type='elevation'
     left join ipt.mv_darwin_ipt_rbins_mof sampling_depth on sampling_depth.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and sampling_depth.measurement_type='sampling_depth'
     left join ipt.mv_darwin_ipt_rbins_mof sampling_depth_min on sampling_depth_min.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and sampling_depth_min.measurement_type='sampling_depth_min'
     left join ipt.mv_darwin_ipt_rbins_mof sampling_depth_max on sampling_depth_max.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and sampling_depth_max.measurement_type='sampling_depth_max'
     left join ipt.mv_darwin_ipt_rbins_mof mof_preparation on mof_preparation.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and mof_preparation.measurement_type='preparation'
     left join ipt.mv_darwin_ipt_rbins_mof mof_preparator on mof_preparator.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and mof_preparator.measurement_type='preparator'

     where collections.path not like '/231%' and specimens.taxon_name is not null
     GROUP BY specimens.id, collections.code, collections.name, collections.id, collections.path, scientific_name, scientific_name_id, taxon_id, taxa.kingdom, taxa.phylum, taxa.class, taxa.ordo, taxa.family, taxa.genus, taxa.subgenus, 
     taxa.specific_epithet, taxa.infra_specific_epithet, taxa.scientific_name_authorship, taxa.taxonomy_ref, taxa.parent_name_usage, taxa.taxonomic_status, taxon_rank, specimens.spec_coll_ids, specimens.taxon_name, specimens.spec_ident_ids, 
     specimens.station_visible, specimens.type, specimens.taxon_path, specimens.taxon_ref, specimens.specimen_count_max, specimens.specimen_count_min, specimens.sex, specimens.stage, specimens.container_type, specimens.container_storage, 
     specimens.ig_num, ndwc_verbatim_country, locations.verbatim_location, locations.country_code, locations.location, locations.ndwc_nice_verbatim_location, locations.location_id, locations.ndwc_geotypes, locations.country, locations.water_body, 
     locations.island_group, locations.island, locations.decimal_latitude, locations.decimal_longitude, locations.ndwc_tag_decimal_latitude, locations.ndwc_tag_decimal_longitude, locations.ndwc_gtu_decimal_latitude, locations.ndwc_gtu_decimal_longitude, 
     locations.geodetic_datum, locations.verbatim_SRS, locations.coordinate_uncertainty_in_meters, locations.footprint_wkt, specimens.gtu_from_date_mask, specimens.gtu_from_date, specimens.gtu_to_date_mask, specimens.gtu_to_date, specimens.gtu_ref, 
     specimens.gtu_code, specimens.specimen_status, taxon_remarks.comment, /*mof_preparation.measurement_value, mof_preparator.measurement_value,*/ elevation.measurement_value, sampling_depth.measurement_value, sampling_depth_min.measurement_value, sampling_depth_max.measurement_value
     order by occurrence_id;--,LENGTH(b.title), LENGTH(b.abstract);
     
ALTER TABLE ipt.v_darwin_ipt_rbins OWNER TO darwin2;
GRANT ALL ON TABLE ipt.v_darwin_ipt_rbins TO darwin2;

create materialized view ipt.mv_darwin_ipt_rbins as select * from ipt.v_darwin_ipt_rbins;


 --DROP MATERIALIZED VIEW mv_eml_marine;
 --DROP MATERIALIZED VIEW mv_eml;
 
CREATE MATERIALIZED VIEW ipt.mv_eml AS 

select 'The ' || title_en ||' contains ' ||total|| ' digitised specimens of '||nb_species||' taxa. The following classes are included: '||class_taxonomic_coverage
as abstract, total as nb_specimens, nb_species, null as ig_num, ranks, null as existing_code, c.id, name, code, title_en, title_nl, title_fr, profile, path, geographic_coverage, min_lon, max_lon, min_lat, max_lat, start_date, end_date,
	'natural history collection, RBINS, DaRWIN, '::text || c.name::text AS keywords,
	'Royal Belgian Institute for Natural Sciences'::text AS institute_name,
	'Department of Scientific Heritage Service'::text AS institute_dept_abbrev,
	(curator.given_name::text || ' '::text) || curator.family_name::text AS boss,
	uc1.entry AS boss_email,
	'curator'::text AS boss_role,
	(staff.given_name::text || ' '::text) || staff.family_name::text AS subboss,
	uc2.entry AS subboss_email,
	'Collection manager'::text AS subboss_role, class_taxonomic_coverage,order_taxonomic_coverage from (
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='aves' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='belgianmarineinvertebrates' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='brachiopoda' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='bryozoa' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='cheliceratamarine' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='cnidaria' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='crustacea' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='echinodermata' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='mammalia' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='mollusca' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='pisces' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='reptilia' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='rotifera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='vertebratestypes' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='acari' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='amphibia' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='araneae' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='coleoptera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='diptera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='heterocera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='hymenoptera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='orthoptera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from ipt.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='rhopalocera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
) c 
     LEFT JOIN darwin2.users curator ON c.main_manager_ref = curator.id
     LEFT JOIN darwin2.users_comm uc1 ON uc1.person_user_ref = curator.id AND uc1.comm_type::text = 'e-mail'::text
     LEFT JOIN darwin2.users staff ON c.staff_ref = staff.id
     LEFT JOIN darwin2.users_comm uc2 ON uc2.person_user_ref = staff.id AND uc2.comm_type::text = 'e-mail'::text
order by code;


ALTER TABLE ipt.mv_eml
  OWNER TO darwin2;