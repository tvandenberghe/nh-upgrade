set search_path to darwin2,public;

CREATE TABLE darwin2.tag_group_distinct (
                id SERIAL NOT NULL,
                sub_group_name_indexed VARCHAR NOT NULL,
                group_name_indexed VARCHAR NOT NULL,
                tag_value VARCHAR NOT NULL,
                --path VARCHAR NOT NULL, --TODO
                CONSTRAINT id PRIMARY KEY (id),
                CONSTRAINT subgroup_group_value_unique UNIQUE (tag_value, group_name_indexed, sub_group_name_indexed)
);
ALTER TABLE darwin2.tag_group_distinct
  OWNER TO darwin2;
GRANT ALL ON TABLE darwin2.tag_group_distinct TO darwin2;
COMMENT ON TABLE darwin2.tag_group_distinct
  IS 'List of all distinct tags';
COMMENT ON COLUMN darwin2.tag_group_distinct.id IS 'Unique identifier of a tag value/group name/sub group name combination';
COMMENT ON COLUMN darwin2.tag_group_distinct.sub_group_name_indexed IS 'Reference to the sub_group_name';
COMMENT ON COLUMN darwin2.tag_group_distinct.group_name_indexed IS 'Reference to the group_name';
COMMENT ON COLUMN darwin2.tag_group_distinct.tag_value IS 'Textual value of the tag.';

ALTER TABLE darwin2.tag_groups ADD COLUMN tag_group_distinct_ref bigint, 
ADD CONSTRAINT fk_tag_group_distinct_id FOREIGN KEY (tag_group_distinct_ref) REFERENCES tag_group_distinct(id);

CREATE TABLE darwin2.authority_domain (
                id SERIAL NOT NULL,
                name VARCHAR NOT NULL,
                website_url VARCHAR NULL,
                webservice_root VARCHAR NULL,
                webservice_format VARCHAR NULL,
                CONSTRAINT authority_domain_pk PRIMARY KEY (id),
                CONSTRAINT authority_domain_uq UNIQUE (name) --a domain can only be defined once
);

ALTER TABLE darwin2.authority_domain
  OWNER TO darwin2;
GRANT ALL ON TABLE darwin2.authority_domain TO darwin2;
COMMENT ON TABLE darwin2.authority_domain
  IS 'List of all authority domains that contributed to a mapping';
COMMENT ON COLUMN darwin2.authority_domain.id IS 'Unique identifier of a authority domain.';
COMMENT ON COLUMN darwin2.authority_domain.name IS 'Name of the authority domain';
COMMENT ON COLUMN darwin2.authority_domain.website_url IS 'Front-end URL of the authority domain';
COMMENT ON COLUMN darwin2.authority_domain.webservice_root IS 'Webservice endpoint of the authority domain.';
COMMENT ON COLUMN darwin2.authority_domain.webservice_format IS 'Main returned format of the authority domain. Might be multiple.';

CREATE TABLE darwin2.tag_authority (
                id SERIAL NOT NULL,
                domain_ref BIGINT NOT NULL,
                source VARCHAR,
                url VARCHAR NOT NULL,
                urn VARCHAR,
                code VARCHAR,
                type text[],
                pref_label VARCHAR(255) NOT NULL,
                definition VARCHAR,
                synonyms text[],
                language_variants hstore,
                alternative_representations jsonb,
                CONSTRAINT tag_authority_pk PRIMARY KEY (id),
                CONSTRAINT fk_authority_domain FOREIGN KEY (domain_ref)
				REFERENCES darwin2.authority_domain (id) MATCH SIMPLE,
				CONSTRAINT tag_authority_uq UNIQUE (domain_ref, url) --an authority entry can only occur once
);
ALTER TABLE darwin2.tag_authority
  OWNER TO darwin2;
GRANT ALL ON TABLE darwin2.tag_authority TO darwin2;
COMMENT ON TABLE darwin2.tag_authority
  IS 'Formal representations of tags used in DarWIN as they appear in vocabularies or gazetteers. All mapped entries must have a resolvable url and a preferred label.';
COMMENT ON COLUMN darwin2.tag_authority.id IS 'Primary key of the authoritative representation of a tag.';

COMMENT ON COLUMN darwin2.tag_authority.domain_ref IS 'Reference to the domain that authored the authoritative representation.';
COMMENT ON COLUMN darwin2.tag_authority.source IS 'A gazetter might have aggregated a matching entry from other sources. This source can be considered a subdomain if it is only aggregated by one (this) domain.';
COMMENT ON COLUMN darwin2.tag_authority.url IS 'The url of the authority entry. Mandatory.';
COMMENT ON COLUMN darwin2.tag_authority.urn IS 'The urn or pseudo-urn of the authority entry.';
COMMENT ON COLUMN darwin2.tag_authority.code IS 'The internal identifier used in the domain (for example the GeoNames number).';
COMMENT ON COLUMN darwin2.tag_authority.type IS 'An array of the most specific types that a gazetteer has attached to this entry. Example:';
COMMENT ON COLUMN darwin2.tag_authority.pref_label IS 'The principal name used for the term by the authority or gazetteer. Mandatory.';
COMMENT ON COLUMN darwin2.tag_authority.definition IS 'The definition of the term used by the authority or gazetteer.';
COMMENT ON COLUMN darwin2.tag_authority.synonyms IS 'A flat array containing synonyms. NOT intended as a reference towards other entries in the same authority, should contain only information gathered from the entry itself. Example: "Montana","The Buckeye State"';
COMMENT ON COLUMN darwin2.tag_authority.language_variants IS 'An associative array containing key-value pairs for language variants. NOT intended as a reference towards other entries in the same authority, should contain only information gathered from the entry itself. Example: "@de": "Bayern"; "@nl":"Beieren"';
COMMENT ON COLUMN darwin2.tag_authority.alternative_representations IS 'An associative array containing key-value pairs for alternative representations. NOT intended as a reference towards other entries in the same authority, should contain only information gathered from the entry itself. Example: "ISO 3166-2": "DE"; "ISO 3166-3":"DEU"';

CREATE TABLE darwin2.tag_tag_authority (
                tag_authority_ref BIGINT NOT NULL,
                tag_group_distinct_ref BIGINT NOT NULL,
                tag_authority_match_predicate text NOT NULL, 
				CONSTRAINT tag_tag_authority_pk PRIMARY KEY (tag_authority_ref, tag_group_distinct_ref,tag_authority_match_predicate),
                CONSTRAINT fk_tag FOREIGN KEY (tag_group_distinct_ref)
				REFERENCES darwin2.tag_group_distinct (id) MATCH SIMPLE,
				CONSTRAINT fk_authority FOREIGN KEY (tag_authority_ref)
				REFERENCES darwin2.tag_authority (id) MATCH SIMPLE,
				CONSTRAINT chk_predicate_onto CHECK (tag_authority_match_predicate LIKE '%skos:%' or tag_authority_match_predicate LIKE '%owl:%')
);

