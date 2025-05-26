CREATE OR REPLACE FUNCTION public.asentarcancelacionenviodescuentotactev2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta la cencelacion de los envios a descontar a la universidad de la deuda
en ctacte
*/
DECLARE
       cursormovimientos CURSOR FOR
                         SELECT *
                         FROM cuentacorrientedeuda
                         JOIN persona USING(nrodoc,tipodoc)
                         LEFT JOIN ( SELECT nrodoc,tipodoc
                                      FROM informedescuentoplanillav2
                                      JOIN cuentacorrientedeuda USING(nrodoc,tipodoc)
                                      WHERE NOT informedescuentoplanillav2.imputado
                                            AND not nullvalue(cuentacorrientedeuda.fechaenvio)
                                            AND  informedescuentoplanillav2.mes = EXTRACT(MONTH  FROM cuentacorrientedeuda.fechaenvio)
                                            AND  informedescuentoplanillav2.anio = EXTRACT(YEAR  FROM cuentacorrientedeuda.fechaenvio)
                                     ) as informesinimputar
                         USING(nrodoc,tipodoc)
                         WHERE not nullvalue(cuentacorrientedeuda.fechaenvio) AND
                                nullvalue(informesinimputar.nrodoc)
                               /*AND barra <> 32*/ ;

       unmovimiento RECORD;
       rectacte RECORD;
       nrocuentacontable VARCHAR;
       movcancala BIGINT;
       idcomprobantetipo INTEGER;
       movconceptocancelacion VARCHAR;
       signomovimiento INTEGER;
       fechamov TIMESTAMP;
BEGIN
     OPEN cursormovimientos;
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
        UPDATE cuentacorrientedeuda SET fechaenvio=null
               WHERE iddeuda = unmovimiento.iddeuda AND idcentrodeuda = unmovimiento.idcentrodeuda;
        /*Elimino los movimiento de los que se envian a descontar*/
        INSERT INTO enviodescontarctactev2borrados
                (idenviodescontarctacte,fechaenvio,cancelado,idmovimiento,idcomprobantetipos
                 ,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante
                 ,idmovcancela,idconcepto,nrodoc,idcentromovimiento)
              SELECT idenviodescontarctacte,fechaenvio,cancelado,idmovimiento,idcomprobantetipos
              ,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante
              ,idmovcancela,idconcepto,nrodoc,idcentromovimiento
               FROM enviodescontarctactev2
               WHERE idmovimiento = unmovimiento.iddeuda AND idcentromovimiento = unmovimiento.idcentrodeuda
               AND NOT cancelado;

        /*22-02-2012 comento vivi para tener un historico de lo que se envio en cada mes a la unc 
        DELETE FROM enviodescontarctactev2 WHERE enviodescontarctactev2.idmovimiento = unmovimiento.iddeuda
                                           AND idcentromovimiento = unmovimiento.idcentrodeuda
                                            AND NOT enviodescontarctactev2.cancelado;
        */

     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;
/*Cancelo todos los envios, para los cuales ya se cancelo la deuda, es decir, su saldo es cero.*/
UPDATE enviodescontarctactev2 SET cancelado = true
       WHERE not cancelado AND (idmovimiento,idcentromovimiento )  IN (
       SELECT iddeuda,idcentrodeuda
       FROM cuentacorrientedeuda
       WHERE saldo = 0 
             );

--UPDATE cuentacorrientedeuda SET fechaenvio=null WHERE  not nullvalue(fechaenvio);

RETURN TRUE;
END;
$function$
