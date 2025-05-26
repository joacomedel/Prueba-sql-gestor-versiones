CREATE OR REPLACE FUNCTION public.bancatransferenciaprocesar()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       c_sinprocesar refcursor;
       r_sinprocesar record;
rasientorevertir record;
       elidpagoordenpagocontable bigint;
       elidcentropagoordenpagocontable integer;
       resp boolean;
       xidasiento_new bigint;
respminuta  	character varying;

BEGIN
     --- busco todas las trnasferencias que no fueron procesadas

     OPEN c_sinprocesar FOR  SELECT      
                                 to_number( split_part(bancatransferencia.elidpagoordenpagocontable, '-', 1),9999999999)as celidcentropagoordenpagocontable
                               , to_number(split_part(bancatransferencia.elidpagoordenpagocontable, '-', 2),9999999999) as celidpagoordenpagocontable
                               ,to_number(split_part(split_part(btobservacion, '*#*',3),'-',2),9999999999)  as elidordenpagocontable
                               , to_number(split_part(split_part(btobservacion, '*#*',3),'-',1) ,9999999999) as elidcentroordenpagocontable
                               ,*
                             FROM bancatransferencia
                             NATURAL JOIN bancaoperacion
                             WHERE nullvalue(btprocesado) --and idbancatransferencia = 32972
                                   and btobservacion ilike '%*#*%'; -- me aseguro que solo va a tomar las que se generen desde el modulo de tesoreria

  
     FETCH c_sinprocesar into r_sinprocesar;
     WHILE FOUND LOOP
                    -- cargo la info del pago en pagoordenpagocontable
                     elidpagoordenpagocontable = r_sinprocesar.celidpagoordenpagocontable;
                     elidcentropagoordenpagocontable = r_sinprocesar.celidcentropagoordenpagocontable;
                     SELECT INTO resp  cambiarestadoordenpagocontable(r_sinprocesar.elidordenpagocontable::bigint,
                                    r_sinprocesar.elidcentroordenpagocontable::integer, 7, 'Generado desde SP bancatransferenciaprocesar') ;
                     UPDATE pagoordenpagocontable
                     SET popobservacion = concat(popobservacion
                                             , E'\n', '--INFO BANCA--' ,' Fecha Pago :',r_sinprocesar.bofechapago
                                             , ' CBU: ',   r_sinprocesar.btcbuctadestino
                                             , ' NroOp.: ',   r_sinprocesar.bonrooperacion   
                                             ,' Estado: ', r_sinprocesar.btestado ,'--INFO BANCA-- \n' )
                     WHERE idpagoordenpagocontable = elidpagoordenpagocontable
                            and idcentropagoordenpagocontable = elidcentropagoordenpagocontable;
                    
-- CS 2018-11-12 para permitir volver a registrar una misma transferencia manual, luego por ej. de un cambio en la OPC
            /* comento 30919 se elimina y luego se vuelve a insertar
                    DELETE from ordenpagocontablebancatransferencia
                    where idpagoordenpagocontable=elidpagoordenpagocontable and
                          idcentropagoordenpagocontable=elidcentropagoordenpagocontable and idbancatransferencia=r_sinprocesar.idbancatransferencia; 
                           comento 30919 se elimina y luego se vuelve a insertar  */
