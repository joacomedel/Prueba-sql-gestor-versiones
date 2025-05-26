CREATE OR REPLACE FUNCTION public.temporal()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       curdeudas refcursor;
       unadeuda RECORD;
       curdeudas2 refcursor;
       unadeuda2 RECORD;
       rdeuda RECORD;

       asentar boolean;
       importepago float4;
       importedeuda float4;

BEGIN

OPEN curdeudas FOR /*SELECT e.importe as saldoenviado,d.saldo,i.iddeuda,i.idcentrodeuda,i.importeimp,p.idpago,p.idcentropago
                   FROM enviodescontarctactev2 e
                   JOIN cuentacorrientedeudapago i ON e.idmovimiento = i.iddeuda AND e.idcentromovimiento = i.idcentrodeuda
                   JOIN cuentacorrientepagos p ON p.idpago = i.idpago AND p.idcentropago = i.idcentropago
                   JOIN cuentacorrientedeuda d  ON e.idmovimiento = d.iddeuda AND e.idcentromovimiento = d.idcentrodeuda
                   WHERE e.fechaenvio >= '2010-05-01'    -- AND d.importe <> e.importe
                   AND p.fechamovimiento >= '2010-06-01'*/
                   SELECT t.iddeuda,t.idcentrodeuda,t.saldo as saldoenviado,p.saldo as saldopago,d.saldo,p.idpago,p.idcentropago
                    FROM cuentacorrientedeudapago as i
                    JOIN cuentacorrientepagos as p  ON p.idpago = i.idpago AND p.idcentropago = i.idcentropago
                    JOIN deudas100610 t USING(iddeuda,idcentrodeuda)
                    JOIN cuentacorrientedeuda d USING(iddeuda,idcentrodeuda)
                    WHERE nullvalue(importeimp);
FETCH curdeudas INTO unadeuda;
WHILE  found LOOP

/**IF  nullvalue(unadeuda.importeimp) THEN*/

   UPDATE cuentacorrientedeudapago SET importeimp = unadeuda.saldoenviado - unadeuda.saldo
   WHERE iddeuda = unadeuda.iddeuda AND idcentrodeuda = unadeuda.idcentrodeuda
   AND idpago = unadeuda.idpago AND idcentropago = unadeuda.idcentropago;

/*ELSE

      IF unadeuda.importeimp > unadeuda.saldoenviado THEN
         UPDATE cuentacorrientedeudapago SET importeimp = unadeuda.saldoenviado - unadeuda.saldo
         WHERE iddeuda = unadeuda.iddeuda AND idcentrodeuda = unadeuda.idcentrodeuda
         AND idpago = unadeuda.idpago AND idcentropago = unadeuda.idcentropago;

      END IF;

END IF;
*/

FETCH curdeudas INTO unadeuda;
END LOOP;
close curdeudas;
RETURN 'true';
END;
$function$
