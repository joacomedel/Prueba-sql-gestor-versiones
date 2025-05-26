CREATE OR REPLACE FUNCTION public.anularcomprobantesfacturacion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
elem RECORD;
resp BOOLEAN;
respiva RECORD;
--temporal que tiene los datos de la factura a anular
anularfac CURSOR FOR SELECT * FROM tempfacturaaanular;
reganularfac RECORD;
rliquidaciontarjeta RECORD ;

BEGIN

     open anularfac;
     fetch anularfac into reganularfac;

     WHILE FOUND LOOP
           /**
           ** CORROBORO QUE EL COMPROBANTE NO ESTE VINCULADO A UNA LIQ IVA CERRADA
           *010319
           */
           SELECT INTO  respiva facturaventa_esposiblemodificarcomprobante_v1(concat('{tipofactura=',reganularfac.tipofactura,', tipocomprobante=',reganularfac.tipocomprobante,', nrosucursal=',reganularfac.nrosucursal,', nrofactura=',reganularfac.nrofactura,'}')) as semodifica;
           /*IF NOT FOUND THEN
             respiva.semodifica = false;
           END IF;*/
           IF( not nullvalue(respiva.semodifica) )THEN
                        --BelenA: El mensaje del RAISE ahora sera dependiendo del mensaje que te devuelve en el respiva. TK 6093
                        RAISE EXCEPTION '%',respiva.semodifica;
               ELSE
                            --Updateo la factura que se anulo como anulada
                            UPDATE facturaventa SET anulada = CURRENT_DATE WHERE nrosucursal= reganularfac.nrosucursal AND tipocomprobante=reganularfac.tipocomprobante
                            AND tipofactura =reganularfac.tipofactura AND nrofactura =reganularfac.nrofactura;

                            IF (reganularfac.tipofactura='NC') THEN
                               SELECT INTO resp * FROM anularnotacredito(reganularfac.nrosucursal,reganularfac.tipocomprobante,reganularfac.tipofactura,reganularfac.nrofactura);
                            ELSE
                                SELECT INTO resp * FROM anularfacturaventa(reganularfac.nrosucursal,reganularfac.tipocomprobante,reganularfac.tipofactura,reganularfac.nrofactura);
                            END IF;

                            -- CS 2017-10-24
                            -- Permite que vuelva a ser migrada a Multivac
                            DELETE from multivac.facturaventa_migrada
                            WHERE nrosucursal=reganularfac.nrosucursal and tipocomprobante=reganularfac.tipocomprobante and tipofactura=reganularfac.tipofactura and nrofactura=reganularfac.nrofactura;
           END IF;




    fetch anularfac into reganularfac;
    END LOOP;
    close anularfac;

return true;
END;
$function$
