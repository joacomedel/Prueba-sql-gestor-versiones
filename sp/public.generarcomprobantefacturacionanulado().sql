CREATE OR REPLACE FUNCTION public.generarcomprobantefacturacionanulado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que genera comprobantes de facturacion anuladas */
DECLARE
     
--registros
       resultado  RECORD;
       rfactventa record;
       rcentro RECORD;
--variables
       nrotalonario bigint;
       vcantanular integer;
--CURSORES

cfactventa CURSOR FOR SELECT * FROM tempfacturaventa;
rusuario record;
elidusuario integer;
BEGIN
   SELECT INTO rcentro * from tempfacturaventa natural join talonario;
   IF FOUND THEN 
     open cfactventa;
     FETCH cfactventa into rfactventa;
      
     
      SELECT INTO resultado * FROM talonario  natural join unidadnegociotalonario
      WHERE (talonario.centro=rcentro.centro /* OR (CASE WHEN  centro()=1 THEN centro=14 END)*/) AND talonario.tipocomprobante=rfactventa.tipocomprobante
            AND talonario.tipofactura = rfactventa.tipofactura
--KR 10-12-20 NO me importa si esta vencido 
        -- AND vencimiento >= CURRENT_DATE      
           AND  rfactventa.fechaanulacion<=vencimiento 
            AND talonario.nrosucursal =rfactventa.nrosucursal AND sgtenumero <= nrofinal;



      IF NOT FOUND then
        RAISE EXCEPTION 'No se puede asentar la factura de venta. El motivo puede ser que la fecha de anulación es superior a la fecha de vencimiento o que ha llegado a la última factura del talonario';
      ELSE
          nrotalonario = resultado.sgtenumero ;
          vcantanular = (case when rfactventa.cantanular = 0 then resultado.nrofinal-resultado.sgtenumero+1 else rfactventa.cantanular end);
          FOR i IN 1..vcantanular  LOOP
	      
	               /* Se inserta la factura anulada */
                  INSERT INTO facturaventa (tipocomprobante,nrosucursal,nrofactura,tipofactura,fechaemision,anulada,centro)
		          VALUES(rfactventa.tipocomprobante,rfactventa.nrosucursal,nrotalonario,rfactventa.tipofactura, rfactventa.fechaemision,rfactventa.fechaanulacion,resultado.centro);
                   INSERT INTO itemfacturaventa (tipocomprobante,nrosucursal,nrofactura,tipofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem)
                   VALUES(rfactventa.tipocomprobante,rfactventa.nrosucursal,nrotalonario,rfactventa.tipofactura,'40718',1,0,'Factura Anulada',1,nextval('itemfacturaventa_iditem_seq'::regclass));

                INSERT INTO facturaventacupon (centro,tipocomprobante,nrosucursal,nrofactura,tipofactura,idvalorescaja,monto,autorizacion,nrotarjeta,cuotas,nrocupon)
 VALUES(resultado.centro,rfactventa.tipocomprobante,rfactventa.nrosucursal,nrotalonario,rfactventa.tipofactura,505,0,'','',0,'');

                 /* Se guarda la informacion del usuario que genero el comprobante */
                 SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
                 IF not found THEN
                    elidusuario = 25;
                 ELSE
                     elidusuario = rusuario.idusuario;
                 END IF;
                 INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                 VALUES   (rfactventa.tipocomprobante,rfactventa.nrosucursal,nrotalonario, rfactventa.tipofactura,elidusuario,nrotalonario);



                 /* Actualizo el comprobante*/

		          UPDATE talonario SET sgtenumero=sgtenumero+1
                  WHERE  (talonario.centro=rcentro.centro /* OR (CASE WHEN  centro()=1 THEN centro=14 END)*/)
                        AND talonario.tipocomprobante =rfactventa.tipocomprobante
		          AND talonario.nrosucursal =rfactventa.nrosucursal AND talonario.tipofactura = rfactventa.tipofactura;
                  nrotalonario = resultado.sgtenumero + i;
       
              
       END LOOP;
       
       END IF;
   END IF;
           
       
RETURN true;
END;
$function$
