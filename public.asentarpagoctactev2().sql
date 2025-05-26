CREATE OR REPLACE FUNCTION public.asentarpagoctactev2()
 RETURNS SETOF recibo
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta los pagos que se realizan por caja
de los pagos de la cuenta corriente. */
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
       unmovimiento  RECORD;
respuesta  RECORD;
       unpago RECORD;
       unpagofp RECORD;
       pagoctacte RECORD;
       rctactedeuda RECORD;
       unpagoctacte RECORD;
       regri RECORD;
       runadeuda RECORD;
       rdeuda RECORD;	
       rrecibopago RECORD;
       rdatoscliente RECORD;
       rorigenctacte RECORD;
       rctactedeudacliente RECORD;
       rvalorescajacomercio RECORD;
       rescliente RECORD;	
--variables
       nrorecibo bigint;
       vidpago bigint;
       vidpagocliente bigint;
       vmovpago bigint;
       vmovpagocliente bigint;
       idconceptodeuda integer;
       vimporteapagar double precision;
       vimputacionrecibo varchar;
       movimientoconcepto varchar;
       vorigen varchar;
       vtipodoc INTEGER;
       vtotaldeuda DOUBLE PRECISION DEFAULT 0.0;

BEGIN

SELECT INTO vimporteapagar sum(importeapagar) FROM temppagodeuda;
SELECT INTO rdeuda * FROM temppagodeuda LIMIT 1;
--MaLaPi 19/03/2021 Si el proceso se llama desde Java en barra se pone la barra del afiliado, con lo que verifica_origen_ctacte() falla al buscar el origen, pues necesita el tipoddoc

SELECT INTO rescliente * FROM cliente WHERE nrocliente = rdeuda.nrodoc AND cliente.barra < 99 AND rdeuda.tipodoc > 29;
IF FOUND THEN 
vtipodoc = rescliente.barra;

ELSE
vtipodoc = rdeuda.tipodoc;

END IF;


	--MaLaPi 12-12-2017 Verifico en que tabla deberian estar las deudas y pagos. 
	CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
	INSERT INTO tempcliente(nrocliente,barra) VALUES(rdeuda.nrodoc,vtipodoc);
	SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5) as clavecentropersonactacte 
		FROM (
		SELECT verifica_origen_ctacte() as origen 
		) as t;
DROP TABLE tempcliente;

-- KR 18-03-21 si el iddeuda esta en tablas de cliente y afiliados da error, primero se debe determinar el origen
-- MaLaPi 19/03/2021 No funciona esto si la deuda se selecciona de la tabla de deuda de afiliado, y ya el afiliado es cliente

--Determino el origen de la deuda
SELECT INTO runadeuda cuentacorrientedeuda.*,temppagodeuda.importeapagar 
                    FROM temppagodeuda JOIN cuentacorrientedeuda USING(iddeuda,idcentrodeuda,nrodoc) 
                    WHERE saldo > 1 
                    LIMIT 1;
IF FOUND THEN 
	vorigen = 'afiliado';
        UPDATE temppagodeuda SET origendeuda = vorigen;
	SELECT INTO vimputacionrecibo text_concatenar(concat(movconcepto , '-'))
                                   FROM temppagodeuda
                                   JOIN cuentacorrientedeuda USING(iddeuda,idcentrodeuda);
ELSE 
	

        IF rorigenctacte.origentabla = 'clientectacte' THEN 
		SELECT INTO runadeuda * FROM temppagodeuda NATURAL JOIN ctactedeudacliente LIMIT 1;
		vorigen = 'noafiliado';
		UPDATE temppagodeuda SET origendeuda = vorigen;
		SELECT INTO vimputacionrecibo text_concatenar(concat(movconcepto , '-'))
                                   FROM temppagodeuda
                                   NATURAL JOIN ctactedeudacliente;

	END IF;
	IF rorigenctacte.origentabla = 'prestadorctacte' THEN 
		SELECT INTO runadeuda * FROM temppagodeuda NATURAL JOIN ctactedeudaprestador LIMIT 1;
		vorigen = 'noafiliado';
		UPDATE temppagodeuda SET origendeuda = vorigen;
		SELECT INTO vimputacionrecibo text_concatenar(concat(movconcepto , '-'))
                                   FROM temppagodeuda
                                   NATURAL JOIN ctactedeudaprestador;
	END IF;
	IF rorigenctacte.origentabla = 'nolose' THEN 
		SELECT INTO runadeuda * FROM temppagodeuda NATURAL JOIN ctactedeudanoafil LIMIT 1;
		vorigen = 'noafiliado';
		UPDATE temppagodeuda SET origendeuda = vorigen;
		SELECT INTO vimputacionrecibo text_concatenar(concat(movconcepto , '-'))
                                   FROM temppagodeuda
                                   NATURAL JOIN ctactedeudanoafil;
        END IF;
        IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
