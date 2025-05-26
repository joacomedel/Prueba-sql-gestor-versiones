CREATE OR REPLACE FUNCTION public.pagosautorizados_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--DROP TABLE  temp_libroiva_ventas_contemporal;
CREATE  temp TABLE temp_pagosautorizados_contemporal
AS (
       SELECT 
*,
 '1-NroMinuta#nroordenpago@2-Fecha#fechaingreso@3-Beneficiario#beneficiario@4-Concepto#concepto@5-Importe#importetotal#suma'::text as mapeocampocolumna
                       FROM ordenpago
NATURAL JOIN  cambioestadoordenpago
NATURAL JOIN tipoestadoordenpago
WHERE  nullvalue(ceopfechafin)
AND
rfiltros.idtipoestadoordenpago=idtipoestadoordenpago
and  fechaingreso>=rfiltros.fechadesde
and  (fechaingreso<=rfiltros.fechahasta or nullvalue(rfiltros.fechahasta) )
order by nroordenpago,fechaingreso
);

return true;
END;
$function$
