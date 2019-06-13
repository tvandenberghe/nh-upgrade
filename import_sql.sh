#!/bin/bash   
#psql -h ostrea.rbins.be -d darwin2_rbins_test -U postgres < /home/thomas/Documents/Project-NaturalHeritage/datadumps/darwin_dev_rbins_20190503.dump
server=ostrea.rbins.be
#localhost
serveruser=thomas
#localhost
db=darwin2_rbins_test

echo "Working on $server"
scp taxamatch2.csv "$serveruser@$server:/tmp"

export PGPASSWORD='postgres'; 

psql -h "$server" -d "$db" -U postgres -c "DROP TABLE IF EXISTS import.taxamatch;"

pgfutter --table "taxamatch" --schema "import" --db "$db"  --host "$server" --port 5432 --user postgres --pw "postgres" csv taxamatch.csv -d ','
psql -h "$server" -d "$db" -U postgres -c "COPY import.taxamatch (taxon, worms_id, worms_scientific_name, worms_is_terrestrial, worms_is_freshwater, worms_is_brackish, worms_is_marine, worms_lsid, worms_url) FROM '/tmp/taxamatch2.csv' DELIMITER E'\t' CSV HEADER;"

psql -h "$server" -d "$db" -U postgres -c "
DROP MATERIALIZED VIEW IF EXISTS darwin2.mv_darwin_ipt_rbins_mof;
DROP VIEW IF EXISTS darwin2.v_darwin_ipt_rbins_mof;
DROP MATERIALIZED VIEW IF EXISTS darwin2.mv_properties CASCADE;

DROP VIEW IF EXISTS darwin2.v_darwin_ipt_rbins,darwin2.v_darwin_ipt_rbins_mof CASCADE;
DROP MATERIALIZED VIEW IF EXISTS darwin2.mv_tag_to_country, darwin2.mv_eml, darwin2.mv_eml_marine, darwin2.mv_spatial, darwin2.mv_tag_to_locations, darwin2.mv_darwin_ipt_rbins;

ALTER TABLE darwin2.tag_groups DROP COLUMN IF EXISTS tag_group_distinct_ref;
DROP TABLE IF EXISTS darwin2.tag_groups_authority_categories;
DROP TABLE IF EXISTS darwin2.property_tag_authority;
DROP TABLE IF EXISTS darwin2.tag_authority_tag_authority;
DROP TABLE IF EXISTS darwin2.tag_tag_authority;
DROP TABLE IF EXISTS darwin2.tag_authority;
DROP TABLE IF EXISTS darwin2.tag_group_distinct;
DROP TABLE IF EXISTS darwin2.taxonomy_authority;
DROP TABLE IF EXISTS darwin2.authority_domain;

ALTER TABLE darwin2.collections DROP COLUMN IF EXISTS profile;
ALTER TABLE darwin2.collections DROP COLUMN IF EXISTS publish_to_gbif;
ALTER TABLE darwin2.collections DROP COLUMN IF EXISTS title_en, DROP COLUMN IF EXISTS title_nl, DROP COLUMN IF EXISTS title_fr;
ALTER TABLE darwin2.tag_groups DROP COLUMN IF EXISTS tag_group_distinct_ref;
ALTER TABLE darwin2.properties DROP COLUMN IF EXISTS property_type_ref;

DROP INDEX IF EXISTS darwin2.tag_authority_idx,darwin2.tag_tag_authority_idx,darwin2.taxonomy_is_marine_authority_idx;

DROP FUNCTION IF EXISTS darwin2.cleanup_sample_properties();

SET SEARCH_PATH TO darwin2,public; 

