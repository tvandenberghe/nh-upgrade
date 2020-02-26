set search_path to darwin2;



alter table collections add publish_to_gbif boolean;
alter table collections add profile text[4];
alter table collections add column title_en text, add column title_nl text, add column title_fr text;

--set ile de callot to negative longitude

UPDATE collections set name='Merostomata' where name='Merostomata ';
UPDATE collections set name='Brachiopoda/Types' where name='Brachiopoda /Types';

UPDATE collections set publish_to_gbif = false;

UPDATE collections set publish_to_gbif = true where id=27 and name='Acari';
UPDATE collections set publish_to_gbif = true where id=5 and name='Amphibia';
UPDATE collections set publish_to_gbif = true where id=28 and name='Araneae';
UPDATE collections set publish_to_gbif = true where id=6 and name='Aves';
UPDATE collections set publish_to_gbif = true where id=14 and name='Belgian Marine Invertebrates';
UPDATE collections set publish_to_gbif = true where id=244 and name='Brachiopoda';
UPDATE collections set publish_to_gbif = true where id=285 and name='Bryozoa';
UPDATE collections set publish_to_gbif = true where id=214 and name='Chelicerata (Marine)';
UPDATE collections set publish_to_gbif = true where id=16 and name='Cnidaria';
UPDATE collections set publish_to_gbif = true where id=29 and name='Coleoptera';
UPDATE collections set publish_to_gbif = true where id=15 and name='Crustacea';
UPDATE collections set publish_to_gbif = true where id=30 and name='Diptera';
UPDATE collections set publish_to_gbif = true where id=13 and name='Echinodermata';
UPDATE collections set publish_to_gbif = true where id=31 and name='Heterocera';
UPDATE collections set publish_to_gbif = true where id=32 and name='Hymenoptera';
UPDATE collections set publish_to_gbif = true where id=7 and name='Mammalia';
UPDATE collections set publish_to_gbif = true where id=17 and name='Mollusca';
UPDATE collections set publish_to_gbif = true where id=36 and name='Orthoptera';
UPDATE collections set publish_to_gbif = true where id=8 and name='Pisces';
UPDATE collections set publish_to_gbif = true where id=9 and name='Reptilia';
UPDATE collections set publish_to_gbif = true where id=37 and name='Rhopalocera';
UPDATE collections set publish_to_gbif = true where id=238 and name='Rotifera';
UPDATE collections set publish_to_gbif = true where id=10 and name='Vertebrates/Types';

UPDATE collections set profile =  NULL;

UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=27 and name='Acari';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,'isFreshwater',null] where id=5 and name='Amphibia';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=18 and name='Annelida';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=346 and name='Annelida';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=310 and name='Anthozoa';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=28 and name='Araneae';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=21 and name='Asteroidea';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine',null,null] where id=6 and name='Aves';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=39 and name='Belgian Ceratopogonidae Collection';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=40 and name='Belgian Culicidae Collection';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=14 and name='Belgian Marine Invertebrates';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=168 and name='Belgian Marine Invertebrates Not visible';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=244 and name='Brachiopoda';
UPDATE collections set profile =  ARRAY[null,'isMarine','isFreshwater','isBrackish'] where id=60 and name='Branchiopoda';
UPDATE collections set profile =  ARRAY[null,'isMarine','isFreshwater','isBrackish'] where id=285 and name='Bryozoa';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=210 and name='Cephalocarida';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=313 and name='Cephalorhyncha';

