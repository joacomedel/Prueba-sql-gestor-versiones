CREATE OR REPLACE FUNCTION public.cajadiaria_generarcontabilidad(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

INSERT INTO correr_consulta (ccconsulta,ccmotivo) (
    SELECT concat('asientogenericofacturaventa_crear(''',tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura,''');') as ccconsulta
           ,concat('Ingresan los comprobantes de venta faltantes y visados al ',rfiltros.fechahasta) as  ccmotivo
    FROM facturaventa as f
    JOIN tipofacturaventa tfv on (f.tipofactura=tfv.idtipofactura)
    WHERE f.fechaemision >='2019-01-01' and f.fechaemision <= rfiltros.fechahasta
        and tfv.semigra  --and  ( (not nullvalue(anulada) and anulada<>fechaemision) or nullvalue(anulada) ) 
        and nullvalue(anulada)
        and concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura) NOT IN(
            SELECT idcomprobantesiges
            FROM asientogenerico
            WHERE agfechacontable >'2018-12-31'
        )
);

return true;
END;
$function$
