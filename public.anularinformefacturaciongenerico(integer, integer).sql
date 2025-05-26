CREATE OR REPLACE FUNCTION public.anularinformefacturaciongenerico(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme 
-- $2: idcentroinformefacturacion 

   resp BOOLEAN;
   rdeudactacte record;
   relinforme record;
   rpagoctacte record;
   elidpago bigint;
   eliddeuda bigint;
   rorigenctacte RECORD;

BEGIN
   -- 1 busco los datos del informe de facturacion 
      SELECT INTO relinforme *
      FROM informefacturacion
      JOIN facturaventa USING (nrosucursal,nrofactura,tipofactura,tipocomprobante)
--KR 20-09-21 PARA dejar mas bonita la descripcion 
       join tipocomprobanteventa on (tipocomprobante= idtipo)
      WHERE nroinforme =  $1 and idcentroinformefacturacion = $2;

--KR 02-11-21 Verifico que tipo de afiliado es para saber a que tabla ir 
   CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
   INSERT INTO tempcliente(nrocliente,barra) VALUES(relinforme.nrodoc,relinforme.barra);
   SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
		FROM (SELECT verifica_origen_ctacte() as origen ) as t;
   DROP TABLE tempcliente;
 
   IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
 

      -- Verifico si se trata de un afiliado y el informe de facturacion fue en cuenta corriente
      IF (relinforme.tipofactura = 'FA'  and relinforme.barra < 100 and relinforme.importectacte > 0 )THEN	
		SELECT INTO rdeudactacte * 
		FROM cuentacorrientedeuda	
		WHERE idcomprobante = (relinforme.nroinforme * 100) + relinforme.idcentroinformefacturacion;
		IF FOUND  THEN 
			 	INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,
					    movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc,idconcepto)
				VALUES(6,relinforme.barra,concat(relinforme.nrodoc,relinforme.barra::varchar),now(),
                                       concat('Anulacion ',relinforme.tipofactura,' ',relinforme.desccomprobanteventa, ' Sucursal: ',relinforme.nrosucursal::varchar,' Nro.Factura:', relinforme.nrofactura::varchar),rdeudactacte.nrocuentac,
                                        relinforme.importectacte,(relinforme.nrofactura*100)+relinforme.nrosucursal,
                                        (-1)*abs(relinforme.importectacte),relinforme.nrodoc,rdeudactacte.idconcepto);  --- VAS 2024-03 (--)
                                elidpago =  currval('public.cuentacorrientepagos_idpago_seq');    
                                IF   (rdeudactacte.importe = rdeudactacte.saldo and centro() = 1 ) THEN -- imputo la deuda con el pago
                                      INSERT INTO cuentacorrientedeudapago (idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp)
                                      VALUES(elidpago,rdeudactacte.iddeuda,now(),rdeudactacte.idcentrodeuda,centro(),relinforme.importectacte);
                                     
				      UPDATE cuentacorrientedeuda SET saldo = saldo - relinforme.importectacte
                                      WHERE iddeuda = rdeudactacte.iddeuda and idcentrodeuda = rdeudactacte.idcentrodeuda;

                                      UPDATE cuentacorrientepagos SET saldo = abs(saldo) - relinforme.importectacte  -- VASYBEL 15052024
                                      WHERE idpago = elidpago and idcentropago = centro();
                                END IF ;      
 

		END IF;
       END IF;

        IF (relinforme.tipofactura = 'NC'  and relinforme.barra < 100 and relinforme.importectacte > 0 )THEN	
/*KR 23-11-21 esto nunca anduvo pq la tabla cuentacorrientepago estaba sin la s*/
		SELECT INTO rpagoctacte * 
		FROM cuentacorrientepagos
		WHERE idcomprobante = (relinforme.nroinforme * 100) + relinforme.idcentroinformefacturacion;
		IF FOUND  THEN 
			 	INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,
					    movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc)
				VALUES(7,relinforme.barra,concat(relinforme.nrodoc,relinforme.barra::varchar),now(),
                                       concat('Anulacion ',relinforme.tipofactura,' ',relinforme.desccomprobanteventa, ' Sucursal: ',relinforme.nrosucursal::varchar,' Nro.Factura:', relinforme.nrofactura::varchar),rpagoctacte.nrocuentac,
                                        relinforme.importectacte,(relinforme.nrofactura*100)+relinforme.nrosucursal,
                                        relinforme.importectacte,relinforme.nrodoc);

                                 eliddeuda =  currval('public.cuentacorrientedeuda_iddeuda_seq');    
                                 IF   (rpagoctacte.importe = rpagoctacte.saldo and centro() = 1 ) THEN -- imputo la deuda con el pago
                                      INSERT INTO cuentacorrientedeudapago (idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp)
                                      VALUES(rpagoctacte.idpago,eliddeuda,now(),centro(),rpagoctacte.idcentropago,relinforme.importectacte);

                                      UPDATE cuentacorrientepagos SET saldo = saldo - relinforme.importectacte
                                      WHERE idpago = rpagoctacte.idpago and idcentropago = rpagoctacte.idcentropago;

                                      UPDATE cuentacorrientedeuda SET saldo = saldo - relinforme.importectacte
                                      WHERE iddeuda = eliddeuda and idcentrodeuda = centro();

                                 END IF ;    
 

		END IF;
       END IF;
   END IF;
   IF rorigenctacte.origentabla = 'clientectacte' THEN 
--KR 03-09-21 Agrego porque esto solo contempla cuando el comprobante este en la ctacte afiliado. Llamo a un SP que esta hace tiempo en produccion. 
    
         SELECT INTO resp * FROM  configurarctactevinculadainformecliente ($1,$2);
     
   END IF;
   return true;
END;
$function$
