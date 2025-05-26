CREATE OR REPLACE FUNCTION public.generarcomprobanteanuladointerno(tipocomprobante integer, tipofactura character varying, nrosucursal integer, nrofacturadesde integer, centro integer, fechaanulacion date, cantidadanular integer, idusuario integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  

 /* Funcion que genera comprobantes de facturacion anuladas */


     
--registros
      
       rfactventa record;
--variables

       resultado record;
       nrotalonario bigint;
       nrofacturadesde integer;
       nrofacturahasta integer;
rusuario record;
elidusuario integer;
can integer;
fecha date;
BEGIN

    can=$7;
    elidusuario=$8;
    nrofacturadesde=$4;
    nrofacturahasta=nrofacturadesde+can;    
    fecha=$6;
    
    
    
      SELECT INTO resultado * FROM talonario
      WHERE talonario.centro=$5 AND talonario.tipocomprobante=$1
            AND talonario.tipofactura = $2 
            AND talonario.nrosucursal =$3 ;



      IF NOT FOUND then
        RAISE EXCEPTION 'No se puede asentar la factura de venta. El motivo puede ser, o que el talonario este vencido, o que se haya llegado a la última factura del talonario';
      ELSE
        
	      FOR i IN nrofacturadesde..nrofacturahasta LOOP
	      
	               /* Se inserta la factura anulada */
                  INSERT INTO facturaventa (tipocomprobante,nrosucursal,nrofactura,tipofactura,anulada,fechaemision,fechacreacion,centro)
		          VALUES($1,$3,i,$2, fecha,fecha,fecha,$5);

        
                 INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                 VALUES   ($1,$3,i,$2,$8,i);



                 /* Actualizo el comprobante*/

		          UPDATE talonario SET sgtenumero=sgtenumero+1
                  WHERE talonario.centro=$5 AND talonario.tipocomprobante =$1
		          AND talonario.nrosucursal =$3 AND talonario.tipofactura =$2;
                 
       
              
       END LOOP;
       
       END IF;
       
       
RETURN true;

END;
$function$
