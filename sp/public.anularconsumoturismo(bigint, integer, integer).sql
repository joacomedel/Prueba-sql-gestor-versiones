CREATE OR REPLACE FUNCTION public.anularconsumoturismo(bigint, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que anula el consumo en cuenta correinte de una persona */
DECLARE

       pidcentroconsumoturismo alias for $1;
       pidconsumoturismo alias for $2;
       pdevolveranticipo alias for $3;
       rconsumo RECORD;
       rinforme RECORD;
       rpago RECORD;
       rdeuda RECORD;
       elprestamo RECORD;
       cursorafil refcursor;
       cursorinforme refcursor;
       respuesta boolean;
BEGIN
-- Modificacion realizada por VS: cuando se anula una factura correspondiente a un informe de turismo se
-- Vuelve a generar un nuevo informe de facturacion
-- Por lo tanto hay que cancelar a los informes que se crearon para un determidando consumo
--10-06-2010 MaLaPi Modifico para que genere las NC correspondientes

SELECT INTO  rconsumo * FROM  consumoturismo
                              WHERE idconsumoturismo = pidconsumoturismo
                              AND idcentroconsumoturismo = pidcentroconsumoturismo;
IF FOUND THEN
       -- cambia de estado anulado
       UPDATE consumoturismoestado SET ctefechafin = current_timestamp
           WHERE idconsumoturismo = pidconsumoturismo
           AND idcentroconsumoturismo = pidcentroconsumoturismo
           AND nullvalue(ctefechafin);
       INSERT INTO consumoturismoestado(idconsumoturismo,idcentroconsumoturismo,idconsumoturismoestadotipos)
              VALUES(pidconsumoturismo,pidcentroconsumoturismo,3); -- El estado 3 es Anulado

       -- Verifico que el Informe se haya factura y nunca cancelado
       SELECT INTO rinforme *
            FROM informefacturacion
            NATURAL JOIN informefacturacionturismo
            NATURAL JOIN informefacturacionestado
            WHERE informefacturacionestado.idinformefacturacionestadotipo=4
                  AND idconsumoturismo = pidconsumoturismo
                  AND idcentroconsumoturismo = pidcentroconsumoturismo
                  and (nroinforme , idcentroinformefacturacion ) NOT IN (
                                  SELECT nroinforme , idcentroinformefacturacion
                                  FROM informefacturacion NATURAL JOIN informefacturacionestado
                                  WHERE informefacturacionestado.idinformefacturacionestadotipo=5
            );
            IF FOUND THEN -- Hay que generar NC para anular la operacion
            SELECT INTO elprestamo * FROM prestamo
                                     NATURAL JOIN consumoturismo
                                     NATURAL JOIN persona
                                     WHERE idconsumoturismo = pidconsumoturismo
                                     AND idcentroconsumoturismo = pidcentroconsumoturismo;
                -- Se van a generar tantos informes segun se necesite dependiendo de si se pago algo, si se devuelve el anticipo o se debe todo
                 -- parametros : $1 idconsumoturismo.$2 idcentroconsumoturismo,  $3 nrodoc, $4 barra,  $5 numero cuenta contable, $6 importeTotal, $7 tipofactura, $8 sidevuelveanticipo,$9 FormaPago: Al anular no importa pues luego se verifica en el sp de generar informa y se cambia segun corresponde
                SELECT INTO respuesta * FROM  generarinformeturismo (pidconsumoturismo, pidcentroconsumoturismo::integer, elprestamo.nrodoc::varchar,elprestamo.barra::integer, 'No se usa'::varchar,elprestamo.importeprestamo::real,'NC'::varchar,pdevolveranticipo,0);

            ELSE -- Solo cancelo todos los informes que esten pendientes en facturacion para ese consumo
                     OPEN cursorinforme FOR SELECT  * from informefacturacionturismo
                                            NATURAL JOIN informefacturacionestado
                                            NATURAL JOIN informefacturacionestadotipo
                                            WHERE idconsumoturismo = pidconsumoturismo
                                            AND idcentroconsumoturismo = pidcentroconsumoturismo
                                            AND nullvalue(fechafin) AND idinformefacturacionestadotipo <> 5;

                                            FETCH cursorinforme INTO rinforme;
                                            WHILE  found LOOP
                                            --Falta verificar que la Orden de pago este Anulada
                                            -- Si todo va bien entonces, puedo anular el Consumo
                                            -- 1° Cancelamos la Factura
                                               UPDATE informefacturacionestado SET fechafin = CURRENT_timestamp
                                               WHERE nroinforme = rinforme.nroinforme
                                               AND idcentroinformefacturacion = rinforme.idcentroinformefacturacion
                                               AND nullvalue(fechafin);
                                               INSERT INTO informefacturacionestado(nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini,descripcion)
                                               VALUES (rinforme.nroinforme,rinforme.idcentroinformefacturacion,5,current_timestamp,'Anulacion de Consumo de Turismo');
                                            FETCH cursorinforme INTO rinforme;
                                            END LOOP;
                                            close cursorinforme;


            END IF; -- Cancele el Informe o Genere las NC segun Correspondia


           -- 2° Busco la informacion de la deuda en la cuenta corriente
            OPEN cursorafil FOR SELECT * FROM prestamo
                               NATURAL JOIN prestamocuotas JOIN cuentacorrientedeuda
                                ON cuentacorrientedeuda.idcomprobante = prestamocuotas.idprestamocuotas * 10 + prestamocuotas.idcentroprestamocuota
                                AND cuentacorrientedeuda.idcomprobantetipos = prestamocuotas.idcomprobantetipos
                                WHERE idprestamo = rconsumo.idprestamo AND idcentroprestamo = rconsumo.idcentroprestamo;


            FETCH cursorafil into rdeuda;
            WHILE  found LOOP

                       SELECT INTO rpago * FROM cuentacorrientedeudapago WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;
                       IF NOT FOUND THEN
                           -- SI no se pago aun, simplemente registo el pago de la misma por anulacion
                            UPDATE cuentacorrientedeuda SET saldo = 0  WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;
                            INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,idcentropago)
                            VALUES(rdeuda.idcomprobantetipos,rdeuda.tipodoc,rdeuda.idctacte,CURRENT_TIMESTAMP,concat('Anulacion de Consumo de Turismo' , rdeuda.movconcepto),rdeuda.nrocuentac,rdeuda.importe,rdeuda.idcomprobante,0,rdeuda.idconcepto,rdeuda.nrodoc,centro());
                            INSERT INTO cuentacorrientedeudapago (idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp)
                            VALUES(currval('cuentacorrientepagos_idpago_seq'),rdeuda.iddeuda,CURRENT_TIMESTAMP,rdeuda.idcentrodeuda,centro(),rdeuda.saldo);

                         ELSE -- Si ya se registro el pago hay que registrar una nota de credito solo si se trata de un anticipo y se va a devolver
                              -- Agrega VIVI 15/07/2011 en caso que  se hay devuelto la plata en efectivo no se debe generar la NC en cuenta corriente
                              --Sse devuelve el anticipo en efectivo
                               IF rdeuda.movconcepto ilike '%Anticipo%' AND pdevolveranticipo <> 1 THEN
                                  INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,idcentropago)
                                   VALUES(rdeuda.idcomprobantetipos,rdeuda.tipodoc,rdeuda.idctacte,CURRENT_TIMESTAMP,concat('Nota de Credito p/Anulacion de Turismo', rdeuda.movconcepto),rdeuda.nrocuentac,((-1)*rdeuda.importe),rdeuda.idcomprobante,((-1)*rdeuda.importe),rdeuda.idconcepto,rdeuda.nrodoc,centro());
                               END IF;
                        END IF;
            fetch cursorafil into rdeuda;
            END LOOP;
            close cursorafil;
end if;
return 'TRUE';
END;
$function$
