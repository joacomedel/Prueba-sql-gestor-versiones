CREATE OR REPLACE FUNCTION public.conciliacionbancaria_multivaccomprobantefondo(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE

        rfiltros record;
        ritemcon record;
        elidfacturaventacupon bigint;

BEGIN
    EXECUTE sys_dar_filtros($1) INTO rfiltros;
    -- recupero el item de la conciliacion
    SELECT INTO ritemcon *
    FROM conciliacionbancariaitem
    WHERE idcentroconciliacionbancariaitem  = ritemcon.idcentroconciliacionbancariaitem
          and idconciliacionbancariaitem = ritemcon.idcentroconciliacionbancariaitem;
/*  item pagoordenpagocontable liquidaciontarjeta facturaventacupon recibocupon ordenpago*/
/*  tipoasiento ordenpagocontable liquidaciontarjeta ordenpago facturaventa ordenpago*/
            
    IF(ritemcon.cbitablacomp = 'ordenpagocontable' )THEN
    END IF;
    IF(ritemcon.cbitablacomp = 'liquidaciontarjeta' )THEN
    END IF;
    IF(ritemcon.cbitablacomp = 'ordenpago' )THEN
    END IF;
    IF(ritemcon.cbitablacomp = 'facturaventa' )THEN
    END IF;
    IF(ritemcon.cbitablacomp = 'xxxxx' )THEN
    END IF;
RETURN concat(elcomprobante.nrofactura,'|',elcomprobante.tipocomprobante,'|',elcomprobante.nrosucursal,'|',elcomprobante.tipofactura);
END;
$function$
