CREATE OR REPLACE FUNCTION public.conciliacionbancaria_conciliarcuentacontable(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE
      casiento refcursor;
      ritemasiento record;
      rpopc record;
      ritemconciliacion record;
      actualizar boolean;
      elidliqtarjeta varchar;


BEGIN

      perform asientogenerico_mayordecuenta_contemporal($1);
      CREATE TEMP TABLE temp_asientogenerico_mayordecuenta_contemporal_aux
             AS (  SELECT split_part(elidsiges,'|',1) as elidcomprobante ,
                   split_part(elidsiges,'|',2) as elidcentrocomprobante , *
             FROM temp_asientogenerico_mayordecuenta_contemporal );
   ALTER TABLE temp_asientogenerico_mayordecuenta_contemporal_aux ADD COLUMN idconciliacionbancariaitem varchar, ADD COLUMN montoconciliado double precision, ADD COLUMN cbifechaingreso date;
   
      OPEN casiento FOR SELECT * FROM  temp_asientogenerico_mayordecuenta_contemporal_aux;
      
     /* ALTER TABLE temp_asientogenerico_mayordecuenta_contemporal ADD COLUMN montoconciliado double precision ;
      ALTER TABLE temp_asientogenerico_mayordecuenta_contemporal ADD COLUMN cbifechaingreso date ;
*/
      FETCH  casiento INTO ritemasiento;
      WHILE FOUND LOOP
                            
                       actualizar = false;
                       IF(ritemasiento.idasientogenericocomprobtipo = 1 ) THEN -- ordenpagocontable
                            SELECT INTO ritemconciliacion *
                            FROM conciliacionbancariaitem
                            NATURAL JOIN conciliacionbancaria
                            JOIN cuentabancariasosunc using (idcuentabancaria)
                            JOIN (
                                 SELECT concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|','idcentropagoordenpagocontable=',idcentroordenpagocontable) as elcomprobante
                                 FROM pagoordenpagocontable
                                 WHERE idordenpagocontable = ritemasiento.elidcomprobante
                                       AND idcentroordenpagocontable = ritemasiento.elidcentrocomprobante
                            ) AS temp ON (elcomprobante = cbiclavecompsiges)
                            WHERE cbitablacomp ilike '%pagoordenpagocontable%'
                                  AND cuentabancariasosunc.nrocuentac = ritemasiento.CodCuenta;
                            IF FOUND THEN
                                  actualizar = true;
                                 
                            END IF;
                       END IF;
                       IF(ritemasiento.idasientogenericocomprobtipo = 4) THEN -- ordenpago

                                      SELECT INTO ritemconciliacion *
                                      FROM conciliacionbancariaitem
                                      NATURAL JOIN conciliacionbancaria
                                      JOIN cuentabancariasosunc using (idcuentabancaria)
                                      JOIN (
                                           SELECT concat('nroordenpago=',nroordenpago,'|','idcentroordenpago=',idcentroordenpago) as elcomprobante
                                           FROM ordenpago 
                                           WHERE nroordenpago = ritemasiento.elidcomprobante
                                                 AND idcentroordenpago = ritemasiento.elidcentrocomprobante
                                      ) AS temp ON (elcomprobante = cbiclavecompsiges)
                                      WHERE cbitablacomp ilike '%ordenpago%'
                                            AND cuentabancariasosunc.nrocuentac = ritemasiento.CodCuenta;
                                      IF FOUND THEN
                                               actualizar = true;

                                      END IF;
                                      
                                      IF not actualizar THEN -- Este if debe desaparecer ya que las liq de tarjeta se van a conciliar como minuta
                                      elidliqtarjeta = btrim(split_part(split_part( split_part(ritemasiento.leyenda,'|', 2),'Liq Tarjeta',2   ) ,'(',1),' ');
                                      if (elidliqtarjeta <>'') THEN
                                                         SELECT INTO ritemconciliacion *
                                                         FROM conciliacionbancariaitem
                                                         NATURAL JOIN conciliacionbancaria
                                                         JOIN cuentabancariasosunc using (idcuentabancaria)
                                                         JOIN (
                                                              SELECT concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|','idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta) as elcomprobante
                                                              FROM liquidaciontarjeta
                                                              WHERE idliquidaciontarjeta = elidliqtarjeta
                                                                    AND idcentroliquidaciontarjeta = 1
                                                         ) AS temp ON (elcomprobante = cbiclavecompsiges)
                                                         WHERE cbitablacomp ilike '%liquidaciontarjeta%'
                                                               AND cuentabancariasosunc.nrocuentac = ritemasiento.CodCuenta;
                                                         IF FOUND THEN
                                                            actualizar = true;
                                                         END IF;
                                        END IF;
                                        END IF;
                       END IF;
                            
                            
                       IF actualizar THEN
                               UPDATE temp_asientogenerico_mayordecuenta_contemporal_aux
                               SET idconciliacionbancariaitem =concat(ritemconciliacion.idconciliacionbancariaitem::varchar ,'|',ritemconciliacion.idcentroconciliacionbancariaitem::varchar)
                                       ,montoconciliado = ritemconciliacion.cbiimporte
                                       ,cbifechaingreso = ritemconciliacion.cbifechaingreso::date
                               WHERE idAsiento = ritemasiento.idAsiento;
                       END IF;
/*

                             SELECT INTO rpopc concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|','idcentroordenpagocontable=',idcentroordenpagocontable) as elcomprobante
                             FROM pagoordenpagocontable
                             WHERE idordenpagocontable = ritemasiento.idordenpagocontable
                                   AND idcentroordenpagocontable = ritemasiento.idcentroordenpagocontable
                                   AND popmonto = ritemasiento.acimonto;

*/
                       

        FETCH  casiento INTO ritemasiento;
     END LOOP;
     CLOSE casiento;


    return 2;
END;
$function$