--Dani/ Belen modificaron el 14102024 porq no encontraba la deuda en esa estructura en los afiliados reci
	
		SELECT INTO runadeuda * FROM temppagodeuda JOIN cuentacorrientedeuda  USING(iddeuda,idcentrodeuda,nrodoc)  LIMIT 1;

               --NATURAL JOIN cuentacorrientedeuda LIMIT 1;

		vorigen = 'afiliado';
		UPDATE temppagodeuda SET origendeuda = vorigen;

--Dani/ Belen modificaron el 14102024 porq no encontraba la deuda en esa estructura en los afiliados reci
		SELECT INTO vimputacionrecibo text_concatenar(concat(movconcepto , '-'))
                                   FROM temppagodeuda
                                   JOIN cuentacorrientedeuda  USING(iddeuda,idcentrodeuda,nrodoc);
                                   --NATURAL JOIN cuentacorrientedeuda;
        END IF;

END IF;
--Se asienta la cabecera del recibo

/* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF NOT FOUND THEN 
	rusuario.idusuario = 25;
    END IF;

     SELECT INTO nrorecibo * FROM getidrecibocaja();
     INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,importeenletras)
     VALUES (nrorecibo,vimporteapagar,now(),vimputacionrecibo,centro(),convertinumeroalenguajenatural(vimporteapagar::numeric));

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
      vmovpago= nextval('ctactepagonoafil_idpago_seq');
    --Se tara de un pago de un informe de facturacion
      SELECT INTO movimientoconcepto * FROM asentarpagoctacteinstitucioninterno(vidpago);

      UPDATE pagos SET pconcepto = movimientoconcepto WHERE idpagos = vidpago AND centro = centro();

      UPDATE recibo SET imputacionrecibo = movimientoconcepto WHERE idrecibo = nrorecibo AND centro = centro();

	IF rorigenctacte.origentabla = 'clientectacte' THEN 
	  -- MaLaPi 13-12-2017 Ademas de marcar el pago en ctactepagonoafil, hay que acentarlo en la ctacte de cliente
		INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo) 
		VALUES(0,rorigenctacte.clavepersonactacte,rorigenctacte.clavecentropersonactacte::integer,now(),concat(movimientoconcepto,' ',vimputacionrecibo,'- ccnoafil idpago ',vmovpago::text,'-',centro()),runadeuda.nrocuentac,vimporteapagar*-1, nrorecibo, 0);
		vidpagocliente = currval('ctactepagocliente_idpago_seq'::regclass);
           ELSE
		INSERT INTO ctactepagonoafil(idpago,idcentropago,idcomprobantetipos,tipodoc,idctacte
		,fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo,nrodoc)
		VALUES(vmovpago,centro(),0,runadeuda.tipodoc,runadeuda.idctacte,now()
		,concat(movimientoconcepto,' ',vimputacionrecibo),runadeuda.nrocuentac,runadeuda.idconcepto,vimporteapagar*-1,nrorecibo,0,runadeuda.nrodoc);
		
	END IF;
      
	
     END IF;

    IF vorigen = 'afiliado' THEN 
        vmovpago = nextval('cuentacorrientepagos_idpago_seq');
	movimientoconcepto = vimputacionrecibo;
	INSERT INTO cuentacorrientepagos(idpago,idcentropago,idcomprobantetipos,tipodoc,idctacte
,fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo,nrodoc)
	VALUES(vmovpago,centro(),0,runadeuda.tipodoc,runadeuda.idctacte,now(),movimientoconcepto
     ,runadeuda.nrocuentac,runadeuda.idconcepto,round((vimporteapagar*-1)::numeric,2),nrorecibo,0,runadeuda.nrodoc);

    END IF;
     

     -- Cancelo los movimientos en ctacte
    IF vorigen = 'afiliado' THEN 
--KR 18-03-21 Verifico si la deuda tiene saldo 
     OPEN cursormovimientos FOR SELECT * FROM temppagodeuda JOIN cuentacorrientedeuda USING(iddeuda,idcentrodeuda) WHERE saldo >0;
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
            idconceptodeuda = unmovimiento.idconcepto;
            vtotaldeuda = vtotaldeuda+unmovimiento.saldo;
           --Guardo en la nueva estructura de cuentas corrientes DEUDA PAGO Y UPDATEO LA DEUDA INSTITUCION 
               INSERT INTO cuentacorrientedeudapago (idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
               VALUES (vmovpago,centro(),unmovimiento.iddeuda,unmovimiento.idcentrodeuda,CURRENT_TIMESTAMP, 
/*KR 27-02-23 si el pago es mayor al saldo pongo el saldo sino el importeapagar*/
                                round(CASE WHEN unmovimiento.importeapagar>unmovimiento.saldo THEN unmovimiento.saldo ELSE unmovimiento.importeapagar END::numeric,2));