GRANT ALL ON TABLE darwin2.tag_tag_authority TO darwin2;
COMMENT ON TABLE darwin2.tag_tag_authority
  IS 'The coupling table between vocabulary entries and tags.';
  COMMENT ON COLUMN darwin2.tag_tag_authority.tag_group_distinct_ref IS 'Reference to the distinct grouped tag as used in DarWIN.';
  COMMENT ON COLUMN darwin2.tag_tag_authority.tag_authority_ref IS 'Reference to the authoritative vocabulary entry.';
  COMMENT ON COLUMN darwin2.tag_tag_authority.tag_authority_match_predicate IS 'Predicate that indicates how close the match between the tag and the authoritative url is: must use a predicate from an existing ontology, i.e. skos:broader, skos:narrower, owl:sameAs.';

-- Function: fct_cpy_gtutags()

--DROP FUNCTION IF EXISTS fct_cpy_gtutags();

CREATE OR REPLACE FUNCTION fct_cpy_tags_to_distinct()
  RETURNS trigger AS
$BODY$
DECLARE
BEGIN
  CASE TG_OP
	WHEN 'UPDATE' THEN
		IF NEW.sub_group_name_indexed IS DISTINCT FROM OLD.sub_group_name_indexed or NEW.group_name_indexed IS DISTINCT FROM OLD.group_name_indexed or NEW.tag_value IS DISTINCT FROM OLD.tag_value THEN 
		BEGIN
			RAISE NOTICE 'try to update: %, %, % towards  %, %, %', OLD.sub_group_name_indexed, OLD.group_name_indexed,OLD.tag_value, NEW.sub_group_name_indexed, NEW.group_name_indexed,NEW.tag_value;
			UPDATE tag_group_distinct SET 
			sub_group_name_indexed=NEW.sub_group_name_indexed,
			group_name_indexed=NEW.group_name_indexed,
			tag_value=NEW.tag_value
			where 
			sub_group_name_indexed=OLD.sub_group_name_indexed AND
			group_name_indexed=OLD.group_name_indexed AND
			tag_value=OLD.tag_value;
			--delete the representation in the tag_tag_authority because we don't know if the term is still the same! The whole geonames import script will need to be run again for this term! The old vocabulary entry is kept, only the m:n link is severed.
			DELETE FROM tag_tag_authority WHERE tag_group_distinct_ref IN 
			(SELECT id FROM tag_group_distinct 
			where 
			sub_group_name_indexed=OLD.sub_group_name_indexed AND
			group_name_indexed=OLD.group_name_indexed AND
			tag_value=OLD.tag_value);
		EXCEPTION WHEN unique_violation THEN
			RAISE NOTICE 'UQ violation when updating!';
			--if renaming a term to something that already exists in the table, it means that the original has to go. It also means that the representation in the tag_authority has to go
			--delete first the representation in the tag_authority because otherwise a FK constraint error will be raised.
			DELETE FROM tag_authority WHERE tag_group_distinct_ref IN 
			(SELECT id FROM tag_group_distinct 
			WHERE 
			sub_group_name_indexed=OLD.sub_group_name_indexed AND
			group_name_indexed=OLD.group_name_indexed AND
			tag_value=OLD.tag_value);
			
			DELETE FROM tag_group_distinct WHERE
			sub_group_name_indexed=OLD.sub_group_name_indexed and
			group_name_indexed=OLD.group_name_indexed and
			tag_value=OLD.tag_value;
		END;
		END IF;
		RETURN NEW;
	WHEN 'INSERT' THEN
		BEGIN
			RAISE NOTICE 'try to insert: %, %, %', NEW.sub_group_name_indexed, NEW.group_name_indexed,NEW.tag_value;
			with insert_tag_group_distinct_cte as (
			INSERT INTO tag_group_distinct (sub_group_name_indexed,group_name_indexed,tag_value) VALUES
			(NEW.sub_group_name_indexed,
			NEW.group_name_indexed,
			NEW.tag_value) returning id)
			update tag_groups tg set tag_group_distinct_ref=cte.id from insert_tag_group_distinct_cte cte where tg.id=NEW.id;
			RAISE NOTICE 'Insert successful: created tag_group_distinct entry and made FK referral towards this from tag_groups';
			RETURN NEW;
		EXCEPTION WHEN unique_violation THEN
			RAISE NOTICE 'UQ violation when inserting in tag_group_distinct! Nothing new inserted in tag_group_distinct. You can ignore this message.';
		END;
  END CASE;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fct_cpy_tags_to_distinct()
  OWNER TO darwin2;

DROP TRIGGER IF EXISTS trg_cpy_tags_to_distinct ON tag_groups;
  
/*CREATE TRIGGER trg_cpy_tags_to_distinct
AFTER INSERT OR UPDATE ON tag_groups --delete keeps the values in tag_group_distinct
FOR EACH ROW 
WHEN (NEW.sub_group_name_indexed is not null or NEW.group_name_indexed is not null or NEW.tag_value is not null) 
EXECUTE PROCEDURE fct_cpy_tags_to_distinct();*/ --the trigger causes a deadlock apparently


ALTER TABLE darwin2.tag_groups DISABLE TRIGGER fct_cpy_trg_del_dict_tag_groups;
ALTER TABLE darwin2.tag_groups DISABLE TRIGGER fct_cpy_trg_ins_update_dict_tag_groups;
ALTER TABLE darwin2.tag_groups DISABLE TRIGGER trg_cpy_fulltoindex_taggroups;
ALTER TABLE darwin2.tag_groups DISABLE TRIGGER trg_cpy_gtutags_taggroups;
ALTER TABLE darwin2.tag_groups DISABLE TRIGGER trg_trk_log_table_tag_groups;
ALTER TABLE darwin2.tag_groups DISABLE TRIGGER trg_update_tag_groups_darwin_flat;

with insert_tag_group_distinct_cte as (insert into tag_group_distinct (sub_group_name_indexed,group_name_indexed,tag_value) 
select sub_group_name_indexed, group_name_indexed, tag_value from tag_groups 
group by sub_group_name_indexed, group_name_indexed, tag_value
order by sub_group_name_indexed, group_name_indexed, tag_value
returning id,sub_group_name_indexed, group_name_indexed, tag_value)
update tag_groups set tag_group_distinct_ref=cte.id from insert_tag_group_distinct_cte cte where tag_groups.sub_group_name_indexed=cte.sub_group_name_indexed and tag_groups.group_name_indexed=cte.group_name_indexed and  tag_groups.tag_value=cte.tag_value;

ALTER TABLE darwin2.tag_groups ENABLE TRIGGER fct_cpy_trg_del_dict_tag_groups;
ALTER TABLE darwin2.tag_groups ENABLE TRIGGER fct_cpy_trg_ins_update_dict_tag_groups;
ALTER TABLE darwin2.tag_groups ENABLE TRIGGER trg_cpy_fulltoindex_taggroups;
ALTER TABLE darwin2.tag_groups ENABLE TRIGGER trg_cpy_gtutags_taggroups;
ALTER TABLE darwin2.tag_groups ENABLE TRIGGER trg_trk_log_table_tag_groups;
ALTER TABLE darwin2.tag_groups ENABLE TRIGGER trg_update_tag_groups_darwin_flat;

--ALTER TABLE darwin2.tag_groups ALTER COLUMN tag_group_distinct_ref SET NOT NULL; --remove the constraint because this disallows the creation of new tags! Actually designed in conjunction with the trigger above

insert into authority_domain (name,website_url,webservice_root,webservice_format) values ('geonames.org','http://www.geonames.org/','http://api.geonames.org/search','json, xml');
insert into authority_domain (name,website_url,webservice_root,webservice_format) values ('marineregions.org','http://marineregions.org/','http://marineregions.org/resth','json');


