set search_path to darwin2,public;

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
  
DROP MATERIALIZED VIEW IF EXISTS mv_darwin_ipt_rbins CASCADE;
DROP VIEW IF EXISTS v_darwin_ipt_rbins;

drop materialized view if exists mv_taxonomy;
create materialized view mv_taxonomy as (
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
--where t.level_ref = 48
order by 1);

create view v_darwin_ipt_rbins as
WITH location_cte as (
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
	LEFT JOIN mv_tag_to_locations tag_geoname on tag_geoname.tag_identifier = tags.id and tag_geoname.geonames_type_mapped is not null --ONLY GeoNames!
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
    --'rbins_collections_'||collections.name_indexed as dataset_id,
    --collections.title_en AS dataset_name,
    'urn:catalog:RBINS:'::text || collections.code::text AS collection_code,
    collections.name AS collection_name,
    'http://collections.naturalsciences.be/'::text || collections.id AS collection_id,
    collections.path||collections.id||'/' AS ndwc_collection_path,
    string_agg(distinct (((COALESCE(codes.code_prefix, ''::character varying)::text || COALESCE(codes.code_prefix_separator, ''::character varying)::text) || COALESCE(case when codes.code ~ '\d+ ?[a-zA-Z]+' then upper(regexp_replace(codes.code,'(\d+) ([a-zA-Z]+)','\1\2')) else codes.code end, ''::character varying)::text) || COALESCE(codes.code_suffix_separator, ''::character varying)::text) || COALESCE(codes.code_suffix, ''::character varying)::text, ','::text) AS catalog_number,
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
    CASE COALESCE(specimens.specimen_count_max, specimens.specimen_count_min, 1) WHEN 0 THEN 1 else COALESCE(specimens.specimen_count_max, specimens.specimen_count_min, 1) END AS organism_quantity,
    'SpecimensInContainer'::text AS organism_quantity_type,
    CASE COALESCE(specimens.specimen_count_max, specimens.specimen_count_min, 1) WHEN 0 THEN 'Database specifies zero specimens for this existing specimen. Organism quantity has been set to 1. ' END as occurrence_remarks, 
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
    case when specimens.station_visible THEN locations.georeference_remarks else null end as georeference_remarks, 
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
    CASE WHEN specimens.gtu_from_date_mask = 0 THEN CASE WHEN specimens.gtu_to_date_mask <> 0 then replace(specimens.gtu_to_date::text,'-xx','') 
    ELSE CASE WHEN specimens.acquisition_date::text<>'0001-01-01' THEN '1800-01-01/'||specimens.acquisition_date::text END --if from and to date are both empty, then take the acquisition date. If the acquisition date is empty, take the date of inscription in the IG catalog
    END
    ELSE replace(fct_mask_date(specimens.gtu_from_date, specimens.gtu_from_date_mask),'-xx','') end
    ||
    CASE WHEN specimens.gtu_from_date = specimens.gtu_to_date or specimens.gtu_to_date_mask = 0 or specimens.gtu_from_date_mask = 0 THEN ''
    ELSE '/'||replace(fct_mask_date(specimens.gtu_to_date, specimens.gtu_to_date_mask),'-xx','') END AS event_date,
    CASE WHEN specimens.gtu_from_date_mask = 0 AND specimens.gtu_to_date_mask = 0 and specimens.acquisition_date::text<>'0001-01-01' then 'Event date interpreted from date specimen was acquired by the Museum' END as event_remarks,
    replace(nullif(specimens.gtu_code,'0'),'/ ','/')::character varying AS field_number,
    null as habitat
   FROM specimens
     LEFT JOIN users_tracking specimen_auditing on specimen_auditing.record_id = specimens.id and specimen_auditing.referenced_relation='specimens'
     LEFT JOIN collections ON specimens.collection_ref = collections.id
     LEFT JOIN codes ON codes.referenced_relation::text = 'specimens'::text AND codes.code_category::text = 'main'::text AND specimens.id = codes.record_id
     LEFT JOIN identifications ON identifications.referenced_relation::text = 'specimens'::text AND specimens.id = identifications.record_id AND identifications.notion_concerned::text = 'taxonomy'::text and extract(year from identifications.notion_date) > 1800
     LEFT JOIN gtu ON specimens.gtu_ref = gtu.id
     LEFT JOIN users_tracking gtu_auditing on gtu_auditing.record_id = gtu.id and gtu_auditing.referenced_relation='gtu'
     left join location_cte locations on locations.gtu_ref=gtu.id
     LEFT JOIN mv_taxonomy taxa ON taxa.taxonomy_ref = specimens.taxon_ref
     left join catalogue_bibliography cb on cb.record_id = specimens.id and cb.referenced_relation='specimens'
     left join bibliography b on b.id = cb.bibliography_ref
     left join comments taxon_remarks on taxon_remarks.record_id=taxa.taxonomy_ref and taxon_remarks.referenced_relation='taxonomy' and taxon_remarks.notion_concerned='taxon information'
     left join darwin2.mv_darwin_ipt_rbins_mof elevation on elevation.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and elevation.measurement_type='elevation'
     left join darwin2.mv_darwin_ipt_rbins_mof sampling_depth on sampling_depth.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and sampling_depth.measurement_type='sampling_depth'
     left join darwin2.mv_darwin_ipt_rbins_mof sampling_depth_min on sampling_depth_min.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and sampling_depth_min.measurement_type='sampling_depth_min'
     left join darwin2.mv_darwin_ipt_rbins_mof sampling_depth_max on sampling_depth_max.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and sampling_depth_max.measurement_type='sampling_depth_max'
     left join darwin2.mv_darwin_ipt_rbins_mof mof_preparation on mof_preparation.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and mof_preparation.measurement_type='preparation'
     left join darwin2.mv_darwin_ipt_rbins_mof mof_preparator on mof_preparator.occurrence_id='http://collections.naturalsciences.be/specimen/'::text || specimens.id::text and mof_preparator.measurement_type='preparator'

     where collections.path not like '/231%' and specimens.taxon_name is not null
     GROUP BY specimens.id, collections.code, collections.name, collections.id, collections.path, scientific_name, scientific_name_id, taxon_id, taxa.kingdom, taxa.phylum, taxa.class, taxa.ordo, taxa.family, taxa.genus, taxa.subgenus, 
     taxa.specific_epithet, taxa.infra_specific_epithet, taxa.scientific_name_authorship, taxa.taxonomy_ref, taxa.parent_name_usage, taxa.taxonomic_status, taxon_rank, specimens.spec_coll_ids, specimens.taxon_name, specimens.spec_ident_ids, 
     specimens.station_visible, specimens.type, specimens.taxon_path, specimens.taxon_ref, specimens.specimen_count_max, specimens.specimen_count_min, specimens.sex, specimens.stage, specimens.container_type, specimens.container_storage, 
     specimens.ig_num, ndwc_verbatim_country, locations.verbatim_location, locations.country_code, locations.location, locations.ndwc_nice_verbatim_location, locations.location_id, locations.ndwc_geotypes, locations.country, locations.water_body, 
     locations.island_group, locations.island, locations.decimal_latitude, locations.decimal_longitude, locations.ndwc_tag_decimal_latitude, locations.ndwc_tag_decimal_longitude, locations.ndwc_gtu_decimal_latitude, locations.ndwc_gtu_decimal_longitude, 
     locations.geodetic_datum, locations.verbatim_SRS, locations.coordinate_uncertainty_in_meters, locations.footprint_wkt, locations.georeference_remarks, specimens.gtu_from_date_mask, specimens.gtu_from_date, specimens.gtu_to_date_mask, specimens.gtu_to_date, specimens.gtu_ref, 
     specimens.gtu_code, specimens.specimen_status, taxon_remarks.comment, /*mof_preparation.measurement_value, mof_preparator.measurement_value,*/ elevation.measurement_value, sampling_depth.measurement_value, sampling_depth_min.measurement_value, sampling_depth_max.measurement_value
     order by occurrence_id;
     
ALTER TABLE v_darwin_ipt_rbins OWNER TO darwin2;
GRANT ALL ON TABLE v_darwin_ipt_rbins TO darwin2;

create materialized view mv_darwin_ipt_rbins as select * from v_darwin_ipt_rbins;
