CREATE OR REPLACE FUNCTION public.generarcomprobantefacturacionanulado(bigint, integer, integer, character varying, integer, integer, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que genera un comprobante de facturacion anuladas cuyos datos sepasan por parametro */
DECLARE
     /*
     anulada = fechacreacion = fechaemision
     tipocomprobante  =$1;
     nrosucursal      =$2;
     pnrofactura      =$3;
     ptipofactura     =$4;
     idusuario        =$5;
     centro           =$6;
     anulada          =$7
     
     */
--registros
  
--variables
     
--CURSORES


BEGIN

	      
	               /* Se inserta la factura anulada */
                  INSERT INTO facturaventa (tipocomprobante,nrosucursal,nrofactura,tipofactura,centro,anulada,fechacreacion,fechaemision)
		          VALUES($1,$2,$3,$4,$6,$7,$7,$7);

                  INSERT INTO facturaventacupon(centro,tipocomprobante,nrosucursal,nrofactura,tipofactura,idvalorescaja,monto,autorizacion,nrotarjeta,cuotas,nrocupon)
                          VALUES($6,$1,$2,$3,$4,505,0,'','',0,'');


                 INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                 VALUES   ($1,$2,$3,$4,$5,$3);
     
       
     
       
       
RETURN true;
END;
$function$
