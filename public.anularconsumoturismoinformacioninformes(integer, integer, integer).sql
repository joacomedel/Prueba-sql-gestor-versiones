CREATE OR REPLACE FUNCTION public.anularconsumoturismoinformacioninformes(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Se genera una tabla temporal con los datos necesarios para generar los informes de anulacion del consumo de
 * Turismo 
 * PARAMETROS $1 idconsumoturismo
 *            $2 idcentroconsumoturismo
 *            $3 nrodoc
 *            $4 barra
 *            $5 numero cuenta contable
 *            $6 importeTotal
 *            $7 tipo de factura
 *            $8 si se va a devolver el anticipo
 *
*/

DECLARE
    codconsumoturismo alias for $1;
    centroconsumoturismo alias for $2;
    devolveranticipo alias for $3; -- Se marca si se va a devolver o no el anticipo en la anulacion

    resp boolean;
    impinteres double precision;
    impcuotas double precision;
    imppagado double precision;
    ranticipo record;
    rinforme record;
    
BEGIN
   -- CREATE  TABLE ttanulacionturismoinforme
   CREATE TEMP TABLE ttanulacionturismoinforme 
                                               (idconsumoturismo BIGINT   
                                               ,idcentroconsumoturismo INTEGER
                                               ,importeintereses DOUBLE PRECISION
                                               ,importeanticipo DOUBLE PRECISION
                                               ,importerestante DOUBLE PRECISION
                                               ,importepagado DOUBLE PRECISION
                                               ,importeinteresespagado DOUBLE PRECISION
                                               ,movconceptointereses varchar
                                               ,movconceptointeresespagado varchar
                                               ,movconceptoanticipo varchar
                                               ,movconceptorestante varchar
                                               ,movconceptopagado varchar
                                               ,formapagoanticipo INTEGER
                                               
                                              );
   
   INSERT INTO ttanulacionturismoinforme (idconsumoturismo,idcentroconsumoturismo,importeinteresespagado,importeintereses,importeanticipo,importerestante,importepagado,movconceptointereses,movconceptoanticipo,movconceptorestante,movconceptopagado,movconceptointeresespagado)
                                         VALUES (codconsumoturismo,centroconsumoturismo,0,0,0,0,0,'','','','','');
   --Verifico si se trata de un consumo vendido en efectivo
   SELECT INTO rinforme * FROM informefacturacionturismo
          NATURAL JOIN informefacturacion
          NATURAL JOIN informefacturacionitem
          WHERE informefacturacion.idformapagotipos = 2
          AND idtipofactura = 'FA'
          AND idcentroconsumoturismo = centroconsumoturismo
          AND idconsumoturismo = codconsumoturismo;
   IF FOUND THEN
     UPDATE ttanulacionturismoinforme SET importepagado = rinforme.importe
                                         ,movconceptopagado =concat('Anulacion de Turismo - Conusmo ' , codconsumoturismo , '-' , centroconsumoturismo)
     WHERE  idconsumoturismo = codconsumoturismo 
     AND idcentroconsumoturismo =centroconsumoturismo;
      
   ELSE -- Se trata de un consumo vendido en ctacte

   IF devolveranticipo = 1 THEN -- Hay que generar una NC en cta cte para que le quede a favor
      --MaLaPi 19-11-2021 Modifico para que se cambie la forma de pago del informe del anticipo, teniendo en cuenta si ya se pago o no 
      SELECT INTO ranticipo cuentacorrientedeuda.*,CASE WHEN saldo > 0 THEN 3 ELSE 2 END as formapagoanticipo
             FROM   consumoturismo
             NATURAL JOIN prestamo
             NATURAL JOIN prestamocuotas
             JOIN cuentacorrientedeuda
                  ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                  AND cuentacorrientedeuda.idcomprobantetipos = 7
                  WHERE idconsumoturismo= codconsumoturismo 
                  AND nullvalue(prestamocuotas.pcborrado)
                  and idcentroconsumoturismo=centroconsumoturismo
                  AND movconcepto ilike '%Anticipo%';

             IF FOUND THEN
                  UPDATE ttanulacionturismoinforme SET importeanticipo = ranticipo.importe
                                                       ,movconceptoanticipo = concat('Anulacion de Turismo ' , ranticipo.movconcepto)
                                                       ,formapagoanticipo = ranticipo.formapagoanticipo
                  WHERE  idconsumoturismo = codconsumoturismo 
                  and idcentroconsumoturismo =centroconsumoturismo;
             END IF;
                  
      END IF; -- Se devuelve el anticipo
         --Busco lo que se pago
          SELECT INTO imppagado  sum(cuentacorrientedeuda.importe)
                                 FROM   consumoturismo
                                 NATURAL JOIN prestamo
                                 NATURAL JOIN prestamocuotas
                                 JOIN cuentacorrientedeuda
                                 ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                                  AND cuentacorrientedeuda.idcomprobantetipos = 7
                                 WHERE idconsumoturismo= codconsumoturismo 
                                       AND idcentroconsumoturismo=centroconsumoturismo
                                       AND nullvalue(prestamocuotas.pcborrado)
                                       AND  cuentacorrientedeuda.saldo = 0
                                       AND movconcepto  ilike '%Interes de%';

            IF FOUND AND NOT nullvalue(imppagado)THEN
             UPDATE ttanulacionturismoinforme SET importeinteresespagado = imppagado
                                             ,movconceptointeresespagado = 'Consumo de Turismo - Intereses Pagados'
               WHERE  idconsumoturismo = codconsumoturismo 
               AND idcentroconsumoturismo =centroconsumoturismo;
            END IF;
         
         SELECT INTO imppagado  sum(cuentacorrientedeuda.importe)
                                 FROM   consumoturismo
                                 NATURAL JOIN prestamo
                                 NATURAL JOIN prestamocuotas
                                 JOIN cuentacorrientedeuda
                                 ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                                  AND cuentacorrientedeuda.idcomprobantetipos = 7
                                 WHERE idconsumoturismo= codconsumoturismo 
                                       AND idcentroconsumoturismo=centroconsumoturismo
                                       AND  cuentacorrientedeuda.saldo = 0
                                        AND nullvalue(prestamocuotas.pcborrado)
                                        AND movconcepto ilike '%Cuota Nº%'
                                        AND movconcepto not ilike '%Interes de%';

            IF FOUND AND NOT nullvalue(imppagado)THEN
             UPDATE ttanulacionturismoinforme SET importepagado = imppagado
                                             ,movconceptopagado = 'Consumo de Turismo - Costo de Turismo Pagados'
               WHERE  idconsumoturismo = codconsumoturismo 
               AND idcentroconsumoturismo =centroconsumoturismo;
            END IF;
         
         --Busco lo que resta pagar
          SELECT INTO impinteres  sum(cuentacorrientedeuda.saldo)
                 FROM   consumoturismo
                 NATURAL JOIN prestamo
                 NATURAL JOIN prestamocuotas
                 JOIN cuentacorrientedeuda
                 ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                 AND cuentacorrientedeuda.idcomprobantetipos = 7
                     WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo
                      AND nullvalue(prestamocuotas.pcborrado)
                      AND  cuentacorrientedeuda.saldo > 0 AND cuentacorrientedeuda.movconcepto ilike '%Interes de Cuota%';

          IF FOUND AND NOT nullvalue(impinteres) THEN
             UPDATE ttanulacionturismoinforme SET importeintereses = impinteres
                                           ,movconceptointereses = 'Anulacion de Turismo - Intereses'
             WHERE  idconsumoturismo = codconsumoturismo 
             AND idcentroconsumoturismo =centroconsumoturismo;
          END IF;

           SELECT INTO impcuotas  sum(cuentacorrientedeuda.saldo)
                                 FROM   consumoturismo
                                 NATURAL JOIN prestamo
                                 NATURAL JOIN prestamocuotas
                                 JOIN cuentacorrientedeuda
                                 ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                                  AND cuentacorrientedeuda.idcomprobantetipos = 7
                                   WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo
                                         AND  cuentacorrientedeuda.saldo > 0
                                         AND nullvalue(prestamocuotas.pcborrado)
                                         AND movconcepto ilike '%Cuota Nº%'
                                         AND movconcepto not ilike '%Interes de%';

            IF FOUND AND NOT nullvalue(impcuotas)THEN
             UPDATE ttanulacionturismoinforme SET importerestante = impcuotas
                                             ,movconceptorestante = 'Consumo de Turismo - Costo'
               WHERE  idconsumoturismo = codconsumoturismo 
               AND idcentroconsumoturismo =centroconsumoturismo; 
            END IF;
      END IF; -- Se trata de un consumo vendido en ctacte          

return 'true';
END;
$function$