----------------------------------------------------------------------------------------------------------------------
                    INSERT INTO ordenpagocontablebancatransferencia
                              (idpagoordenpagocontable,idcentropagoordenpagocontable,idbancatransferencia)
                              VALUES (elidpagoordenpagocontable,elidcentropagoordenpagocontable,r_sinprocesar.idbancatransferencia);
 
 
                     UPDATE bancatransferencia SET btprocesado = now()
                     WHERE idbancatransferencia = r_sinprocesar.idbancatransferencia;
             IF(r_sinprocesar.btestado ilike '%Rechazada%') THEN 
                          If (not iftableexistsparasp('tempcomprobante') ) THEN	
                           CREATE TEMP TABLE tempcomprobante (
                                 idordenpagocontable bigint,
		                 idcentroordenpagocontable integer 
                            );
                           END IF;
                           INSERT INTO tempcomprobante(idordenpagocontable,idcentroordenpagocontable) VALUES(r_sinprocesar.elidordenpagocontable::bigint,r_sinprocesar.elidcentroordenpagocontable::integer);
                             SELECT INTO respminuta anularordenpagocontable( );   
                          /* 21-06-2022 no se genera mas la contabilidad directamente, se anula la opc y luego se debe volver a generar
                             SELECT INTO rasientorevertir  (tasiento.idasientogenerico*100+tasiento.idcentroasientogenerico) as idasientorevertir ,*
                             FROM asientogenerico as tasiento
                             LEFT JOIN asientogenerico as tasiento_rev ON(tasiento_rev.idasientogenericorevertido = tasiento.idasientogenerico 
                                                  and  tasiento_rev.idcentroasientogenericorevertido = tasiento.idcentroasientogenerico )
                             WHERE tasiento.idcomprobantesiges =  concat(r_sinprocesar.elidordenpagocontable  ,'|',r_sinprocesar.elidcentroordenpagocontable) 
                                    and tasiento.idasientogenericocomprobtipo =  1
                                    and nullvalue(tasiento.idcentroasientogenericorevertido) 
                                    and nullvalue(tasiento.idasientogenericorevertido)
                                    and nullvalue( tasiento_rev.idasientogenericorevertido);


                             IF FOUND THEN  -- si encuentro el asiento vigente del comprobante lo revierto
                                      
                                       select into xidasiento_new asientogenerico_revertir(rasientorevertir.idasientorevertir);
                                       IF FOUND THEN
                                             UPDATE asientogenerico 
                                             SET agdescripcion = replace(agdescripcion, 'REVERSION', 'REVERSION rechazo transferencia: ') 
                                                                                          
                                             WHERE  idasientogenerico = ((xidasiento_new)/100  )
                                                    and  idcentroasientogenerico = ((xidasiento_new)%100);


                                       END IF; 

                                   --  se deberia regenerar el asiento de la opc xq ahora si se proceso correctamente la transferencia

                             END IF;
                           */
                      END IF; 
                      IF(r_sinprocesar.btestado ilike '%Aceptada%') THEN 
                             -- Verifico que la OPC tenga como asiento vigente una reversión  para generar el nuevo asiento que representa la aceptacion de la operacion
                          /*21-06-2022 no se genera mas la contabilidad directamente, se anula la opc y luego se debe volver a generar
                             SELECT INTO rasientorevertir  (tasiento.idasientogenerico*100+tasiento.idcentroasientogenerico) as idasientorevertir ,*
                             FROM asientogenerico as tasiento
                             LEFT JOIN asientogenerico as tasiento_rev ON(tasiento_rev.idasientogenericorevertido = tasiento.idasientogenerico 
                                                  and  tasiento_rev.idcentroasientogenericorevertido = tasiento.idcentroasientogenerico )
                             WHERE tasiento.idcomprobantesiges =  concat(r_sinprocesar.elidordenpagocontable ,'|',r_sinprocesar.elidcentroordenpagocontable) 
                                     and tasiento.idasientogenericocomprobtipo =  1
                                   and nullvalue(tasiento_rev.idcentroasientogenericorevertido) 
                                    and nullvalue(tasiento_rev.idasientogenericorevertido)
                                    and not nullvalue( tasiento_rev.idasientogenerico);

                                     
                              IF FOUND THEN  -- si encuentro el asiento vigente del comprobante que se corresponde con una reversion vuelvo a generar el asiento de la opc 
                                       
                                       SELECT INTO xidasiento_new asientogenerico_regenerar(rasientorevertir.idcomprobantesiges,1);
                                       IF FOUND THEN
                                             UPDATE asientogenerico 
                                             SET agdescripcion = concat('Transf. Aceptada: ',agdescripcion )
                                                  , agfechacontable = r_sinprocesar.bofechapago       
                                             WHERE  idasientogenerico = (xidasiento_new)/100  
                                                    and  idcentroasientogenerico = (xidasiento_new)%100;


                                       END IF; 
 

                              END IF;
                     */
                     END IF; 
                         
                 
                    FETCH c_sinprocesar into r_sinprocesar;
     END LOOP;
     CLOSE c_sinprocesar;

     ------MaLaPi 22-02-2018 Agrego para que se modifiquen las fechas de los pagos segun las fechas de las transferencias.
     CREATE TEMP TABLE temp_contabilidad_modificaasientogenerico AS (
            SELECT idordenpagocontable,idcentroordenpagocontable,tipoestadofactura,opcfechaingreso,idasientogenerico
            FROM ordenpagocontablebancatransferencia
            NATURAL JOIN bancatransferencia
            NATURAL JOIN bancaoperacion
            NATURAL JOIN pagoordenpagocontable
            NATURAL JOIN ordenpagocontable
            JOIN asientogenerico ON ( idcomprobantesiges = concat(idordenpagocontable,'|',idcentroordenpagocontable) AND   idasientogenericocomprobtipo =  1)
            NATURAL JOIN asientogenericoestado
            WHERE opcfechaingreso <> bofechapago AND nullvalue(agefechafin) AND  tipoestadofactura = 1
                  AND btprocesado = CURRENT_DATE
            GROUP BY idordenpagocontable,idcentroordenpagocontable,tipoestadofactura,opcfechaingreso,idasientogenerico
            ORDER BY opcfechaingreso DESC
     );
     SELECT INTO resp * FROM contabilidad_modificaasientogenerico();


  RETURN TRUE;
END;
$function$
