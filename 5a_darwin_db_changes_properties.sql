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
