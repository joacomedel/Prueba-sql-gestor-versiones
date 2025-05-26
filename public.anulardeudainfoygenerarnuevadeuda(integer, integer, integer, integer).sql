CREATE OR REPLACE FUNCTION public.anulardeudainfoygenerarnuevadeuda(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que anula la deuda del informe al haberse anulada la factura y genera una nueva deuda a partir
del nuevo informe generado al momento de anularse la factura.

*/
DECLARE


-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

       recdeuda RECORD;
       comprobantemovimiento BIGINT;
       movimientoconcepto VARCHAR;
       nrocuentacontable VARCHAR;
       elem RECORD;
       vmovpago bigint;
       rusuario RECORD;
 
BEGIN


    comprobantemovimiento = $1 * 100 + $2;  
    SELECT INTO recdeuda * FROM ctactedeudanoafil WHERE idcomprobante = comprobantemovimiento
                                   AND idcomprobantetipos = 21;

   IF FOUND THEN
       
         --nrocuentacontable = '10323'; --Deudores x convenio AMUC       
         movimientoconcepto =concat('Anulacion de Deuda de informe numero: ' , $1 , ' - ' , $2 ,' por haberse anulado el comprobante de facturacion correspondiente al informe. ');

         INSERT INTO ctactepagonoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,saldo,idconcepto,nrodoc)
VALUES(recdeuda.idcomprobantetipos,recdeuda.tipodoc,recdeuda.nrodoc,now(),movimientoconcepto,recdeuda.nrocuentac,0,0,recdeuda.idconcepto,recdeuda.nrodoc);


         INSERT INTO ctactedeudapagonoafil(iddeuda,idcentrodeuda,idpago,idcentropago,fechamovimientoimputacion, importeimp)
                            VALUES (recdeuda.iddeuda,recdeuda.idcentrodeuda,currval('ctactepagonoafil_idpago_seq'),centro(),now(),0);
	
          UPDATE ctactedeudanoafil SET saldo = 0  WHERE iddeuda = recdeuda.iddeuda AND idcentrodeuda = recdeuda.idcentrodeuda;	

  ----Y GENERO UNA NUEVA DEUDA VINCULADA AL NUEVO INFORME

	movimientoconcepto =concat('Deuda por generacion de informe numero: ' , $3 , ' - ' , centro());
	comprobantemovimiento = $3 * 100 +centro();    
   
	INSERT INTO ctactedeudanoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
			VALUES (21,recdeuda.tipodoc,recdeuda.idctacte,now(),movimientoconcepto,recdeuda.nrocuentac,recdeuda.importe,comprobantemovimiento,recdeuda.importe,
recdeuda.idconcepto,recdeuda.nrodoc);


     
   END IF;

--KR 13-10-22 se perdia el comprobantemovimiento cuando entraba a la condicional anterior, por lo que no anulaba la deuda. Tkt 5260
 comprobantemovimiento = $1 * 100 + $2;  
     
 SELECT INTO recdeuda * FROM ctactedeudacliente WHERE idcomprobante = comprobantemovimiento
                                   AND idcomprobantetipos = 21;

   IF FOUND THEN
       
         /* Se guarda la informacion del usuario que genero el comprobante */
         --MaLapi 03-08-2021 uso la funion sys_dar_usuarioactual SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;

         -- MaLaPi 03-08-2021 Lo comento pues no se esta generando un recibo.. no entiende de donde viene esto... estoy queriendo anular una factura de aporte
         --INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (nrorecibo,centro(),rusuario.idusuario) ;

         movimientoconcepto =concat('Anulacion de Deuda de informe numero: ' , $1 , ' - ' , $2 ,' por haberse anulado el comprobante de facturacion correspondiente al informe. SP anulardeudainfoygenerarnuevadeuda');
         vmovpago= nextval('ctactepagocliente_idpago_seq');
        

         INSERT INTO ctactepagocliente(idpago,idcentropago,idcomprobantetipos,idclientectacte,idcentroclientectacte,
                      fechamovimiento,movconcepto,nrocuentac,importe,saldo,idcomprobante)
          VALUES(vmovpago,centro(),recdeuda.idcomprobantetipos,recdeuda.idclientectacte,recdeuda.idcentroclientectacte,now()
             ,movimientoconcepto,recdeuda.nrocuentac,recdeuda.importe,0,comprobantemovimiento);

         INSERT INTO ctactedeudapagocliente(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp,idusuario,idimputacion)
               VALUES (vmovpago,centro(),recdeuda.iddeuda,recdeuda.idcentrodeuda,CURRENT_TIMESTAMP, recdeuda.importe,sys_dar_usuarioactual(),vmovpago);

        UPDATE ctactedeudacliente SET saldo = 0 WHERE ctactedeudacliente.iddeuda = recdeuda.iddeuda 
			AND ctactedeudacliente.idcentrodeuda = recdeuda.idcentrodeuda; 
--KR 06-07-21 AHORA DESDE EL SP sys_generar_movimientoctacte SE generan los movimientos. 
     
  /* KR 18-06-18 la deuda se genera cuando realizan la factura generica desde el SP asentarcomprobantefacturaciongenerico_v2 que llama al SP asentarcomprobantefacturaciongenerico_generactacte. Este último genera la deuda. 
 ----Y GENERO UNA NUEVA DEUDA VINCULADA AL NUEVO INFORME

	movimientoconcepto =concat('Deuda por generacion de informe numero: ' , $3 , ' - ' , centro());
	comprobantemovimiento = $3 * 100 +centro();    
   
        INSERT INTO ctactedeudacliente(idcomprobantetipos,idclientectacte,fechamovimiento,movconcepto,nrocuentac,
                     importe,idcomprobante,saldo,fechavencimiento)
	  VALUES  (21,recdeuda.idclientectacte,now(),movimientoconcepto,recdeuda.nrocuentac,recdeuda.importeinfo,comprobantemovimiento,
                    recdeuda.importeinfo,current_date+30);

*/
     
   END IF;

     
       

return true;
END;
$function$