CREATE TABLE darwin2.tag_groups_authority_categories (
    authority text,
    original_type character varying,
    original_sub_type character varying,
    gazetteer_type_mapped text,
    "order" smallint,
    priority text
);


ALTER TABLE darwin2.tag_groups_authority_categories OWNER TO postgres;


INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'ocean', 'OCN', 0);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'ridges', 'RDGE', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'ocean', 'OCN', 0);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sea', 'SEA', 1);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'sea', 'SEA', 1);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'seaarea', 'SEA', 1);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'dutchempire', 'PCLH', 2);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'historicstate', 'PCLH', 2);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'keizerrijk', 'PCLH', 2);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'historicalcountry', 'PCLH', 2);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'kingdom', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'autonomousconstituentcountry', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'autonomouscountry', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'republic', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'kingdom', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'country', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'constituentcountry', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'country', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'federatestate', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'independentpoliticalentity', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'sovereignstate', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'payslocalappelation', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'principalityprincedom', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrative', 'country', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'principaute', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'republic', 'PCLI', 3);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'crowncolony', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'frenchprotectorate', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'dependentpoliticalentity', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'colonykolonie', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'protectorate', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'frenchcolony', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'germancolonialempiredeutscheskolonialreich', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'britishoverseasterritories', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'protectedarea', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'britishcrowndependency', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'britishcentralafricaprotectorate', 'PCLD', 4);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'island', 'ISL', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'island', 'ISL', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'island', 'ISL', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'volcanicisland', 'ISL', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'islandcountry', 'ISL', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'island', 'ISL', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'isle', 'ISL', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'islet', 'ISLET', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'smallisland', 'ISLET', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'islet', 'ISLET', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'archipel', 'ISLS', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'islands', 'ISLS', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'archipelago', 'ISLS', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'volcanicarchipelago', 'ISLS', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'islands', 'ISLS', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'archipelago', 'ISLS', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'territory', 'TERR', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'territory', 'TERR', 5);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'monts', 'MTS', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mounts', 'MTS', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'massif', 'MTS', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mountains', 'MTS', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'zonemontagneuse', 'MTS', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'sierra', 'MTS', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mountainrange', 'MTS', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'rangelocalappelation', 'MTS', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'plateau', 'PLAT', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'hoogvlaktehighlandmassifmontagneux', 'PLAT', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'upland', 'UPLD', 6);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'region', 'RGN', 7);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'marineregion', 'SEA', 7);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'region', 'RGN', 7);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'region', 'RGN', 7);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'historicalregion', 'RGNH', 7);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'stateforest', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'naturalregion', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'nationaalparkparcnational', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'domaniaalnatuurreservaatreservenaturelledomanialestatenaturereserve', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'naturalregion', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'marineandcoastalprotectedarea', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'natuurgebied', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'nationalpark', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'reserve', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'naturalregion', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'naturschutzgebietnatuurreservaatnaturereservereservenaturelle', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'nationalpark', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'nationalpark', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'nationalpark', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'reserve', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'reservaatreservation', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'statepark', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'naturalsite', 'RES', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'forestreserve', 'RESF', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'forestreserve', 'RESF', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'beekjepetitruisseausmallstream', 'STM', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'rivulet', 'STM', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'river', 'STM', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'rio', 'STM', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'creek', 'STM', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'beekbrook', 'STM', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'affluentzijriviertributary', 'STM', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'stream', 'STM', 8);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mountain', 'MT', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'summitoftheislandsommetdelile', 'PK', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mountainpeak', 'PK', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'peak', 'PK', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'point', 'PT', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'point', 'PT', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'point', 'PT', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'point', 'PT', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'puntapuentepointe', 'PT', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'puntapuentepointe', 'PT', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'stratovolcano', 'VLC', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'volcano', 'VLC', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'submarinevolcano', 'MTU', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'complexvolcanocompoundvolcano', 'VLC', 9);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'firstorderadministrativedivision', 'ADM1', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'oblast', 'ADM2', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'secondorderadministrativedivision', 'ADM2', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'thirdorderadministrativedivision', 'ADM3', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'fourthorderadministrativedivision', 'ADM4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'specializedmunicipality', 'ADM4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'state', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'stateorprovince', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'stateorterritory', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'autonomousprefecture', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'autonomousregion', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'regionordistrict', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'regionalunit', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'subcountyconstituency', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'bundeslanddeelstaatstate', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'canton', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'province', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'censusarea', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'subdivision', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'subdivisionadministrative', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'prefecture', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'subprefecturessousprefectures', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'subregion', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'subprefecture', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'state', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'subregion', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'administrativedivision', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'province', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'prefecture', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'overseasterritory', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'overseasregion', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'overseasdepartmentsandterritoriesoffrance', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'county', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'department', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'departmentdepartement', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'departement', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'county', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'regionordistrict', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'stateorprovince', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'duchy', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'federaldistrict', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'localgovernmentarea', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'gewestcommunauteregion', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'semiautonomousregion', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'administrativedivision', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'administrativeregion', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'sovereigncitystate', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'arrondissement', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'kanton', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'hoofdstedelijkgewest', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'governorate', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'localgovernment', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'ancientsite', 'ANS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'landkreisprovinciedistrictcomte', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'kreisdistrictarrondissement', 'ADMD', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'site', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'locality', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'locality', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'station', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'place', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'place', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'place', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'location', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'locality', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'station', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'lieudit', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'lieudittopografie', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'lieuditlocalityplaats', 'LCTY', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'goldminingtown', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'populatedplace', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'village', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'autonomouscity', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'kreisfreiestadt', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'dorpvillage', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'community', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'markettown', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'city', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'fishingvillage', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mountainvillage', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'villemetropolitaine', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'village', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'stadvilletown', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'commune', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'fischerdorfvissersdorp', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'urbantypesettlement', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'populatedplace', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'unincorporatedcommunity', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'town', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'township', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'town', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'community', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'stadvilletown', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'autonomouscommunity', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'city', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'censusdesignatedplace', 'PPL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'seatofafirstorderadministrativedivision', 'PPLA', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'seatofasecondorderadministrativedivision', 'PPLA2', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'seatofathirdorderadministrativedivision', 'PPLA3', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'municipalunit', 'PPLA4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'municipality', 'PPLA4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'municipality', 'PPLA4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'petitecommunedeelgemeente', 'PPLA4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'gemeindemunicipality', 'PPLA4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'gemeindegemeenschapmunicipalitycommunaute', 'PPLA4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'gemeentecommune', 'PPLA4', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'capital', 'PPLC', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'provincialcapital', 'PPLG', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'prefecturallevelcity', 'PPLG', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'hamlethameau', 'PPLL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'hamlet', 'PPLL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'populatedlocality', 'PPLL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'gehuchthameauhamlet', 'PPLL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'hamlet', 'PPLL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'sherpavillage', 'PPLL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'hameau', 'PPLL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'settlement', 'PPLL', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'ghosttown', 'PPLQ', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'abandonnedpopulatedplace', 'PPLQ', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'populatedplaces', 'PPLS', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'destroyedpopulatedplace', 'PPLW', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'stadtteilebuurtneighborhoodsquartiers', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'sectionofpopulatedplace', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'borough', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'metropolitanborough', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'frazione', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'division', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'seasidesuburb', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'neighbourhood', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'ward', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'section', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'legaldistrict', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'sector', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'sector', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'suburbanarea', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'suburb', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'periphery', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'subdistrict', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'part', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'center', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'metropolitanarea', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'residentialarea', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'division', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'wijkquarterquartier', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'district', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'district', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'quartier', 'PPLX', 10);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'sectionofrussianempire', 'ADMDH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'plantation', 'AGRC', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'cattlestation', 'AGRF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'airfield', 'AIRF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'airport', 'AIRP', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'seaplanelandingarea', 'AIRS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'amphitheater', 'AMTH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'anchorage', 'ANCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'archaeologicalsite', 'ANS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'prehistoricsite', 'ANS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'fishfarm', 'AQC', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'viskwekerijpisciculturehatchery', 'AQC', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'arch', 'ARCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'area', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'area', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'area', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'area', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'sportcomplex', 'ATHF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'stadion', 'ATHF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'atol', 'ATOL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'atoll', 'ATOL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'bar', 'BAR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'bay', 'BAY', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'bay', 'BAY', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'beach', 'BCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'beach', 'BCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'beacon', 'BCN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'bridge', 'BDG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'bridge', 'BDG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'pontbrugbridge', 'BDG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'bights', 'BGHT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'gebouw', 'BLDG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'buildings', 'BLDG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'banc', 'BNKU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'banks', 'BNKU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'cay', 'BNKU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sandbank', 'BNKU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'cayzandbankbancdesable', 'BNKU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'cay', 'BNKU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'torfsumpfpeatswampturfmoerasmaraistourbeux', 'BOG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'flachmoorboglaagveentourbiereombrotrophe', 'BOG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'drainagebassin', 'BSND', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'basin', 'BSNU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'bushes', 'BUSH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'crag', 'BUTE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'cape', 'CAPE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'cape', 'CAPE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'cave', 'CAVE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'grotgrottecave', 'CAVE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'underground', 'cave', 'CAVE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'volcaniccavegrottevolcanique', 'CAVE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'cave', 'CAVE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'caves', 'CAVE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'cordilleracordillere', 'CDAU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'church', 'CH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'channel', 'CHN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'kanaalcanalchannel', 'CHN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'marinechannel', 'CHN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'vaartchannel', 'CHN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'channel', 'CHN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'channel', 'CHN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'lakechannels', 'CHNL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'caldera', 'CLDA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'cliffs', 'CLF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'cliff', 'CLF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'clearing', 'CLG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'camps', 'CMP', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'confluence', 'CNFL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'canals', 'CNL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'canal', 'CNL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'aqueduct', 'CNLA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'drainagecanal', 'CNLD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'irrigationcanal', 'CNLI', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'aqueducsouterrainundergroundaqueduct', 'CNLSB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'canyonlocalappelation', 'CNYN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'canyon', 'CNYN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'kloof', 'CNYN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'ravine', 'CNYU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'subamrinecanyon', 'CNYU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'ravine', 'CNYU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'cones', 'CONE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'subcontinenet', 'CONT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'continent', 'CONT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'continent', 'CONT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'coves', 'COVE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'tidalcreeks', 'CRKT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'tidalcreek', 'CRKT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'oceancurrent', 'CRNT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'cirque', 'CRQ', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'craters', 'CRTR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'coast', 'CST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'coastkustcote', 'CST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'coast', 'CST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'coast', 'CST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'chateau', 'CSTL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'castle', 'CSTL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'sanctuary', 'CTRR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'chapel', 'CTRR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'priory', 'CTRR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'abbey', 'CTRR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'abby', 'CTRR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'dam', 'DAM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'dam', 'DAM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'dam', 'DAM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'pier', 'DCK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'pier', 'DCK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'docks', 'DCK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'deep', 'DEPU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'delta', 'DLTA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'depressions', 'DPR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'desert', 'DSRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'habitat', 'desert', 'DSRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'ditch', 'DTCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'slootditchwassergrabenfosse', 'DTCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'fosse', 'DTCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'gracht', 'DTCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'drainageditch', 'DTCHD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'duinen', 'DUNE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'sandmeerergduinmassiefmassifdedunes', 'DUNE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'habitat', 'duinen', 'DUNE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'dunes', 'DUNE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'estates', 'EST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'estuary', 'ESTY', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'institute', 'FCL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'fishingarea', 'FISH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'fishery', 'FISH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sealoch', 'FJD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'fjord', 'FJD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'fields', 'FLD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'falls', 'FLLS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'waterfalls', 'FLLS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'waterfall', 'FLLS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'smallwaterfallkleinewatervalcascatelle', 'FLLS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'tidalflats', 'FLTM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'ford', 'FORD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'habitat', 'farm', 'FRM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'farm', 'FRM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'farm', 'FRM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'farms', 'FRMS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'hacienda', 'FRMT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'farmstead', 'FRMT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'farmstead', 'FRMT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'forestbeltceinturedeforetbosgordel', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'rainforest', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'wood', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'woodlandregionarboreebosgebied', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'urbanforest', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'mountainforest', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'forest', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'woodboisbos', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'bosdomein', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'forest', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'wood', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'elfinforest', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'foretwoudforest', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'forestforetbos', 'FRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'fort', 'FT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'fortress', 'FT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'fort', 'FT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'gap', 'GAP', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'botanicalgarden', 'GDN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'botanicalgarden', 'GDN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'arboretum', 'GDN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'garden', 'GDN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'gardens', 'GDN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'botanicalgarden', 'GDN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'plantentuinbotanicalgardenjardinbotanique', 'GDN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'tuinjardingarden', 'GDN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'glacier', 'GLCR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'gully', 'GLYU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'grazingarea', 'GRAZ', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'gorges', 'GRGE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'grassland', 'GRSLD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'gulf', 'GULF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'geyser', 'GYSR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sectionofharbor', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'port', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'seaport', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'port', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'marina', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'port', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'harbors', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'harbour', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'port', 'HBR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'headlands', 'HDLD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'head', 'HDLD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'hill', 'HLL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'hills', 'HLLS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'homestead', 'HMSD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'bluehole', 'HOLU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'hole', 'HOLU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'habitat', 'maison', 'HSE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'houses', 'HSE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'countryhouse', 'HSEC', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'heath', 'HTH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'hotel', 'HTL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'hut', 'HUT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'inlet', 'INLT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'isthmus', 'ISTH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'researchinstitute', 'ITTR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'jettysteigerjetee', 'JTY', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'saturatedkarst', 'KRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'limestoneplateaus', 'KRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'karstique', 'KRST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'landing', 'LDNG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'leveedijkdigue', 'LEV', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'laguna', 'LGN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'lagoon', 'LGN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'lagoons', 'LGN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'lake', 'LK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'lake', 'LK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'lake', 'LK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'glaciallake', 'LK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'craterlake', 'LKC', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'intermittentlake', 'LKI', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'saltlake', 'LKN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'billabong', 'LKO', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'lakes', 'LKS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'undergroundlake', 'LKSB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'unknown', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'recyclingcenter', 'LNDF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'lighthouse', 'LTHSE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'tabletopmountain', 'MESA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mesas', 'MESA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'brewery', 'MFGB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'mangroveswamp', 'MGV', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'mangrove', 'MGV', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'militarybase', 'MILB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'americanarmybase', 'MILB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'militaryairbase', 'MILB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'market', 'MKT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'mills', 'ML', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'formersugarmill', 'MLSGQ', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'windmill', 'MLWND', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'watermolen', 'MLWTR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'underground', 'coalmine', 'MN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'mines', 'MN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'koolmijncoalmineminedecharbon', 'MN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mounds', 'MND', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'kolk', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'floodedquarrycarriereinondee', 'MNQ', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'quarry', 'MNQR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'anciennecarriereoudesteengroevequarry', 'MNQR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'quarrycarrieresteengroeve', 'MNQR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'groevecarrierequarry', 'MNQR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'quarry', 'MNQR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'anciennecarriereoudesteengroevequarry', 'MNQR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'quarry', 'MNQR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'vennenfagnesfens', 'MOOR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'moat', 'MOTU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'marshmoeras', 'MRSH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'moerasmaraismarches', 'MRSH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'marshes', 'MRSH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'saltmarsh', 'MRSHN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'mosquee', 'MSQE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'mission', 'MSSN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'missionaryoutpost', 'MSSN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'mission', 'MSSN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'monastery', 'MSTY', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'museum', 'MUS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'narrows', 'NRWS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'oasis', 'OAS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'oasises', 'OAS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'oasis', 'OAS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'oasises', 'OAS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'oasis', 'OAS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'observatory', 'OBS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'oilfield', 'OILF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'oilrefinery', 'OILR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'palace', 'PAL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'pan', 'PAN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'pan', 'PAN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'pass', 'PASS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'col', 'PASS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'mountainpass', 'PASS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'politicalentity', 'PCL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'presquile', 'PEN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'peninsula', 'PEN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'polder', 'PLDR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'polder', 'PLDR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'plains', 'PLN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'underseaplateau', 'PLTU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'vijveretangpond', 'PND', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'pond', 'PND', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'etangenassec', 'PND', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'etangvijverpond', 'PND', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'ponds', 'PNDS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'fishpond', 'PNDSF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'etangdepechevisvijverfishingpond', 'PNDSF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'fischteichvisvijvervivierfishpond', 'PNDSF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'pools', 'POOL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'provincialdomain', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'provinciaaldomeinprovincialdomain', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'provinciaaldomein', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'recreationparc', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'park', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'recreatiedomein', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'domaineprovincial', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'memorialpark', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'parkparc', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'park', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'provinciaaldomein', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'park', 'PRK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'prison', 'PRN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'promontoryies', 'PROM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'paroisseparochieparish', 'PRSH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'civilparish', 'PRSH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'parish', 'PRSH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'kerncentralenuclearpowerplant', 'PS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'powerstation', 'PS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'reach', 'RCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'route', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'street', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'intersectionroad', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'weg', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'road', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'holleweg', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'highway', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'straatruestreet', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'dreefdreve', 'RD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'ancientroad', 'RDA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'roadjunction', 'RDJCT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'roadsted', 'RDST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'golftresort', 'RECG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'hippodroomhippodrome', 'RECR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'racetrack', 'RECR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'naturereserve', 'RESN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'naturereserve', 'RESN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'pub', 'REST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'restaurant', 'REST', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'indianreservation', 'RESV', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'wildlifereserve', 'RESW', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'store', 'RET', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sectionofreef', 'RFU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'coralreef', 'RFU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'reef', 'RFU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'reef', 'RFU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'reefunit', 'RFU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'rock', 'RK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'rocks', 'RKS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'religioussite', 'RLG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'ranches', 'RNCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'rapids', 'RPDS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'railroad', 'RR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'railroadsiding', 'RSD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'hillresort', 'RSRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'seasideresort', 'RSRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'resort', 'RSRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'seasideresort', 'RSRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'ressort', 'RSRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'resort', 'RSRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'railroadstation', 'RSTN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'railroadstation', 'RSTN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'trainstation', 'RSTN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'railroadstop', 'RSTP', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'stauseereservoir', 'RSV', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'reservoirs', 'RSV', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'ruins', 'RUIN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'ravines', 'RVN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'saltarea', 'SALT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'drystreambed', 'SBED', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'school', 'SCH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'college', 'SCHC', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'escarpment', 'SCRP', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'rim', 'SCRP', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sound', 'SD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'shoals', 'SHLU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'shore', 'SHOR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'shrine', 'SHRN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sinkholezinkgatdoline', 'SINK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'cenotelimestonesinkholes', 'SINK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'locksluisecluse', 'SLCE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sluissas', 'SLCE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'slope', 'SLPU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'seamount', 'SMU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'stationbalneaire', 'SPA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'spa', 'SPA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'spillway', 'SPLY', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'waterspring', 'SPNG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'zonesource', 'SPNG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'springs', 'SPNG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'source', 'SPNG', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'hotsprings', 'SPNT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'anabranch', 'STMA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'distributaryies', 'STMD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'intermittentstream', 'STMI', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'streammouths', 'STMM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'streams', 'STMS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'resurgence', 'STMSB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'exsurgence', 'STMSB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'undergroundriver', 'STMSB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sectionofstream', 'STMX', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'scientificresearchbase', 'STNB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'polarresearchstation', 'STNB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'meteorologicalstation', 'STNM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'weatherstation', 'STNM', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'steps', 'STPS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'strait', 'STRT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'swamp', 'SWMP', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'stationdepurationafvalwaterzuiveringsinstallatiewastewatertreatmentplant', 'SWT', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'necropole', 'TMB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'mausoleum', 'TMB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'temples', 'TMPL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'temple', 'TMPL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'tunnel', 'TNL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'tower', 'TOWR', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'tribalarea', 'TRB', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'appletreeappelboom', 'TREE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'trees', 'TREE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'longdistancefootpaths', 'TRL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'trail', 'TRL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', 'path', 'TRL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'trench', 'TRNU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'trench', 'TRNU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'university', 'UNIV', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'valley', 'VAL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'valleys', 'VALS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'seavalley', 'VALU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'underseavalley', 'VALU', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'oued', 'WAD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'wadi', 'WAD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'wharf', 'WHRF', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'well', 'WLL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'waterpits', 'WLL', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'wells', 'WLLS', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'shipwreck', 'WRCK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'wreck', 'WRCK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'boat', 'WRCK', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'wetland', 'WTLD', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'waterwaywaterloop', 'WTRC', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'watercourse', 'WTRC', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'waterholes', 'WTRH', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'zone', 'ZN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'zone', 'ZN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'zone', 'ZN', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'zoo', 'ZOO', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'undefined', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'hillstation', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'stretch', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'wijnboerderij', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'streampool', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'stationzoologique', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'stagnantwater', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'shrubbeltceinturearbustivestruikgordel', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'seep', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'sand', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'rainforestforetombrophileregenwoud', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'puddles', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'pitcavegouffreondergrondsekalksteenkoepel', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'phreaticzone', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'petitaffluent', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'passage', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'paddyswamp', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'paalweringpileresistance', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'outflow', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'oeverbank', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'nile', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'musselbeds', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'moss', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'cornichecornice', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'littoralzone', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'littoralvegetation', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'leaflitterbladafvallitiere', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'intertidalzone', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'interstitialwater', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'elevation', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'iceshelves', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'hyporheiczone', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'floodplainoverstromingsvlaktelit', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'highprairiehautesprairieshogeweide', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'groundwatereauxsouterrainesgrondwater', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'forestlitterbosstrooisellitiereforestiere', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'geologicformation', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'flow', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'drain', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'divesite', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'culvertsiphon', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'crevassespleet', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'coastalwater', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'coastallakes', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'cloudforestedmountain', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'branch', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'islandstation', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'betweenislands', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'bassindechassespuikom', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'kettleholetoteisseedoodijsgat', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'bassindechasse', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'badeseerecreatieplasbathinglakelacdebaignade', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'aquarium', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'lowlandslaagte', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'anchialinepool', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'massive', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'altwasseropstuwingbackwater', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'undefined', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'spanishempire', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'occupiedterritory', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'mandatmandaat', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', 'colonialfederationkolonialefederatiefederationcoloniale', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'historical', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'naturalarchnaturalbridge', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'habitat', 'savannasavannahsavanne', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'habitat', 'samplingarea', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'habitat', 'ecology', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'zeczonedexploitationcontrolee', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'naturallandscape', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'nationalforest', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'ecoregion', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', 'biogeografie', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'area', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'villagedevelopmentcommittee', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'unitesstates', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'unitaryauthority', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'unincorporatedarea', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'researchstation', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'rockhead', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'regency', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'overseascollectivity', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'scarp', 'RDGE', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'ortsteilwijkdistrictquartier', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'originaladministrativedata', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'occupiedterritory', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'steppe', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'oasiscity', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'topographic', 'thelesser', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'microregio', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'mesoregio', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'lieutenancyarea', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'underground', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'hillstation', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'federalsubject', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'exlave', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'counties', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'councilarea', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'condominium', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'communeafacilitesfaciliteitengemeente', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'commonwealthrealm', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'commonwealth', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'citystate', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'vegetation', 'plant', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'biogeographicrealmecozone', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', 'bassinlocalappelation', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'unescoworldheritagesite', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'guesthouse', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'greenhouseserre', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'enterprise', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'domein', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'cliffdwelling', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'mirador', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'citadel', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'carrieregroeve', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'career', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'camping', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'allotment', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'nationalreserve', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'naturallandscape', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'naturepark', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'naturereservenaturalreservebioreserve', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'road', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', 'siedlungsbereichenwoongebied', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'populated', '', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'vishandel', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'view', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'undefined', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'trawl', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'seamarknavigationmark', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'roadhouse', NULL, 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'refstockmans', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'poste', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'paroisse', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'formation', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'exactsite', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', 'domaine', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'other', '', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'orography', '', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'wolfsgrubewolfskuiltrappingpit', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'wheelrutsspoorvormingornierage', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'refuge', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'watervoorzieningarriveedeauwatersupply', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'watertube', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'waterplas', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'roadhouse', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'waterketelboilerchaudiere', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'wateringwatermeadow', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'vlei', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'vlasrootput', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'vadose', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'undefined', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'transbordeurpontferry', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'hydrographic', 'terrasse', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'administrativearea', '', 'AREA', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('geonames.org', 'spot', 'jeugdverblijf', 'AREA', 20);

INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'archipel', 'Archipelago', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'archipelago', 'Archipelago', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'archipelago', 'Archipelago', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'atol', 'Atoll', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'atoll', 'Atoll', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'cay', 'Bank', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'cay', 'Bank', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'banks', 'Bank', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'banc', 'Bank', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'bar', 'Bar', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'bay', 'Bay', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'bay', 'Bay', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'beach', 'Beach', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'beach', 'Beach', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'bights', 'Bight', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'subamrinecanyon', 'Canyon', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'cape', 'Cape', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'cape', 'Cape', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'channel', 'Channel', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'marinechannel', 'Channel', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'other', 'channel', 'Channel', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'channel', 'Channel', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'cliffs', 'Cliffs', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'cliff', 'Cliffs', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'coast', 'Coast', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'area', 'coast', 'Coast', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'coastkustcote', 'Coast', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'administrativearea', 'coast', 'Coast', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'coves', 'Cove', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'tidalcreeks', 'Creek', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'oceancurrent', 'Current', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'deep', 'Deep', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'pier', 'Dock', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'pier', 'Dock', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'docks', 'Dock', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'estuary', 'Estuary', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'fjord', 'Fjord', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'gulf', 'Gulf', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'port', 'Harbour', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'historical', 'port', 'Harbour', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'harbors', 'Harbour', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'area', 'port', 'Harbour', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'marina', 'Harbour', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'seaport', 'Harbour', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'sectionofharbor', 'Harbour', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'administrativearea', 'port', 'Harbour', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'headlands', 'Headland', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'bluehole', 'Hole', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'inlet', 'Inlet', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'isthmus', 'Isthmus', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'lagoons', 'Lagoon', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'laguna', 'Lagoon', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'lagoon', 'Lagoon', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'vegetation', 'mangrove', 'Mangrove', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'mangroveswamp', 'Mangrove', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'marineregion', 'Marine Region', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'area', 'tidalflats', 'Mud flat', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'other', 'ocean', 'Ocean', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'ocean', 'Ocean', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'spot', 'reefunit', 'Reef', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'reef', 'Reef', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'coralreef', 'Reef', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'sectionofreef', 'Reef', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'reef', 'Reef', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'spot', 'seasideresort', 'Resort', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'seasideresort', 'Resort', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'streammouths', 'River Outlet', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'sandbank', 'Sandbank', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'seaarea', 'Sea', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'sea', 'Sea', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'other', 'sea', 'Sea', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'shoals', 'Shoal', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'underseavalley', 'Submarine valley(s)', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'trench', 'Trench', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'topographic', 'trench', 'Trench', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'seavalley', 'Valley', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'submarinevolcano', 'Volcano', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'wharf', 'Wharf', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'shipwreck', 'Wreck', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'spot', 'wreck', 'Wreck', 20);
INSERT INTO darwin2.tag_groups_authority_categories VALUES ('marineregions.org', 'hydrographic', 'boat', 'Wreck', 20);


