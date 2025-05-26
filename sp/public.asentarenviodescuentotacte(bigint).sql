CREATE OR REPLACE FUNCTION public.asentarenviodescuentotacte(bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que asienta los envios a descontar a la universidad de la deuda
en ctacte
*/
DECLARE
       cursormovimientos CURSOR FOR SELECT * FROM enviodescontarctacte WHERE enviodescontarctacte.idenviodescontarctacte = $1;
       unmovimiento RECORD;
       rectacte RECORD;
       nrocuentacontable VARCHAR;
       movcancala BIGINT;
       idcomprobantetipo INTEGER;
       movconceptocancelacion VARCHAR;
       movconceptocancelacionini VARCHAR;
       signomovimiento INTEGER;

       

BEGIN
     idcomprobantetipo = 11 ; -- Envio a descontar Codigo 387
     movconceptocancelacionini = 'E/D';
     nrocuentacontable = '60131';
     signomovimiento = -1; --Porque es como si fuera un pago de la deuda, se usa una cuenta temporal
     /*Modifico los movimentos para que figuren como cancelados y enviados a descontar*/
     OPEN cursormovimientos;
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
            SELECT INTO rectacte * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = unmovimiento.idmovimiento AND nullvalue(cuentacorriente.idmovcancela);
            IF FOUND THEN
                         movconceptocancelacion = concat(movconceptocancelacionini , rectacte.movconcepto);
                        /*El movimineto aun no se ha cancelado, hay que generar el movimiento de cancelacion de la cuenta corriente*/
                        INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,comprobante)
                        VALUES(nextval('cuentacorriente_idmovimiento_seq'),idcomprobantetipo,unmovimiento.tipodoc,unmovimiento.nrodoc,unmovimiento.fechaenvio,movconceptocancelacion,nrocuentacontable,unmovimiento.importe,signomovimiento,unmovimiento.idenviodescontarctacte,rectacte.comprobante);
                        movcancala = currval('cuentacorriente_idmovimiento_seq');
                        UPDATE cuentacorriente set idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = unmovimiento.idmovimiento;
            END IF;
     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;
RETURN TRUE;
END;
$function$
