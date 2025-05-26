CREATE OR REPLACE FUNCTION public.asentarpagoctactecliente()
 RETURNS SETOF recibo
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta los pagos que se realizan por caja de los pagos de la cuenta corriente. */
DECLARE
rusuario record;

       rrecibo public.recibo%rowtype;
--cursores
       cursormovimientos refcursor;
       --Las formas de pago del recibo, para insertarlos en importes recibos y recibocupon
       cursorpagos CURSOR FOR SELECT * FROM tempfacturaventacupon NATURAL JOIN valorescaja;

       cursorpagosformapago CURSOR FOR SELECT idformapagotipos,sum(monto) as importefpt
                            FROM tempfacturaventacupon
                            NATURAL JOIN valorescaja
                            GROUP BY idformapagotipos;
--registros
       unmovimiento RECORD;
       unpago RECORD;
       unpagofp RECORD;
       pagoctacte RECORD;
       rctactedeuda RECORD;
       unpagoctacte RECORD;
       regri RECORD;
       runadeuda RECORD;
       rrecibopago RECORD;
--variables
       nrorecibo bigint;
       vidpago bigint;
       vmovpago bigint;
       vmovpagonoafil bigint;
       idconceptodeuda integer;
       vimporteapagar double precision;
       vimputacionrecibo varchar;
       movimientoconcepto varchar;
       vorigen varchar;

BEGIN

SELECT INTO vimporteapagar sum(importeapagar) FROM temppagodeuda;

--Determino el origen de la deuda
SELECT INTO runadeuda cuentacorrientedeuda.*,temppagodeuda.importeapagar 
                    FROM temppagodeuda JOIN cuentacorrientedeuda USING(iddeuda,idcentrodeuda,nrodoc) LIMIT 1;
IF FOUND THEN 
	vorigen = 'afiliado';
        UPDATE temppagodeuda SET origendeuda = vorigen;
	SELECT INTO vimputacionrecibo text_concatenar(concat(movconcepto , '-'))
                                   FROM temppagodeuda
                                   JOIN cuentacorrientedeuda USING(iddeuda,idcentrodeuda);
ELSE 

SELECT INTO runadeuda * FROM temppagodeuda NATURAL JOIN ctactedeudanoafil LIMIT 1;
IF FOUND THEN 
	vorigen = 'noafiliado';
	UPDATE temppagodeuda SET origendeuda = vorigen;
	SELECT INTO vimputacionrecibo text_concatenar(concat(movconcepto , '-'))
                                   FROM temppagodeuda
                                   NATURAL JOIN ctactedeudanoafil;
END IF;

END IF;



--Se asienta la cabecera del recibo
     

     SELECT INTO nrorecibo * FROM getidrecibocaja();
     INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,importeenletras)
     VALUES (nrorecibo,vimporteapagar,now(),vimputacionrecibo,centro(),convertinumeroalenguajenatural(vimporteapagar::numeric));

/* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (nrorecibo,centro(),rusuario.idusuario) ;


     SELECT INTO rrecibo * FROM recibo WHERE idrecibo = nrorecibo AND centro = centro();

--inserto en importesrecibo tantas tupla como formas de pago existan, agrupadas x idformapagotipos

     OPEN cursorpagosformapago;
     FETCH cursorpagosformapago into unpagofp;
     WHILE  found LOOP
          INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
          VALUES (nrorecibo,unpagofp.idformapagotipos,unpagofp.importefpt,centro());
           -- Se asienta en pagos Dejo por defecto tipopago = 4, que es efectivo y creo que no se usa
           --Le coloco la nrocuentac de la deuda.
           INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,pfechaemision,idpagostipos,idbanco,idlocalidad,idprovincia,nrooperacion,nrocuentabanco,nrocuentac)
           VALUES(nextval('pagos_idpagos_seq'),centro(),nrorecibo,unpagofp.idformapagotipos,vimputacionrecibo,now(),now(),4,0,6,2,0,0,runadeuda.nrocuentac);
           vidpago =currval('pagos_idpagos_seq');

           IF vorigen = 'afiliado' THEN 
		INSERT INTO pagosafiliado(idpagos,nrodoc,tipodoc) 
                 VALUES(vidpago,runadeuda.nrodoc,runadeuda.tipodoc);
	   END IF;
	  
     FETCH cursorpagosformapago into unpagofp;
     END LOOP;
     close cursorpagosformapago;

-- Ingreso el pago en la cuenta corriente, el Idcomprobante = nrorecibo
    IF vorigen = 'noafiliado' THEN
      vmovpago= nextval('ctactepagocliente_idpago_seq');
    --Se tara de un pago de un informe de facturacion
      SELECT INTO movimientoconcepto * FROM asentarpagoctacteinstitucioninterno(vidpago);

      UPDATE pagos SET pconcepto = movimientoconcepto WHERE idpagos = vidpago AND centro = centro();
      UPDATE recibo SET imputacionrecibo = movimientoconcepto WHERE idrecibo = nrorecibo AND centro = centro();

      INSERT INTO ctactepagocliente(idpago,idcentropago,idcomprobantetipos,idclientectacte,
                      fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo)
      VALUES(vmovpago,centro(),0,runadeuda.idctacte,now()
             ,movimientoconcepto,runadeuda.nrocuentac,runadeuda.idconcepto,vimporteapagar*-1,nrorecibo,0);


    END IF;

    IF vorigen = 'afiliado' THEN 
        vmovpago = nextval('cuentacorrientepagos_idpago_seq');
	movimientoconcepto = concat('Recibo: ', nrorecibo, ' - ' ,centro(), ' ', vimputacionrecibo);
	INSERT INTO cuentacorrientepagos(idpago,idcentropago,idcomprobantetipos,tipodoc,idctacte
,fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo,nrodoc)
	VALUES(vmovpago,centro(),0,runadeuda.tipodoc,runadeuda.idctacte,now(),movimientoconcepto
     ,runadeuda.nrocuentac,runadeuda.idconcepto,vimporteapagar*-1,nrorecibo,0,runadeuda.nrodoc);

    END IF;
     

     -- Cancelo los movimientos en ctacte
    IF vorigen = 'afiliado' THEN 
     OPEN cursormovimientos FOR SELECT * FROM temppagodeuda JOIN cuentacorrientedeuda USING(iddeuda,idcentrodeuda);
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
            idconceptodeuda = unmovimiento.idconcepto;
           --Guardo en la nueva estructura de cuentas corrientes DEUDA PAGO Y UPDATEO LA DEUDA INSTITUCION 
               INSERT INTO cuentacorrientedeudapago (idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
               VALUES (vmovpago,centro(),unmovimiento.iddeuda,unmovimiento.idcentrodeuda,CURRENT_TIMESTAMP, unmovimiento.importeapagar);

               UPDATE cuentacorrientedeuda SET saldo =   round(CAST (unmovimiento.saldo-unmovimiento.importeapagar AS numeric), 2)
               WHERE cuentacorrientedeuda.iddeuda = unmovimiento.iddeuda AND cuentacorrientedeuda.idcentrodeuda = unmovimiento.idcentrodeuda;
           --Si se trata de un prestamo, asigno el idrecibo con que se pago la cuota - Si idcomprobantetipos = 7 se trata de una cuota de prestamo
            IF FOUND AND unmovimiento.idcomprobantetipos = 7 THEN
                  UPDATE prestamocuotas SET idrecibo = nrorecibo
                                           , idcentrorecibo = centro()
                  WHERE prestamocuotas.idprestamocuotas *10 + prestamocuotas.idcentroprestamocuota = unmovimiento.idcomprobante;
            END IF;

            INSERT INTO pagoscuentacorriente(idmovimiento,idcentrodeuda,idcentropago,idpagos)
            VALUES (unmovimiento.iddeuda,unmovimiento.idcentrodeuda,centro(),vidpago);
     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;

     UPDATE cuentacorrientepagos SET idconcepto = idconceptodeuda
            WHERE idpago= vmovpago AND idcentropago=centro();


    END IF; --vorigen = 'afiliado' 

    IF vorigen = 'noafiliado' THEN 
     OPEN cursormovimientos FOR SELECT * FROM temppagodeuda
                                   NATURAL JOIN ctactedeudanoafil;
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
            idconceptodeuda = unmovimiento.idconcepto;
           --Guardo en la nueva estructura de cuentas corrientes DEUDA PAGO Y UPDATEO LA DEUDA INSTITUCION 
               INSERT INTO ctactedeudapagocliente(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp,idusuario)
               VALUES (vmovpago,centro(),unmovimiento.iddeuda,unmovimiento.idcentrodeuda,CURRENT_TIMESTAMP, unmovimiento.importeapagar,rusuario.idusuario);

               UPDATE ctactedeudacliente SET saldo =round(CAST (unmovimiento.saldo-unmovimiento.importeapagar AS numeric), 2)
               WHERE ctactedeudanoafil.iddeuda = unmovimiento.iddeuda 
			AND ctactedeudanoafil.idcentrodeuda = unmovimiento.idcentrodeuda;
           
            INSERT INTO pagoscuentacorriente(idmovimiento,idcentrodeuda,idcentropago,idpagos)
            VALUES (unmovimiento.iddeuda,unmovimiento.idcentrodeuda,centro(),vidpago);
     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;

    END IF;

     
-- Ingreso los datos en recibocupon
   open cursorpagos;
   FETCH cursorpagos into rrecibopago;
      WHILE FOUND LOOP
            INSERT INTO recibocupon(idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon,idrecibo,centro)
            VALUES(rrecibopago.idvalorescaja, rrecibopago.autorizacion, rrecibopago.nrotarjeta,rrecibopago.monto,
             rrecibopago.cuotas, rrecibopago.nrocupon, nrorecibo, centro());


     FETCH cursorpagos into rrecibopago;
     END LOOP;
     close cursorpagos;


RETURN NEXT rrecibo;
END;
$function$
