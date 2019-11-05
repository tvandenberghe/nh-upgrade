set search_path to darwin2,public;

/*
--Run the GBIF/WORMS importer
--INEFFICIENT
--alter table taxonomy add column is_marine boolean;
--UPDATE taxonomy SET IS_MARINE=FALSE;
--update taxonomy set is_marine=true where id in ( select DISTINCT t.id from taxonomy t join taxon_gbif_map g on g.canonical_name=t.name or g.canonical_name||' '||g.authority=t.name);

--update taxonomy set is_marine=true where taxonomy.id in (
--select t2.id from taxonomy t1 
--left join taxonomy t2 on t2.path LIKE '%/'||t1.id||'/%' where t1.level_ref=41 and t1.is_marine=true)

--ALTER TABLE SPEcimens add column is_marine boolean;
--UPDATE SPECIMENS SET IS_MARINE=FALSE;
--update SPEcimens set is_marine=true where taxon_ref in (select id from taxonomy where is_marine=true)

--drop table if exists taxon_gbif_map;
--create table taxon_gbif_map(GBIF_KEY text, CANONICAL_NAME text, AUTHORITY text,ACCEPTED_KEY text,IS_MARINE boolean,WORMS_ID text);

--update specimens set is_marine=true where id in (
--SELECT s.id
--FROM specimens s
--JOIN oceans o  ON ST_within(ST_setSRID(ST_Point(s.gtu_location[1],s.gtu_location[0]), 4326), ST_EXPAND(o.geom,-4000))) and is_marine is null;
*/
update taxonomy set name=trim(name) where name ~ ' $';
update taxonomy set name=trim(name, chr(160)) where name like '%'||chr(160)||'%';
/*
Import the csv file (83MB) from Franck his taxa match as import.taxamatch.
example pgfutter --host dddd --db darwin_dev2019 --port 5432 --user postgres --pw "" csv /home/thomas/Documents/Project-NaturalHeritage/mappings/import.taxamatch.csv -d ','
default is to place the file in a new schema named import.
*/

 DROP table if exists taxonomy_authority  ;