UPDATE collections set profile =  ARRAY['isTerrestrial',null,'isFreshwater',null] where id=29 and name='Coleoptera';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=24 and name='Crinoidea';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=318 and name='Echinoidea';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=129 and name='General Crustacea Collection';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=31 and name='Heterocera';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=22 and name='Holothuroidea';
UPDATE collections set profile =  ARRAY[null,'isMarine','isFreshwater','isBrackish'] where id=19 and name='Hydroidomedusae';
UPDATE collections set profile =  ARRAY[null,'isMarine','isFreshwater','isBrackish'] where id=188 and name='Hydroidomedusae Not visible';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=32 and name='Hymenoptera';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=116 and name='Malacostraca';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=7 and name='Mammalia';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=107 and name='Maxillopoda';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=33 and name='Mecoptera';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,'isFreshwater',null] where id=34 and name='Megaloptera';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=212 and name='Merostomata ';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=17 and name='Mollusca';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,'isFreshwater',null] where id=35 and name='Neuroptera';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=23 and name='Ophiuroidea';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=36 and name='Orthoptera';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=125 and name='Ostracoda';
UPDATE collections set profile =  ARRAY[null,'isMarine','isFreshwater','isBrackish'] where id=8 and name='Pisces';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=335 and name='Plathyhelminthes';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=113 and name='Pycnogonida';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=211 and name='Remipedia';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=9 and name='Reptilia';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=181 and name='Reptilia Not visible';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=37 and name='Rhopalocera';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=238 and name='Rotifera';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,null] where id=314 and name='Sipuncula';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=10 and name='Vertebrates/Types';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=214 and name='Chelicerata (Marine)';
UPDATE collections set profile =  ARRAY[null,'isMarine','isFreshwater','isBrackish'] where id=16 and name='Cnidaria';
UPDATE collections set profile =  ARRAY['isTerrestrial','isMarine','isFreshwater','isBrackish'] where id=15 and name='Crustacea';
UPDATE collections set profile =  ARRAY['isTerrestrial',null,null,null] where id=30 and name='Diptera';
UPDATE collections set profile =  ARRAY[null,'isMarine',null,'isBrackish'] where id=13 and name='Echinodermata';

UPDATE collections set publish_to_gbif = false where name like '%Not visible%' or name like '%test%';

update collections set name ='Vertebrates/Types' where id=10 and name='Types';
update collections set name ='Crustacea/Types' where id=25 and name='Types';

update collections  set main_manager_ref= (select id from users where formated_name_unique like '%olivierpauwels%') where 
id=1 and name='Vertebrates' or
id=5 and name='Amphibia' or
id=6 and name='Aves' or
id=7  and name='Mammalia' or
id=8  and name='Pisces' or
id=9  and name='Reptilia' or
id=10  and name='Vertebrates/Types' or
id=176  and name='Aves Not visible' or
id=181  and name='Reptilia Not visible' or
id=225  and name='Rhinocerotidae' or
id=308  and name='Vertebrates_Import_test';

update collections set title_en=null, title_nl=null, title_fr=null;

