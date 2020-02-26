set search_path to darwin2,public;
alter table tag_tag_authority  owner to darwin2;

CREATE INDEX tag_tag_authority_idx
  ON darwin2.tag_tag_authority
  USING btree
  (tag_authority_ref, tag_group_distinct_ref);

CREATE UNIQUE INDEX tag_authority_idx
  ON darwin2.tag_authority
  USING btree
  (domain_ref, pref_label COLLATE pg_catalog."default", url COLLATE pg_catalog."default", code COLLATE pg_catalog."default");

DROP MATERIALIZED VIEW IF EXISTS darwin2.mv_tag_to_country;
create schema ipt;
grant all on schema ipt to darwin2;

CREATE MATERIALIZED VIEW ipt.mv_tag_to_country AS
SELECT t1.gtu_ref,
    t1.tag_group_distinct_ref,
    t1.tag_value,
    tacountry.code as country_code_gn,
    tacountry.url as country_url_gn,
    tacountry.pref_label as country_pref_label_gn,
    tacountry.alternative_representations ->> 'iso 3166-2' AS country_iso,
   jsonb_object(coord.property_type, coord.lower_value) as country_coord
    FROM darwin2.tag_groups t1
    RIGHT JOIN darwin2.tag_groups tcountry ON t1.gtu_ref = tcountry.gtu_ref
    LEFT JOIN darwin2.tag_tag_authority ttacountry ON ttacountry.tag_group_distinct_ref = tcountry.tag_group_distinct_ref
    LEFT JOIN darwin2.tag_authority tacountry ON ttacountry.tag_authority_ref = tacountry.id
    LEFT JOIN (select record_id,
			  array_agg(COALESCE(lower_value::text,'no coords'::text)) lower_value,
			   array_agg(COALESCE(property_type::text,'no coords'::text)) property_type from darwin2.properties where referenced_relation='tag_authority' and property_type in ('latitude_wgs_84','longitude_wgs_84')  group by record_id ) coord on coord.record_id = tacountry.id
    WHERE t1.tag_value not in ('Oceans','/','?') AND tcountry.sub_group_name_indexed::text = 'country'::text AND tacountry.id IS NOT NULL and t1.sub_group_name_indexed::text not in ('ocean','country','continent') AND t1.id IS NOT NULL

    
	
WITH DATA;

ALTER TABLE ipt.mv_tag_to_country
  OWNER TO darwin2;
set search_path to darwin2,public;

CREATE INDEX tag_tag_authority_idx
  ON darwin2.tag_tag_authority
  USING btree
  (tag_authority_ref, tag_group_distinct_ref);

CREATE UNIQUE INDEX tag_authority_idx
  ON darwin2.tag_authority
  USING btree
  (domain_ref, pref_label COLLATE pg_catalog."default", url COLLATE pg_catalog."default", code COLLATE pg_catalog."default");
  
GRANT ALL ON TABLE ipt.mv_tag_to_country TO postgres;
GRANT ALL ON TABLE ipt.mv_tag_to_country TO darwin2;

DROP MATERIALIZED VIEW IF EXISTS darwin2.mv_darwin_ipt_rbins;
DROP VIEW IF EXISTS darwin2.v_darwin_ipt_rbins;

DROP MATERIALIZED VIEW IF EXISTS darwin2.mv_tag_to_locations;
CREATE MATERIALIZED VIEW ipt.mv_tag_to_locations
TABLESPACE pg_default
AS
 SELECT DISTINCT t.id AS tag_identifier,
    t.gtu_ref AS gtu_identifier,
    tta.tag_group_distinct_ref AS distinct_tag_identifier,
    t.tag_value AS original_location,
    t.group_name_indexed AS original_type,
    t.sub_group_name_indexed AS original_sub_type,
    tcat_gn.gazetteer_type_mapped AS geonames_type_mapped,
    tcat_mrg.gazetteer_type_mapped AS marineregions_type_mapped,
    tcat_gn.priority,
        CASE
            WHEN tcat_gn.gazetteer_type_mapped = 'PCLI'::text THEN countries.country_code_gn
            ELSE ta.code
        END AS gazetteer_code,
        CASE
            WHEN tcat_gn.gazetteer_type_mapped = 'PCLI'::text THEN countries.country_url_gn
            ELSE ta.url
        END AS gazetteer_url,
    ta.pref_label AS gazetteer_pref_label,
        CASE
            WHEN tcat_gn.gazetteer_type_mapped = 'PCLI'::text THEN countries.country_coord ->> 'latitude_wgs_84'::text
            ELSE prop_coordinates.coords ->> 'latitude_wgs_84'::text
        END::numeric AS latitude,
        CASE
            WHEN tcat_gn.gazetteer_type_mapped = 'PCLI'::text THEN countries.country_coord ->> 'latitude_wgs_84'::text
            ELSE prop_coordinates.coords ->> 'longitude_wgs_84'::text
        END::numeric AS longitude,
    countries.country_iso,
    countries.country_pref_label_gn AS country_pref_label
   FROM tag_groups t
     LEFT JOIN gtu ON t.gtu_ref = gtu.id
     LEFT JOIN tag_tag_authority tta ON tta.tag_group_distinct_ref = t.tag_group_distinct_ref AND t.sub_group_name_indexed::text <> 'country'::text
     LEFT JOIN tag_authority ta ON tta.tag_authority_ref = ta.id
     LEFT JOIN tag_groups_authority_categories tcat_gn ON tcat_gn.original_type::text = t.group_name_indexed::text AND tcat_gn.original_sub_type::text = t.sub_group_name_indexed::text AND tcat_gn.authority = 'geonames.org'::text
     LEFT JOIN tag_groups_authority_categories tcat_mrg ON tcat_mrg.original_type::text = t.group_name_indexed::text AND tcat_mrg.original_sub_type::text = t.sub_group_name_indexed::text AND tcat_mrg.authority = 'marineregions.org'::text
     LEFT JOIN ( SELECT DISTINCT props_lat.record_id,
            jsonb_object_agg(props_lat.property_type, props_lat.lower_value) AS coords
           FROM properties props_lat
          WHERE props_lat.referenced_relation::text = 'tag_authority'::text AND (props_lat.property_type::text = 'latitude_wgs_84'::text OR props_lat.property_type::text = 'longitude_wgs_84'::text)
          GROUP BY props_lat.record_id) prop_coordinates ON ta.id = prop_coordinates.record_id
     LEFT JOIN ( SELECT DISTINCT mv_tag_to_country.gtu_ref,
            mv_tag_to_country.tag_group_distinct_ref,
            mv_tag_to_country.country_iso,
            mv_tag_to_country.country_pref_label_gn,
            mv_tag_to_country.country_code_gn,
            mv_tag_to_country.country_url_gn,
            mv_tag_to_country.country_coord
           FROM ipt.mv_tag_to_country) countries ON countries.gtu_ref = t.gtu_ref
WITH DATA;

ALTER TABLE ipt.mv_tag_to_locations
    OWNER TO postgres;

GRANT ALL ON TABLE ipt.mv_tag_to_locations TO postgres;
GRANT ALL ON TABLE ipt.mv_tag_to_locations TO darwin2;
