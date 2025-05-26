CREATE OR REPLACE FUNCTION public.asentarenviodescuentotactev2(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta los envios a descontar a la universidad de la deuda en ctacte
   Quedan afuera los afiliados Adherentes (35 y 36).
*/
DECLARE
       cursormovimientos refcursor;
       unmovimiento RECORD;
       vfechaenvio date;
       videnviodescontarctacte bigint;
       videnviodescontarctactesosunc bigint;
       videnviodescontarctactefarma bigint;
BEGIN
 
     
     SELECT INTO  vfechaenvio date_trunc('MONTH', now())::date + 21::integer;
     SELECT INTO  videnviodescontarctacte trim(to_char(current_date, 'YYYYMM')) as idenviodescontarctacte;
     SELECT INTO  videnviodescontarctactesosunc concat('32',trim(to_char(current_date, 'YYYYMM'))) as idenviodescontarctacte;
      SELECT INTO  videnviodescontarctactefarma concat('35',trim(to_char(current_date, 'YYYYMM'))) as idenviodescontarctacte;

     OPEN cursormovimientos FOR SELECT iddeuda, idcentrodeuda, barra, 'afiliado' as tipodeuda
                         FROM cuentacorrientedeuda
                         NATURAL JOIN (
                                 SELECT *
                                 FROM persona
                                 WHERE barra <> 35 and concat(nrodoc,tipodoc) in (select concat(nrodoc,tipodoc)
                                                                  from cargo 
                                              where true 
                                                   AND fechafinlab>= CURRENT_DATE-120::integer --27-12-2016 Malapi, lo vuelvo a agregar pues sino se mandan saldos a la UNC de personas que ya se dieron de baja. 
                                                   --fechafinlab>= CURRENT_DATE 23-08-2016 Malapi: Ya no verifico que tenga un cargo vigente
                                       )
          /* KR 20-07-20 Las deudas de empleados de farmacia se guardan en la tabla ctactedeudacliente
                              UNION (  -- buscar los empleados de farmacia
                                         SELECT ppe.*
                                         FROM public.persona as ppe
                                         JOIN ca.persona as cape ON (nrodoc=penrodoc)
                                         WHERE ppe.barra=35
                                )
*/
                          ) as persona

/*
                         JOIN persona USING(nrodoc,tipodoc)
                         LEFT JOIN cargo USING(nrodoc,tipodoc)
*/
                         WHERE saldo > 0
                              ---- AND barra = 35  -- 21/06/2016 esta condicion comentar despues de la prueba
				               AND fechamovimiento <= vfechaenvio
				               AND nullvalue(fechaenvio)
--                                AND cargo.fechafinlab >= CURRENT_DATE
                               AND (
                                      ( $1 ilike 'sosunc' AND persona.barra = 32 )
				                      OR ( $1 ilike 'unc' AND persona.barra <> 35 AND persona.barra <> 32 AND persona.barra <> 36 AND persona.barra <> 34 )
   				          --            OR ( $1 ilike 'farm' AND persona.barra = 35 )
                                      )

                         UNION 
                         SELECT iddeuda, idcentrodeuda, 35 as barra, 'cliente' as tipodeuda
                         FROM ctactedeudacliente natural join clientectacte JOIN persona ON nrocliente=nrodoc
/* KR 20-09-21 estaba probando algo pero lo dejo para futuro x las dudas LEFT JOIN ca.persona pe on persona.nrodoc= pe.penrodoc left join ca.empleado using (idpersona)*/
--KR 21-05-22 HAGO un join con ca.empleado pq solo los adherentes empleados de sosunc (farma) se genera el descuento tkt 5085
                         JOIN ca.persona pe ON persona.nrodoc= pe.penrodoc JOIN ca.empleado using (idpersona)
                         WHERE  saldo > 0 AND   fechamovimiento <= now()  AND nullvalue(ccdcfechaenvio) and cccdtohaberes
                          and  (( $1  ilike 'sosunc' AND persona.barra = 32 )
				                      OR (  $1 ilike 'unc' AND persona.barra <> 35 AND persona.barra <> 32 AND persona.barra <> 36 AND persona.barra <> 34) 
--KR 20-09-21 agrego pq los txts de la farma tambien se deben generar 
--KR 21-09-21 Saque las deudas de aportes
                                 OR (  $1 ilike 'farm' AND persona.barra = 35  and nrocuentac <>'10826' 
/* KR 20-09-21 and idsector=10  AND not nullvalue(pe.penrodoc)*/)
                                        )
                   	ORDER BY barra,iddeuda, idcentrodeuda;
 
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
                  
                IF (unmovimiento.tipodeuda = 'afiliado') THEN
                  UPDATE cuentacorrientedeuda SET fechaenvio=vfechaenvio
                  WHERE iddeuda = unmovimiento.iddeuda AND idcentrodeuda = unmovimiento.idcentrodeuda;
                END IF;
                IF (unmovimiento.tipodeuda = 'cliente') THEN
                  UPDATE ctactedeudacliente SET ccdcfechaenvio=vfechaenvio
                  WHERE iddeuda = unmovimiento.iddeuda AND idcentrodeuda = unmovimiento.idcentrodeuda;
                END IF;

                  /*Elimino los movimiento de los que se envian a descontar*/

	              INSERT INTO enviodescontarctactev2 (enviodescontarctactev2tipo,idenviodescontarctacte,fechaenvio,idmovimiento,idcomprobantetipos
               	,tipodoc,idctacte,fechamovimiento,movconcepto, nrocuentac, importe,    idcomprobante,    idconcepto,    nrodoc,    idcentromovimiento)
	             (
              SELECT CASE WHEN unmovimiento.barra = 32  THEN 2
                          WHEN unmovimiento.barra = 35 THEN 3
                          ELSE 1 END as enviodescontarctactev2tipo,
	                 CASE WHEN unmovimiento.barra = 32 THEN videnviodescontarctactesosunc
	                      WHEN unmovimiento.barra = 35 THEN videnviodescontarctactefarma
                          ELSE videnviodescontarctacte END
                     ,vfechaenvio, ctacte.iddeuda,ctacte.idcomprobantetipos
                     ,ctacte.tipodoc,ctacte.idctacte,ctacte.fechamovimiento,ctacte.movconcepto,ctacte.nrocuentac, saldo,ctacte.idcomprobante,
--KR 22-09-21 Cambie el or por el and.....si no es ninguno de esos conceptos entonces es asistencial
                     CASE WHEN unmovimiento.barra <> 32 AND (ctacte.idconcepto <> 360 AND ctacte.idconcepto <> 372)  THEN 387 ELSE ctacte.idconcepto END as idconcepto
                     ,ctacte.nrodoc,idcentrodeuda
          --  FROM cuentacorrientedeuda as ctacte
              FROM  (SELECT iddeuda, idcomprobantetipos,  tipodoc, idctacte, fechamovimiento, movconcepto, nrocuentac, saldo, idcomprobante, idconcepto, nrodoc, idcentrodeuda
                       FROM cuentacorrientedeuda 
                     UNION 
                     SELECT iddeuda, idcomprobantetipos, 1 as tipodoc, concat(nrocliente,barra) as idctacte, fechamovimiento, movconcepto, ccdc.nrocuentac, saldo, idcomprobante, m.nroconcepto idconcepto, nrocliente as nrodoc, idcentrodeuda
--KR 21-07-22 modifico, antes estaba hardcodeado el concepto 387, supongo era lo unico hablado que podian usar los adherentes pero este mes zaia uso turismo, asi que ve se abrio esa opcion
                     FROM ctactedeudacliente ccdc natural join clientectacte join (SELECT  nrocuentac, min(nroconcepto)nroconcepto from mapeocuentascontablesconcepto GROUP BY nrocuentac) m on m.nrocuentac =ccdc.nrocuentac 
                     WHERE cccdtohaberes) AS ctacte
                     LEFT JOIN enviodescontarctactev2 as e ON e.idmovimiento = iddeuda AND e.idcentromovimiento = idcentrodeuda AND e.fechaenvio = vfechaenvio
                     WHERE iddeuda = unmovimiento.iddeuda AND idcentrodeuda = unmovimiento.idcentrodeuda AND nullvalue(e.idenviodescontarctacte)
                 ) ;

       

     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;

RETURN TRUE;
END;$function$
