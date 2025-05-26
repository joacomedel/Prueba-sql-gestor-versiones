CREATE OR REPLACE FUNCTION public.ingresarmovimientoctactecatgasto()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD
       regtemp RECORD;
       rmapcgp RECORD;
       rctacte RECORD;
       rctactecliente RECORD;
       relcliente RECORD;
--VARIABLES 
       vmovconcepto VARCHAR;
       lactacble VARCHAR; 
BEGIN

  SELECT INTO regtemp * FROM temprecepcion NATURAL JOIN tipofacturatipomovimiento JOIN reclibrofact using(idrecepcion, idcentroregional); 

  IF FOUND THEN -- Si el tipo de factura se encuentra en esta tabla entonces se debe generar movimientos en la cta.cte.

      SELECT INTO rmapcgp * FROM mapeocatgastoprestador NATURAL JOIN prestador
                     WHERE idcategoriagastosiges=regtemp.catgasto;
     IF FOUND THEN 
         vmovconcepto =  concat('Mov. en cta cte por ingreso de comprobante: ',regtemp.tipofactura,'-',regtemp.letra,regtemp.numero, ' en recepcion Nro.:', regtemp.idrecepcion ,'-', regtemp.idcentroregional);
         IF regtemp.tipomovimiento ilike 'Deuda' THEN --Se debe generar deuda en cta cte

             SELECT INTO rctacte * FROM ctactedeudanoafil JOIN mapeocatgastoprestador 
                       ON(nrodoc= idprestador)
                      WHERE idcomprobante = (regtemp.numeroregistro*10000)+regtemp.anio 
							AND idcomprobantetipos = 49 AND tipodoc = 600
                      AND (nrodoc) IN (SELECT idprestador FROM mapeocatgastoprestador);
	    IF FOUND THEN
   		UPDATE ctactedeudanoafil SET importe = regtemp.monto
					, idctacte = replace (replace(rmapcgp.pcuit,'-',''),'/','')
					, movconcepto = vmovconcepto
					, saldo =(regtemp.monto - (rctacte.importe - abs(rctacte.saldo) ) ) 
					,fechavencimiento = regtemp.fechavenc
                                         ,nrodoc = rmapcgp.idprestador
					WHERE idcomprobante = (regtemp.numeroregistro*10000)+regtemp.anio 
							AND idcomprobantetipos = 49 AND tipodoc = 600
                                       AND iddeuda=rctacte.iddeuda AND idcentrodeuda=rctacte.idcentrodeuda;  
	      ELSE 


            INSERT INTO ctactedeudanoafil(idcomprobantetipos, tipodoc,idctacte,
              movconcepto,nrocuentac,importe, idcomprobante, saldo,idconcepto,nrodoc,fechavencimiento)
              VALUES(49,600,replace(rmapcgp.pcuit,'-',''),vmovconcepto,10311,regtemp.monto,
              (regtemp.numeroregistro*10000)+regtemp.anio,regtemp.monto,555,rmapcgp.idprestador,regtemp.fechavenc);
         END IF;
        END IF ;


         IF regtemp.tipomovimiento ilike 'Pago' THEN --Se debe generar pago en cta cte
	               
            IF (regtemp.tipofactura ilike 'NCR')  THEN
                      lactacble = '41500'; 
/*si es NCR guardo la deuda en la ctacte del cliente, BUSCO los datos del cliente*/

                     SELECT INTO relcliente * FROM  cliente as c   JOIN clientectacte USING(nrocliente, barra) 
                     WHERE concat(c.cuitini ,c.cuitmedio,c.cuitfin) ilike  (replace(rmapcgp.pcuit,'-',''));
        	
	             SELECT INTO rctactecliente * FROM ctactepagocliente
                     WHERE idcomprobante =(regtemp.numeroregistro*10000)+regtemp.anio 
							AND idcomprobantetipos = 51 ;
                      -- AND idclientectacte = relcliente.idclientectacte;
             --Asumo que se puede cambiar el CLIENTE de la factura. 
         	  IF FOUND THEN
                  --para cambiar el importe hay que tener en cuenta el monto usado del mismo.
		            UPDATE ctactepagocliente SET importe = regtemp.monto *-1
					,movconcepto = vmovconcepto
                                        ,idclientectacte = relcliente.idclientectacte
                                        ,idcentroclientectacte=relcliente.idcentroclientectacte
                                        ,saldo = (abs(regtemp.monto) - 
                                         (abs(rctactecliente.importe) - abs(rctactecliente.saldo)))*-1
					WHERE idcomprobante = (regtemp.numeroregistro*10000)+regtemp.anio 
					AND idcomprobantetipos = 51 
                                        AND idpago=rctactecliente.idpago AND idcentropago=rctactecliente.idcentropago; 
	          ELSE 
                          INSERT INTO ctactepagocliente(idcomprobantetipos, idclientectacte,idcentroclientectacte,
                           movconcepto,nrocuentac,importe, idcomprobante, saldo)
                          VALUES(51,relcliente.idclientectacte,relcliente.idcentroclientectacte,vmovconcepto,lactacble,regtemp.monto*-1,
                         (regtemp.numeroregistro*10000)+regtemp.anio,regtemp.monto*-1);
                 END IF; --DEL IF FOUND

     
          END IF ; -- IF (regtemp.tipofactura ilike 'NCR')

               	--Verifico si ya se ingreso este movimiento 
        --Asumo que se puede cambiar el prestador de la factura. 
	  SELECT INTO rctacte * FROM ctactepagonoafil 
                WHERE idcomprobante =(regtemp.numeroregistro*10000)+regtemp.anio 
							AND idcomprobantetipos = 51 AND tipodoc = 600
                       AND (nrodoc) IN (SELECT idprestador FROM mapeocatgastoprestador);
	  IF FOUND THEN
         --Malapi Verificar este punto, pues para cambiar el importe hay que tener en cuenta el monto usado del mismo.
		UPDATE ctactepagonoafil SET importe = regtemp.monto *-1
					,idctacte = replace(rmapcgp.pcuit,'-','')
					,movconcepto = vmovconcepto
                                        ,nrodoc = rmapcgp.idprestador
					,saldo = (abs(regtemp.monto) - (abs(rctacte.importe) - abs(rctacte.saldo)))*-1
				
					WHERE idcomprobante = (regtemp.numeroregistro*10000)+regtemp.anio 
							AND idcomprobantetipos = 51 AND (tipodoc = 600 OR  tipodoc = 500)
                                        AND idpago=rctacte.idpago AND idcentropago=rctacte.idcentropago; 
	  ELSE 
                  INSERT INTO ctactepagonoafil(idcomprobantetipos, tipodoc,idctacte,
                  movconcepto,nrocuentac,importe, idcomprobante, saldo,idconcepto,nrodoc)
                  VALUES(51,600,replace(rmapcgp.pcuit,'-',''),vmovconcepto,lactacble,regtemp.monto*-1,
                  (regtemp.numeroregistro*10000)+regtemp.anio,regtemp.monto*-1,555,rmapcgp.idprestador);
         END IF;
      END IF;
    END IF; 
 END IF;
     
 RETURN true;
END;
$function$
