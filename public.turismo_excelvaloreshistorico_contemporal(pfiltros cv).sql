CREATE OR REPLACE FUNCTION public.turismo_excelvaloreshistorico_contemporal(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       
	rfiltros RECORD;
       
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
CREATE TEMP TABLE temp_turismo_excelvaloreshistorico_contemporal
AS (
	SELECT 
tadescripcion,turismounidadvalor.tuvfechaini,turismounidadvalor.tuvfechfin,tuvimporteafiliado,
tuvimportesosunc,idturismoadmin,tudescripcion,tttdescripcion,
	
	'1-Administrador#tadescripcion@2-Unidad#tudescripcion@3-TipoTarifa#tttdescripcion@4-FechaDesde#tuvfechaini@5-FechaHasta#tuvfechfin@6-Importe
Afiliado#tuvimporteafiliado@7-ImporteSosunc#tuvimportesosunc' as mapeocampocolumna
    
FROM turismounidadvalor  
NATURAL JOIN turismounidad
NATURAL JOIN  turismoadmin
NATURAL JOIN  turismotemporadatipos  
NATURAL JOIN turismounidadvalortipo  
WHERE  idturismoadmin =rfiltros.idturismoadmin   --  125 
AND (turismounidadvalor.tuvfechaini >= rfiltros.fechadesde ) 
AND (nullvalue(rfiltros.fechahasta) OR turismounidadvalor.tuvfechfin >= rfiltros.fechahasta )  
 

order by tuvfechaini,tuvfechfin
	
	 
);
     

return 'Ok';
END;
$function$
