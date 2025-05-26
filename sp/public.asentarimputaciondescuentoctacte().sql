CREATE OR REPLACE FUNCTION public.asentarimputaciondescuentoctacte()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que realiza la imputación  de los descuentos por planillas realizados.
Se toman en cuanta:
Si el importe Descontado = 0 y si el importe Enviado es igual al importe Descontado.
*/
DECLARE
       curdescuento refcursor;
       undescuento RECORD;
       rdeuda RECORD;
       rpago RECORD;
       saldodeuda DECIMAL;
       saldopago DECIMAL;
       rexistedeudapago RECORD;

BEGIN
OPEN curdescuento FOR SELECT *
                          FROM tempimputacion
                          ORDER BY tempimputacion.idpago,iddeuda;

FETCH curdescuento INTO undescuento;
WHILE  found LOOP
       SELECT INTO rdeuda * FROM cuentacorrientedeuda WHERE iddeuda = undescuento.iddeuda AND idcentrodeuda = undescuento.idcentrodeuda AND saldo > 0;       
IF FOUND THEN 
            SELECT INTO rpago * FROM cuentacorrientepagos WHERE idpago = undescuento.idpago AND idcentropago = undescuento.idcentropago AND saldo <> 0;
IF FOUND THEN 
       saldodeuda = cast(rdeuda.saldo + (abs(rpago.saldo)*-1) as DECIMAL(10,2));
       IF saldodeuda < 0.9 THEN --MaLaPi 12-06-2018 si el saldo es de menos de un peso, la doy por saldada
          saldodeuda = 0;
       END IF;

       saldopago = cast((abs(rpago.saldo)*-1) + rdeuda.saldo as DECIMAL(10,2));
       IF saldopago >= 0 OR abs(rpago.saldo) <= 0.9 THEN --MaLaPi 12-06-2018 si el saldo es de menos de un peso, la doy por saldada
          saldopago = 0;
          DELETE FROM tempimputacion WHERE idpago = rpago.idpago AND idcentropago = rpago.idcentropago;
          close curdescuento;
          OPEN curdescuento FOR SELECT *
                          FROM tempimputacion
                          ORDER BY tempimputacion.idpago;

       END IF;

       UPDATE cuentacorrientedeuda SET saldo = saldodeuda, fechaenvio = null
              WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;
   
      /* comento VAS 10/08/2017
          UPDATE enviodescontarctactev2 SET cancelado = TRUE
              WHERE idmovimiento = rdeuda.iddeuda AND idcentromovimiento = rdeuda.idcentrodeuda AND idenviodescontarctacte = undescuento.idenviodescontarctacte;
      */
        UPDATE cuentacorrientepagos SET saldo = saldopago
              WHERE idpago = rpago.idpago AND idcentropago = rpago.idcentropago;
      IF not nullvalue(undescuento.idenviodescontarctacte) THEN  -- MaLaPi 12-06-2018 Solo marco como imputado si es que la imputacion se hace desde un informe de descuento, no desde un remanente.
       -- reemplazo VAS 10/08/2017 UPDATE informedescuentoplanillav2 SET imputado = TRUE, importeimputado = cast(importeimputado + rdeuda.saldo as DECIMAL(10,2))
       UPDATE informedescuentoplanillav2 SET imputado = TRUE, importeimputado = cast(rdeuda.saldo - saldodeuda as DECIMAL(10,2))
              WHERE idpago = rpago.idpago and idcentropago = rpago.idcentropago;
      END IF;
/*KR 18-11-21 Por disposicion de ctactes (Maricel) si el saldo es < a 1 es despreciable y no se imputa. Esta pasando ademas que queda saldo en deuda o pago con valores como  0.000299999 que se quieren imputar nuevamente el mismo iddeuda al mismo idpago y da error. Tkt 4672. Por lo que solo inserto si el saldo de la deuda y pago es distinto de 0*/
--MaLaPi 15-12-2021 saco la comprobacion de saldodeuda > 0 and saldopago > 0 pues ya esta calculado como se se hubieran aplicados, si o si hay que cargar la vinculacion. Agrego que si el importeimp a cargar es <> 0 entonces lo vinculo, sino lo dejo pasar
      IF (cast(rdeuda.saldo - saldodeuda as DECIMAL(10,2)) <> 0) THEN 
--KR 15-06-22 Verifico si las claves ya existen y envio cartel
        SELECT INTO rexistedeudapago * from cuentacorrientedeudapago where idpago= rpago.idpago and idcentropago=rpago.idcentropago  and iddeuda=rdeuda.iddeuda and idcentrodeuda=rdeuda.idcentrodeuda;
        IF FOUND THEN     
             RAISE EXCEPTION 'R-001, Ya existe un pago para esa deuda. Realice la imputacion manual con otros datos.(Datos%)',concat(' Nro. Doc: ',rdeuda.nrodoc,' Id.deuda ',rexistedeudapago.iddeuda,'-', rexistedeudapago.idcentrodeuda,' Id.pago ',rexistedeudapago.idpago,'-', rexistedeudapago.idcentropago) ;         
         
   
        ELSE
          INSERT INTO cuentacorrientedeudapago(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
               VALUES(rpago.idpago,rpago.idcentropago,rdeuda.iddeuda,rdeuda.idcentrodeuda,CURRENT_DATE,cast(rdeuda.saldo - saldodeuda as DECIMAL(10,2)));
       END IF;
      END IF;
END IF;
END IF;
FETCH curdescuento INTO undescuento;
END LOOP;
close curdescuento;
RETURN 'true';
END;
$function$