create table taxonomy_authority  (
  id serial NOT NULL, -- Primary key of the authoritative representation of a taxon.
  taxonomy_ref integer NOT NULL, --a reference to a entry in the taxonomy table: these are unique wrt path, name and level (rank)
  domain_ref bigint NOT NULL, -- Reference to the domain (taxonomic backbone) that authored the authoritative representation of a taxon entry.
  url character varying  NULL, -- The url of the taxonomic backbone entry. Mandatory.
  urn character varying, -- The urn or pseudo-urn of the taxonomic backbone entry.
  code character varying NOT NULL, -- The internal identifier used in the domain (for example the WORMS Aphia ID).
  pref_label character varying(255), -- The principal name used for the term by the taxonomic backbone.
  profile hstore, -- the ecological profile (marine, terrestrial, brackish, freshwater) as found on the taxonomic backbone
CONSTRAINT taxonomy_authority_pk PRIMARY KEY (id),
CONSTRAINT fk_taxon FOREIGN KEY (taxonomy_ref)
  REFERENCES taxonomy (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT fk_taxonomy_authority_domain_id FOREIGN KEY (domain_ref)
  REFERENCES authority_domain (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT unq_taxonomy_authority UNIQUE (url,taxonomy_ref));

insert into authority_domain (name,website_url,webservice_root,webservice_format) values ('marinespecies.org','http://www.marinespecies.org/','http://www.marinespecies.org/rest/','json');
insert into authority_domain (name,website_url,webservice_root,webservice_format) values ('gbif.org','https://www.gbif.org/','http://api.gbif.org/v1','json');

insert into taxonomy_authority (taxonomy_ref,domain_ref,code,urn,url,pref_label)
select t.id, a.id, m.worms_id, m.worms_lsid, m.worms_url, m.worms_scientific_name
 from taxonomy t
 inner join import.taxamatch m on t.name=m.taxon
 left join authority_domain a on a.name='marinespecies.org'
 where m.worms_id <>''
and t.id is not null ON CONFLICT (url, taxonomy_ref) DO NOTHING;

insert into taxonomy_authority (taxonomy_ref,domain_ref,code,urn,url,pref_label)
select t.id, a.id, m.gbif_id, null, case when m.gbif_id=null or m.gbif_id='' then null else 'https://www.gbif.org/species/'||m.gbif_id end, m.gbif_matched
 from taxonomy t
 right join import.taxamatch m on t.name=m.taxon
 left join authority_domain a on a.name='gbif.org'
 where m.gbif_id <>''
and t.id is not null ON CONFLICT (url, taxonomy_ref) DO NOTHING;

delete from taxonomy_authority where url='' and urn is not null;

CREATE UNIQUE INDEX taxonomy_authority_idx ON taxonomy_authority (taxonomy_ref,pref_label,url,code);

update taxonomy_authority set profile='';
update taxonomy_authority set profile=profile || 'isTerrestrial=>true' where code in (select distinct worms_id from import.taxamatch where worms_is_terrestrial='True');
update taxonomy_authority set profile=profile || 'isMarine=>true' where code in (select distinct worms_id from import.taxamatch where worms_is_marine='True');
update taxonomy_authority set profile=profile || 'isFreshwater=>true' where code in (select distinct worms_id from import.taxamatch where worms_is_freshwater='True');
update taxonomy_authority set profile=profile || 'isBrackish=>true' where code in (select distinct worms_id from import.taxamatch where worms_is_brackish='True');
update taxonomy_authority set profile= null where profile ='';
CREATE INDEX taxonomy_is_marine_authority_idx ON taxonomy_authority (
	(profile -> 'isMarine')
);
--wrong entries
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=129841 and urn='urn:lsid:marinespecies.org:taxname:205193';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=130228 and urn='urn:lsid:marinespecies.org:taxname:731966';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177173 and urn='urn:lsid:marinespecies.org:taxname:205662';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177174 and urn='urn:lsid:marinespecies.org:taxname:205662';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177175 and urn='urn:lsid:marinespecies.org:taxname:205662';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177179 and urn='urn:lsid:marinespecies.org:taxname:106978';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177186 and urn='urn:lsid:marinespecies.org:taxname:123476';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177191 and urn='urn:lsid:marinespecies.org:taxname:123460';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177192 and urn='urn:lsid:marinespecies.org:taxname:137758';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177201 and urn='urn:lsid:marinespecies.org:taxname:127635';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177203 and urn='urn:lsid:marinespecies.org:taxname:205267';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177208 and urn='urn:lsid:marinespecies.org:taxname:123438';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177209 and urn='urn:lsid:marinespecies.org:taxname:123477';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177212 and urn='urn:lsid:marinespecies.org:taxname:206862';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177213 and urn='urn:lsid:marinespecies.org:taxname:206862';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177214 and urn='urn:lsid:marinespecies.org:taxname:206862';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177218 and urn='urn:lsid:marinespecies.org:taxname:160249';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177225 and urn='urn:lsid:marinespecies.org:taxname:206304';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177230 and urn='urn:lsid:marinespecies.org:taxname:123447';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177265 and urn='urn:lsid:marinespecies.org:taxname:106445';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177267 and urn='urn:lsid:marinespecies.org:taxname:545512';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177277 and urn='urn:lsid:marinespecies.org:taxname:206887';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177295 and urn='urn:lsid:marinespecies.org:taxname:768325';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177302 and urn='urn:lsid:marinespecies.org:taxname:123453';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177303 and urn='urn:lsid:marinespecies.org:taxname:123453';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177305 and urn='urn:lsid:marinespecies.org:taxname:413467';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=177310 and urn='urn:lsid:marinespecies.org:taxname:138615';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=178012 and urn='urn:lsid:marinespecies.org:taxname:101537';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=181904 and urn='urn:lsid:marinespecies.org:taxname:744599';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=191562 and urn='urn:lsid:marinespecies.org:taxname:138615';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=192276 and urn='urn:lsid:marinespecies.org:taxname:594494';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201687 and urn='urn:lsid:marinespecies.org:taxname:138144';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201714 and urn='urn:lsid:marinespecies.org:taxname:138091';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201720 and urn='urn:lsid:marinespecies.org:taxname:156822';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201749 and urn='urn:lsid:marinespecies.org:taxname:492481';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201826 and urn='urn:lsid:marinespecies.org:taxname:138457';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201854 and urn='urn:lsid:marinespecies.org:taxname:138072';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201858 and urn='urn:lsid:marinespecies.org:taxname:716494';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201868 and urn='urn:lsid:marinespecies.org:taxname:598651';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=201873 and urn='urn:lsid:marinespecies.org:taxname:415594';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=206077 and urn='urn:lsid:marinespecies.org:taxname:205242';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=206478 and urn='urn:lsid:marinespecies.org:taxname:106930';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=206741 and urn='urn:lsid:marinespecies.org:taxname:138013';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=206825 and urn='urn:lsid:marinespecies.org:taxname:137760';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=206836 and urn='urn:lsid:marinespecies.org:taxname:464459';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=206839 and urn='urn:lsid:marinespecies.org:taxname:160231';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=208669 and urn='urn:lsid:marinespecies.org:taxname:137703';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=210360 and urn='urn:lsid:marinespecies.org:taxname:172883';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=230444 and urn='urn:lsid:marinespecies.org:taxname:382562';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=230603 and urn='urn:lsid:marinespecies.org:taxname:123620';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=230936 and urn='urn:lsid:marinespecies.org:taxname:206252';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=231095 and urn='urn:lsid:marinespecies.org:taxname:178195';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=231469 and urn='urn:lsid:marinespecies.org:taxname:206179';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=231569 and urn='urn:lsid:marinespecies.org:taxname:123592';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=231585 and urn='urn:lsid:marinespecies.org:taxname:123592';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=232415 and urn='urn:lsid:marinespecies.org:taxname:178808';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=234273 and urn='urn:lsid:marinespecies.org:taxname:526241';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=234960 and urn='urn:lsid:marinespecies.org:taxname:172883';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=234963 and urn='urn:lsid:marinespecies.org:taxname:172883';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=235058 and urn='urn:lsid:marinespecies.org:taxname:110865';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=235076 and urn='urn:lsid:marinespecies.org:taxname:146779';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=235099 and urn='urn:lsid:marinespecies.org:taxname:173618';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=235170 and urn='urn:lsid:marinespecies.org:taxname:110941';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=235223 and urn='urn:lsid:marinespecies.org:taxname:174320';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=235244 and urn='urn:lsid:marinespecies.org:taxname:110979';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=236058 and urn='urn:lsid:marinespecies.org:taxname:269225';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=236062 and urn='urn:lsid:marinespecies.org:taxname:1043464';
DELETE FROM darwin2.taxonomy_authority WHERE taxonomy_ref=237776 and urn='urn:lsid:marinespecies.org:taxname:101506';
