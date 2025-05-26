CREATE OR REPLACE FUNCTION public.insertarccfactura(fila factura)
 RETURNS factura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturacc:= current_timestamp;
    UPDATE sincro.factura SET anio= fila.anio, anioresumen= fila.anioresumen, clase= fila.clase, facturacc= fila.facturacc, ffecharecepcion= fila.ffecharecepcion, fimportepagar= fila.fimportepagar, fimportesiniva= fila.fimportesiniva, fimportetotal= fila.fimportetotal, idcentrofactura= fila.idcentrofactura, idcentroordenpago= fila.idcentroordenpago, idcomprobantemultivac= fila.idcomprobantemultivac, idlocalidad= fila.idlocalidad, idprestador= fila.idprestador, idresumen= fila.idresumen, idtipocomprobante= fila.idtipocomprobante, nrofactura= fila.nrofactura, nroordenpago= fila.nroordenpago, nroregistro= fila.nroregistro, prefacturacion= fila.prefacturacion WHERE nroregistro= fila.nroregistro AND anio= fila.anio AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.factura(anio, anioresumen, clase, facturacc, ffecharecepcion, fimportepagar, fimportesiniva, fimportetotal, idcentrofactura, idcentroordenpago, idcomprobantemultivac, idlocalidad, idprestador, idresumen, idtipocomprobante, nrofactura, nroordenpago, nroregistro, prefacturacion) VALUES (fila.anio, fila.anioresumen, fila.clase, fila.facturacc, fila.ffecharecepcion, fila.fimportepagar, fila.fimportesiniva, fila.fimportetotal, fila.idcentrofactura, fila.idcentroordenpago, fila.idcomprobantemultivac, fila.idlocalidad, fila.idprestador, fila.idresumen, fila.idtipocomprobante, fila.nrofactura, fila.nroordenpago, fila.nroregistro, fila.prefacturacion);
    END IF;
    RETURN fila;
    END;
    $function$
