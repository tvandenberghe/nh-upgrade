set search_path to darwin2,public;
CREATE OR REPLACE FUNCTION fct_get_tax_hierarchy(
--A function that retrieves the id and the name of the parent levels of the provided taxonomic unit for the provided levels. Eg. get Family and Order of Macusia satyroides = select fct_get_tax_hierarchy(184921, ARRAY[12, 28])
    IN start_id integer,
    IN levels integer[])
  RETURNS TABLE(r_start_id integer, id integer, name text, level_ref integer, parent_ref integer) AS
$BODY$
WITH RECURSIVE select_levels AS (
        SELECT  t.id,t.name,t.level_ref,t.parent_ref
        FROM    darwin2.taxonomy t
        where t.id=start_id
        UNION ALL
        SELECT   tn.id, tn.name,tn.level_ref,tn.parent_ref
        FROM    darwin2.taxonomy tn
        JOIN    select_levels
        ON      tn.id = select_levels.parent_ref
        )
        select start_id,* from select_levels sl where sl.level_ref = ANY(levels);
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION fct_get_tax_hierarchy(integer, integer[])
  OWNER TO darwin2;
  

 --DROP MATERIALIZED VIEW mv_eml_marine;
 --DROP MATERIALIZED VIEW mv_eml;
 
CREATE MATERIALIZED VIEW mv_eml AS 

select 'The ' || title_en ||' contains ' ||total|| ' digitised specimens of '||nb_species||' taxa. The following classes are included: '||class_taxonomic_coverage
as abstract, total as nb_specimens, nb_species, null as ig_num, ranks, null as existing_code, c.id, name, code, title_en, title_nl, title_fr, profile, path, geographic_coverage, min_lon, max_lon, min_lat, max_lat, start_date, end_date,
	'natural history collection, RBINS, DaRWIN, '::text || c.name::text AS keywords,
	'Royal Belgian Institute for Natural Sciences'::text AS institute_name,
	'Department of Scientific Heritage Service'::text AS institute_dept_abbrev,
	(curator.given_name::text || ' '::text) || curator.family_name::text AS boss,
	uc1.entry AS boss_email,
	'curator'::text AS boss_role,
	(staff.given_name::text || ' '::text) || staff.family_name::text AS subboss,
	uc2.entry AS subboss_email,
	'Collection manager'::text AS subboss_role, class_taxonomic_coverage,order_taxonomic_coverage from (
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='aves' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='belgianmarineinvertebrates' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='brachiopoda' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='bryozoa' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='cheliceratamarine' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='cnidaria' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='crustacea' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='echinodermata' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='mammalia' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='mollusca' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='pisces' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='reptilia' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='rotifera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='vertebratestypes' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='acari' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='amphibia' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='araneae' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='coleoptera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='diptera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='heterocera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='hymenoptera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='orthoptera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
union all
select id, name, name_indexed as code, title_en, title_nl, title_fr, profile, path, string_agg(DISTINCT country, ', ') as geographic_coverage, min(decimal_longitude) as min_lon, max(decimal_longitude) as max_lon, min(decimal_latitude) as min_lat, max(decimal_latitude) as max_lat, min(event_date) as start_date, max(event_date) as end_date, main_manager_ref, staff_ref, count(*) as total, count(distinct scientific_name) as nb_species, string_agg(distinct taxon_rank, ', ') as ranks, string_agg(distinct class, ', ') as class_taxonomic_coverage, string_agg(distinct ordo, ', ') as order_taxonomic_coverage from darwin2.mv_darwin_ipt_rbins left join darwin2.collections c on ndwc_collection_path LIKE '%/'||c.id||'/%' where name_indexed='rhopalocera' group by id, name, name_indexed, title_en, title_nl, title_fr, profile, path
) c 
     LEFT JOIN darwin2.users curator ON c.main_manager_ref = curator.id
     LEFT JOIN darwin2.users_comm uc1 ON uc1.person_user_ref = curator.id AND uc1.comm_type::text = 'e-mail'::text
     LEFT JOIN darwin2.users staff ON c.staff_ref = staff.id
     LEFT JOIN darwin2.users_comm uc2 ON uc2.person_user_ref = staff.id AND uc2.comm_type::text = 'e-mail'::text
order by code;


