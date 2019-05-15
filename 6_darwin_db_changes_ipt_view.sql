set search_path to darwin2,public;
--ALTER VIEW v_darwin_ipt_rbins RENAME TO v_darwin_ipt_rbins_old;

REFRESH MATERIALIZED VIEW darwin2.mv_tag_to_locations;

DROP MATERIALIZED VIEW IF EXISTS mv_darwin_ipt_rbins;
DROP VIEW IF EXISTS v_darwin_ipt_rbins;
CREATE VIEW v_darwin_ipt_rbins AS 
 WITH taxonomy_authority_cte AS (
         SELECT t.id AS taxonomy_ref,
            taxa_gbif.url AS gbif_id,
            taxa_worms.urn AS worms_id
           FROM taxonomy t
             LEFT JOIN taxonomy_authority taxa_gbif ON taxa_gbif.taxonomy_ref = t.id AND taxa_gbif.domain_ref = (( SELECT authority_domain.id
                   FROM authority_domain
                  WHERE authority_domain.name::text = 'gbif.org'::text))
             LEFT JOIN taxonomy_authority taxa_worms ON taxa_worms.taxonomy_ref = t.id AND taxa_worms.domain_ref = (( SELECT authority_domain.id
                   FROM authority_domain
                  WHERE authority_domain.name::text = 'marinespecies.org'::text))
          WHERE NOT (taxa_gbif.url IS NULL AND taxa_worms.urn IS NULL)
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
	'Coordinates are based on original information.' 
	else case when ndwc_tag_decimal_latitude is not null then 'WARNING! No original coordinate information found. The coordinates have been geocoded from the stated locational information (see verbatimLocation) by automated mapping+human verification to GeoNames.org ('||location_id||'). The mapping is done constrained by type and by country (if available), and assessed by probability. When multiple locations have been mapped for this specimen, the most precise is taken here.' end 
end as georeference_protocol 
from (
select 
	gtu.id as gtu_ref,
	string_agg(DISTINCT tags.tag_value::text, ', '::text) AS verbatim_location,
	(array_agg(tag_geoname.gazetteer_pref_label ORDER BY tag_geoname.priority DESC))[1] as location,--first the gazetteer labels with the highest priority
	string_agg(DISTINCT tag_geoname.gazetteer_pref_label::text, ', '::text) AS ndwc_nice_verbatim_location,
	(array_agg(tag_geoname.gazetteer_url ORDER BY tag_geoname.priority DESC))[1] as location_id,--first the gazetteer urls with the highest priority
	array_agg (tag_geoname.geonames_type_mapped ORDER BY tag_geoname.priority ASC, tag_geoname.geonames_type_mapped) as ndwc_geotypes,
	string_agg(DISTINCT tag_geoname.country_pref_label,', ') as country,
	string_agg(DISTINCT tag_geoname.country_iso,', ') as country_code,
	string_agg(DISTINCT case when tag_geoname.geonames_type_mapped in ('CHN','CHNL','CNL','CNLD','CNLI','CNLSB','DLTA','ESTY','FJD','GULF','ISTH','LGN','LK','LKC','LKI','LKN','LKO','LKS','OCN','RSV','SBED','SD','SEA','STM','STMA','STMD','STMI','STMM','STMS','STMSB','STRT','WTRC') then coalesce (tag_geoname.gazetteer_pref_label, tag_geoname.original_location) end,', ') as water_body,
	string_agg(DISTINCT case when tag_geoname.geonames_type_mapped in ('ISLS') then coalesce (tag_geoname.gazetteer_pref_label, tag_geoname.original_location) end,', ') as island_group,
	string_agg(DISTINCT case when tag_geoname.geonames_type_mapped in ('ATOL','ISL','ISLET') then coalesce (tag_geoname.gazetteer_pref_label, tag_geoname.original_location) end,', ') as island,
	(array_agg(tag_geoname.latitude ORDER BY tag_geoname.priority DESC))[1] as ndwc_tag_decimal_latitude,--first the location latitude with the highest priority
	(array_agg(tag_geoname.longitude ORDER BY tag_geoname.priority DESC))[1] as ndwc_tag_decimal_longitude,--first the location longitude with the highest priority
	coordinates.decimal_start_latitude as ndwc_gtu_decimal_latitude,
	coordinates.decimal_start_longitude as ndwc_gtu_decimal_longitude,
	case coordinates.datum when 'ED50' then 'EPSG:4230' when 'WGS84' then 'EPSG:4326' end as geodetic_datum,
	coordinates.datum||' ('||coordinates.ellipsoid||')' as verbatim_SRS, 
	gtu.lat_long_accuracy AS coordinate_uncertainty_in_meters,
	case when coordinates.decimal_start_longitude is not null and coordinates.decimal_start_latitude is not null and coordinates.decimal_end_longitude is not null and coordinates.decimal_end_latitude is not null then
	'LINESTRING('||coordinates.decimal_start_longitude||' '||coordinates.decimal_start_latitude||', '||coordinates.decimal_end_longitude||' '||coordinates.decimal_end_latitude||')' 
	end as footprint_wkt
from gtu 
	LEFT JOIN tag_groups tags ON gtu.id = tags.gtu_ref
	LEFT JOIN mv_tag_to_locations tag_geoname on tag_geoname.original_identifier = tags.id and tag_geoname.geonames_type_mapped is not null --ONLY GeoNames!
	LEFT JOIN mv_spatial coordinates ON coordinates.gtu_ref = gtu.id
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
    'http://collections.naturalsciences.be/specimen/'::text || specimens.id::character varying::text AS occurence_id,
    min(specimens.specimen_creation_date) as ndwc_created,
    max(GREATEST(specimen_auditing.modification_date_time, gtu_auditing.modification_date_time)) as modified,
    'PreservedSpecimen'::text AS basis_of_record, --fossilspecimen,....
    'present'::text AS occurence_status,
    'Royal Belgian Institute of Natural Sciences' as rights_holder,
    'RBINS_DaRWIN' as dataset_id,
    collections.name AS dataset_name,
    'rbins.be:collection:'::text || collections.code::text AS collection_code,
    collections.name AS collection_name,
    'http://collections.naturalsciences.be/'::text || collections.id AS collection_id, --or collection.code
    collections.path||collections.id||'/' AS ndwc_collection_path,
    (((COALESCE(codes.code_prefix, ''::character varying)::text || COALESCE(codes.code_prefix_separator, ''::character varying)::text) || COALESCE(codes.code, ''::character varying)::text) || COALESCE(codes.code_suffix_separator, ''::character varying)::text) || COALESCE(codes.code_suffix, ''::character varying)::text AS catalog_number,
    'https://www.wikidata.org/wiki/Q222297'::text AS institution_id,
    'http://biocol.org/urn:lsid:biocol.org:col:35271' as old_institution_id,
    'RBINS-Scientific Heritage'::text AS institution_code,
    'RBINS' as owner_institution_code,
    'https://creativecommons.org/licenses/by-nc/4.0'::text AS license,
    specimens.taxon_name AS scientific_name,
    taxa.worms_id AS scientific_name_id,
    taxa.gbif_id AS taxon_id,
    specimens.taxon_level_name AS taxon_rank,
    trim(substring(specimens.taxon_name from ' spp\.+$| sp\.| aff\.+| cfr\.+| cf\.+')) as identification_qualifier,
    specimens.type AS type_status,
    specimens.taxon_path AS ndwc_taxon_path,
    specimens.taxon_ref AS ndwc_taxon_ref,
    ( SELECT string_agg(people.formated_name::text, ', '::text ORDER BY people.id) AS string_agg
           FROM people
          WHERE people.id = ANY (specimens.spec_coll_ids)) AS recorded_by,
    COALESCE(specimens.specimen_count_max, specimens.specimen_count_min, 1) AS organism_quantity,
    'SpecimensInContainer'::text AS organism_quantity_type,
    specimens.sex,
    specimens.stage AS life_stage,
    (('container type: '::text || specimens.container_type::text) || '; preservation method: '::text) || specimens.container_storage::text AS preparations,
    NULL::text AS disposition,
    'rbins.be:specimens:IG:'::text || specimens.ig_num::text AS other_catalog_numbers,
    CASE when specimens.station_visible THEN null else 'Precise location information not given - country only' end as information_withheld,
    CASE when specimens.station_visible THEN locations.verbatim_location else NULL end as verbatim_location,
    CASE when specimens.station_visible THEN locations.location else NULL end as location,
    CASE when specimens.station_visible THEN locations.ndwc_nice_verbatim_location else NULL end as ndwc_nice_verbatim_location,
    CASE when specimens.station_visible THEN locations.location_id else NULL end as location_id,
    CASE when specimens.station_visible THEN locations.ndwc_geotypes else NULL end as ndwc_geotypes,
    specimens.gtu_country_tag_value AS ndwc_verbatim_country,
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
    null as habitat, 
    null as minimum_depth_in_meters, 
    null as maximum_depth_in_meters
   FROM specimens
     LEFT JOIN users_tracking specimen_auditing on specimen_auditing.record_id = specimens.id and specimen_auditing.referenced_relation='specimens'
     LEFT JOIN collections ON specimens.collection_ref = collections.id
     LEFT JOIN codes ON codes.referenced_relation::text = 'specimens'::text AND codes.code_category::text = 'main'::text AND specimens.id = codes.record_id
     LEFT JOIN identifications ON identifications.referenced_relation::text = 'specimens'::text AND specimens.id = identifications.record_id AND identifications.notion_concerned::text = 'taxonomy'::text
     LEFT JOIN gtu ON specimens.gtu_ref = gtu.id
     LEFT JOIN users_tracking gtu_auditing on gtu_auditing.record_id = gtu.id and gtu_auditing.referenced_relation='gtu'
     left join location_cte locations on locations.gtu_ref=gtu.id
     LEFT JOIN taxonomy_authority_cte taxa ON taxa.taxonomy_ref = specimens.taxon_ref
     GROUP BY occurence_id, collections.code, collections.name, collections.id, collections.path, codes.code_prefix, codes.code_prefix_separator, codes.code, codes.code_suffix_separator, codes.code_suffix, scientific_name, scientific_name_id, taxon_id, taxon_rank, specimens.spec_coll_ids, specimens.taxon_name, specimens.spec_ident_ids, specimens.station_visible, specimens.type, specimens.taxon_path, specimens.taxon_ref, specimens.specimen_count_max, specimens.specimen_count_min, specimens.sex, specimens.stage, specimens.container_type, specimens.container_storage, specimens.ig_num, ndwc_verbatim_country, locations.verbatim_location, locations.country_code, locations.location, locations.ndwc_nice_verbatim_location, locations.location_id, locations.ndwc_geotypes, locations.country, locations.water_body, locations.island_group, locations.island, locations.decimal_latitude, locations.decimal_longitude, locations.ndwc_tag_decimal_latitude, locations.ndwc_tag_decimal_longitude, locations.ndwc_gtu_decimal_latitude, locations.ndwc_gtu_decimal_longitude, locations.geodetic_datum, locations.verbatim_SRS, locations.coordinate_uncertainty_in_meters, locations.footprint_wkt, specimens.gtu_from_date_mask, specimens.gtu_from_date, specimens.gtu_to_date_mask, specimens.gtu_to_date
     order by occurence_id;
     ALTER TABLE v_darwin_ipt_rbins
  OWNER TO darwin2;
GRANT ALL ON TABLE v_darwin_ipt_rbins TO darwin2;

create materialized view mv_darwin_ipt_rbins as select * from v_darwin_ipt_rbins;
