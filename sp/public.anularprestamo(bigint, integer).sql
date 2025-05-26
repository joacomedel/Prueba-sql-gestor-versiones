CREATE OR REPLACE FUNCTION public.anularprestamo(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que anula el consumo en cuenta correinte de una persona */
DECLARE

       
       pidprestamo alias for $1;
       pidcentroprestamo alias for $2;
       rconsumo RECORD;
       rinforme RECORD;
       rpago RECORD;
       rdeuda RECORD;
       elprestamo RECORD;
       cursorafil refcursor;
       cursorinforme refcursor;
       respuesta boolean;
       resp boolean;
       informeF bigint;
BEGIN

SELECT INTO  rconsumo * FROM  prestamo
                              WHERE idprestamo = pidprestamo
                              AND idcentroprestamo = pidcentroprestamo;
IF FOUND THEN

          UPDATE prestamoestado SET pefechafin = current_timestamp
          WHERE idprestamo = pidprestamo
                AND idcentroprestamo = pidcentroprestamo
                AND nullvalue(pefechafin);
          INSERT INTO prestamoestado(idprestamo,idcentroprestamo,idprestamoestadotipos)
          VALUES(pidprestamo,pidcentroprestamo,3); -- El estado 3 es Anulado
          
          -- Anulo el movimiento de fondo en caso de que exita
          SELECT INTO resp * FROM movimientofondoanular('prestamo', concat(pidprestamo,'|',pidcentroprestamo));

-- Verifico que el Informe se haya factura y nunca cancelado
 /*           SELECT INTO rinforme *
            FROM informefacturacion
            NATURAL JOIN informefacturacionsolicitudfinanciacion
            NATURAL JOIN prestamosolicitudfinanciacion
            NATURAL JOIN informefacturacionestado
            WHERE informefacturacionestado.idinformefacturacionestadotipo=4
            AND idprestamo = pidprestamo
            AND idcentroprestamo = pidcentroprestamo
            and (nroinforme , idcentroinformefacturacion ) NOT IN (
            SELECT nroinforme , idcentroinformefacturacion
            FROM informefacturacion NATURAL JOIN informefacturacionestado
            WHERE informefacturacionestado.idinformefacturacionestadotipo=5
            );
*/


-- BelenA 06/02/25 comento la consulta y cambio para que si el prestamo es nulo en  solicitudfinanciacion, que se fije si esta en prestamosolicitudfinanciacion y viceversa
                                            SELECT INTO rinforme 
                                            from informefacturacion
                                            NATURAL JOIN informefacturacionsolicitudfinanciacion
                                            NATURAL JOIN solicitudfinanciacion  
                                            LEFT JOIN prestamosolicitudfinanciacion USING (idsolicitudfinanciacion, 	idcentrosolicitudfinanciacion)
                                            NATURAL JOIN informefacturacionestado
                                            NATURAL JOIN informefacturacionestadotipo
                                            WHERE informefacturacionestado.idinformefacturacionestadotipo=4

                                            AND CASE WHEN nullvalue(solicitudfinanciacion.idprestamo) THEN prestamosolicitudfinanciacion.idprestamo=pidprestamo ELSE solicitudfinanciacion.idprestamo=pidprestamo END

                                            AND CASE WHEN nullvalue(solicitudfinanciacion.idcentroprestamo) THEN prestamosolicitudfinanciacion.idcentroprestamo=pidcentroprestamo ELSE solicitudfinanciacion.idcentroprestamo=pidcentroprestamo END
                                            and (nroinforme , idcentroinformefacturacion ) NOT IN (
                                            SELECT nroinforme , idcentroinformefacturacion
                                            FROM informefacturacion NATURAL JOIN informefacturacionestado
                                            WHERE informefacturacionestado.idinformefacturacionestadotipo=5
                                            );


            IF FOUND THEN -- Hay que generar NC para anular la operacion
            SELECT INTO elprestamo * FROM prestamo
                                     NATURAL JOIN prestamosolicitudfinanciacion
                                     NATURAL JOIN persona
                                     WHERE idprestamo = pidprestamo
                                     AND idcentroprestamo = pidcentroprestamo;

             SELECT INTO informeF * FROM crearinformefacturacion(elprestamo.nrodoc,elprestamo.barra, 4 );
             INSERT INTO  informefacturacionsolicitudfinanciacion(nroinforme,idcentroinformefacturacion,idsolicitudfinanciacion,idcentrosolicitudfinanciacion )
             VALUES(informeF,Centro(),elprestamo.idsolicitudfinanciacion,elprestamo.idcentrosolicitudfinanciacion);
             UPDATE informefacturacion SET tipofactura = 'NC'
                    WHERE nroinforme = informeF AND idcentroinformefacturacion = centro();
                       -- Creo los item del informe de facturacion
             CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);
             INSERT INTO ttinformefacturacionitem (	nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
             VALUES (informeF,nrocuentacontablecuota,1,elprestamo.importeprestamo,' Valor de prestamo');
             INSERT INTO ttinformefacturacionitem (	nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
             VALUES (informeF,nrocuentacontableintereses,1,elpagoprestamo.intereses,' Intereses');

             SELECT INTO resp * FROM insertarinformefacturacionitem();

             -- Cambio el estado del informe de facturacion 3=facturable
             UPDATE informefacturacionestado
             SET fechafin=NOW()
             WHERE nroinforme=informeF and idcentroinformefacturacion=Centro() and fechafin is null;

             INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini)
             VALUES(informeF,Centro(),3,NOW());

           
            ELSE -- Solo cancelo todos los informes que esten pendientes en facturacion para ese consumo
                     OPEN cursorinforme FOR /*SELECT  * from informefacturacion
                                            NATURAL JOIN informefacturacionsolicitudfinanciacion
                                            NATURAL JOIN prestamosolicitudfinanciacion
                                            NATURAL JOIN informefacturacionestado
                                            NATURAL JOIN informefacturacionestadotipo
                                            WHERE idprestamo = pidprestamo
                                            AND idcentroprestamo = pidcentroprestamo
                                            AND nullvalue(fechafin) AND idinformefacturacionestadotipo <> 5;*/

-- BelenA 06/02/25 comento la consulta y cambio para que si el prestamo es nulo en  solicitudfinanciacion, que se fije si esta en prestamosolicitudfinanciacion y viceversa
                                            SELECT  * from informefacturacion
                                            NATURAL JOIN informefacturacionsolicitudfinanciacion
                                            NATURAL JOIN solicitudfinanciacion  
                                            LEFT JOIN prestamosolicitudfinanciacion USING (idsolicitudfinanciacion, 	idcentrosolicitudfinanciacion)
                                            NATURAL JOIN informefacturacionestado
                                            NATURAL JOIN informefacturacionestadotipo
                                            WHERE

                                            CASE WHEN nullvalue(solicitudfinanciacion.idprestamo) THEN prestamosolicitudfinanciacion.idprestamo=pidprestamo ELSE solicitudfinanciacion.idprestamo=pidprestamo END

                                            AND CASE WHEN nullvalue(solicitudfinanciacion.idcentroprestamo) THEN prestamosolicitudfinanciacion.idcentroprestamo=pidcentroprestamo ELSE solicitudfinanciacion.idcentroprestamo=pidcentroprestamo END
                                            AND nullvalue(fechafin) AND idinformefacturacionestadotipo <> 5;

                                            FETCH cursorinforme INTO rinforme;
                                            WHILE  found LOOP
                                            -- Si todo va bien entonces, puedo anular el prestamo
                                            -- 1° Cancelamos la Factura
                                               UPDATE informefacturacionestado SET fechafin = CURRENT_timestamp
                                               WHERE nroinforme = rinforme.nroinforme
                                               AND idcentroinformefacturacion = rinforme.idcentroinformefacturacion
                                               AND nullvalue(fechafin);
                                               INSERT INTO informefacturacionestado(nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini,descripcion)
                                               VALUES (rinforme.nroinforme,rinforme.idcentroinformefacturacion,5,current_timestamp,'Anulacion de Prestamo');
                                            FETCH cursorinforme INTO rinforme;
                                            END LOOP;
                       close cursorinforme;


            END IF; -- Cancele el Informe o Genere las NC segun Correspondia


           -- 2° Busco la informacion de la deuda en la cuenta corriente
            OPEN cursorafil FOR SELECT * FROM prestamo
                                NATURAL JOIN prestamocuotas JOIN cuentacorrientedeuda
                                        ON cuentacorrientedeuda.idcomprobante = prestamocuotas.idprestamocuotas * 10 + prestamocuotas.idcentroprestamocuota
                                        AND cuentacorrientedeuda.idcomprobantetipos = prestamocuotas.idcomprobantetipos
                                WHERE idprestamo = rconsumo.idprestamo
                                  AND idcentroprestamo = rconsumo.idcentroprestamo;


            FETCH cursorafil into rdeuda;
            WHILE  found LOOP

                       SELECT INTO rpago * FROM cuentacorrientedeudapago WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;
                       IF NOT FOUND THEN
                           -- SI no se pago aun, simplemente registo el pago de la misma por anulacion
                            UPDATE cuentacorrientedeuda SET saldo = 0  WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;
                            INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,idcentropago)
                            VALUES(rdeuda.idcomprobantetipos,rdeuda.tipodoc,rdeuda.idctacte,CURRENT_TIMESTAMP,concat('Anulacion de Prestamo' , rdeuda.movconcepto),rdeuda.nrocuentac,rdeuda.importe,rdeuda.idcomprobante,0,rdeuda.idconcepto,rdeuda.nrodoc,centro());
                            INSERT INTO cuentacorrientedeudapago (idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp)
                            VALUES(currval('cuentacorrientepagos_idpago_seq'),rdeuda.iddeuda,CURRENT_TIMESTAMP,rdeuda.idcentrodeuda,centro(),rdeuda.saldo);

                         ELSE -- Si ya se registro el pago hay que registrar una nota de credito 
                              INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,idcentropago)
                              VALUES(rdeuda.idcomprobantetipos,rdeuda.tipodoc,rdeuda.idctacte,CURRENT_TIMESTAMP,concat('Nota de Credito p/Anulacion de Prestamo ', rdeuda.movconcepto),rdeuda.nrocuentac,rdeuda.importe,rdeuda.idcomprobante,rdeuda.importe,rdeuda.idconcepto,rdeuda.nrodoc,centro());
                        END IF;
            fetch cursorafil into rdeuda;
            END LOOP;
            close cursorafil;
            
            -- Si se trata de un plan de pago, hay que volver a generar la deuda que se cancelo por el plan de pago
             SELECT INTO elprestamo * FROM prestamo
                                     NATURAL JOIN prestamocuotas
                                     NATURAL JOIN prestamoplandepago
                                     WHERE idprestamo = pidprestamo
                                     AND idcentroprestamo = pidcentroprestamo
                                     LIMIT 1;
             IF FOUND THEN
             -- Se trata de un plan de pago, genero una nueva deuda por el total del prestamo anulado
             INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
             VALUES(elprestamo.idcomprobantetipos,elprestamo.tipodoc,elprestamo.nrodoc::integer*10+elprestamo.tipodoc,current_date,'Generacion deuda por Anulacion de Plan de Pago'
             ,'123456',elprestamo.importeprestamo,elprestamo.idprestamo::integer*10+elprestamo.idcentroprestamo,elprestamo.importeprestamo,374,elprestamo.nrodoc);

             END IF;
            
end if;
return 'TRUE';
END;
$function$