update darwin2.tag_groups_authority_categories set priority = 'a0' where gazetteer_type_mapped='OCN';
update darwin2.tag_groups_authority_categories set priority = 'a1' where gazetteer_type_mapped='SEA';
update darwin2.tag_groups_authority_categories set priority = 'a2' where gazetteer_type_mapped='PCLH';
update darwin2.tag_groups_authority_categories set priority = 'a3' where gazetteer_type_mapped='PCLI';
update darwin2.tag_groups_authority_categories set priority = 'a4' where gazetteer_type_mapped='PCLD';

update darwin2.tag_groups_authority_categories set priority = 'b0' where gazetteer_type_mapped='ADMD';
update darwin2.tag_groups_authority_categories set priority = 'b1' where gazetteer_type_mapped='ADM1';
update darwin2.tag_groups_authority_categories set priority = 'b1' where gazetteer_type_mapped='ADM2';
update darwin2.tag_groups_authority_categories set priority = 'b1' where gazetteer_type_mapped='ADM3';
update darwin2.tag_groups_authority_categories set priority = 'b1' where gazetteer_type_mapped='ADM4';

update darwin2.tag_groups_authority_categories set priority = 'c0' where gazetteer_type_mapped='ISLS';
update darwin2.tag_groups_authority_categories set priority = 'c1' where gazetteer_type_mapped='ISL';
update darwin2.tag_groups_authority_categories set priority = 'c1' where gazetteer_type_mapped='ATOL';
update darwin2.tag_groups_authority_categories set priority = 'c2' where gazetteer_type_mapped='ISLET';

