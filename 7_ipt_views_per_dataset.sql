CREATE OR REPLACE view ipt.be_rbins_vertebrates_aves as select 'be_rbins_vertebrates_aves' as dataset_id, 'Royal Belgian Institute of Natural Sciences Bird Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='aves';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_belgianmarineinvertebrates as select 'be_rbins_invertebrates_belgianmarineinvertebrates' as dataset_id, 'Royal Belgian Institute of Natural Sciences Belgian Marine Invertebrates collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='belgianmarineinvertebrates';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_brachiopoda as select 'be_rbins_invertebrates_brachiopoda' as dataset_id, 'Royal Belgian Institute of Natural Sciences Brachiopoda collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='brachiopoda';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_bryozoa as select 'be_rbins_invertebrates_bryozoa' as dataset_id, 'Royal Belgian Institute of Natural Sciences Bryozoa collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='bryozoa';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_cheliceratamarine as select 'be_rbins_invertebrates_cheliceratamarine' as dataset_id, 'Royal Belgian Institute of Natural Sciences marine Chelicerata collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='cheliceratamarine';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_cnidaria as select 'be_rbins_invertebrates_cnidaria' as dataset_id, 'Royal Belgian Institute of Natural Sciences Cnidaria collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='cnidaria';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_crustacea as select 'be_rbins_invertebrates_crustacea' as dataset_id, 'Royal Belgian Institute of Natural Sciences Crustacea collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='crustacea';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_echinodermata as select 'be_rbins_invertebrates_echinodermata' as dataset_id, 'Royal Belgian Institute of Natural Sciences Echinodermata collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='echinodermata';
CREATE OR REPLACE view ipt.be_rbins_vertebrates_mammalia as select 'be_rbins_vertebrates_mammalia' as dataset_id, 'Royal Belgian Institute of Natural Sciences Mammalia collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='mammalia';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_mollusca as select 'be_rbins_invertebrates_mollusca' as dataset_id, '	Royal Belgian Institute of Natural Sciences Mollusca collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='mollusca';
CREATE OR REPLACE view ipt.be_rbins_vertebrates_pisces as select 'be_rbins_vertebrates_pisces' as dataset_id, 'Royal Belgian Institute of Natural Sciences Pisces collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='pisces';
CREATE OR REPLACE view ipt.be_rbins_vertebrates_reptilia as select 'be_rbins_vertebrates_reptilia' as dataset_id, 'Royal Belgian Institute of Natural Sciences Reptilia collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='reptilia';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_rotifera as select 'be_rbins_invertebrates_rotifera' as dataset_id, 'Royal Belgian Institute of Natural Sciences Rotifera collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='rotifera';
CREATE OR REPLACE view ipt.be_rbins_vertebrates_vertebratestypes as select 'be_rbins_vertebrates_vertebratestypes' as dataset_id, 'Royal Belgian Institute of Natural Sciences vertebrate types collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='vertebratestypes';

CREATE OR REPLACE view ipt.be_rbins_invertebrates_acari as select 'be_rbins_invertebrates_acari' as dataset_id, 'Royal Belgian Institute of Natural Sciences Acari Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='acari';
CREATE OR REPLACE view ipt.be_rbins_vertebrates_amphibia as select 'be_rbins_vertebrates_amphibia' as dataset_id, 'Royal Belgian Institute of Natural Sciences Amphibia Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='amphibia';
CREATE OR REPLACE view ipt.be_rbins_invertebrates_araneae as select 'be_rbins_invertebrates_araneae' as dataset_id, 'Royal Belgian Institute of Natural Sciences Araneae Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='araneae';
CREATE OR REPLACE view ipt.be_rbins_entomology_coleoptera as select 'be_rbins_entomology_coleoptera' as dataset_id, 'Royal Belgian Institute of Natural Sciences Coleoptera Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='coleoptera';
CREATE OR REPLACE view ipt.be_rbins_entomology_diptera as select 'be_rbins_entomology_diptera' as dataset_id, 'Royal Belgian Institute of Natural Sciences Diptera Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='diptera';
CREATE OR REPLACE view ipt.be_rbins_entomology_heterocera as select 'be_rbins_entomology_heterocera' as dataset_id, 'Royal Belgian Institute of Natural Sciences Heterocera Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='heterocera';
CREATE OR REPLACE view ipt.be_rbins_entomology_hymenoptera as select 'be_rbins_entomology_hymenoptera' as dataset_id, 'Royal Belgian Institute of Natural Sciences Hymenoptera Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='hymenoptera';
CREATE OR REPLACE view ipt.be_rbins_entomology_orthoptera as select 'be_rbins_entomology_orthoptera' as dataset_id, 'Royal Belgian Institute of Natural Sciences Orthoptera Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='orthoptera';
CREATE OR REPLACE view ipt.be_rbins_entomology_rhopalocera as select 'be_rbins_entomology_rhopalocera' as dataset_id, 'Royal Belgian Institute of Natural Sciences Rhopalocera Collection' as dataset_name, occ.* from ipt.mv_darwin_ipt_rbins occ left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where /*scientific_name_id is not null and decimal_latitude is not null and*/ name_indexed='rhopalocera';

