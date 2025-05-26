CREATE OR REPLACE FUNCTION public.valorizaciones(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_cajadiaria_cantidadfacturas_contemporal 
AS (
	SELECT * 
	,'1-Centro Regional#crdescripcion@2-Fecha#fechaemision@3-Cant.Facturas#cantidadfacturas@4-Cant.Personas#cantidadpersonas@5-Importe#importe'::text as mapeocampocolumna
	FROM centroregional 
	NATURAL JOIN (
	select centro as  idcentroregional,fechaemision,count(*) as cantidadfacturas,count(distinct nrodoc) as cantidadpersonas,sum(importeefectivo) as  importe
	from facturaventa 
	where fechaemision >= rfiltros.fechadesde AND fechaemision <=  rfiltros.fechahasta
	group by centro,fechaemision 
	) as t

);
     

return true;
END;
$function$
