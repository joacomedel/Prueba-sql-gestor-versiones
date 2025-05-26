CREATE OR REPLACE FUNCTION public.liberardescuentos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta la cencelacion de los envios a descontar a la universidad de la deuda
en ctacte
*/
/* Funcion que asienta la cencelacion de los envios a descontar a la universidad de la deuda
en ctacte
*/
DECLARE
       cursormovimientos CURSOR FOR
 --KR 02-11-22 Modifico para que tenga en cuenta la cta cte de adherentes
                      --   SELECT *
                       --   FROM cuentacorrientedeuda
                       --   JOIN persona USING(nrodoc,tipodoc)
                      --    LEFT JOIN ( SELECT nrodoc,tipodoc
                       --                FROM informedescuentoplanillav2
                       --                JOIN cuentacorrientedeuda USING(nrodoc,tipodoc)
                      --                 WHERE NOT informedescuentoplanillav2.imputado
                      --                       AND not nullvalue(cuentacorrientedeuda.fechaenvio)
                      --                       AND  informedescuentoplanillav2.mes = EXTRACT(MONTH  FROM cuentacorrientedeuda.fechaenvio)
                      --                       AND  informedescuentoplanillav2.anio = EXTRACT(YEAR  FROM cuentacorrientedeuda.fechaenvio)
                      --                ) as informesinimputar
                       --   USING(nrodoc,tipodoc)
                      --    WHERE not nullvalue(cuentacorrientedeuda.fechaenvio) AND
                       --          nullvalue(informesinimputar.nrodoc) 
                      --          /*AND barra <> 32*/ ;
                         SELECT *
                         FROM 
                              (SELECT nrodoc, tipodoc, fechaenvio, iddeuda, idcentrodeuda,'afiliado' tipoafil FROM cuentacorrientedeuda WHERE not nullvalue(fechaenvio)
                              UNION         
                              SELECT nrocliente as nrodoc, barra as tipodoc, ccdcfechaenvio as fechaenvio, iddeuda, idcentrodeuda,'adherente' tipoafil FROM ctactedeudacliente NATURAL JOIN clientectacte WHERE not nullvalue(ccdcfechaenvio) ) T
                        JOIN persona USING(nrodoc,tipodoc) 
                         LEFT JOIN ( SELECT nrodoc,tipodoc, mes, anio 
                                      FROM informedescuentoplanillav2
                                      WHERE NOT informedescuentoplanillav2.imputado 
                                     ) as informesinimputar ON (informesinimputar.nrodoc= T.nrodoc AND informesinimputar.tipodoc= T.tipodoc AND  mes = EXTRACT(MONTH  FROM T.fechaenvio) AND anio = EXTRACT(YEAR  FROM T.fechaenvio) )
                         WHERE   nullvalue(informesinimputar.nrodoc) ;

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
       IF (unmovimiento.tipoafil ilike 'afiliado') THEN 
        UPDATE cuentacorrientedeuda SET fechaenvio=null
               WHERE iddeuda = unmovimiento.iddeuda AND idcentrodeuda = unmovimiento.idcentrodeuda;
       END IF;
       IF (unmovimiento.tipoafil ilike 'adherente') THEN 
        UPDATE ctactedeudacliente SET ccdcfechaenvio=null
               WHERE iddeuda = unmovimiento.iddeuda AND idcentrodeuda = unmovimiento.idcentrodeuda;
       END IF;
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
/*
COMENTO VAS 08/08/2017
Cancelo todos los envios, para los cuales ya se cancelo la deuda, es decir, su saldo es cero.
UPDATE enviodescontarctactev2 SET cancelado = true
       WHERE not cancelado AND (idmovimiento,idcentromovimiento )  IN (
       SELECT iddeuda,idcentrodeuda
       FROM cuentacorrientedeuda
       WHERE saldo = 0 
             );
*/
  IF (unmovimiento.tipoafil ilike 'afiliado') THEN 
    UPDATE cuentacorrientedeuda SET fechaenvio=null WHERE  not nullvalue(fechaenvio);
  END IF;
  IF (unmovimiento.tipoafil ilike 'adherente') THEN 
    UPDATE ctactedeudacliente SET ccdcfechaenvio=null WHERE  not nullvalue(ccdcfechaenvio);
  END IF;
RETURN TRUE;
END;

$function$
