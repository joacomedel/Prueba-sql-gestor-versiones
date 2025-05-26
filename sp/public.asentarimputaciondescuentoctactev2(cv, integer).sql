CREATE OR REPLACE FUNCTION public.asentarimputaciondescuentoctactev2(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       pnrodoc alias for $1;
       ptipodc alias for $2;
       curpagos refcursor;
       curdeudas refcursor;
       unpago RECORD;
       unadeuda RECORD;
       importe DECIMAL;
       saldodeuda DECIMAL;
       saldopago DECIMAL;

BEGIN

OPEN curpagos FOR SELECT *
                          FROM cuentacorrientepagos
                          WHERE nrodoc = pnrodoc and tipodoc = ptipodc and saldo <> 0
                          ORDER BY cuentacorrientepagos.fechamovimiento;


FETCH curpagos INTO unpago;
WHILE  found LOOP
/*Me aseguro que el importe del pago sea negativo*/
IF unpago.saldo > 0 THEN
saldopago = cast(unpago.saldo as DECIMAL(10,2)) * -1 ;
ELSE
saldopago = cast(unpago.saldo as DECIMAL(10,2));
END IF;
/*Primero busco, si existe una deuda con igual importe, para imputarla entre elllos*/
SELECT INTO unadeuda * FROM cuentacorrientedeuda
                      WHERE nrodoc = pnrodoc and tipodoc = ptipodc
                      and saldo <> 0 AND saldo = abs(saldopago)
                      AND nullvalue(fechaenvio)
                      ORDER BY cuentacorrientedeuda.fechamovimiento
                      LIMIT 1;
    IF FOUND THEN
           importe = unadeuda.saldo;
           saldodeuda = 0;
           saldopago = 0;
        UPDATE cuentacorrientedeuda SET saldo = saldodeuda, fechaenvio = null
               WHERE iddeuda = unadeuda.iddeuda AND idcentrodeuda = unadeuda.idcentrodeuda;
        --UPDATE enviodescontarctactev2 SET cancelado = TRUE WHERE idmovimiento = rdeuda.iddeuda AND idcentromovimiento = rdeuda.idcentrodeuda AND idenviodescontarctacte = undescuento.idenviodescontarctacte;
        UPDATE cuentacorrientepagos SET saldo = saldopago
               WHERE idpago = unpago.idpago AND idcentropago = unpago.idcentropago;
        --UPDATE informedescuentoplanillav2 SET imputado = TRUE, importeimputado = cast(importeimputado + rdeuda.saldo as DECIMAL(10,2)) WHERE idinforme = rpago.idcomprobante;
        INSERT INTO cuentacorrientedeudapago(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
            VALUES(unpago.idpago,unpago.idcentropago,unadeuda.iddeuda,unadeuda.idcentrodeuda,CURRENT_DATE,importe);

     ELSE -- SI no encuentro una deuda con igual saldo, entonces uso para pagar cualquiera

/*Imputo las deudas que figuran en la descripcion del pago*/

OPEN curdeudas FOR SELECT *
                          FROM cuentacorrientedeuda
                          WHERE nrodoc = pnrodoc
                                and tipodoc = ptipodc and saldo <> 0
                                and  unpago.movconcepto ilike concat('%',movconcepto,'%')
                                and nullvalue(fechaenvio)
                          ORDER BY cuentacorrientedeuda.fechamovimiento;
/*Los saldos de los pagos son negativos */
FETCH curdeudas INTO unadeuda;
WHILE  found AND saldopago < 0 LOOP

IF  abs(saldopago) >= unadeuda.saldo THEN
 importe = unadeuda.saldo;
ELSE
 importe = abs(saldopago);
END IF;

saldodeuda = cast(unadeuda.saldo + saldopago as DECIMAL(10,2));
IF saldodeuda < 0 THEN
   saldodeuda = 0;
END IF;

saldopago = cast(saldopago + unadeuda.saldo as DECIMAL(10,2));
IF saldopago > 0 THEN
saldopago = 0;
END IF;



UPDATE cuentacorrientedeuda SET saldo = saldodeuda, fechaenvio = null
       WHERE iddeuda = unadeuda.iddeuda AND idcentrodeuda = unadeuda.idcentrodeuda;
--UPDATE enviodescontarctactev2 SET cancelado = TRUE WHERE idmovimiento = rdeuda.iddeuda AND idcentromovimiento = rdeuda.idcentrodeuda AND idenviodescontarctacte = undescuento.idenviodescontarctacte;
UPDATE cuentacorrientepagos SET saldo = saldopago
       WHERE idpago = unpago.idpago AND idcentropago = unpago.idcentropago;
--UPDATE informedescuentoplanillav2 SET imputado = TRUE, importeimputado = cast(importeimputado + rdeuda.saldo as DECIMAL(10,2)) WHERE idinforme = rpago.idcomprobante;
INSERT INTO cuentacorrientedeudapago(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
            VALUES(unpago.idpago,unpago.idcentropago,unadeuda.iddeuda,unadeuda.idcentrodeuda,CURRENT_DATE,importe);

FETCH curdeudas INTO unadeuda;
END LOOP;
close curdeudas;

/*Ahora imputo teniendo en cuenta el concepto*/
IF saldopago < 0 THEN
OPEN curdeudas FOR SELECT *
                          FROM cuentacorrientedeuda
                          WHERE nrodoc = pnrodoc
                                and tipodoc = ptipodc and saldo <> 0
                                and idconcepto = unpago.idconcepto
                                and nullvalue(fechaenvio)
                          ORDER BY cuentacorrientedeuda.fechamovimiento;
/*Los saldos de los pagos son negativos */
FETCH curdeudas INTO unadeuda;
WHILE  found AND saldopago < 0 LOOP

IF  abs(saldopago) >= unadeuda.saldo THEN
 importe = unadeuda.saldo;
ELSE
 importe = abs(saldopago);
END IF;

saldodeuda = cast(unadeuda.saldo + saldopago as DECIMAL(10,2));
IF saldodeuda < 0 THEN
   saldodeuda = 0;
END IF;

saldopago = cast(saldopago + unadeuda.saldo as DECIMAL(10,2));
IF saldopago > 0 THEN
saldopago = 0;
END IF;



UPDATE cuentacorrientedeuda SET saldo = saldodeuda, fechaenvio = null
       WHERE iddeuda = unadeuda.iddeuda AND idcentrodeuda = unadeuda.idcentrodeuda;
--UPDATE enviodescontarctactev2 SET cancelado = TRUE WHERE idmovimiento = rdeuda.iddeuda AND idcentromovimiento = rdeuda.idcentrodeuda AND idenviodescontarctacte = undescuento.idenviodescontarctacte;
UPDATE cuentacorrientepagos SET saldo = saldopago
       WHERE idpago = unpago.idpago AND idcentropago = unpago.idcentropago;
--UPDATE informedescuentoplanillav2 SET imputado = TRUE, importeimputado = cast(importeimputado + rdeuda.saldo as DECIMAL(10,2)) WHERE idinforme = rpago.idcomprobante;
INSERT INTO cuentacorrientedeudapago(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
            VALUES(unpago.idpago,unpago.idcentropago,unadeuda.iddeuda,unadeuda.idcentrodeuda,CURRENT_DATE,importe);

FETCH curdeudas INTO unadeuda;
END LOOP;
close curdeudas;
END IF; /*Fin de la Imputacion teniendo en cuenta el concepto*/
/*Ya pague todas las deudas del mismo concepto, ahora pago las de otros conceptos*/
IF saldopago < 0 THEN
OPEN curdeudas FOR SELECT *
                          FROM cuentacorrientedeuda
                          WHERE nrodoc = pnrodoc
                          AND tipodoc = ptipodc
                          and saldo <> 0
                          and nullvalue(fechaenvio)
                          ORDER BY cuentacorrientedeuda.fechamovimiento;
/*Los saldos de los pagos son negativos */
FETCH curdeudas INTO unadeuda;
WHILE  found AND saldopago < 0 LOOP

IF  abs(saldopago) >= unadeuda.saldo THEN
 importe = unadeuda.saldo;
ELSE
 importe = abs(saldopago);
END IF;

saldodeuda = cast(unadeuda.saldo + saldopago as DECIMAL(10,2));
IF saldodeuda < 0 THEN
   saldodeuda = 0;
END IF;

saldopago = cast(saldopago + unadeuda.saldo as DECIMAL(10,2));
IF saldopago > 0 THEN
saldopago = 0;
END IF;



UPDATE cuentacorrientedeuda SET saldo = saldodeuda, fechaenvio = null
       WHERE iddeuda = unadeuda.iddeuda AND idcentrodeuda = unadeuda.idcentrodeuda;
--UPDATE enviodescontarctactev2 SET cancelado = TRUE WHERE idmovimiento = rdeuda.iddeuda AND idcentromovimiento = rdeuda.idcentrodeuda AND idenviodescontarctacte = undescuento.idenviodescontarctacte;
UPDATE cuentacorrientepagos SET saldo = saldopago
       WHERE idpago = unpago.idpago AND idcentropago = unpago.idcentropago;
--UPDATE informedescuentoplanillav2 SET imputado = TRUE, importeimputado = cast(importeimputado + rdeuda.saldo as DECIMAL(10,2)) WHERE idinforme = rpago.idcomprobante;
INSERT INTO cuentacorrientedeudapago(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
            VALUES(unpago.idpago,unpago.idcentropago,unadeuda.iddeuda,unadeuda.idcentrodeuda,CURRENT_DATE,importe);

FETCH curdeudas INTO unadeuda;
END LOOP;
close curdeudas;

END IF; -- IF saldopago < 0 THEN
END IF; -- El Else de buscar las deudas con igual importe
FETCH curpagos INTO unpago;
END LOOP;
close curpagos;
RETURN 'true';
END;
$function$
