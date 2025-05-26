CREATE OR REPLACE FUNCTION public.asentarimputacionautomatica(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que realiza la imputación automatica  de los descuentos por planillas
realizados.
Se toman en cuanta:
Si el importe Descontado = 0 y si el importe Enviado es igual al importe Descontado.
*/
DECLARE
       mesinforme alias for $1;
       anioinforme alias for $2;
       curinforme refcursor;
       curdescuento refcursor;
       uninforme RECORD;
       undescuento RECORD;
       renviodescontar RECORD;
       rectacte RECORD;
       inimovconceptocancelacion VARCHAR;
       movconceptocancelacion VARCHAR;
       nrocuentacontable VARCHAR;
       signomovimiento INTEGER;
       fechamov timestamp;
       movcancala bigint;
       vcomprobanteimputacion BIGINT;
       vcomprobantetipos INTEGER;
       automatico boolean;
       sindescuento boolean;
       pagototal boolean;


BEGIN
OPEN curinforme FOR SELECT enviodescontar.impenvio
                           ,enviodescontar.idenviodescontarctacte
                           ,enviodescontar.idctacte
                           ,enviodescontar.nrodoc
                           ,enviodescontar.tipodoc
                           ,persona.nombres
                           ,persona.apellido
                           ,CASE WHEN nullvalue(informedescuentoplanilla.importe) THEN 0
                           ELSE informedescuentoplanilla.importe END as impdescontado
                           ,informedescuentoplanilla.idinforme
                           FROM (SELECT SUM(vistaenviodescontarctacte.importe) as impenvio
                                ,vistaenviodescontarctacte.idctacte
                                ,vistaenviodescontarctacte.idenviodescontarctacte
                                ,vistaenviodescontarctacte.nrodoc
                                ,vistaenviodescontarctacte.tipodoc
                                FROM vistaenviodescontarctacte
                                WHERE (NOT vistaenviodescontarctacte.cancelado OR nullvalue(vistaenviodescontarctacte.cancelado))
                                AND  vistaenviodescontarctacte.idenviodescontarctacte = 200708
                                GROUP BY vistaenviodescontarctacte.idenviodescontarctacte
                                ,vistaenviodescontarctacte.idctacte
                                ,vistaenviodescontarctacte.nrodoc
                                ,vistaenviodescontarctacte.tipodoc ) as enviodescontar
                           NATURAL JOIN persona
                           LEFT JOIN informedescuentoplanilla
                                USING(nrodoc,tipodoc)
                           WHERE nrodoc = '08666468' AND
                           (NOT informedescuentoplanilla.imputado OR nullvalue(informedescuentoplanilla.imputado))
                           AND enviodescontar.idenviodescontarctacte = 200708
                           AND (nullvalue(informedescuentoplanilla.mes)
                               OR  (informedescuentoplanilla.mes = 08 AND informedescuentoplanilla.anio = 2007))
                           ORDER BY impdescontado;
FETCH curinforme INTO uninforme;
WHILE  found LOOP
sindescuento = false;
pagototal = false;
automatico = false;
IF uninforme.impdescontado = 0 THEN
--Se mando un descuento por planilla y no se efectuo ningun descuento
-- NroCuenta   idMovimiento  idMovCancela  Signo
-- 10311        1            2-->null          -1
-- 60311        2            3                 1
-- 60311        3            2                 -1 --> la tupla que debo agregar
   automatico = TRUE;
   sindescuento = true;
   inimovconceptocancelacion = 'I.A.Sin/DtoUNC-';
  --La fecha del movimiento es la fecha en la que se cancelo el envio a descontar
     SELECT INTO fechamov CURRENT_TIMESTAMP;
END IF;
IF uninforme.impdescontado = uninforme.impenvio THEN
   --Se mando un descuento por planilla y se efectuo el descuento total
-- NroCuenta   idMovimiento  idMovCancela  Signo
-- 10311        1            2-->4          -1
-- 60311        2            3               1
-- 60311        3            2              -1 --> la tupla que debo agregar
-- 10311        4            1               1 --> la tupla que debo agregar
   automatico = TRUE;
   pagototal = true;
 -- El tipo de comprobante vuelve a ser el del consumo original
     inimovconceptocancelacion = 'I.A.P/TotalUNC-';
    --La fecha del movimiento es la fecha en la que se imputo el envio a descontar
     SELECT INTO fechamov CURRENT_TIMESTAMP;
END IF;
IF automatico THEN
--Modifico los movimentos para que figuren como cancelados e imputados
    OPEN curdescuento FOR SELECT * FROM enviodescontarctacte
                                   WHERE enviodescontarctacte.idenviodescontarctacte = uninforme.idenviodescontarctacte
                                                           AND enviodescontarctacte.nrodoc = uninforme.idctacte
                                                           AND (NOT enviodescontarctacte.cancelado OR nullvalue(enviodescontarctacte.cancelado))
                                                           ORDER BY enviodescontarctacte.idmovimiento;
    FETCH curdescuento INTO undescuento;
    WHILE  found LOOP
    movconceptocancelacion = concat(inimovconceptocancelacion , undescuento.movconcepto);
    SELECT INTO rectacte * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = undescuento.idmovimiento;
    SELECT INTO renviodescontar * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = rectacte.idmovcancela
                                                             AND nullvalue(cuentacorriente.idmovcancela);
    IF FOUND THEN

          IF pagototal THEN
                vcomprobantetipos = 11;
                vcomprobanteimputacion = uninforme.idinforme;
          END IF;

          IF sindescuento THEN
                vcomprobanteimputacion  = rectacte.idcomprobante;
                vcomprobantetipos = rectacte.idcomprobantetipos;
           END IF;
    --El movimineto de la cuenta puente aun no se ha cancelado, hay que generar el movimiento de cancelacion de la cuenta corriente
       INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,idmovcancela,comprobante)
       VALUES(nextval('cuentacorriente_idmovimiento_seq'),vcomprobantetipos,renviodescontar.tipodoc,renviodescontar.nrodoc,fechamov,movconceptocancelacion,renviodescontar.nrocuentac,renviodescontar.importe,renviodescontar.signo * -1,vcomprobanteimputacion,renviodescontar.idmovimiento,rectacte.comprobante);
       movcancala =  currval('cuentacorriente_idmovimiento_seq');
        --Tengo que marcar como cancelado el movimiento que cancelaba al movimiento original, es decir el 60311
        UPDATE cuentacorriente SET idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = renviodescontar.idmovimiento;
        --Tengo que marcar como cancelado el movimiento que cancelaba al movimiento original
         IF pagototal THEN --Si es un pago Total tengo que insertar la tupla que cancela el pago de 10311 y modificar el movimiento que lo cancela
                vcomprobantetipos = 11;
                vcomprobanteimputacion = uninforme.idinforme;
                INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,idmovcancela,comprobante)
                       VALUES(nextval('cuentacorriente_idmovimiento_seq'),vcomprobantetipos,rectacte.tipodoc,rectacte.nrodoc,fechamov,movconceptocancelacion,rectacte.nrocuentac,rectacte.importe,rectacte.signo * -1,vcomprobanteimputacion,rectacte.idmovimiento,rectacte.comprobante);
                movcancala =  currval('cuentacorriente_idmovimiento_seq');
                UPDATE cuentacorriente SET idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = rectacte.idmovimiento;
          END IF;
          IF sindescuento THEN -- Tengo que volver a dejar sin cancelar el pago del comprobante
                  UPDATE cuentacorriente SET idmovcancela = null WHERE cuentacorriente.idmovimiento = rectacte.idmovimiento;
           END IF;
    END IF;
        --Marco como cancelado el envio a descontar, aunque en realidad lo que significa es que ya esta imputado
        UPDATE enviodescontarctacte SET cancelado = TRUE, idmovcancela = movcancala
                                 WHERE enviodescontarctacte.idenviodescontarctacte = undescuento.idenviodescontarctacte
                                 AND enviodescontarctacte.idmovimiento = undescuento.idmovimiento;

           IF NOT nullvalue(uninforme.idinforme) THEN
               --Marco como imputado el informe de descuento por planilla
               UPDATE informedescuentoplanilla SET imputado = TRUE
                      WHERE informedescuentoplanilla.idinforme = uninforme.idinforme;
           END IF;

     FETCH curdescuento INTO undescuento;
    END LOOP;
    close curdescuento;
    END IF; --IF automatico THEN
FETCH curinforme INTO uninforme;
END LOOP;
close curinforme;
RETURN TRUE;
END;
$function$
