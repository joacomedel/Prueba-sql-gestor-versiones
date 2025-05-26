CREATE OR REPLACE FUNCTION public.asentarpagoctacteconpagoreservado(bigint, integer, bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* MaLaPi: 26-01-2012 Esta funcion, dados un pago reservado y una deuda, marca el pago de la deuda con el pago reservado.
*  Se asume que: 1 - El importe del pago reservado es igual al importe de la deuda a pagar.
                 2 - Que la deuda del pago reservado era solo una y que fue pagada con un unico recibo.
*/
DECLARE
--Parametros
       pidconsumoturismoreservado alias for $1;
       pidcentroconsumoturismoreservado alias for $2;
       piddeuda alias for $3;
       pidcentrodeuda alias for $4;
--registros
       rctactedeuda RECORD;
       rctactepago RECORD;
       rctactedeudapago RECORD;
       rconsumoreservado RECORD;
       rdeudaapagar RECORD; 
     
--variables
       idpagoreservado bigint;


BEGIN
     SELECT INTO rconsumoreservado * FROM consumoturismopagoreservado
                                     WHERE idconsumoturismopagoreservado =  pidconsumoturismoreservado
                                           AND idcentroconsumoturismopagoreservado = pidcentroconsumoturismoreservado;  
     IF FOUND THEN 
     
     SELECT INTO rctactedeuda * FROM cuentacorrientedeuda 
                                WHERE iddeuda = rconsumoreservado.iddeuda
                                AND idcentrodeuda = rconsumoreservado.idcentrodeuda;
         IF FOUND THEN

          /*Ingreso el pago en la cuenta corriente, en concepto de anulacion por el importe reservado */
          INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento
          ,movconcepto,nrocuentac,importe,idcomprobante,saldo
          ,idconcepto,nrodoc,idcentropago)
          VALUES(rctactedeuda.idcomprobantetipos,rctactedeuda.tipodoc,rctactedeuda.idctacte,rconsumoreservado.ctprfechareserva
          ,concat('Reserva de Anticipo p/Anulacion ', rctactedeuda.movconcepto),rctactedeuda.nrocuentac,((-1)*rconsumoreservado.ctprmonto)
          ,rctactedeuda.idcomprobante,0,rctactedeuda.idconcepto,rctactedeuda.nrodoc,centro());
          idpagoreservado = currval('cuentacorrientepagos_idpago_seq');
          
          -- Busco y guardo el pago de la dueda reservada
          SELECT INTO rctactedeudapago * FROM cuentacorrientedeudapago 
                                         JOIN cuentacorrientepagos USING(idpago,idcentropago)
                                         WHERE iddeuda = rconsumoreservado.iddeuda 
                                               AND idcentrodeuda = rconsumoreservado.idcentrodeuda;
          --Modifico el vinculo entre la deuda y el pago anterior
          --Asumo que solo un movimiento de pago, pago la deuda reservada, cuando esto cambie, esto va a generar problemas
--Dani modifico el 12032025 porq con Vivi se encontro que no deberia actualizar las vinculaciones previas, solo insertar las nuevas.
         /* UPDATE cuentacorrientedeudapago SET idpago = idpagoreservado, idcentropago = centro()
                                              ,fechamovimientoimputacion = rconsumoreservado.ctprfechareserva
          WHERE  iddeuda = rconsumoreservado.iddeuda 
                 AND idcentrodeuda = rconsumoreservado.idcentrodeuda;
*/

          --Vinculo el pago anterior, con la nueva deuda
          INSERT INTO cuentacorrientedeudapago(idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp)
          VALUES(rctactedeudapago.idpago,piddeuda,current_date,pidcentrodeuda,rctactedeudapago.idcentropago,rctactedeudapago.importeimp);
          --Marco la Cuota del prestamo como pagado con el recibo que genero el pago reservado
          SELECT INTO rdeudaapagar (idcomprobante/10)::integer as idprestamocuotas,(idcomprobante%10)::INTEGER as idcentroprestamocuotas
                                     FROM cuentacorrientedeuda 
                                     WHERE iddeuda = piddeuda AND idcentrodeuda = pidcentrodeuda; 
          
          UPDATE prestamocuotas SET idrecibo = rctactedeudapago.idcomprobante
                                    ,idcentrorecibo = rctactedeudapago.idcentropago
                 WHERE idprestamocuotas = rdeudaapagar.idprestamocuotas 
                 AND idcentroprestamocuota = rdeudaapagar.idcentroprestamocuotas;
          --Cancelo la deuda nueva       
          UPDATE cuentacorrientedeuda SET saldo = 0 WHERE iddeuda = piddeuda 
                                                  AND idcentrodeuda = pidcentrodeuda;
          -- Marco como usado el pago de turismo reservado
          UPDATE consumoturismopagoreservado SET ctprsaldo = 0,iddeudapagada = piddeuda,idcentrodeudapagada = pidcentrodeuda
                                      WHERE idconsumoturismopagoreservado =  pidconsumoturismoreservado
                                      AND idcentroconsumoturismopagoreservado = pidcentroconsumoturismoreservado;  
          END IF;
          
     END IF;
      
RETURN TRUE;
END;
$function$