update darwin2.tag_groups_authority_categories set priority = 'd0' where gazetteer_type_mapped='TERR';
update darwin2.tag_groups_authority_categories set priority = 'd1' where gazetteer_type_mapped='MTS';
update darwin2.tag_groups_authority_categories set priority = 'd2' where gazetteer_type_mapped='CDAU';
update darwin2.tag_groups_authority_categories set priority = 'd2' where gazetteer_type_mapped='PLAT';
update darwin2.tag_groups_authority_categories set priority = 'd2' where gazetteer_type_mapped='UPLD';
update darwin2.tag_groups_authority_categories set priority = 'd3' where gazetteer_type_mapped='DSRT';
update darwin2.tag_groups_authority_categories set priority = 'd3' where gazetteer_type_mapped='RGN';
update darwin2.tag_groups_authority_categories set priority = 'd3' where gazetteer_type_mapped='RGNH';
update darwin2.tag_groups_authority_categories set priority = 'd3' where gazetteer_type_mapped='GULF';
update darwin2.tag_groups_authority_categories set priority = 'd4' where gazetteer_type_mapped='RDGE';
update darwin2.tag_groups_authority_categories set priority = 'd4' where gazetteer_type_mapped='KRST';
update darwin2.tag_groups_authority_categories set priority = 'd5' where gazetteer_type_mapped='RES';
update darwin2.tag_groups_authority_categories set priority = 'd5' where gazetteer_type_mapped='RESW';
update darwin2.tag_groups_authority_categories set priority = 'd5' where gazetteer_type_mapped='RESF';
update darwin2.tag_groups_authority_categories set priority = 'd6' where gazetteer_type_mapped='RESN';
update darwin2.tag_groups_authority_categories set priority = 'd6' where gazetteer_type_mapped='STRT';
update darwin2.tag_groups_authority_categories set priority = 'd6' where gazetteer_type_mapped='BGHT';

