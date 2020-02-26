create table
import.taxamatch
(
taxon text,gbif_name_status text,gbif_match_type text,gbif_rank text,gbif_id text,gbif_matched text,gbif_kingdom text,gbif_phylum text,gbif_class text,gbif_order text,gbif_family text,gbif_genus text,gbif_species text,gbif_subspecies text,gbif_full_name text,gbif_author text,gbif_source text,gbif_reference text,rgb_match_type text,background_style text,gbif_url text,worms_id text,worms_scientific_name text,worms_author text,worms_status text, worms_accepted_name text,worms_accepted_author text,worms_phylum text,worms_class text,worms_order text,worms_family text,worms_genus text,worms_species text,worms_subspecies text,worms_is_marine text,worms_is_brackish text,worms_is_freshwater text,worms_is_terrestrial text,worms_lsid text,worms_url text);

/*
COPY import.taxamatch 
FROM 
'/home/ftheeten/transfer/import_tv_ipt/taxamatch.csv'
WITH CSV
DELIMITER ','
QUOTE E'\"'
HEADER
*/

/*

COPY import.taxamatch (taxon, worms_id, worms_scientific_name, worms_is_terrestrial, worms_is_freshwater, worms_is_brackish, worms_is_marine, worms_lsid, worms_url)

FROM '/home/ftheeten/transfer/import_tv_ipt/taxamatch2.csv' DELIMITER E'\t' CSV HEADER;

*/