CREATE OR REPLACE FUNCTION public.asentarpagoctacteinstitucion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE




--REGISTROS
       unafactpago RECORD;
       unpago RECORD;
       regtipoinfo RECORD;
       pagoctacte RECORD;
       pagofact RECORD;
       recdeuda RECORD;
       elem RECORD;
       regmesinfo RECORD;
       unpagoctacte RECORD;
--CURSORES
       cursorfactpago CURSOR FOR SELECT * FROM temppagosfacturaventa; 
       cursorpagos CURSOR FOR SELECT * FROM temppagodeuda;
--VARIABLES
       nrorecibo bigint;
       ridpago bigint;
       imptotal DOUBLE PRECISION;
       imppagado REAL;
       movpago bigint;
       comprobantemovimiento BIGINT;
       movimientoconcepto VARCHAR;
       nrocuentacontable VARCHAR;
      


BEGIN

     SELECT INTO unpago * FROM temppagoctacte;
     --Se asienta el recibo
     SELECT INTO nrorecibo * FROM getidrecibocaja();
     INSERT INTO recibo(idrecibo,importerecibo,imputacionrecibo,importeenletras)
     VALUES (nrorecibo, unpago.importeapagar,unpago.conceptoPago,unpago.importeenletras);

    
     UPDATE temppagoctacte SET idrecibo = nrorecibo;

 


/*inserto en importesrecibo tantas tupla como formas de pago existan*/
     OPEN cursorpagos;
     FETCH cursorpagos into unpagoctacte;
     WHILE  found LOOP
         
         INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
         VALUES (nrorecibo,unpagoctacte.idformapagotipos,unpagoctacte.monto,centro());
   


     -- Se asienta en pagos
    INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,pfechaemision,idpagostipos,idbanco,idlocalidad,idprovincia,nrooperacion,nrocuentabanco)
    VALUES(nextval('pagos_idpagos_seq'),unpago.centro,nrorecibo,unpagoctacte.idformapagotipos,unpago.conceptoPago,unpago.fechaingreso,unpago.fechaemision,unpago.idpagotipo,unpagoctacte.idbanco,unpago.idlocalidad,unpago.idprovincia,unpagoctacte.nrooperacion,unpagoctacte.nrocuentabanco);
    ridpago =currval('pagos_idpagos_seq');
  

     FETCH cursorpagos into unpagoctacte;
     END LOOP;
     close cursorpagos;





     OPEN cursorfactpago;
     FETCH cursorfactpago into unafactpago;
     WHILE  found LOOP

	SELECT INTO pagofact * FROM pagosfacturaventa
	WHERE nroinforme=unafactpago.nroinforme AND idcentroinformefacturacion=unafactpago.idcentroinformefacturacion
	        AND nrofactura= unafactpago.nrofactura AND tipocomprobante = unafactpago.tipocomprobante AND nrosucursal=unafactpago.nrosucursal AND tipofactura=unafactpago.tipofactura;

	IF FOUND THEN
		
	    UPDATE pagosfacturaventa SET importepagado=(unafactpago.importe + pagosfacturaventa.importepagado)
	    WHERE nroinforme=unafactpago.nroinforme AND idcentroinformefacturacion=unafactpago.idcentroinformefacturacion
	        AND nrofactura= unafactpago.nrofactura AND tipocomprobante = unafactpago.tipocomprobante AND nrosucursal=unafactpago.nrosucursal AND tipofactura=unafactpago.tipofactura;

	ELSE
	
          INSERT INTO pagosfacturaventa (idpagos,nrofactura,tipocomprobante,nrosucursal,tipofactura,importepagado,nroinforme,idcentroinformefacturacion)
          VALUES (ridpago,unafactpago.nrofactura,unafactpago.tipocomprobante,unafactpago.nrosucursal,unafactpago.tipofactura,unafactpago.importe,unafactpago.nroinforme,unafactpago.idcentroinformefacturacion);

	END IF;
	
	  SELECT INTO imptotal SUM(informefacturacionitem.importe) FROM informefacturacionitem NATURAL JOIN informefacturacion
	  	WHERE nroinforme=unafactpago.nroinforme AND idcentroinformefacturacion=unafactpago.idcentroinformefacturacion
	        AND nrofactura= unafactpago.nrofactura AND tipocomprobante = unafactpago.tipocomprobante AND nrosucursal=unafactpago.nrosucursal AND tipofactura=unafactpago.tipofactura;

	  SELECT INTO imppagado SUM(pagosfacturaventa.importepagado) FROM pagosfacturaventa
	  	WHERE nroinforme=unafactpago.nroinforme AND idcentroinformefacturacion=unafactpago.idcentroinformefacturacion
	        AND nrofactura= unafactpago.nrofactura AND tipocomprobante = unafactpago.tipocomprobante AND nrosucursal=unafactpago.nrosucursal AND tipofactura=unafactpago.tipofactura;
	

	
          IF float84le(float8abs(float84mi(imptotal,imppagado)),0.03) THEN
	   --SI EL INFORME FUE COMPLETAMENTE PAGADO ENTONCES LE CAMBIO EL ESTADO A PAGADO, SINO A PARCIALMENTE PAGADO
		PERFORM  cambiarestadoinformefacturacion(unafactpago.nroinforme,unafactpago.idcentroinformefacturacion,6,'GENERADO AUTOMATICAMENTE DESDE SP:asentarpagoctacteinstitucion');
	  ELSE
		PERFORM  cambiarestadoinformefacturacion(unafactpago.nroinforme,unafactpago.idcentroinformefacturacion,7,'GENERADO AUTOMATICAMENTE DESDE CAJA, PAGO A UNA INSTITUCION, SP:asentarpagoctacteinstitucion');
	   END IF;

    /*Siempre el Comprobante Tipo (0) va a ser un nro de Recibo*/
     comprobantemovimiento = unafactpago.nroinforme * 100 + unafactpago.idcentroinformefacturacion;



      SELECT INTO recdeuda * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.idcomprobante = comprobantemovimiento
                                   AND cuentacorrientedeuda.idcomprobantetipos = 21;



   IF FOUND THEN
          ---quiere decir que la orden tenia una deuda que cancelo
          -- Se Anula el movimiento de cuenta correinte

         SELECT INTO pagoctacte * FROM pagocuentacorriente WHERE nullvalue(pagocuentacorriente.idmovimiento);

       --Si el cliente es una institucion la cta contable es 10325

        IF pagoctacte.tipodoc <>'24' THEN
           nrocuentacontable = '10325'; --Deudores x convenio Reciprocidad
        ELSE
           nrocuentacontable = '10323'; --Deudores x convenio AMUC
        END IF;

        SELECT INTO regtipoinfo * 
        FROM informefacturacion 
        WHERE nroinforme=unafactpago.nroinforme and idcentroinformefacturacion=unafactpago.idcentroinformefacturacion; 
        
        IF (regtipoinfo.idinformefacturaciontipo = 8) THEN --si el informe es de aportes y contribuciones

            SELECT INTO regmesinfo mesingreso, anioingreso FROM informefacturacionaportescontribuciones 
            WHERE nroinforme=unafactpago.nroinforme and idcentroinformefacturacion=unafactpago.idcentroinformefacturacion 
            GROUP BY mesingreso, anioingreso; 
          movimientoconcepto = concat('Pago del Informe de Facturacion: ' , unafactpago.nroinforme , ' - ' ,        unafactpago.idcentroinformefacturacion , 'del mes ' , regmesinfo.mesingreso , ' - ' ,regmesinfo.anioingreso);
        ELSE
         movimientoconcepto = concat('Pago del Informe de Facturacion: ' , unafactpago.nroinforme , ' - ' , unafactpago.idcentroinformefacturacion);
        END IF; 

        INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
