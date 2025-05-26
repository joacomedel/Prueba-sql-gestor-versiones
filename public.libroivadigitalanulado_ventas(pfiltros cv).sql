CREATE OR REPLACE FUNCTION public.libroivadigitalanulado_ventas(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;  

CREATE TEMP  TABLE temp_libroivadigitalanulado_ventas
AS (

SELECT TO_CHAR( fv.fechaemision :: DATE, 'yyyymmdd')::numeric fechacomprobante,
tccodigo, 
lpad(fv.nrosucursal,5,'0') puntodeventa, 
lpad(fv.nrofactura,20,'0') numerocomprobante, 
TO_CHAR( fv.anulada:: DATE, 'yyyymmdd')::numeric fechaanulacion

FROM contabilidad_periodofiscalfacturaventa NATURAL JOIN facturaventa fv JOIN  tipocomprobantecodigo tcc ON (fv.tipocomprobante= tcc.idtipo AND fv.tipofactura = tcc.tipofactura) 

--WHERE nullvalue(anulada) and idperiodofiscal = 925
WHERE  not nullvalue(anulada) and  idperiodofiscal = rfiltros.idperiodofiscal
 
ORDER BY puntodeventa,numerocomprobante
);

return 'Ok';
END;
$function$
