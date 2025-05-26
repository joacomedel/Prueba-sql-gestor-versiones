CREATE OR REPLACE FUNCTION public.aportescontribucionesporconcepto(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_aportescontribucionesporconcepto_contemporal
AS (
	
select   nroconcepto,importe,mesingreso,anioingreso,nrodoc,apellido,nombres
	'1-nroconcepto#nroconcepto@2-importe#importe@3-mesingreso#mesingreso@4-anioingreso#anioingreso@5-nrodoc#nrodoc@6-apellido#apellido@7-nombres#nombres'::text as mapeocampocolumna 
 from dh21
 
join cargo
on(nrolegajo=legajosiu and nrocargo=idcargo)
join persona using(nrodoc,tipodoc)
where mesingreso=2
and anioingreso=2025
and nrodoc='27091730'
order by nroconcepto
limit 100

  );

return true;
END;
$function$