update darwin2.tag_groups_authority_categories set priority = 'e0' where gazetteer_type_mapped='PPL';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLA';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLA2';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLA3';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLA4';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLC';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLG';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLQ';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLW';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLL';
update darwin2.tag_groups_authority_categories set priority = 'e1' where gazetteer_type_mapped='PPLS';

update darwin2.tag_groups_authority_categories set priority = 'f0' where gazetteer_type_mapped='MT';
update darwin2.tag_groups_authority_categories set priority = 'f0' where gazetteer_type_mapped='VLC';
update darwin2.tag_groups_authority_categories set priority = 'f0' where gazetteer_type_mapped='PEN';
update darwin2.tag_groups_authority_categories set priority = 'f0' where gazetteer_type_mapped='LKS';

update darwin2.tag_groups_authority_categories set priority = 'f1' where gazetteer_type_mapped='LGN';
update darwin2.tag_groups_authority_categories set priority = 'f1' where gazetteer_type_mapped='LK';
update darwin2.tag_groups_authority_categories set priority = 'f2' where gazetteer_type_mapped='LKC';
update darwin2.tag_groups_authority_categories set priority = 'f2' where gazetteer_type_mapped='LKI';
update darwin2.tag_groups_authority_categories set priority = 'f2' where gazetteer_type_mapped='LKN';
update darwin2.tag_groups_authority_categories set priority = 'f2' where gazetteer_type_mapped='LKO';
update darwin2.tag_groups_authority_categories set priority = 'f2' where gazetteer_type_mapped='LKSB';
update darwin2.tag_groups_authority_categories set priority = 'f3' where gazetteer_type_mapped='BAY';
update darwin2.tag_groups_authority_categories set priority = 'f3' where gazetteer_type_mapped='ISTH';
update darwin2.tag_groups_authority_categories set priority = 'f4' where gazetteer_type_mapped='STMS';
update darwin2.tag_groups_authority_categories set priority = 'f5' where gazetteer_type_mapped='STM';
update darwin2.tag_groups_authority_categories set priority = 'f5' where gazetteer_type_mapped='STMA';
update darwin2.tag_groups_authority_categories set priority = 'f5' where gazetteer_type_mapped='STMD';
update darwin2.tag_groups_authority_categories set priority = 'f5' where gazetteer_type_mapped='STMI';
update darwin2.tag_groups_authority_categories set priority = 'f5' where gazetteer_type_mapped='STMM';
update darwin2.tag_groups_authority_categories set priority = 'f5' where gazetteer_type_mapped='STMSB';
update darwin2.tag_groups_authority_categories set priority = 'f5' where gazetteer_type_mapped='CHN';
update darwin2.tag_groups_authority_categories set priority = 'f6' where gazetteer_type_mapped='PROM';
update darwin2.tag_groups_authority_categories set priority = 'f6' where gazetteer_type_mapped='CAPE';
update darwin2.tag_groups_authority_categories set priority = 'f7' where gazetteer_type_mapped='BCH';
update darwin2.tag_groups_authority_categories set priority = 'f7' where gazetteer_type_mapped='MESA';
update darwin2.tag_groups_authority_categories set priority = 'f8' where gazetteer_type_mapped='PK';
update darwin2.tag_groups_authority_categories set priority = 'f8' where gazetteer_type_mapped='PT';

update darwin2.tag_groups_authority_categories set priority = 'g0' where gazetteer_type_mapped='PPLX';
update darwin2.tag_groups_authority_categories set priority = 'g0' where gazetteer_type_mapped='HBR';
update darwin2.tag_groups_authority_categories set priority = 'g1' where gazetteer_type_mapped='LCTY';
update darwin2.tag_groups_authority_categories set priority = 'g2' where gazetteer_type_mapped='COVE';

update darwin2.tag_groups_authority_categories set priority = 'h0' where priority is null;


GRANT ALL ON TABLE darwin2.tag_groups_authority_categories TO darwin2;

