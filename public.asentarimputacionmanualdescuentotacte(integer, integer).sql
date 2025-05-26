CREATE OR REPLACE FUNCTION public.asentarimputacionmanualdescuentotacte(integer, integer)
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
OPEN curdescuento FOR SELECT *
                          FROM tempimputacion
                          ORDER BY tempimputacion.nrodoc
                          ,tempimputacion.idmovimiento;

FETCH curdescuento INTO undescuento;
WHILE  found LOOP
sindescuento = false;
pagototal = false;
automatico = false;
pagoparcial = false;

/*Se cancela completo, es como se hace en la imputacion automatica cuando se descuenta todo lo que se mando a descontar*/
IF undescuento.importe = undescuento.importepagado THEN
  --Se mando un descuento por planilla y se efectuo el descuento total
   automatico = TRUE;
   pagototal = true;
   IF undescuento.automatica THEN
       -- El tipo de comprobante vuelve a ser el del consumo original
         inimovconceptocancelacion = 'I.A.P/TotalUNC-';

   ELSE
   -- El tipo de comprobante vuelve a ser el del consumo original
     inimovconceptocancelacion = 'I.M.P/TotalUNC-';

   END IF;
    --La fecha del movimiento es la fecha en la que se imputo el envio a descontar
     SELECT INTO fechamov CURRENT_TIMESTAMP;
END IF;
/*Se cancela parcial*/
IF undescuento.importepagado > 0
   AND undescuento.importepagado < undescuento.importe THEN
 --Se mando un descuento por planilla y se efectuo el descuento parcial, se cancela la deuda existente y se genera la nueva percial
pagoparcial = true;
automatico = TRUE;
 IF undescuento.automatica THEN
   -- El tipo de comprobante vuelve a ser el del consumo original
     inimovconceptocancelacion = 'I.A.P/ParcialUNC-';

   ELSE
 -- El tipo de comprobante vuelve a ser el del consumo original
     inimovconceptocancelacion = 'I.M.P/ParcialUNC-';

   END IF;
    --La fecha del movimiento es la fecha en la que se imputo el envio a descontar
     SELECT INTO fechamov CURRENT_TIMESTAMP;
END IF;
/*Se cancela parcial*/
IF undescuento.importepagado = 0 THEN
--Se mando un descuento por planilla y no se efectuo ningun descuento
sindescuento = true;
automatico = TRUE;
 IF undescuento.automatica THEN
   -- El tipo de comprobante vuelve a ser el del consumo original
     inimovconceptocancelacion = 'I.A.P/S-DesUNC-';

   ELSE
 -- El tipo de comprobante vuelve a ser el del consumo original
     inimovconceptocancelacion = 'I.M.P/S-DesUNC-';

   END IF;
    --La fecha del movimiento es la fecha en la que se imputo el envio a descontar
     SELECT INTO fechamov CURRENT_TIMESTAMP;
END IF;


