set search_path to darwin2;
drop table darwin2.tag_groups_authority_categories;

create table darwin2.tag_groups_authority_categories as
select * from (
select distinct    
'geonames.org' as authority,
original_type,
original_sub_type,
case when gazetteer_type_mapped ='' then null else gazetteer_type_mapped end as gazetteer_type_mapped,
null::text as priority
from darwin2.mv_tag_to_locations

union all

select distinct
'marineregions.org' as authority,
original_type,
original_sub_type,
marineregions_type_mapped as gazetteer_type_mapped,
null::smallint as priority
from darwin2.mv_tag_to_locations
where marineregions_type_mapped is not null
)q
    order by authority,gazetteer_type_mapped;

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