ALTER TABLE mv_eml
  OWNER TO darwin2;
  
set search_path to darwin2,public;

--drop materialized view mv_darwin_ipt_rbins;
--drop view v_darwin_ipt_rbins;
--DROP FUNCTION DMS2DD(strDegMinSec text);
CREATE OR REPLACE FUNCTION DMS2DD(strDegMinSec text)
	RETURNS double precision
	AS
	$$
	DECLARE
		i				numeric;
		j				numeric;
		intDmsLen		numeric;		  -- Length of original string
		strCompassPoint Char(1);
		strNorm		 varchar(32) = ''; -- Will contain normalized string
		strDegMinSecB	varchar(100);
		blnGotSeparator integer;		  -- Keeps track of separator sequences
		arrDegMinSec	varchar[];		-- TYPE stringarray is table of varchar(2048) ;
		dDeg			numeric := 0;
		dMin			numeric := 0;
		dSec			numeric := 0;
		strChr		  Char(1);
	BEGIN
		if strDegMinSec is null or strDegMinSec='' or strDegMinSec=' ' then 
			return null; 
		elsif  strDegMinSec ~ '^\d+(\.\d+)?$' then
			return trunc(strDegMinSec::numeric,10)::double precision;
		else 
		-- Remove leading and trailing spaces
		strDegMinSecB := REPLACE(strDegMinSec,' ','');
		-- assume no leading and trailing spaces?
		intDmsLen := Length(strDegMinSecB);

		blnGotSeparator := 0; -- Not in separator sequence right now

		-- Loop over string, replacing anything that is not a digit or a
		-- decimal separator with
		-- a single blank
		FOR i in 1..intDmsLen LOOP
		  -- Get current character
		  strChr := SubStr(strDegMinSecB, i, 1);

		  -- either add character to normalized string or replace
		  -- separator sequence with single blank		 
		  If strpos('-0123456789,.', strChr) > 0 Then
			 -- add character but replace comma with point
			 If (strChr <> ',') Then
				strNorm := strNorm || strChr;
			 Else
				strNorm := strNorm || '.';
			 End If;
			 blnGotSeparator := 0;
		  ElsIf strpos('neswNESW',strChr) > 0 Then -- Extract Compass Point if present
			strCompassPoint := strChr;
		  Else
			 -- ensure only one separator is replaced with a blank -
			 -- suppress the rest
			 If blnGotSeparator = 0 Then
				strNorm := strNorm || ' ';
				blnGotSeparator := 0;
			 End If;
		  End If;
		End Loop;

		-- Split normalized string into array of max 3 components
		arrDegMinSec := string_to_array(strNorm, ' ');
--	  raise notice 'array: %',arrDegMinSec;
		--convert specified components to double
		i := array_upper(arrDegMinSec,1);
--	raise notice 'i: %',i;
		j:=1;
		If i >= j and arrDegMinSec[j] <> '' Then
		  dDeg := CAST(arrDegMinSec[j] AS numeric);
		End If;
		j:=2;
		If i >= j and arrDegMinSec[j] <> '' Then
		  dMin := CAST(arrDegMinSec[j] AS numeric);
		End If;
		j:=3;
		If i >= j and arrDegMinSec[j] <> '' Then --if I'm at position 3+
		  dSec := CAST(arrDegMinSec[j] AS numeric);
		End If;

		-- convert components to value
		return trunc(CASE WHEN UPPER(strCompassPoint) IN ('S','W') 
					THEN -1 
					ELSE 1 
				END 
				*
				(dDeg + dMin / 60 + dSec / 3600),10)::double precision;
	end if;
	End 
$$
	LANGUAGE 'plpgsql' IMMUTABLE;

CREATE OR REPLACE FUNCTION darwin2.cleanupDMS(dms_string text)
  RETURNS text AS
$$
BEGIN
if  dms_string ~ '^\d+(\.\d+)?$' then
	return dms_string;