VALUES(pagoctacte.idcomprobantetipos,pagoctacte.tipodoc,pagoctacte.idctacte,pagoctacte.fechamovimiento,movimientoconcepto,nrocuentacontable,(case when unafactpago.importe >0 then (unafactpago.importe* (- 1::double precision)) else (unafactpago.importe) end),nrorecibo,0 ,387,pagoctacte.nrodoc);


         INSERT INTO cuentacorrientedeudapago(iddeuda,idcentrodeuda,idpago,idcentropago,fechamovimientoimputacion,importeimp)
                            VALUES (recdeuda.iddeuda,recdeuda.idcentrodeuda,currval('cuentacorrientepagos_idpago_seq'),centro(),now(),round(CAST (unafactpago.importe AS numeric), 2));
	
          UPDATE cuentacorrientedeuda SET saldo =  round(CAST (recdeuda.saldo- unafactpago.importe AS numeric), 2) WHERE cuentacorrientedeuda.iddeuda = recdeuda.iddeuda
	  AND cuentacorrientedeuda.idcentrodeuda = recdeuda.idcentrodeuda;
	

 UPDATE pagos set nrocuentac= nrocuentacontable WHERE idpagos=ridpago and centro=centro();

     SELECT INTO elem * FROM pagosinstitucion WHERE idpagos= ridpago AND  nrofactura = unafactpago.nrofactura AND tipocomprobante=unafactpago.tipocomprobante AND nrosucursal= unafactpago.nrosucursal AND tipofactura=unafactpago.tipofactura;
     IF NOT FOUND THEN

     INSERT INTO pagosinstitucion (idpagos,idprestador,fechaenviofactura,nrofactura,tipocomprobante,nrosucursal,tipofactura)   VALUES(ridpago,pagoctacte.tipodoc,unpago.fechaenviofactura,unafactpago.nrofactura,unafactpago.tipocomprobante,unafactpago.nrosucursal,unafactpago.tipofactura);

     END IF;

      END IF;


     FETCH cursorfactpago into unafactpago;


     END LOOP;
     close cursorfactpago;




RETURN FALSE;
END;
$function$
