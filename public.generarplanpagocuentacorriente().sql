CREATE OR REPLACE FUNCTION public.generarplanpagocuentacorriente()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$/*
 * Datos entrada: TABLA  temppagoprestamo (
 *				  tipodoc
 *				  idbanco
 *				  fechaingreso
 *				  nrooperacion
 *				  nrodoc
 *				  concepto
 *				  idsolicitudfinanciacion
 *				  idcentrosolicitudfinanciacion
 *				  importetotal
 *				  idlocalidad
 *				  idprovincia
 *				  formapagotipos
 *				  idusuario
 *       pagocuentacorriente ( Cada una de las deudas seleccionadas para generar el plan de pago
 *				  idmovimiento         -   iddeuda
                  idcentrodeuda         -  con el campo anterior se identifica la deuda
 *				  idcomprobantetipos  -
 *				  tipodoc              -
 *				  nrodoc          -
 *				  fechamovimiento        -
 *				  movconcepto          -
 *				  nrocuentac           -
 *				  importe              -  Suma de lo importe de las deudas seleccionadas
 *				  signo                -  poner en cuenta corriente pagos
 *				  idcomprobante 
 *				  idmovcancela 
 *                En el primer registro de la tabla temporal se encuentra informacion propia del pago,
 *                los registros siguiente son cada una de las deudas seleccionadas para generar un nuevo prestamo
 * Llamar al Sp generarprestamocuotas que recibe como Parametro  el id del tipo de prestamo en este caso: 3 Plan pago cuenta corriente
 * Guardar la informacion propia del prestamo para el plan de pago de cuenta corriente
 * Registrar el Pago de la deuda.
 * Se asienta en pagos: se genera el pago en la tabla cuenta cuentacorrientepagos,
 * el pago hace referencia al prestamo que fue generado para pagar la deuda
 * Actualizar cada una de las deudas con saldo 0 para quede reflejada la concelacion de la misma
 * Insertar cada uno de los pagos en cuentacorrientedeudapago
 *
 */
DECLARE
        elpagocuentacorriente record;
        confprestamo  record;
        cursorpagoctacte refcursor; --CURSOR FOR SELECT * FROM pagocuentacorriente WHERE idmovimiento is not null;
        cursorpagos refcursor;
      	rpagoctacte record;	
        codprestamo integer;
        indice integer;
        codpago integer;
        nrodocumento varchar;
        centroctacte integer;
        nroctacte integer;
        rctactedeuda record;
	respuesta boolean;
BEGIN