end if;
	dms_string := replace(dms_string,'’','''');
	dms_string := replace(dms_string,',','.');
	dms_string := replace(dms_string,'º','°');
	dms_string := replace(dms_string,' ','');
	dms_string := replace(dms_string,'''''','"');
	dms_string := regexp_replace(dms_string,'^0','');
	dms_string := regexp_replace(dms_string,'^°(\d*)?\.','\1°');
	dms_string := regexp_replace(dms_string,'(\d*)?°(\d*)?''([NEWS])$','\1°\2''00"\3');
	dms_string := trim(dms_string);
	dms_string := trim(dms_string, chr(160));
return dms_string;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE
SECURITY DEFINER
  COST 10;



drop materialized view if exists mv_spatial;
create materialized view mv_spatial as
 WITH 
property_mess_cte as (
select * from (values
	('Accuracy coordinates','coordinatePrecision'),
	('Accuracy Coordinates','coordinatePrecision'),
	('coordinates_original','verbatimCoordinates'),
	('datum','datum'),
	('ellipsoid','ellipsoid'),
	('geo position','verbatimCoordinates'),
('gis_type','spatial_type'),
('km (offset from named place)','offset_from_location'),
	('Lambert','lambert_coordinates_x_y'),
	('latitude','decimal_latitude'),
	('latitude1','decimal_start_latitude'),
	('latitude2','decimal_end_latitude'),
	('Latitude DMS (end of operation)','end_latitude'),
	('Latitude DMS (start of operation)','start_latitude'),
('Locality','verbatimLocality'),
	('longitude','decimal_longitude'),
	('longitude1','decimal_start_longitude'),
	('longitude2','decimal_end_longitude'),
	('Longitude DMS (end of operation)','end_longitude'),
	('Longitude DMS (start of operation)','start_longitude'),
('Named Place','verbatimLocality'),
('utm','utm_grid')
) as map(orig_property,mapped_property)
),
 coordinates_cte
	 AS (SELECT distinct record_id,
				mapped_property as property,
				lower_value as value,
				applies_to
		 FROM	darwin2.properties
	 LEFT JOIN property_mess_cte cte on cte.orig_property=properties.property_type
		 WHERE  referenced_relation = 'gtu'
				AND property_type IN (
'Accuracy coordinates',
'Accuracy Coordinates',
'coordinates_original',
'datum',
'ellipsoid',
'geo position',
'gis_type',
'km (offset from named place)',
'Lambert',
'latitude',
'latitude1',
'latitude2',
'Latitude DMS (end of operation)',
'Latitude DMS (start of operation)',
'Locality',
'longitude',
'longitude1',
'longitude2',
'Longitude DMS (end of operation)',
'Longitude DMS (start of operation)',
'Named Place',
'utm') ORDER  BY record_id, mapped_property)
select distinct on (gtu_ref) gtu_ref,source, decimal_start_latitude,decimal_start_longitude,decimal_end_latitude,decimal_end_longitude,datum,ellipsoid,verbatim_coordinates,coordinate_precision,lambert_coordinates_x_y from (
SELECT distinct gtu.id as gtu_ref,
'1_prop_start_end_dms' as source,
		case when start_longitude.value is null then null else DMS2DD(cleanupDMS(start_latitude.value)) end AS decimal_start_latitude,
		case when start_latitude.value is null then null else DMS2DD(cleanupDMS(start_longitude.value)) end AS decimal_start_longitude,
		case when end_longitude.value is null or end_latitude.value = start_latitude.value then null else DMS2DD(cleanupDMS(end_latitude.value)) end as decimal_end_latitude,
		case when end_latitude.value is null or end_longitude.value = start_longitude.value then null else DMS2DD(cleanupDMS(end_longitude.value)) end as decimal_end_longitude,
		datum.value as datum,
		ellipsoid.value as ellipsoid,
		verbatim_coordinates.value as verbatim_coordinates,
		coordinate_precision.value as coordinate_precision, 
		lambert_coordinates_x_y.value as lambert_coordinates_x_y
FROM	gtu
		left join coordinates_cte AS start_latitude ON gtu.id=start_latitude.record_id and start_latitude.property = 'start_latitude'
		left join coordinates_cte AS end_latitude ON gtu.id = end_latitude.record_id AND end_latitude.property = 'end_latitude'  
		left join coordinates_cte AS start_longitude ON gtu.id = start_longitude.record_id AND start_longitude.property = 'start_longitude' 
		left join coordinates_cte AS end_longitude ON gtu.id = end_longitude.record_id AND end_longitude.property = 'end_longitude' 	
		left join coordinates_cte AS datum ON gtu.id = datum.record_id AND datum.property = 'datum' 
		left join coordinates_cte AS ellipsoid ON gtu.id = ellipsoid.record_id AND ellipsoid.property = 'ellipsoid' 	
		left join coordinates_cte AS verbatim_coordinates ON gtu.id = verbatim_coordinates.record_id AND verbatim_coordinates.property = 'verbatimCoordinates' 
		left join coordinates_cte AS coordinate_precision ON gtu.id = coordinate_precision.record_id AND coordinate_precision.property = 'coordinatePrecision'
		left join coordinates_cte AS lambert_coordinates_x_y ON gtu.id = lambert_coordinates_x_y.record_id AND lambert_coordinates_x_y.property = 'lambert_coordinates_x_y'
WHERE start_latitude.value is not null
union
SELECT distinct gtu.id as gtu_ref,
'1_prop_start_end' as source,
		case when decimal_start_longitude.value is null then null else DMS2DD(cleanupDMS(decimal_start_latitude.value)) end as decimal_start_latitude,
		case when decimal_start_latitude.value is null then null else DMS2DD(cleanupDMS(decimal_start_longitude.value)) end as decimal_start_longitude,
		case when decimal_end_longitude.value is null or decimal_end_latitude.value = decimal_start_latitude.value then null else DMS2DD(cleanupDMS(decimal_end_latitude.value)) end as decimal_end_latitude,
		case when decimal_end_latitude.value is null or decimal_end_longitude.value = decimal_start_longitude.value then null else DMS2DD(cleanupDMS(decimal_end_longitude.value)) end as decimal_end_longitude,
		datum.value as datum,
		ellipsoid.value as ellipsoid,
		verbatim_coordinates.value as verbatim_coordinates,
		coordinate_precision.value as coordinate_precision, 
		lambert_coordinates_x_y.value as lambert_coordinates_x_y 
FROM	gtu		
		left join coordinates_cte AS decimal_start_latitude ON gtu.id = decimal_start_latitude.record_id AND decimal_start_latitude.property = 'decimal_start_latitude' 
		left join coordinates_cte AS decimal_start_longitude ON gtu.id = decimal_start_longitude.record_id AND decimal_start_longitude.property = 'decimal_start_longitude' 
		left join coordinates_cte AS decimal_end_latitude ON gtu.id = decimal_end_latitude.record_id AND decimal_end_latitude.property = 'decimal_end_latitude' 
		left join coordinates_cte AS decimal_end_longitude ON gtu.id = decimal_end_longitude.record_id AND decimal_end_longitude.property = 'decimal_end_longitude' 	
		left join coordinates_cte AS datum ON gtu.id = datum.record_id AND datum.property = 'datum' 	
		left join coordinates_cte AS ellipsoid ON gtu.id = ellipsoid.record_id AND ellipsoid.property = 'ellipsoid' 
		left join coordinates_cte AS verbatim_coordinates ON gtu.id = verbatim_coordinates.record_id AND verbatim_coordinates.property = 'verbatimCoordinates' 
		left join coordinates_cte AS coordinate_precision ON gtu.id = coordinate_precision.record_id AND coordinate_precision.property = 'coordinatePrecision' 
		left join coordinates_cte AS lambert_coordinates_x_y ON gtu.id = lambert_coordinates_x_y.record_id AND lambert_coordinates_x_y.property = 'lambert_coordinates_x_y'
WHERE decimal_start_latitude.value is not null
union
SELECT distinct gtu.id as gtu_ref,
'2_prop_lat_long' as source,
		case when decimal_longitude.value is null then null else DMS2DD(cleanupDMS(decimal_latitude.value)) end as decimal_latitude,
		case when decimal_latitude.value is null then null else DMS2DD(cleanupDMS(decimal_longitude.value)) end as decimal_longitude,
		null::numeric,
		null::numeric,
		datum.value as datum,
		ellipsoid.value as ellipsoid,
		verbatim_coordinates.value as verbatim_coordinates,
		coordinate_precision.value as coordinate_precision, 
		lambert_coordinates_x_y.value as lambert_coordinates_x_y
FROM	gtu		
		left join coordinates_cte AS decimal_latitude ON gtu.id = decimal_latitude.record_id AND decimal_latitude.property = 'decimal_latitude' 
		left join coordinates_cte AS decimal_longitude ON gtu.id = decimal_longitude.record_id AND decimal_longitude.property = 'decimal_longitude' 
		left join coordinates_cte AS datum ON gtu.id = datum.record_id AND datum.property = 'datum' 	
		left join coordinates_cte AS ellipsoid ON gtu.id = ellipsoid.record_id AND ellipsoid.property = 'ellipsoid' 
		left join coordinates_cte AS verbatim_coordinates ON gtu.id = verbatim_coordinates.record_id AND verbatim_coordinates.property = 'verbatimCoordinates'
		left join coordinates_cte AS coordinate_precision ON gtu.id = coordinate_precision.record_id AND coordinate_precision.property = 'coordinatePrecision' 
		left join coordinates_cte AS lambert_coordinates_x_y ON gtu.id = lambert_coordinates_x_y.record_id AND lambert_coordinates_x_y.property = 'lambert_coordinates_x_y'
WHERE decimal_latitude.value is not null
union
SELECT distinct gtu.id as gtu_ref,
'3_gtu_lat_long' as source,
		trunc(gtu.latitude::numeric,10)::double precision,
		trunc(gtu.longitude::numeric,10)::double precision,
		null::numeric,
		null::numeric,
		datum.value as datum,
		ellipsoid.value as ellipsoid,
		string_agg(verbatim_coordinates.value,', ') as verbatim_coordinates,
		string_agg(coordinate_precision.value,', ') as coordinate_precision, 
		string_agg(lambert_coordinates_x_y.applies_to||': '||lambert_coordinates_x_y.value,', ' order by lambert_coordinates_x_y.applies_to) as lambert_coordinates_x_y 
FROM	gtu 
		left join coordinates_cte AS datum ON gtu.id = datum.record_id AND datum.property = 'datum'
		left join coordinates_cte AS ellipsoid ON gtu.id = ellipsoid.record_id AND ellipsoid.property = 'ellipsoid' 
		left join coordinates_cte AS verbatim_coordinates ON gtu.id = verbatim_coordinates.record_id AND verbatim_coordinates.property = 'verbatimCoordinates'
		left join coordinates_cte AS coordinate_precision ON gtu.id = coordinate_precision.record_id AND coordinate_precision.property = 'coordinatePrecision' 
		left join coordinates_cte AS lambert_coordinates_x_y ON gtu.id = lambert_coordinates_x_y.record_id AND lambert_coordinates_x_y.property = 'lambert_coordinates_x_y' 
where gtu.latitude is not null or verbatim_coordinates is not null
group by id,trunc(gtu.latitude::numeric,10), trunc(gtu.longitude::numeric,10), datum.value,ellipsoid.value

) q

order by gtu_ref,source asc, decimal_start_latitude,decimal_start_longitude, decimal_end_latitude asc,decimal_end_longitude asc --this ensures that preference is taken for gtus that have an end coordinate, and that locational info from gtu is not considered if there is locational information found in the properties

/*
Rationale for not including the gtu location information if ot is different from the locations calculated from the infortmation in properties:

set search_path to darwin2,public;

select gtu.id,gtu.code,p.lower_value, gtu.location, mv_spatial.source,mv_spatial.decimal_start_latitude, gtu.latitude, mv_spatial.decimal_start_longitude, gtu.longitude from 
mv_spatial left join gtu on id=gtu_ref 
left join properties p on p.record_id=gtu.id
where mv_spatial.decimal_start_latitude <> gtu.latitude
order by gtu.id

set search_path to darwin2,public;

select gtu.id,gtu.code,p.lower_value, gtu.location, mv_spatial.source,round(mv_spatial.decimal_start_latitude::numeric,7), round(gtu.latitude::numeric,7) as gtu_latitude, round(mv_spatial.decimal_start_longitude::numeric,7), round(gtu.longitude::numeric,7) as gtu_longitude from 
mv_spatial left join gtu on id=gtu_ref 
left join properties p on p.record_id=gtu.id
where round(mv_spatial.decimal_start_latitude::numeric,1) <> round(gtu.latitude::numeric,1)
order by gtu.id

The query returns many wrong coordinates being stored in gtu
*/