--KR 27-02-23 El saldo de la deuda no puede ser superior al saldo mismo sino queda en negativo
               UPDATE cuentacorrientedeuda SET saldo =  CASE WHEN unmovimiento.importeapagar>=cuentacorrientedeuda.saldo THEN 0 ELSE round(CAST (cuentacorrientedeuda.saldo-unmovimiento.importeapagar AS numeric), 2) end
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
     --KR 27-02-23 SI el importe del pago es mayor a la deuda lo dejo a favor
     IF (vimporteapagar>vtotaldeuda) THEN 
         UPDATE cuentacorrientepagos SET saldo = round(CAST(vimporteapagar-vtotaldeuda AS numeric), 2)*-1 WHERE idpago= vmovpago AND idcentropago=centro();

     END IF;

    END IF; --vorigen = 'afiliado' 

    IF vorigen = 'noafiliado' THEN 
     IF rorigenctacte.origentabla = 'clientectacte' THEN 

--KR 18-03-21 Verifico si la deuda tiene saldo 
	     OPEN cursormovimientos FOR SELECT * FROM temppagodeuda JOIN ctactedeudacliente USING(iddeuda,idcentrodeuda) WHERE saldo >0;
	     FETCH cursormovimientos into unmovimiento;
      
	     WHILE  found LOOP
                   vtotaldeuda = vtotaldeuda+unmovimiento.saldo;
		    --idconceptodeuda = unmovimiento.idconcepto;
		 --MaLaPi 13-12-2017 Hay que cancelar la deuda en ctactecliente.
		   INSERT INTO ctactedeudapagocliente(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idusuario,idimputacion)
		   VALUES (vidpagocliente,unmovimiento.iddeuda,unmovimiento.idcentrodeuda,centro(),
/*KR 09-05-20 si el pago es mayor al saldo pongo el saldo sino el importeapagar*/
                                round(CASE WHEN unmovimiento.importeapagar>unmovimiento.saldo THEN unmovimiento.saldo ELSE unmovimiento.importeapagar END::numeric,2)
                                       ,rusuario.idusuario,1);
		   
		   UPDATE ctactedeudacliente SET movconcepto=concat(movconcepto,' ccnoafil iddeuda ',unmovimiento.iddeuda,'-',unmovimiento.idcentrodeuda),saldo =
