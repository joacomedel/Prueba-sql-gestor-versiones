CREATE OR REPLACE FUNCTION public.consumoturismoactualizartacte(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       lascuotaspresmodif refcursor;
       lascuotasnuevas refcursor;
       ladeudainteres  refcursor;
       unacuotamodif record;
       unacuotanueva record;
       elconsumo record;
       elpago record;
       deudainicial record;
        unadeudanueva record;
       nuevosaldodeuda double precision;
       elimporteimp double precision;
       nuevosaldopago double precision;
       diferenciadp double precision;
       haymascuotasnuevas boolean;
       rorigenctacte RECORD;
BEGIN


     -- Trcupero la info del consumo turismo
     SELECT INTO elconsumo * FROM consumoturismo NATURAL JOIN prestamo WHERE idcentroconsumoturismo = $2 and idconsumoturismo =$1;
     
--KR 30-05-22 Busco si el afiliado es adherente o afiliado
     CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
     INSERT INTO tempcliente(nrocliente,barra) VALUES(elconsumo.nrodoc,elconsumo.tipodoc);
     SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
		FROM (SELECT verifica_origen_ctacte() as origen ) as t;
     DROP TABLE tempcliente;
     -- Recupero las cuotas del prestamo actualizado
     OPEN lascuotasnuevas FOR SELECT * FROM prestamocuotas
                                 WHERE nullvalue (pcborrado)
                                       and idprestamo= elconsumo.idprestamo and  idcentroprestamo =elconsumo.idcentroprestamo
                                 order by idprestamocuotas;
     FETCH lascuotasnuevas INTO unacuotanueva;
     IF not FOUND THEN
        haymascuotasnuevas = false;
     ELSE 
        haymascuotasnuevas = true;
     END IF ;

     -- recupero las deudas de la cta cte iniciales
     OPEN lascuotaspresmodif FOR SELECT * FROM prestamocuotas
                                 WHERE not nullvalue (pcborrado)
                                        AND prestamocuotascc = NOW() --Malapi10-04-2015 Necesito solo las borrasdas en el sp anterior 
                                       and idprestamo= elconsumo.idprestamo and  idcentroprestamo =elconsumo.idcentroprestamo
                                      
                                 order by idprestamocuotas;
     FETCH lascuotaspresmodif INTO unacuotamodif;
     WHILE  found LOOP
           IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
     
                  -- busco la deuda
                  OPEN ladeudainteres FOR SELECT   * FROM cuentacorrientedeuda LEFT JOIN cuentacorrientedeudapago using (iddeuda,idcentrodeuda)
                         WHERE idcomprobantetipos = 7
                               and  idcomprobante = unacuotamodif.idprestamocuotas *10 +unacuotamodif.idcentroprestamocuota
                               and nrodoc = elconsumo.nrodoc and  tipodoc=  elconsumo.tipodoc 
                          order by cuentacorrientedeuda.iddeuda;
                  FETCH ladeudainteres INTO deudainicial;
                  WHILE FOUND LOOP -- recorro las deudas generadas para el consumo anterior
                           SELECT INTO elpago *
                           FROM cuentacorrientepagos 
                           WHERE idpago = deudainicial.idpago and idcentropago=deudainicial.idcentropago
                                 AND idcomprobantetipos <> 7; --Malapi 10-04-2015 Para excluir los movimientos de modificaciones anteriores sobre el prestamos. 

                           IF FOUND THEN  -- Encontre un pago para la deuda vieja
                           
                                    nuevosaldopago = elpago.saldo;
                                    -- Si tengo nuevas deudas intento imputar el pago
                                    IF (haymascuotasnuevas) THEN -- hay nuevas cuotas
                                             -- corroboro si el prestamo cuota tiene un recibo asignado
                                            UPDATE prestamocuotas SET idcentrorecibo =unacuotamodif.idcentrorecibo
                                                                   , idrecibo=unacuotamodif.idrecibo
                                            WHERE idprestamocuotas = unacuotanueva.idprestamocuotas
                                               and idcentroprestamocuota =unacuotanueva.idcentroprestamocuota ;
                                    
                                    
                                              -- Imputar el pago con la deuda que se genero nueva
                                              SELECT INTO unadeudanueva *
                                              FROM cuentacorrientedeuda
                                              WHERE idcomprobantetipos = 7
                                                    and  idcomprobante = unacuotanueva.idprestamocuotas *10 +unacuotanueva.idcentroprestamocuota AND movconcepto= deudainicial.movconcepto
                                                    and nrocuentac = deudainicial.nrocuentac
                                                    and nrodoc = elconsumo.nrodoc and  tipodoc=  elconsumo.tipodoc ;

                                              -- Actualizo el saldo de la deuda con el pago
                                              diferenciadp = unadeudanueva.saldo - deudainicial.importeimp;
                                              IF (diferenciadp<=0)THEN
                                                 nuevosaldodeuda =0;
                                                 elimporteimp = unadeudanueva.saldo;
                                                 nuevosaldopago = deudainicial.importeimp - unadeudanueva.saldo;
                                              ELSE
                                                  nuevosaldodeuda = diferenciadp;
                                                  elimporteimp = deudainicial.importeimp;
                                                  nuevosaldopago = 0;
                                              END IF;

                                              UPDATE cuentacorrientedeuda SET saldo = nuevosaldodeuda
                                              WHERE iddeuda = unadeudanueva.iddeuda and idcentrodeuda =unadeudanueva.idcentrodeuda;
                           --KR 30-11-17 es una tabla sincronizable (al llegar a sede central, si la modificacion se hizo en un centro se pisa), se debe actualizar el importeimp de cuentacorrientedeudapago en 0 de la deuda anterior y generar la imputación con la nueva deuda del pago. Es decir, 
                                            /*  UPDATE cuentacorrientedeudapago SET iddeuda = unadeudanueva.iddeuda ,
                                                               idcentrodeuda =unadeudanueva.idcentrodeuda ,
                                                               importeimp = elimporteimp
                                              WHERE iddeuda = deudainicial.iddeuda and idcentrodeuda =deudainicial.idcentrodeuda
                                                    and idpago =deudainicial.idpago and idcentropago =deudainicial.idcentropago;*/
					      UPDATE cuentacorrientedeudapago SET importeimp = 0
                                              WHERE iddeuda = deudainicial.iddeuda and idcentrodeuda =deudainicial.idcentrodeuda
                                                    and idpago =deudainicial.idpago and idcentropago =deudainicial.idcentropago;
                                             RAISE NOTICE 'deudainicial(%)',deudainicial;
                                             RAISE NOTICE 'unadeudanueva(%)',unadeudanueva;
						INSERT INTO cuentacorrientedeudapago (idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp)
                                   VALUES(deudainicial.idpago,unadeudanueva.iddeuda,CURRENT_TIMESTAMP,unadeudanueva.idcentrodeuda,centro(),elimporteimp);
                                   END IF; -- hay nuevas cuotas
                                 -- verifico si es necesario actualizar el importe del saldo del pago
                                 if (nuevosaldopago > 0 ) THEN -- la nueva cuota tiene un monto menor a la anterio => devuelvo $ al pago
                                      UPDATE cuentacorrientepagos SET saldo = saldo + nuevosaldopago
                                      WHERE idpago = elpago.idpago and idcentropago=elpago.idcentropago ;
                                  END IF;
                            END IF ; -- Encontre un pago para la deuda vieja

                            -- Genero un pago por cada una de las deudas
                            INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,idcentropago)
                                   VALUES(deudainicial.idcomprobantetipos,deudainicial.tipodoc,deudainicial.idctacte,CURRENT_TIMESTAMP,concat('Modificacion de Consumo de Turismo' , deudainicial.movconcepto),deudainicial.nrocuentac,(-1)*deudainicial.importe,deudainicial.idcomprobante,0,deudainicial.idconcepto,deudainicial.nrodoc,centro());
                            INSERT INTO cuentacorrientedeudapago (idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp)
                                   VALUES(currval('cuentacorrientepagos_idpago_seq'),deudainicial.iddeuda,CURRENT_TIMESTAMP,deudainicial.idcentrodeuda,centro(),deudainicial.importe);

                             --  El saldo de las cuotas del consumo inicial = 0
                             --  cada una de las deudas generadas por el consumo turismo que se modifico
                             UPDATE cuentacorrientedeuda SET saldo = 0
                             WHERE iddeuda = deudainicial.iddeuda and idcentrodeuda =deudainicial.idcentrodeuda;
                FETCH ladeudainteres INTO deudainicial;
                END LOOP ;  -- recorro las deudas generadas para el consumo anterior
                CLOSE ladeudainteres;
                FETCH lascuotasnuevas INTO unacuotanueva;
                IF not FOUND THEN
                         haymascuotasnuevas = false;
                END IF ;
                FETCH lascuotaspresmodif INTO unacuotamodif;
           END IF ;      
             IF rorigenctacte.origentabla = 'clientectacte' THEN      
                  -- busco la deuda
                  OPEN ladeudainteres FOR SELECT   * FROM ctactedeudacliente NATURAL JOIN clientectacte LEFT JOIN ctactedeudapagocliente using (iddeuda,idcentrodeuda)
                         WHERE idcomprobantetipos = 7
                               and  idcomprobante = unacuotamodif.idprestamocuotas *10 +unacuotamodif.idcentroprestamocuota
                               and nrocliente= elconsumo.nrodoc and  barra=  elconsumo.tipodoc 
                          order by ctactedeudacliente.iddeuda;
                  FETCH ladeudainteres INTO deudainicial;
                  WHILE FOUND LOOP -- recorro las deudas generadas para el consumo anterior
                           SELECT INTO elpago *
                           FROM ctactepagocliente
                           WHERE idpago = deudainicial.idpago and idcentropago=deudainicial.idcentropago
                                 AND idcomprobantetipos <> 7; 
                           IF FOUND THEN  -- Encontre un pago para la deuda vieja
                           
                                    nuevosaldopago = elpago.saldo;
                                    -- Si tengo nuevas deudas intento imputar el pago
                                    IF (haymascuotasnuevas) THEN -- hay nuevas cuotas
                                             -- corroboro si el prestamo cuota tiene un recibo asignado
                                            UPDATE prestamocuotas SET idcentrorecibo =unacuotamodif.idcentrorecibo
                                                                   , idrecibo=unacuotamodif.idrecibo
                                            WHERE idprestamocuotas = unacuotanueva.idprestamocuotas
                                               and idcentroprestamocuota =unacuotanueva.idcentroprestamocuota ;
                                    
                                    
                                              -- Imputar el pago con la deuda que se genero nueva
                                              SELECT INTO unadeudanueva *
                                              FROM ctactedeudacliente  NATURAL JOIN clientectacte
                                              WHERE idcomprobantetipos = 7
                                                    and  idcomprobante = unacuotanueva.idprestamocuotas *10 +unacuotanueva.idcentroprestamocuota AND movconcepto= deudainicial.movconcepto
                                                    and nrocuentac = deudainicial.nrocuentac
                                                    and nrocliente= elconsumo.nrodoc and  barra=  elconsumo.tipodoc ;

                                              -- Actualizo el saldo de la deuda con el pago
                                              diferenciadp = unadeudanueva.saldo - deudainicial.importeimp;
                                              IF (diferenciadp<=0)THEN
                                                 nuevosaldodeuda =0;
                                                 elimporteimp = unadeudanueva.saldo;
                                                 nuevosaldopago = deudainicial.importeimp - unadeudanueva.saldo;
                                              ELSE
                                                  nuevosaldodeuda = diferenciadp;
                                                  elimporteimp = deudainicial.importeimp;
                                                  nuevosaldopago = 0;
                                              END IF;

                                              UPDATE ctactedeudacliente SET saldo = nuevosaldodeuda
                                              WHERE iddeuda = unadeudanueva.iddeuda and idcentrodeuda =unadeudanueva.idcentrodeuda;
                           
					      UPDATE ctactedeudapagocliente SET importeimp = 0
                                              WHERE iddeuda = deudainicial.iddeuda and idcentrodeuda =deudainicial.idcentrodeuda
                                                    and idpago =deudainicial.idpago and idcentropago =deudainicial.idcentropago;
                                        
				              INSERT INTO ctactedeudapagocliente (idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idusuario)
                                   VALUES(deudainicial.idpago,unadeudanueva.iddeuda,unadeudanueva.idcentrodeuda,centro(),elimporteimp,sys_dar_usuarioactual());
                                   END IF; -- hay nuevas cuotas
                                 -- verifico si es necesario actualizar el importe del saldo del pago
                                 if (nuevosaldopago > 0 ) THEN -- la nueva cuota tiene un monto menor a la anterio => devuelvo $ al pago
                                      UPDATE ctactepagocliente SET saldo = saldo + nuevosaldopago
                                      WHERE idpago = elpago.idpago and idcentropago=elpago.idcentropago ;
                                  END IF;
                            END IF ; -- Encontre un pago para la deuda vieja

                            -- Genero un pago por cada una de las deudas
                            INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo)
                            VALUES(deudainicial.idcomprobantetipos,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte, CURRENT_TIMESTAMP,concat('Modificacion de Consumo de Turismo' , deudainicial.movconcepto),deudainicial.nrocuentac,(-1)*deudainicial.importe,deudainicial.idcomprobante,0);
                            INSERT INTO ctactedeudapagocliente (idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idusuario)
                                   VALUES(currval('ctactepagocliente_idpago_seq'),deudainicial.iddeuda,deudainicial.idcentrodeuda,centro(),deudainicial.importe,sys_dar_usuarioactual());

                             --  El saldo de las cuotas del consumo inicial = 0
                             --  cada una de las deudas generadas por el consumo turismo que se modifico
                             UPDATE ctactedeudacliente SET saldo = 0
                             WHERE iddeuda = deudainicial.iddeuda and idcentrodeuda =deudainicial.idcentrodeuda;
                FETCH ladeudainteres INTO deudainicial;
                END LOOP ;  -- recorro las deudas generadas para el consumo anterior
                CLOSE ladeudainteres;
                FETCH lascuotasnuevas INTO unacuotanueva;
                IF not FOUND THEN
                         haymascuotasnuevas = false;
                END IF ;
                FETCH lascuotaspresmodif INTO unacuotamodif;
           END IF ;      
     END LOOP;
     CLOSE lascuotaspresmodif;
     -- recupero las nuevas deudas

     return true;
END;$function$
