CREATE OR REPLACE FUNCTION public.asentarcancelacionenviodescuentotacte(bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que asienta la cencelacion de los envios a descontar a la universidad de la deuda
en ctacte
*/
DECLARE
       cursormovimientos CURSOR FOR SELECT * FROM tempenviodescontarctacte WHERE tempenviodescontarctacte.idenviodescontarctacte = $1;
       unmovimiento RECORD;
       rectacte RECORD;
       nrocuentacontable VARCHAR;
       movcancala BIGINT;
       idcomprobantetipo INTEGER;
       movconceptocancelacion VARCHAR;
       signomovimiento INTEGER;
       fechamov TIMESTAMP;



BEGIN
     -- El tipo de comprobante vuelve a ser el del consumo original
     movconceptocancelacion = 'C.E';
     nrocuentacontable = '60131';
     signomovimiento = 1; --Porque se cancelo el envio de la deuda con lo que se debe volver a marcar para pagar, se usa una cuenta temporal
     /*La fecha del movimiento es la fecha en la que se cancelo el envio a descontar*/
     SELECT INTO fechamov CURRENT_TIMESTAMP;
     /*Modifico los movimentos para que figuren como cancelados y enviados a descontar*/
     OPEN cursormovimientos;
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
            SELECT INTO rectacte * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = unmovimiento.idmovimiento
                                                              AND NOT nullvalue(cuentacorriente.idmovcancela);
            IF FOUND THEN
                        /*El movimineto aun no se ha cancelado, hay que generar el movimiento de cancelacion de la cuenta corriente*/
                        INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,comprobante,idconcepto)
                        VALUES(nextval('cuentacorriente_idmovimiento_seq'),rectacte.idcomprobantetipos,unmovimiento.tipodoc,unmovimiento.nrodoc,fechamov,concat(movconceptocancelacion , unmovimiento.movconcepto),nrocuentacontable,unmovimiento.importe,signomovimiento,rectacte.idcomprobante,rectacte.comprobante,rectacte.idconcepto);
                        movcancala = currval('cuentacorriente_idmovimiento_seq');
                        /*Tengo que marcar como cancelado el movimiento que cancelaba al movimiento original*/
                        UPDATE cuentacorriente SET idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = rectacte.idmovcancela;
            END IF;
     /*Elimino los movimiento de los que se envian a descontar*/
     DELETE FROM enviodescontarctacte WHERE enviodescontarctacte.idmovimiento = unmovimiento.idmovimiento
                                        AND enviodescontarctacte.idenviodescontarctacte = unmovimiento.idenviodescontarctacte;

     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;


RETURN TRUE;
END;
$function$
