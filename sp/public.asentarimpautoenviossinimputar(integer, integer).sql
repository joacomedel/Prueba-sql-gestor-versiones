CREATE OR REPLACE FUNCTION public.asentarimpautoenviossinimputar(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que libera los envios a descontar que no se han imputado
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
       rectactepuente RECORD;
       inimovconceptocancelacion VARCHAR;
       movconceptocancelacion VARCHAR;
       nrocuentacontable VARCHAR;
       signomovimiento INTEGER;
       fechamov timestamp;
       movcancala bigint;
       vcomprobanteimputacion BIGINT;
       vcomprobantetipos INTEGER;
       importenuevadeuda DOUBLE PRECISION;
       sindescuento boolean;
       pagototal boolean;
       pagoparcial boolean;
       automatico BOOLean;


BEGIN
OPEN curdescuento FOR SELECT * FROM enviodescontarctacte
                              WHERE NOT enviodescontarctacte.cancelado
                              AND enviodescontarctacte.idenviodescontarctacte = (anioinforme * 100 + mesinforme)
                              ORDER BY enviodescontarctacte.idmovimiento;

FETCH curdescuento INTO undescuento;
WHILE  found LOOP
sindescuento = false;
pagototal = false;
automatico = false;
pagoparcial = false;
--Se mando un descuento por planilla y no se efectuo ningun descuento
sindescuento = true;
automatico = TRUE;
-- El tipo de comprobante vuelve a ser el del consumo original
     inimovconceptocancelacion = 'I.A.SinImp-UNC-';
    --La fecha del movimiento es la fecha en la que se imputo el envio a descontar
     SELECT INTO fechamov CURRENT_TIMESTAMP;

IF automatico THEN
--Modifico los movimentos para que figuren como cancelados e imputados
  movconceptocancelacion = concat(inimovconceptocancelacion , undescuento.movconcepto);
   /*Tiene el movimiento que se envio a descontar y que se esta pagando*/
   SELECT INTO rectacte * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = undescuento.idmovimiento;
          IF FOUND THEN
             /*Tiene el movimiento de la cuenta puente */
              SELECT INTO rectactepuente * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = rectacte.idmovcancela;
          IF FOUND THEN
   --El movimineto que cancela el movimiento de la cuenta puente
       INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,idmovcancela,comprobante)
       VALUES(nextval('cuentacorriente_idmovimiento_seq'),rectactepuente.idcomprobantetipos,rectactepuente.tipodoc,rectactepuente.nrodoc,concat(fechamov,movconceptocancelacion , rectacte.movconcepto),rectactepuente.nrocuentac,rectactepuente.importe,rectactepuente.signo * -1,vcomprobanteimputacion,rectactepuente.idmovimiento,rectacte.idcomprobante);
       movcancala =  currval('cuentacorriente_idmovimiento_seq');
        --Tengo que marcar como cancelado el movimiento que cancelaba al movimiento original, es decir el 60311
        UPDATE cuentacorriente SET idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = rectactepuente.idmovimiento;
       --Si no se desconto nada, por lo que hay que volver a poner vigente la deuda
           IF sindescuento THEN
           --Hace la deuda vuelva a estar vigente
                UPDATE cuentacorriente SET idmovcancela = null WHERE cuentacorriente.idmovimiento = rectacte.idmovimiento;

          END IF;

        --Marco como cancelado el envio a descontar, aunque en realidad lo que significa es que ya esta imputado
        UPDATE enviodescontarctacte SET cancelado = TRUE, idmovcancela = movcancala
                                 WHERE enviodescontarctacte.idenviodescontarctacte = undescuento.idenviodescontarctacte
                                 AND enviodescontarctacte.idmovimiento = rectacte.idmovimiento;
        END IF;
        END IF;
  END IF; --IF automatico THEN
FETCH curdescuento INTO undescuento;
END LOOP;
close curdescuento;
RETURN 'true';
END;
$function$
