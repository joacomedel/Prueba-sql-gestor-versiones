CREATE OR REPLACE FUNCTION public.cd_cantafillsghporunidadacademica_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--Cantidad de lsgh activas por unidad académica 
CREATE TEMP TABLE temp_cd_cantafillsghporunidadacademica_contemporal
AS (
	
	
SELECT COUNT(*) AS cantidad, iddepen,descrip,
	 '1-CantidadCargos#cantidad@2-Descripcion#descrip'::text as mapeocampocolumna 
 
   FROM licencias 
   join cargo USING(legajosiu)
   JOIN persona  on(persona.nrodoc=cargo.nrodoc and persona.tipodoc=cargo.tipodoc)   
   JOIN depuniversitaria USING(iddepen)
   WHERE fechafinos>=CURRENT_DATE     
    AND fechafin>=CURRENT_DATE
    group by  iddepen,descrip
   ORDER BY iddepen 

  );

return true;
END;
$function$
