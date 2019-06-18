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
CREATE MATERIALIZED VIEW darwin2.mv_tag_to_country AS 
SELECT t1.gtu_ref,
    t1.tag_group_distinct_ref,
    t1.tag_value,
    tacountry.code as country_code_gn,
    tacountry.url as country_url_gn,
    tacountry.pref_label as country_pref_label_gn,
    tacountry.alternative_representations -> 'ISO 3166-2'::text AS country_iso,
    array_agg(DISTINCT coord.lower_value) as country_coord
    FROM darwin2.tag_groups t1
    RIGHT JOIN darwin2.tag_groups tcountry ON t1.gtu_ref = tcountry.gtu_ref
    LEFT JOIN darwin2.tag_tag_authority ttacountry ON ttacountry.tag_group_distinct_ref = tcountry.tag_group_distinct_ref
    LEFT JOIN darwin2.tag_authority tacountry ON ttacountry.tag_authority_ref = tacountry.id
    LEFT JOIN (select record_id,lower_value from darwin2.properties where referenced_relation='tag_authority' and property_type in ('latitude_wgs_84','longitude_wgs_84') order by record_id, property_type asc) coord on coord.record_id = tacountry.id
    WHERE t1.tag_value not in ('Oceans','/','?') AND tcountry.sub_group_name_indexed::text = 'country'::text AND tacountry.id IS NOT NULL and t1.sub_group_name_indexed::text not in ('ocean','continent') AND t1.id IS NOT NULL
group by 
    t1.gtu_ref,
    t1.tag_group_distinct_ref,
    t1.tag_value,
    tacountry.code,
    tacountry.url,
    tacountry.pref_label,
    tacountry.alternative_representations -> 'ISO 3166-2'::text
WITH DATA;

ALTER TABLE darwin2.mv_tag_to_country
  OWNER TO postgres;
GRANT ALL ON TABLE darwin2.mv_tag_to_country TO postgres;
GRANT ALL ON TABLE darwin2.mv_tag_to_country TO darwin2;

DROP MATERIALIZED VIEW IF EXISTS darwin2.mv_darwin_ipt_rbins;
DROP VIEW IF EXISTS darwin2.v_darwin_ipt_rbins;

DROP MATERIALIZED VIEW IF EXISTS darwin2.mv_tag_to_locations;
CREATE MATERIALIZED VIEW darwin2.mv_tag_to_locations AS 
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
    cast (case when tcat_gn.gazetteer_type_mapped = 'PCLI' then countries.country_coord[1] else props_lat.lower_value end as NUMERIC) as latitude,
    cast (case when tcat_gn.gazetteer_type_mapped = 'PCLI' then countries.country_coord[2] else props_lon.lower_value end as NUMERIC) as longitude,
    countries.country_iso,
    countries.country_pref_label_gn as country_pref_label
   FROM darwin2.gtu
     RIGHT JOIN darwin2.tag_groups t ON gtu.id = t.gtu_ref
     --RIGHT JOIN darwin2.tag_group_distinct td ON t.tag_value::text = td.tag_value::text AND td.sub_group_name_indexed::text = t.sub_group_name_indexed::text AND td.group_name_indexed::text = t.group_name_indexed::text AND td.sub_group_name_indexed::text <> 'country'::text
     LEFT JOIN darwin2.tag_tag_authority tta ON tta.tag_group_distinct_ref = t.tag_group_distinct_ref and t.sub_group_name_indexed::text <> 'country'::text
     LEFT JOIN darwin2.tag_authority ta ON tta.tag_authority_ref = ta.id
     LEFT JOIN darwin2.tag_groups_authority_categories tcat_gn on tcat_gn.original_type = t.group_name_indexed and tcat_gn.original_sub_type = t.sub_group_name_indexed and tcat_gn.authority = 'geonames.org'--get the priority of the original terms
     LEFT JOIN darwin2.tag_groups_authority_categories tcat_mrg on tcat_mrg.original_type = t.group_name_indexed and tcat_mrg.original_sub_type = t.sub_group_name_indexed and tcat_mrg.authority = 'marineregions.org' --get the priority of the original terms
     --LEFT JOIN darwin2.tag_groups_authority_categories tcat_gzterms on tcat.gazetteer_type_mapped = ta.type[1]  --get the priority of the mapped terms
     LEFT JOIN darwin2.properties props_lat on props_lat.record_id = ta.id and props_lat.referenced_relation='tag_authority' and props_lat.property_type='latitude_wgs_84'
     LEFT JOIN darwin2.properties props_lon on props_lon.record_id = ta.id and props_lon.referenced_relation='tag_authority' and props_lon.property_type='longitude_wgs_84'
     LEFT JOIN (select distinct gtu_ref, tag_group_distinct_ref, country_iso, country_pref_label_gn, country_code_gn, country_url_gn,country_coord 
     from darwin2.mv_tag_to_country) countries ON countries.gtu_ref = t.gtu_ref
     ORDER BY t.tag_value
WITH DATA;

ALTER TABLE darwin2.mv_tag_to_locations OWNER TO postgres;
GRANT ALL ON TABLE darwin2.mv_tag_to_locations TO postgres;
GRANT ALL ON TABLE darwin2.mv_tag_to_locations TO darwin2;
