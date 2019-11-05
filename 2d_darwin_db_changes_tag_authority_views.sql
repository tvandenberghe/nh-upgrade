set search_path to darwin2,public;

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
  OWNER TO postgres;
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
CREATE MATERIALIZED VIEW ipt.mv_tag_to_locations AS 
SELECT DISTINCT 
	t.id AS tag_identifier,
	t.gtu_ref AS gtu_identifier,
	tta.tag_group_distinct_ref AS distinct_tag_identifier,
	t.tag_value AS original_location,
	t.group_name_indexed AS original_type,
	t.sub_group_name_indexed AS original_sub_type,
    tcat_gn.gazetteer_type_mapped AS geonames_type_mapped,
    tcat_mrg.gazetteer_type_mapped AS marineregions_type_mapped,
    tcat_gn.priority,
    case when tcat_gn.gazetteer_type_mapped = 'PCLI' then countries.country_code_gn else ta.code end AS gazetteer_code,
    case when tcat_gn.gazetteer_type_mapped = 'PCLI' then countries.country_url_gn else ta.url end AS gazetteer_url,
    ta.pref_label AS gazetteer_pref_label,
    cast (case when tcat_gn.gazetteer_type_mapped = 'PCLI' then countries.country_coord->>'latitude_wgs_84' else coordinates.lower_value end as NUMERIC) as latitude,
    cast (case when tcat_gn.gazetteer_type_mapped = 'PCLI' then countries.country_coord->>'longitude_wgs_84' else props_lon.lower_value end as NUMERIC) as longitude,
    countries.country_iso,
    countries.country_pref_label_gn as country_pref_label
   FROM darwin2.tag_groups t
     LEFT JOIN darwin2.gtu ON  t.gtu_ref=gtu.id 
    
     LEFT JOIN darwin2.tag_tag_authority tta ON tta.tag_group_distinct_ref = t.tag_group_distinct_ref and t.sub_group_name_indexed::text <> 'country'::text
     LEFT JOIN darwin2.tag_authority ta ON tta.tag_authority_ref = ta.id
     LEFT JOIN darwin2.tag_groups_authority_categories tcat_gn on tcat_gn.original_type = t.group_name_indexed and tcat_gn.original_sub_type = t.sub_group_name_indexed and tcat_gn.authority = 'geonames.org'--get the priority of the original terms
     LEFT JOIN darwin2.tag_groups_authority_categories tcat_mrg on tcat_mrg.original_type = t.group_name_indexed and tcat_mrg.original_sub_type = t.sub_group_name_indexed and tcat_mrg.authority = 'marineregions.org' --get the priority of the original terms
    
     LEFT JOIN (
            SELECT
            distinct
            record_id, jsonb_object_agg(property_type, lower_value)

            FROM darwin2.properties props_lat
            WHERE props_lat.referenced_relation='tag_authority' and 
            (props_lat.property_type='latitude_wgs_84'

            OR
             props_lat.property_type='longitude_wgs_84'
            )
            group by record_id
            )

            AS
            prop_coordinates
     LEFT JOIN (select distinct gtu_ref, tag_group_distinct_ref, country_iso, country_pref_label_gn, country_code_gn, country_url_gn,country_coord 
     from ipt.mv_tag_to_country) countries ON countries.gtu_ref = t.gtu_ref
     ORDER BY t.tag_value
WITH DATA;

ALTER TABLE ipt.mv_tag_to_locations OWNER TO postgres;
GRANT ALL ON TABLE ipt.mv_tag_to_locations TO postgres;
GRANT ALL ON TABLE ipt.mv_tag_to_locations TO darwin2;