ALTER TABLE darwin2.properties DISABLE TRIGGER fct_cpy_trg_del_dict_properties;
ALTER TABLE darwin2.properties DISABLE TRIGGER fct_cpy_trg_ins_update_dict_properties;
ALTER TABLE darwin2.properties DISABLE TRIGGER trg_chk_ref_record_properties;
ALTER TABLE darwin2.properties DISABLE TRIGGER trg_cpy_fulltoindex_properties;
ALTER TABLE darwin2.properties DISABLE TRIGGER trg_cpy_unified_values;
ALTER TABLE darwin2.properties DISABLE TRIGGER trg_trk_log_table_properties;

DELETE FROM darwin2.properties where property_type in ('latitude_wgs_84','longitude_wgs_84');

ALTER TABLE darwin2.properties ENABLE TRIGGER fct_cpy_trg_del_dict_properties;
ALTER TABLE darwin2.properties ENABLE TRIGGER fct_cpy_trg_ins_update_dict_properties;
ALTER TABLE darwin2.properties ENABLE TRIGGER trg_chk_ref_record_properties;
ALTER TABLE darwin2.properties ENABLE TRIGGER trg_cpy_fulltoindex_properties;
ALTER TABLE darwin2.properties ENABLE TRIGGER trg_cpy_unified_values;
ALTER TABLE darwin2.properties ENABLE TRIGGER trg_trk_log_table_properties;
"

#psql -h "$server" -d "$db" -U postgres -c "VACUUM ANALYZE;"

echo "1-->MAKE CHANGES TO TABLES"
psql -h "$server" -d "$db" -U postgres -q < 1_darwin_db_changes_tables.sql
echo "2a-->ADD TAG AUTHORITY TABLE"
psql -h "$server" -d "$db" -U postgres -q  < 2a_darwin_db_changes_tag_authority.sql
echo "2b-->POPULATE AUTHORITY COUNTRIES"
psql -h "$server" -d "$db" -U postgres -q  < 2b_darwin_db_changes_tag_authority_data_countries.sql 
echo "2c-->POPULATE AUTHORITY LOCALITIES"
psql -h "$server" -d "$db" -U postgres -q  < 2c_darwin_db_changes_tag_authority_data.sql
echo "2d-->ADD LOCATION VIEWS"
psql -h "$server" -d "$db" -U postgres -q  < 2d_darwin_db_changes_tag_authority_views.sql
echo "4-->MODIFY TAXONOMY TABLES"
psql -h "$server" -d "$db" -U postgres -q  < 4_darwin_db_changes_tables_taxonomy.sql 
echo "5-->CREATE EML VIEW"
psql -h "$server" -d "$db" -U postgres -q  < 5_darwin_db_changes_functions_eml_views.sql
echo "6-->CREATE IPT OCCURRENCE VIEW"
psql -h "$server" -d "$db" -U postgres -q  < 6_darwin_db_changes_ipt_view.sql
echo "7-->CREATE TABLES TO BETTER STORE PROPERTIES"
psql -h "$server" -d "$db" -U postgres -q  < 7_darwin_db_changes_properties.sql
echo "8-->CREATE SAMPLING VIEW"
psql -h "$server" -d "$db" -U postgres -q  < 8_darwin_db_changes_sampling_view.sql
echo "9-->CREATE MOF VIEW"
psql -h "$server" -d "$db" -U postgres -q  < 9_darwin_db_changes_ipt_mof_view.sql
echo "10-->CREATE IPT VIEW PER DATASET"
psql -h "$server" -d "$db" -U postgres -q  < 10_ipt_views_per_dataset.sql

psql -h "$server" -d "$db" -U postgres -c "
--DROP ROLE IF EXISTS iptreader;
--create user iptreader with password 'OstreaEdulis';
GRANT SELECT ON ALL TABLES IN SCHEMA darwin2 TO iptreader;
GRANT USAGE ON SCHEMA darwin2 TO iptreader;
"

#--DROP VIEW IF EXISTS darwin2.v_darwin_ipt_rbins_mof;
#DETAIL:  view v_darwin_ipt_rbins_mof depends on materialized view darwin2.mv_properties