--respuesta = false;

            SELECT INTO codprestamo * FROM generarprestamocuotas(3);
      --     codprestamo = 4895;
            IF codprestamo <> 0 THEN -- El prestamo fue creado
                        SELECT * INTO confprestamo  FROM tempconfiguracionprestamo;
                        nrodocumento = confprestamo.nrodoc;
                        /* Ver !!!!!!!  idctacte nrodoc */
                        /* Ingreso el pago*/
                        --Malapi 28-03-2017 Genero un pago, por cada idconcepto
                        OPEN cursorpagos FOR SELECT text_concatenarsinrepetir(ccd.movconcepto) as movconcepto ,sum(ccd.saldo) as importe,min(ccd.nrocuentac::integer) as nrocuentac,ccd.idconcepto,ccd.idctacte,ccd.tipodoc,ccd.nrodoc 
				FROM pagocuentacorriente pcc
				JOIN cuentacorrientedeuda ccd ON pcc.idmovimiento = ccd.iddeuda AND ccd.idcentrodeuda = pcc.centro
				WHERE idmovimiento is not null
				GROUP BY ccd.idctacte,ccd.tipodoc,ccd.nrodoc,ccd.idconcepto;

			FETCH cursorpagos INTO elpagocuentacorriente;
			WHILE  found LOOP
				--INSERT INTO cuentacorrientepagos(idcentropago,idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
				--VALUES(centro(),17,elpagocuentacorriente.tipodoc,elpagocuentacorriente.nrodoc,current_date,elpagocuentacorriente.movconcepto,elpagocuentacorriente.nrocuentac,abs(elpagocuentacorriente.importe)*-1,codprestamo,0,'387',nrodocumento);
                       
				INSERT INTO cuentacorrientepagos(idcentropago,idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
				VALUES(centro(),17,elpagocuentacorriente.tipodoc,elpagocuentacorriente.idctacte,current_date,elpagocuentacorriente.movconcepto,elpagocuentacorriente.nrocuentac,abs(elpagocuentacorriente.importe)*-1,codprestamo,0,elpagocuentacorriente.idconcepto,elpagocuentacorriente.nrodoc);
				codpago = currval('cuentacorrientepagos_idpago_seq');
                       	
                        OPEN cursorpagoctacte FOR SELECT pcc.* 
						  FROM pagocuentacorriente as pcc
						  JOIN cuentacorrientedeuda ccd ON pcc.idmovimiento = ccd.iddeuda AND ccd.idcentrodeuda = pcc.centro
						  WHERE idmovimiento is not null 
						  AND ccd.idconcepto = elpagocuentacorriente.idconcepto
						  AND ccd.idctacte =elpagocuentacorriente.idctacte
						  AND ccd.tipodoc = elpagocuentacorriente.tipodoc
						  AND ccd.nrodoc = elpagocuentacorriente.nrodoc;

                        FETCH cursorpagoctacte INTO rpagoctacte;
                        WHILE  found LOOP
                              centroctacte = rpagoctacte.centro;
                              nroctacte = rpagoctacte.idmovimiento;
                               -- GUARDAR LA INFORMACION  propia del prestamo plan de pago cuenta corriente
                               -- Lo que se pago y con que se pago. Queda registro del pago de las deudas seleccionadas. La raiz del prestamo
                              INSERT INTO prestamoplandepago( idprestamo,idcentroprestamo,iddeuda,idcentrodeuda,idpago,idcentropago
                              )VALUES (codprestamo,centro(),nroctacte,centroctacte,codpago,centro());
                              
                              -- Se vincula la deuda con el pago
                              SELECT INTO rctactedeuda * FROM cuentacorrientedeuda WHERE iddeuda = nroctacte and idcentrodeuda = centroctacte;
                              INSERT INTO cuentacorrientedeudapago (idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)VALUES (codpago,centro(),nroctacte,centroctacte,NOW(),abs(rctactedeuda.saldo));

-- Actualizo el saldo de la deuda
                              UPDATE cuentacorrientedeuda  SET saldo = 0  WHERE cuentacorrientedeuda.iddeuda = nroctacte and cuentacorrientedeuda.idcentrodeuda = centroctacte;
                              FETCH cursorpagoctacte INTO rpagoctacte;
                       END LOOP;
                       CLOSE cursorpagoctacte;
                FETCH cursorpagos INTO elpagocuentacorriente;
		END LOOP;
                CLOSE cursorpagos;

		CREATE TEMP TABLE reciboautomaticoctacte (
			iddeuda bigint,
			idcentrodeuda integer,
			idvalorescaja integer,
			idprestamo bigint,
			idcentroprestamo integer,
			idrecibo bigint,
			idcentrorecibo integer,
			importeimp double precision,
                        idpago bigint,
			idcentropago integer,
			fechaemision timestamp 
			);
		INSERT INTO reciboautomaticoctacte(idpago,idcentropago,iddeuda,idcentrodeuda,idvalorescaja,idprestamo,idcentroprestamo,importeimp,fechaemision) (
			select idpago,idcentropago,iddeuda,idcentrodeuda,97 as idvalorescaja,idprestamo,idcentroprestamo,importeimp,fechamovimiento
			from cuentacorrientepagos 
			JOIN cuentacorrientedeudapago USING(idpago,idcentropago)
			natural join prestamoplandepago 
			where idcomprobantetipos = 17
			and idpago = codpago 
			AND idcentropago = centro()
			ORDER BY idprestamo,idcentroprestamo
		);

		select INTO respuesta * FROM generarreciboautomaticodesdectactedeuda();
            END IF;

--MaLapi 19-12-2019 dejo el codigo del prestamo en la tabla por si es necesario para otra cosa
UPDATE tempconfiguracionprestamo SET idprestamo = codprestamo, idcentroprestamo= centro();
RETURN codprestamo;
END;
$function$
