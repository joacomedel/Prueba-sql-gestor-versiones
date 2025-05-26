CREATE OR REPLACE FUNCTION public.facturaventa_arreglarjubilados(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/* Funcion que realiza la imputación  entre deudas y pagos
*/
DECLARE
       c_factura refcursor;
       r_factura RECORD;
       cant integer;
       rdata record;
BEGIN
     EXECUTE sys_dar_filtros($1) INTO rdata;
     cant = 0 ;
     -- 1 busco todas las facturas de jubilados dentro del rango de fecha indicado
     OPEN c_factura FOR SELECT *
                        FROM facturaventa
                        NATURAL JOIN itemfacturaventa
                        WHERE fechaemision >=rdata.fdesde and  fechaemision <=rdata.fhasta
                              and centro <> 99
                            /*  and nrofactura = rdata.nrofactura
                              and nrosucursal = rdata.nrosucursal
                              and tipocomprobante = rdata.tipocomprobante
                              and tipofactura = rdata.tipofactura*/
                              and idconcepto=50840;
     FETCH c_factura INTO r_factura;
     WHILE FOUND LOOP
           -- 2 Agrego una nueva forma de pago
           INSERT INTO facturaventacupon(centro, nrofactura,tipocomprobante,nrosucursal,tipofactura,idvalorescaja,autorizacion,nrotarjeta,monto,cuotas,nrocupon)
           VALUES(r_factura.centro,r_factura.nrofactura,r_factura.tipocomprobante,r_factura.nrosucursal,r_factura.tipofactura,104,'','',abs(r_factura.importe),0,'');
          -- 3 Eliminar de itemfacturavernta
          
           DELETE FROM itemfacturaventa tipofactura
           WHERE nrofactura= r_factura.nrofactura
                 and nrosucursal=r_factura.nrosucursal
                 and tipocomprobante = r_factura.tipocomprobante
                 and tipofactura =r_factura.tipofactura
                 and iditem = r_factura.iditem
                 and idconcepto=50840;
            -- Actualizar la cabecera del comprobante
           PERFORM facturaventa_actualizarcabecera(concat('{nrosucursal=', r_factura.nrosucursal
                          ,', nrofactura=',r_factura.nrofactura
                          ,', tipocomprobante=',r_factura.tipocomprobante
                          ,', tipofactura=',r_factura.tipofactura,'}'));
           cant = cant +1;
           FETCH c_factura INTO r_factura;
     END LOOP;

     CLOSE c_factura;

RETURN cant;
END;
$function$
