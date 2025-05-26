CREATE OR REPLACE FUNCTION public.cd_cantbenefreciporlocalidad_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--cantidad de beneficiarios de reciprocidad activos discriminados por vinculo
CREATE TEMP TABLE temp_cd_cantbenefreciporlocalidad_contemporal
AS (

  
	select count(*) as cantidad,vinculos.descrip as tipobenef,
	'1-CantidadTitulares#cantidad@2-TipoBenef#tipobenef'::text as mapeocampocolumna 
	from benefreci
	join afilreci on(nrodoctitu=afilreci.nrodoc and tipodoctitu=afilreci.tipodoc)
	natural  join osreci join vinculos using(idvin)
	where
	benefreci.fechavtoreci>=current_date
	group  by idvin,vinculos.descrip
  );

return true;
END;
$function$
