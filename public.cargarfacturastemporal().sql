CREATE OR REPLACE FUNCTION public.cargarfacturastemporal()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Proceso que migra las facturas ingresadas en temporalfactura para poder ser
auditadas por el modulo de contros de facturacion.*/
DECLARE
    rfactura RECORD;
    alta refcursor;
    rresultado boolean;

BEGIN
OPEN alta FOR SELECT *
               FROM temporalfactura;

FETCH alta INTO rfactura;
WHILE  found LOOP
    INSERT INTO factura(nroregistro,anio,idprestador,ffecharecepcion,nrofactura,fimportetotal,fimportepagar,prefacturacion,idlocalidad)
    VALUES (rfactura.nroregistro,rfactura.anio,rfactura.idprestador,rfactura.ffecharecepcion,rfactura.nrofactura,rfactura.fimportetotal,rfactura.fimportepagar,FALSE,rfactura.idlocalidad);

    INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion)
    VALUES (CURRENT_DATE,rfactura.nroregistro,rfactura.anio,1,'Desde Proceso de Migracion. MaLaPi.');

    INSERT INTO facturacionfechas (nroregistro,anio,ffechaini,ffechafin)
    VALUES(rfactura.nroregistro,rfactura.anio,rfactura.fechaini,rfactura.fechafin);
FETCH alta INTO rfactura;
END LOOP;
CLOSE alta;
rresultado = TRUE;
RETURN rresultado;
END;
$function$
