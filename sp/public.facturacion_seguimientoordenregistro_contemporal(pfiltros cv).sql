CREATE OR REPLACE FUNCTION public.facturacion_seguimientoordenregistro_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_facturacion_seguimientoordenregistro_contemporal
AS (
	SELECT concat(factura.nroregistro,'-', anio) as elregistro, pdescripcion, estadofacturadesc, concat(nroorden,'-', centro) as laorden,fechauso,'1-Registro#elregistro@2-Prestador#pdescripcion@3-Estado#estadofacturadesc@4-Orden#laorden@5-FechaUso#fechauso'::text as mapeocampocolumna
	FROM factura NATURAL JOIN prestador NATURAL JOIN facturaordenesutilizadas NATURAL JOIN festados NATURAL JOIN tipoestadosfactura
        NATURAL JOIN ordenesutilizadas
	WHERE (nroorden::varchar = rfiltros.nroorden OR nullvalue(rfiltros.nroorden)) AND (centro::varchar = rfiltros.centro OR rfiltros.centro::varchar='' OR nullvalue(rfiltros.centro)) AND (nroregistro = rfiltros.nroregistro OR rfiltros.nroregistro::varchar='' OR nullvalue(rfiltros.nroregistro)) AND (anio::varchar = rfiltros.anio OR rfiltros.anio::varchar=''  OR nullvalue(rfiltros.anio)) AND nullvalue(fefechafin)
);
     

return true;
END;
$function$