CREATE OR REPLACE view ipt.be_rbins_darwin as select 'be_rbins_darwin'::text AS dataset_id,'Royal Belgian Institute of Natural Sciences Collection'::text AS dataset_name,* from ipt.mv_darwin_ipt_rbins;
/*------------------------*/

CREATE OR REPLACE view ipt.be_rbins_vertebrates_aves_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_vertebrates_aves occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_belgianmarineinvertebrates_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_belgianmarineinvertebrates occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_brachiopoda_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_brachiopoda occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_bryozoa_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_bryozoa occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_cheliceratamarine_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_cheliceratamarine occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_cnidaria_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_cnidaria occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_crustacea_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_crustacea occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_echinodermata_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_echinodermata occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_vertebrates_mammalia_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_vertebrates_mammalia occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_mollusca_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_mollusca occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_vertebrates_pisces_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_vertebrates_pisces occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_vertebrates_reptilia_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_vertebrates_reptilia occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_rotifera_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_rotifera occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_vertebrates_vertebratestypes_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_vertebrates_vertebratestypes occ on occ.occurrence_id=mof.occurrence_id;

CREATE OR REPLACE view ipt.be_rbins_invertebrates_acari_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_acari occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_vertebrates_amphibia_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_vertebrates_amphibia occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_invertebrates_araneae_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_invertebrates_araneae occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_entomology_coleoptera_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_entomology_coleoptera occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_entomology_diptera_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_entomology_diptera occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_entomology_heterocera_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_entomology_heterocera occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_entomology_hymenoptera_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_entomology_hymenoptera occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_entomology_orthoptera_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_entomology_orthoptera occ on occ.occurrence_id=mof.occurrence_id;
CREATE OR REPLACE view ipt.be_rbins_entomology_rhopalocera_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof inner join ipt.be_rbins_entomology_rhopalocera occ on occ.occurrence_id=mof.occurrence_id;

CREATE OR REPLACE view ipt.be_rbins_darwin_mof as select mof.* from ipt.mv_darwin_ipt_rbins_mof mof;

GRANT SELECT ON ipt.be_rbins_vertebrates_aves TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_belgianmarineinvertebrates TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_brachiopoda TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_bryozoa TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_cheliceratamarine TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_cnidaria TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_crustacea TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_echinodermata TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_mammalia TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_mollusca TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_pisces TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_reptilia TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_rotifera TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_vertebratestypes TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_acari TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_amphibia TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_araneae TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_coleoptera TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_diptera TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_heterocera TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_hymenoptera TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_orthoptera TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_rhopalocera TO iptreader;

GRANT SELECT ON ipt.be_rbins_darwin TO iptreader;

GRANT SELECT ON ipt.be_rbins_vertebrates_aves_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_belgianmarineinvertebrates_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_brachiopoda_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_bryozoa_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_cheliceratamarine_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_cnidaria_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_crustacea_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_echinodermata_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_mammalia_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_mollusca_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_pisces_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_reptilia_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_rotifera_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_vertebratestypes_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_acari_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_vertebrates_amphibia_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_invertebrates_araneae_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_coleoptera_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_diptera_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_heterocera_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_hymenoptera_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_orthoptera_mof TO iptreader;
GRANT SELECT ON ipt.be_rbins_entomology_rhopalocera_mof TO iptreader;

GRANT SELECT ON ipt.be_rbins_darwin_mof TO iptreader;

