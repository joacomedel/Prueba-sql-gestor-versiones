CREATE OR REPLACE FUNCTION public.generarcomprobantefacturacionanuladoaux()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que genera comprobantes de facturacion anuladas */
DECLARE
     
--registros
       resultado  RECORD;
       rfactventa record;
--variables
       nrotalonario bigint;
cantanular bigint;
--CURSORES


rusuario record;
elidusuario integer;
BEGIN
nrotalonario=101;
cantanular=50;
    
      SELECT INTO resultado * FROM talonario  natural join unidadnegociotalonario
      WHERE (talonario.centro=14 ) AND talonario.tipocomprobante=1
            AND talonario.tipofactura = 'NC' AND vencimiento >= CURRENT_DATE
            AND talonario.nrosucursal =16 AND sgtenumero <= nrofinal;



      IF NOT FOUND then
        RAISE EXCEPTION 'No se puede asentar la factura de venta. El motivo puede ser, o que el talonario este vencido, o que se haya llegado a la última factura del talonario';
      ELSE
          nrotalonario = resultado.sgtenumero ;
	      FOR i IN 1..cantanular LOOP
	      
	               /* Se inserta la factura anulada */
                  INSERT INTO facturaventa (tipocomprobante,nrosucursal,nrofactura,tipofactura,anulada,fechacreacion,fechaemision,centro)
		          VALUES(resultado.tipocomprobante,resultado.nrosucursal,nrotalonario,resultado.tipofactura, '2018-11-24','2018-11-24','2018-11-24',/*centro()*/resultado.centro);



                 /* Se guarda la informacion del usuario que genero el comprobante */
                 SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
                 IF not found THEN
                    elidusuario = 25;
                 ELSE
                     elidusuario = rusuario.idusuario;
                 END IF;
                 INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                 VALUES   (resultado.tipocomprobante,resultado.nrosucursal,nrotalonario, resultado.tipofactura,25,nrotalonario);



                 /* Actualizo el comprobante*/

		          UPDATE talonario SET sgtenumero=sgtenumero+1
                  WHERE (talonario.centro=14 )
                        AND talonario.tipocomprobante =resultado.tipocomprobante
		          AND talonario.nrosucursal =resultado.nrosucursal AND talonario.tipofactura = resultado.tipofactura;
                  nrotalonario = resultado.sgtenumero + i;
       
              
       END LOOP;
       
       END IF;
       
       
RETURN true;
END;
$function$
