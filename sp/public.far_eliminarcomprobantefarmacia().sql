CREATE OR REPLACE FUNCTION public.far_eliminarcomprobantefarmacia()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       cfactura refcursor;
       lafactura record;
       raux record;
       resp boolean;
       respuestaeliminar  boolean;
BEGIN

       -- Antes que nada verifico que existan todas las FK que deben existir para garantizar la robustez y buen funcionamiento del SP
        SELECT INTO respuestaeliminar * FROM existefkey();
        IF (not respuestaeliminar) THEN RAISE EXCEPTION 'Error de Sistemas ' USING HINT = 'Avisar al departamento de sistemas que hay un error con las fonraneas. '; END IF ;

     /* Recupero todas las facturas que se desean eliminar*/
     open cfactura for  SELECT  * 
                        FROM tempfactura 
						JOIN talonario USING(tipocomprobante,nrosucursal,tipofactura)
                        WHERE ( nrosucursal =2 or nrosucursal =4 or nrosucursal =19 or nrosucursal =20 OR nrosucursal = 1) AND centro = 99 ;
                             ---   and  EXTRACT ('hour' FROM now()) < 12; --- VAS Para verificar que los datos quedaron correctamente 27-08-2019
     fetch cfactura into lafactura;
     while FOUND loop
           /* se verifica que solo se pueda eliminar un comprobante emitido en el dia para evitar problemas de sincronizacion */
          
           SELECT INTO raux 
           FROM facturaventa
           LEFT JOIN facturaventausuario USING (nrofactura,tipocomprobante,nrosucursal,tipofactura)
           WHERE nrofactura= lafactura.nrofactura
                 AND tipocomprobante = lafactura.tipocomprobante
                 AND nrosucursal=lafactura.nrosucursal
                 AND tipofactura=lafactura.tipofactura
                 AND fechaemision = now()::date
                 AND nullvalue(nrofacturafiscal);
            IF FOUND THEN
                      SELECT INTO resp far_eliminarcomprobantenoemitido(lafactura.nrofactura,lafactura.nrosucursal,lafactura.tipocomprobante, lafactura.tipofactura  );

                      IF resp THEN
                              SELECT INTO resp far_compdesplazamientodecreciente(
                              (lafactura.nrofactura + 1) ,lafactura.nrosucursal,
                              lafactura.tipofactura ,
                              lafactura.tipocomprobante );
                      END IF;
            ELSE
                RAISE EXCEPTION 'Error de Sistemas ' USING HINT = 'Fecha de emision distinta a la fecha actual % o nrofacturafiscal distinto de null. ';
            END IF;
    fetch cfactura into lafactura;

     END loop;

return resp;
END;
$function$