update collections set title_en='Royal Belgian Institute of Natural Sciences Bird Collection', title_nl='Vogelcollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Oiseaux de l''Institut royal des Sciences naturelles de Belgique' where id=6;
update collections set title_en='Royal Belgian Institute of Natural Sciences Belgian Marine Invertebrates collection', title_nl='Belgische mariene invertebratencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Invertebrés marins belges de l''Institut royal des Sciences naturelles de Belgique' where id=14;
update collections set title_en='Royal Belgian Institute of Natural Sciences Brachiopoda collection', title_nl='Brachiopodacollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Brachiopodes de l''Institut royal des Sciences naturelles de Belgique' where id=244;
update collections set title_en='Royal Belgian Institute of Natural Sciences Bryozoa collection', title_nl='Bryozoacollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Bryozoaires de l''Institut royal des Sciences naturelles de Belgique' where id=285;
update collections set title_en='Royal Belgian Institute of Natural Sciences marine Chelicerata collection', title_nl='Mariene cheliceratacollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Chélicérates marins de l''Institut royal des Sciences naturelles de Belgique' where id=214;
update collections set title_en='Royal Belgian Institute of Natural Sciences Cnidaria collection', title_nl='Neteldierencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Cnidaires de l''Institut royal des Sciences naturelles de Belgique' where id=16;
update collections set title_en='Royal Belgian Institute of Natural Sciences Crustacea collection', title_nl='Schaaldierencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Crustacés de l''Institut royal des Sciences naturelles de Belgique' where id=15;
update collections set title_en='Royal Belgian Institute of Natural Sciences Echinodermata collection', title_nl='Stekelhuidigencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Echinodermes de l''Institut royal des Sciences naturelles de Belgique' where id=13;
update collections set title_en='Royal Belgian Institute of Natural Sciences Mammalia collection', title_nl='Zoogdiercollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Mammifères de l''Institut royal des Sciences naturelles de Belgique' where id=7;
update collections set title_en='Royal Belgian Institute of Natural Sciences Mollusca collection', title_nl='Weekdierencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Mollusques de l''Institut royal des Sciences naturelles de Belgique' where id=17;
update collections set title_en='Royal Belgian Institute of Natural Sciences Pisces collection', title_nl='Vissencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Poissons de l''Institut royal des Sciences naturelles de Belgique' where id=8;
update collections set title_en='Royal Belgian Institute of Natural Sciences Reptilia collection', title_nl='Reptielencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Reptiles de l''Institut royal des Sciences naturelles de Belgique' where id=9;
update collections set title_en='Royal Belgian Institute of Natural Sciences Rotifera collection', title_nl='Raderdierencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Rotifères de l''Institut royal des Sciences naturelles de Belgique' where id=238;
update collections set title_en='Royal Belgian Institute of Natural Sciences vertebrate types collection', title_nl='Vertebraten typecollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des types de les Vertébrés de l''Institut royal des Sciences naturelles de Belgique' where id=10;
update collections set title_en='Royal Belgian Institute of Natural Sciences Acari collection', title_nl='Mijten- en tekencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Acariens de l''Institut royal des Sciences naturelles de Belgique' where id=27;
update collections set title_en='Royal Belgian Institute of Natural Sciences Amphibia collection', title_nl='Amfibieëncollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Amphibiens de l''Institut royal des Sciences naturelles de Belgique' where id=5;
update collections set title_en='Royal Belgian Institute of Natural Sciences Araneae collection', title_nl='Spinnencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Aranéides de l''Institut royal des Sciences naturelles de Belgique' where id=28;
update collections set title_en='Royal Belgian Institute of Natural Sciences Coleoptera collection', title_nl='Kevercollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Coléoptères de l''Institut royal des Sciences naturelles de Belgique' where id=29;
update collections set title_en='Royal Belgian Institute of Natural Sciences Diptera collection', title_nl='Tweevleugeligencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Diptères de l''Institut royal des Sciences naturelles de Belgique' where id=30;
update collections set title_en='Royal Belgian Institute of Natural Sciences Heterocera collection', title_nl='Nachtvlindercollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Hétérocères de l''Institut royal des Sciences naturelles de Belgique' where id=31;
update collections set title_en='Royal Belgian Institute of Natural Sciences Hymenoptera collection', title_nl='Vliesvleugeligencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Hyménoptères de l''Institut royal des Sciences naturelles de Belgique' where id=32;
update collections set title_en='Royal Belgian Institute of Natural Sciences Orthoptera collection', title_nl='Rechtvleugeligencollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Orthoptères de l''Institut royal des Sciences naturelles de Belgique' where id=36;
update collections set title_en='Royal Belgian Institute of Natural Sciences Rhopalocera collection', title_nl='Dagvlindercollectie van het Koninklijk Belgisch Instituut voor Natuurwetenschappen', title_fr='Collection des Rhopalocères de l''Institut royal des Sciences naturelles de Belgique' where id=37;


update gtu set code=replace(code,'Vertebrates','VERTEBRATES') where code like 'Vertebrates%';
update gtu set code=replace(code,'vertebrates','VERTEBRATES') where code like 'vertebrates%';
update gtu set code=replace(code,'VERTEBRATS','VERTEBRATES') where code like 'VERTEBRATS%';
update gtu set code=replace(code,'VERTERATES','VERTEBRATES') where code like 'VERTERATES%';
update gtu set code=replace(code,'VERTREBRATES','VERTEBRATES') where code like 'VERTREBRATES%';
update gtu set code=replace(code,'VERTYEBRATES','VERTEBRATES') where code like 'VERTYEBRATES%';
update gtu set code=replace(code,'VRETEBRATES','VERTEBRATES') where code like 'VRETEBRATES%';
update gtu set code=replace(code,'VRTEBRATES','VERTEBRATES') where code like 'VRTEBRATES%';
update gtu set code=replace(code,'VETEBRATES','VERTEBRATES') where code like 'VETEBRATES%';
update gtu set code=replace(code,'VERTEBTATES','VERTEBRATES') where code like 'VERTEBTATES%';

update gtu set latitude=null, longitude=null where id=131934 --wrong, data entry person mapped this to place in england while it's in canada
update gtu set latitude=null, longitude=null where id=121530 --wrong, location in South Africa set to 0-0.

delete from properties where record_id=131934 and referenced_relation='gtu' and property_type='latitude';  --remove a 0-0 coordinate from the properties, for Canada
delete from properties where record_id=131934 and referenced_relation='gtu' and property_type='longitude'  --remove a 0-0 coordinate from the properties, for Canada

delete from properties where record_id=121530 and referenced_relation='gtu' and property_type='latitude';  --remove a 0-0 coordinate from the properties, for South Africa
delete from properties where record_id=121530 and referenced_relation='gtu' and property_type='longitude'  --remove a 0-0 coordinate from the properties, for South Africa