CREATE TABLE darwin2.tag_authority_tag_authority
(
  tag_authority_ref1 bigint NOT NULL, -- Reference to the left-hand (subject) authoritative vocabulary entry.
  tag_authority_ref2 bigint NOT NULL, -- Reference to the right-hand (object) authoritative vocabulary entry.
  tag_authority_predicate text NOT NULL, -- Predicate that indicates a relation between a subject and an object
  CONSTRAINT tag_authority_tag_authority_pk PRIMARY KEY (tag_authority_ref1,tag_authority_ref2,tag_authority_predicate),
  CONSTRAINT fk_authority_ref1 FOREIGN KEY (tag_authority_ref1)
      REFERENCES darwin2.tag_authority (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_authority_ref2 FOREIGN KEY (tag_authority_ref2)
      REFERENCES darwin2.tag_authority (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT chk_tag_authority_predicate CHECK (tag_authority_predicate ~~ '%:%'::text) --must specify <domain>:<predicate>
);

COMMENT ON TABLE darwin2.tag_authority_tag_authority IS 'Table to link together authoritative vocabularies: MUST make use of existing linked data relationships. Example: gn:';
COMMENT ON COLUMN darwin2.tag_authority_tag_authority.tag_authority_ref1 IS 'Reference to the left-hand (subject) authoritative vocabulary entry.';
COMMENT ON COLUMN darwin2.tag_authority_tag_authority.tag_authority_ref2 IS 'Reference to the right-hand (object) authoritative vocabulary entry.';
COMMENT ON COLUMN darwin2.tag_authority_tag_authority.tag_authority_predicate IS 'Predicate that indicates a relation between a subject and an object.';

set search_path to darwin2,public;
/*WRONG COORD SIGN*/
update darwin2.properties set lower_value=54.2 where lower_value NOT LIKE '%''%' and record_id=130623 and property_type='longitude';		
		
update darwin2.properties set lower_value=-76.066667 where lower_value NOT LIKE '%''%' and record_id=137101 and property_type='longitude';	
	
update darwin2.properties set lower_value=-74.3 where lower_value NOT LIKE '%''%' and record_id=137109 and property_type='longitude';
		
update darwin2.properties set lower_value=-68.533333 where lower_value NOT LIKE '%''%' and record_id=137112 and property_type='longitude';	
	
update darwin2.properties set lower_value=-58.233333 where lower_value NOT LIKE '%''%' and record_id=137116 and property_type='longitude';	
	
update darwin2.properties set lower_value=-17.06 where lower_value NOT LIKE '%''%' and record_id=137632 and property_type='longitude';	
	
update darwin2.properties set lower_value=-5.583333 where lower_value NOT LIKE '%''%' and record_id=138186 and property_type='longitude';	
		
update darwin2.properties set lower_value=-5.583333 where lower_value NOT LIKE '%''%' and record_id=138208 and property_type='longitude';		
		
update darwin2.properties set lower_value=-5.583333 where lower_value NOT LIKE '%''%' and record_id=138510 and property_type='longitude';
		
update darwin2.properties set lower_value=5.433333 where lower_value NOT LIKE '%''%' and record_id=159099 and property_type='longitude';
		
update darwin2.properties set lower_value=4.766667 where lower_value NOT LIKE '%''%' and record_id=159557 and property_type='longitude';
		
update darwin2.properties set lower_value=-67.435277 where lower_value NOT LIKE '%''%' and record_id=181793 and property_type='longitude';

update darwin2.properties set lower_value=-3.16667 where lower_value NOT LIKE '%''%' and record_id=198136 and property_type='latitude';	
		
update darwin2.properties set lower_value=-3.16667 where lower_value NOT LIKE '%''%' and record_id=198136 and property_type='longitude';
		
update darwin2.properties set lower_value=-4.618334 where lower_value NOT LIKE '%''%' and record_id=203650 and property_type='longitude';
		
update darwin2.properties set lower_value=-4.497777 where lower_value NOT LIKE '%''%' and record_id=203947 and property_type='longitude';		

update darwin2.properties set lower_value=-4.485 where lower_value NOT LIKE '%''%' and record_id=203997 and property_type='longitude';	
	
update darwin2.properties set lower_value=-4.556389 where lower_value NOT LIKE '%''%' and record_id=204002 and property_type='longitude';
		
update darwin2.properties set lower_value=-4.546666 where lower_value NOT LIKE '%''%' and record_id=205001 and property_type='longitude';
		
update darwin2.properties set lower_value=-4.386944 where lower_value NOT LIKE '%''%' and record_id=205004 and property_type='longitude';
		
update darwin2.properties set lower_value=-4.589166 where lower_value NOT LIKE '%''%' and record_id=205168 and property_type='longitude';
		
update darwin2.properties set lower_value=-4.567778 where lower_value NOT LIKE '%''%' and record_id=205172 and property_type='longitude';
		
update darwin2.properties set lower_value=-4.598889 where lower_value NOT LIKE '%''%' and record_id=205197 and property_type='longitude';
		
update darwin2.properties set lower_value=2.85 where lower_value NOT LIKE '%''%' and record_id=207714 and property_type='longitude';
		
update darwin2.properties set lower_value=-27.9 where lower_value NOT LIKE '%''%' and record_id=208002 and property_type='longitude';
		
update darwin2.properties set lower_value=-28.6 where lower_value NOT LIKE '%''%' and record_id=208020 and property_type='longitude';
		
update darwin2.properties set lower_value=-13.45 where lower_value NOT LIKE '%''%' and record_id=208324 and property_type='longitude';

update darwin2.properties set lower_value=-70.5333333 where lower_value NOT LIKE '%''%' and record_id=208324 and property_type='latitude';	

--KEEP OLD DMS coordinates
INSERT INTO darwin2.properties(
	referenced_relation, record_id,  property_type, applies_to, applies_to_indexed, date_from_mask, date_from, date_to_mask, date_to, is_quantitative, property_unit, method, method_indexed, lower_value, lower_value_unified, upper_value, upper_value_unified, property_accuracy, property_type_ref)
SELECT referenced_relation, record_id,  property_type||'_dms', applies_to, applies_to_indexed, date_from_mask, date_from, date_to_mask, date_to, is_quantitative, property_unit, method, method_indexed, lower_value, lower_value_unified, upper_value, upper_value_unified, property_accuracy, property_type_ref
	FROM darwin2.properties
	where referenced_relation='gtu'
	and (property_type ilike '%latitude%' OR property_type ilike '%longitude%')
	and lower_value ilike '%°%';


	update darwin2.gtu set longitude=11.0333335 where id=167181;

--fix wrongly spelled coordinates
-- DMS with no minute sign
--e.g : 45 ° 45.333 N
--        45° 45"

UPDATE properties
SET lower_value=
REPLACE(REPLACE(regexp_replace(lower_value,'(.+°)(.+)([^''])$', '\1\2''00"\3'),'''''',''''),'""','"'),
upper_value=
REPLACE(REPLACE(regexp_replace(upper_value,'(.+°)(.+)([^''])$', '\1\2''00"\3'),'''''',''''),'""','"')
where 
(property_type ='latitude_dms'
or property_type ='longitude_dms')
and 
lower_value ~ '°\s*([\.\d]+)[^'']+$'
OR 
upper_value ~ '°\s*([\.\d]+)[^'']+$';

--Convert DMS to DD
DELETE FROM properties WHERE 
(property_type ilike 'latitude'
 OR 
 property_type ilike 'longitude')
 and referenced_relation ='gtu'
 and record_id in (select record_id from properties where property_type='latitude_dms' OR property_type = 'longitude_dms' 
				  and referenced_relation='gtu');

INSERT INTO properties
(
	referenced_relation,
	record_id,  
	property_type, 
	applies_to,
	date_from_mask, 
	date_from, 
	date_to_mask,
	date_to, 
	is_quantitative,
	property_unit,
	method, 
	lower_value, 
	upper_value, 
	property_accuracy,
	property_type_ref)
	SELECT
	
	referenced_relation,
		record_id, 
		property_type, 
		applies_to, 
		date_from_mask,
		date_from, 
		date_to_mask,
		date_to,
		is_quantitative,
		property_unit,
		method, 
		rmca_dms_to_dd(lower_value, REPLACE(property_type, '_dms','')),
		 COALESCE(rmca_dms_to_dd(upper_value, REPLACE(property_type, '_dms',''))::varchar,''), 
		property_accuracy, 
		property_type_ref
	from properties where property_type='latitude_dms' OR property_type = 'longitude_dms' and referenced_relation='gtu';
	