CASE WHEN unmovimiento.importeapagar>=ctactedeudacliente.saldo THEN 0 ELSE round(CAST (ctactedeudacliente.saldo-unmovimiento.importeapagar AS numeric), 2) end
/*round(CAST (unmovimiento.saldo-unmovimiento.importeapagar AS numeric), 2)*/
		       WHERE ctactedeudacliente.iddeuda = unmovimiento.iddeuda 
			     AND ctactedeudacliente.idcentrodeuda = unmovimiento.idcentrodeuda;
		   
                  --- VAS 060624
                  IF (unmovimiento.movconcepto ILIKE '%aporte%') THEN
                       INSERT INTO ctacteadherenteestado (iddeuda,idcentrodeuda,ccaedescripcion) VALUES(unmovimiento.iddeuda,unmovimiento.idcentrodeuda, 'VOY a llamar al sp modificarestadoaporte ');
                       SELECT INTO respuesta modificarestadoaporte(CONCAT('{iddeuda=',unmovimiento.iddeuda::varchar,',idcentrodeuda=',unmovimiento.idcentrodeuda::varchar, '}')) FROM temppagodeuda; 

                  END IF;
                  --- VAS 060624
	     FETCH cursormovimientos into unmovimiento;
	     END LOOP;
	     close cursormovimientos;
             --KR 09-05-20 SI el importe del pago es mayo a la deuda lo dejo a favor
             IF (vimporteapagar>vtotaldeuda) THEN 
                UPDATE ctactepagocliente SET saldo = round(CAST(vimporteapagar-vtotaldeuda AS numeric), 2)*-1 WHERE idpago=vidpagocliente AND idcentropago=centro();

             END IF;
	
     ELSE --No es un cliente, asumo que la deuda esta en noafil
	     OPEN cursormovimientos FOR SELECT * FROM temppagodeuda
					   NATURAL JOIN ctactedeudanoafil;
	     FETCH cursormovimientos into unmovimiento;
	     WHILE  found LOOP
		    idconceptodeuda = unmovimiento.idconcepto;
                    vtotaldeuda = vtotaldeuda+unmovimiento.saldo;
		   --Guardo en la nueva estructura de cuentas corrientes DEUDA PAGO Y UPDATEO LA DEUDA INSTITUCION 
		       INSERT INTO ctactedeudapagonoafil(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
		       VALUES (vmovpago,centro(),unmovimiento.iddeuda,unmovimiento.idcentrodeuda,CURRENT_TIMESTAMP, 
/*KR 09-05-20 si el pago es mayor al saldo pongo el saldo sino el importeapagar*/
                                CASE WHEN unmovimiento.importeapagar>unmovimiento.saldo THEN unmovimiento.saldo ELSE unmovimiento.importeapagar END

                         );

		       UPDATE ctactedeudanoafil SET saldo =round(CAST (unmovimiento.saldo-unmovimiento.importeapagar AS numeric), 2)
		       WHERE ctactedeudanoafil.iddeuda = unmovimiento.iddeuda 
				AND ctactedeudanoafil.idcentrodeuda = unmovimiento.idcentrodeuda;
		   
		    INSERT INTO pagoscuentacorriente(idmovimiento,idcentrodeuda,idcentropago,idpagos)
		    VALUES (unmovimiento.iddeuda,unmovimiento.idcentrodeuda,centro(),vidpago);

	     FETCH cursormovimientos into unmovimiento;
	     END LOOP;
	     close cursormovimientos;
               --KR 09-05-20 SI el importe del pago es mayo a la deuda lo dejo a favor
             IF (vimporteapagar>vtotaldeuda) THEN 
                UPDATE ctactepagocliente SET saldo = round(CAST(vimporteapagar-vtotaldeuda AS numeric), 2) WHERE vmovpago AND idcentropago=centro();

             END IF;
     END IF; 	
     

    END IF;

     
-- Ingreso los datos en recibocupon
   open cursorpagos;
   FETCH cursorpagos into rrecibopago;
      WHILE FOUND LOOP
            INSERT INTO recibocupon(idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon,idrecibo,centro)
            VALUES(rrecibopago.idvalorescaja, rrecibopago.autorizacion, rrecibopago.nrotarjeta,rrecibopago.monto,
             rrecibopago.cuotas, rrecibopago.nrocupon, nrorecibo, centro());
             SELECT INTO rvalorescajacomercio * FROM valorescajacomercio 
                     WHERE valorescajacomercio.idvalorescaja = rrecibopago.idvalorescaja 
                       AND valorescajacomercio.idvalorescaja = 959 
                       LIMIT 1;
             IF FOUND THEN 
                    INSERT INTO recibocuponlote (idrecibocupon,idcentrorecibocupon,idposnet,nrocomercio,nrolote)
                    VALUES(CURRVAL('recibocupon_idrecibocupon_seq'::regclass),centro(),rvalorescajacomercio.idposnet,rvalorescajacomercio.nrocomercio,CURRVAL('recibocupon_idrecibocupon_seq'::regclass));
             END IF;

     FETCH cursorpagos into rrecibopago;
     END LOOP;
     close cursorpagos;

--CS 2018-12-26 
-- Esto estaba mas arriba, lo pongo acá porque hay un trigger que registra en asientogenerico
    INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (nrorecibo,centro(),rusuario.idusuario);
----------------------------------------------------------------------------------------------

--KR 05-05-20 invoco al SP que cambia el estado de un aporte, por ahora si el aporte es de jubilados
 -- PERFORM modificarestadoaporte(CONCAT('{iddeuda=',unmovimiento.iddeuda::varchar,',idcentrodeuda=',unmovimiento.idcentrodeuda::varchar, '}')) ;
/* MOD VAS 280623
INSERT INTO ctacteadherenteestado (iddeuda,idcentrodeuda,ccaedescripcion) 
SELECT iddeuda,idcentrodeuda, 'VOY a llamar al sp modificarestadoaporte ' FROM temppagodeuda;


SELECT INTO respuesta modificarestadoaporte(CONCAT('{iddeuda=',iddeuda::varchar,',idcentrodeuda=',idcentrodeuda::varchar, '}')) FROM temppagodeuda; 
*/

----VAS 280623  GRRRRRRRR
/* 060624 ESTO SOLO SE DEBE REALIZAR SI LA DEUDA ES DE UN APORTE
INSERT INTO ctacteadherenteestado (iddeuda,idcentrodeuda,ccaedescripcion) VALUES(rdeuda.iddeuda,rdeuda.idcentrodeuda, 'VOY a llamar al sp modificarestadoaporte ');
SELECT INTO respuesta modificarestadoaporte(CONCAT('{iddeuda=',rdeuda.iddeuda::varchar,',idcentrodeuda=',rdeuda.idcentrodeuda::varchar, '}')) FROM temppagodeuda; 

*/
---- VAS 280623

RETURN NEXT rrecibo;
END;

$function$