IF automatico THEN
--Modifico los movimentos para que figuren como cancelados e imputados
   SELECT INTO uninforme * FROM informedescuentoplanilla
                         WHERE (informedescuentoplanilla.nrodoc)::integer * 10 + informedescuentoplanilla.tipodoc = undescuento.nrodoc
                         AND (nullvalue(informedescuentoplanilla.mes)
                             OR  (informedescuentoplanilla.mes = mesinforme AND informedescuentoplanilla.anio = anioinforme));
   IF FOUND THEN
   /*Si se realizo algun descuento el comprobante de la cancelacion de la ctacte es el idinforme*/
       vcomprobantetipos = 11;
       vcomprobanteimputacion = uninforme.idinforme;
   END IF;
    movconceptocancelacion =concat( inimovconceptocancelacion , undescuento.movconcepto);
    /*Tiene el movimiento que se envio a descontar y que se esta pagando*/
    SELECT INTO rectacte * FROM cuentacorriente WHERE cuentacorriente.idmovcancela = undescuento.idmovimiento;
    /*Tiene el movimiento de la cuenta puente */
    SELECT INTO rectactepuente * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = undescuento.idmovimiento;

   --El movimineto que cancela el movimiento de la cuenta puente
       INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,idmovcancela,comprobante)
       VALUES(nextval('cuentacorriente_idmovimiento_seq'),vcomprobantetipos,rectactepuente.tipodoc,rectactepuente.nrodoc,fechamov,movconceptocancelacion,rectactepuente.nrocuentac,rectactepuente.importe,rectactepuente.signo * -1,vcomprobanteimputacion,rectactepuente.idmovimiento,rectactepuente.comprobante);
       movcancala =  currval('cuentacorriente_idmovimiento_seq');
        --Tengo que marcar como cancelado el movimiento que cancelaba al movimiento original, es decir el 60311
        UPDATE cuentacorriente SET idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = rectactepuente.idmovimiento;

        --Tengo que marcar como cancelado el movimiento que cancelaba al movimiento original
         IF pagototal THEN --Si es un pago Total tengo que insertar la tupla que cancela el pago de 10311 y modificar el movimiento que lo cancela
                vcomprobantetipos = 11;
                vcomprobanteimputacion = uninforme.idinforme;
                INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,idmovcancela)
                       VALUES(nextval('cuentacorriente_idmovimiento_seq'),vcomprobantetipos,rectacte.tipodoc,rectacte.nrodoc,fechamov,movconceptocancelacion,rectacte.nrocuentac,rectacte.importe,rectacte.signo * -1,vcomprobanteimputacion,rectacte.idmovimiento);
                movcancala =  currval('cuentacorriente_idmovimiento_seq');
                UPDATE cuentacorriente SET idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = rectacte.idmovimiento;
          END IF;
           --Si es un pago Parcial tengo que insertar la tupla que cancela el pago de 10311
           -- y modificar el movimiento que lo cancela y crear la nueva deuda parcial
           IF pagoparcial THEN
                vcomprobantetipos = 11;
                vcomprobanteimputacion = uninforme.idinforme;

               --Tupla que inserta el importe que se desconto, efectivamente
                INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,idmovcancela,comprobante)
                       VALUES(nextval('cuentacorriente_idmovimiento_seq'),vcomprobantetipos,rectacte.tipodoc,rectacte.nrodoc,fechamov,movconceptocancelacion,rectacte.nrocuentac,undescuento.importepagado,rectacte.signo * -1,vcomprobanteimputacion,rectacte.idmovimiento,rectacte.comprobante);
                movcancala =  currval('cuentacorriente_idmovimiento_seq');
                --HAce que apunte al movimiento que lo esta cancelando, es decir el pago parcial que se ricibio
                UPDATE cuentacorriente SET idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = rectacte.idmovimiento;
               --Hace que el importe del aciento en cta cte sea el mismo que se pago
                UPDATE cuentacorriente SET importe = undescuento.importepagado WHERE cuentacorriente.idmovimiento = rectacte.idmovimiento;


                vcomprobanteimputacion  = rectacte.idcomprobante;
                vcomprobantetipos = rectacte.idcomprobantetipos;
                importenuevadeuda = rectacte.importe - undescuento.importepagado;
                --Creo la nueva deuda parcial, con el importe que no se pago
                INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,idmovcancela,comprobante)
                       VALUES(nextval('cuentacorriente_idmovimiento_seq'),vcomprobantetipos,rectacte.tipodoc,rectacte.nrodoc,fechamov,movconceptocancelacion,rectacte.nrocuentac,importenuevadeuda,rectacte.signo,vcomprobanteimputacion,null,rectacte.comprobante);


          END IF;

           --Si no se desconto nada, por lo que hay que volver a poner vigente la deuda
           IF sindescuento THEN
                vcomprobanteimputacion  = rectacte.idcomprobante;
                vcomprobantetipos = rectacte.idcomprobantetipos;
                importenuevadeuda = rectacte.importe - undescuento.importepagado;
               --Hace la deuda vuelva a estar vigente
                UPDATE cuentacorriente SET idmovcancela = null WHERE cuentacorriente.idmovimiento = rectacte.idmovimiento;

          END IF;

        --Marco como cancelado el envio a descontar, aunque en realidad lo que significa es que ya esta imputado
        UPDATE enviodescontarctacte SET cancelado = TRUE, idmovcancela = movcancala
                                 WHERE enviodescontarctacte.idenviodescontarctacte = undescuento.idenviodescontarctacte
                                 AND enviodescontarctacte.idmovimiento = rectacte.idmovimiento;

           IF NOT nullvalue(uninforme.idinforme) THEN
               --Marco como imputado el informe de descuento por planilla
               UPDATE informedescuentoplanilla SET imputado = TRUE
                      WHERE informedescuentoplanilla.idinforme = uninforme.idinforme;
           END IF;

    END IF; --IF automatico THEN
FETCH curdescuento INTO undescuento;
END LOOP;
close curdescuento;
RETURN 'true';
END;
$function$
