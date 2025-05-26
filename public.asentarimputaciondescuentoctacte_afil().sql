CREATE OR REPLACE FUNCTION public.asentarimputaciondescuentoctacte_afil()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que realiza la imputación  entre deudas y pagos
*/
DECLARE
       curdescuento refcursor;
       undescuento RECORD;
       rdeuda RECORD;
       rpago RECORD;
       rexistedeudapago RECORD;
--VARIABLES
       saldodeuda DOUBLE PRECISION;
       saldopago DOUBLE PRECISION;
       importe_imp DOUBLE PRECISION;
       respuesta BOOLEAN;

BEGIN
OPEN curdescuento FOR SELECT * FROM tempimputacion ORDER BY tempimputacion.idpago;

FETCH curdescuento INTO undescuento;
WHILE  found LOOP
       SELECT INTO rdeuda * FROM cuentacorrientedeuda WHERE iddeuda = undescuento.iddeuda AND idcentrodeuda = undescuento.idcentrodeuda ;
       SELECT INTO rpago * FROM cuentacorrientepagos WHERE idpago = undescuento.idpago AND idcentropago = undescuento.idcentropago;
        -- BelenA 04/04/24 con Vivi modificamos la forma en la que se calcula la imputacion y luego se actualizan los saldos 
        saldodeuda = rdeuda.saldo - abs(rpago.saldo) ;
        importe_imp = 0;
        IF (saldodeuda <0 ) THEN----- Pago es mayor a la deuda          
            importe_imp = rdeuda.saldo;
            saldodeuda = 0;
            saldopago = abs(rpago.saldo) -importe_imp;

        ELSE  --- Pago es menor o igual a la deuda
            importe_imp = abs( rpago.saldo);
            saldopago = 0;

        END IF;

        IF (saldodeuda < 0.09  ) THEN 
             saldodeuda = 0;
        END IF;
        IF (saldopago < 0.09  ) THEN 
            saldopago = 0;
        END IF;


       UPDATE cuentacorrientedeuda SET saldo = saldodeuda, fechaenvio = null
              WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;
       
       UPDATE cuentacorrientepagos SET saldo = (abs(saldopago)*-1)
              WHERE idpago = rpago.idpago AND idcentropago = rpago.idcentropago;
       --KR 15-06-22 Verifico si las claves ya existen y envio cartel
         -- BelenA 18/03/24 comento esto porque segun vivi, no tiene sentido que se haga este control
        

        SELECT INTO rexistedeudapago * 
        FROM cuentacorrientedeudapago 
        WHERE idpago= rpago.idpago AND idcentropago=rpago.idcentropago  AND iddeuda=rdeuda.iddeuda AND idcentrodeuda=rdeuda.idcentrodeuda;
        
        IF FOUND THEN     
        --  RAISE EXCEPTION 'R-001, Ya existe un pago para esa deuda. Realice la imputacion manual con otros IDs.(IdPagoIdDeuda%)',rexistedeudapago;        
        -- BelenA 18/03/24 Si ya existe, sobreescribo la fila con el nuevo importe imp que va a tener
            UPDATE cuentacorrientedeudapago
            SET importeimp=importe_imp
            WHERE idpago=rpago.idpago AND idcentropago=rpago.idcentropago AND iddeuda=rdeuda.iddeuda AND idcentrodeuda=rdeuda.idcentrodeuda; 

        ELSE
            INSERT INTO cuentacorrientedeudapago(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
            VALUES(rpago.idpago,rpago.idcentropago,rdeuda.iddeuda,rdeuda.idcentrodeuda,CURRENT_DATE,rdeuda.saldo - saldodeuda);
        END IF;

    FETCH curdescuento INTO undescuento;

END LOOP;
close curdescuento;

---SELECT INTO respuesta * FROM verificarcompensacionasientoctacte();
RETURN respuesta;
END;
$function$
