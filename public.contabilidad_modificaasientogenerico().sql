CREATE OR REPLACE FUNCTION public.contabilidad_modificaasientogenerico()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        c_cursor refcursor;
registro_asientogenerico refcursor;

        r_cursor record;
	rverificaopc record;
        rinfooperacion record;
        datoretencion record;
        resp boolean;
BEGIN

/*
CREATE TEMP TABLE temp_contabilidad_modificaasientogenerico AS (
SELECT idordenpagocontable,idcentroordenpagocontable,tipoestadofactura,opcfechaingreso,idasientogenerico
FROM ordenpagocontablebancatransferencia
NATURAL JOIN bancatransferencia
NATURAL JOIN bancaoperacion
NATURAL JOIN pagoordenpagocontable
NATURAL JOIN ordenpagocontable
JOIN asientogenerico ON  idcomprobantesiges = concat(idordenpagocontable,'|',idcentroordenpagocontable)
NATURAL JOIN asientogenericoestado
WHERE opcfechaingreso <> bofechapago AND nullvalue(agefechafin) AND  tipoestadofactura = 1
GROUP BY idordenpagocontable,idcentroordenpagocontable,tipoestadofactura,opcfechaingreso,idasientogenerico
ORDER BY opcfechaingreso DESC
);

SELECT * FROM contabilidad_modificaasientogenerico();


*/
     --- busco todas las trnasferencias que no fueron procesadas

     OPEN c_cursor FOR  SELECT * FROM temp_contabilidad_modificaasientogenerico;
     FETCH c_cursor into r_cursor;
     WHILE FOUND LOOP

          -- Busco el asiento generico 
          SELECT INTO registro_asientogenerico * FROM asientogenerico WHERE idasientogenerico = 176285 and idcentroasientogenerico = 1 and idasientogenericocomprobtipo = 4  and agdescripcion ilike '%REVERSION%';
          IF FOUND THEN 
                    UPDATE asientogenerico SET agfechacontable = r_cursor.opcfechaingreso
                    WHERE idasientogenerico = r_cursor.idasientogenerico   and idcentroasientogenerico = 1 and idasientogenericocomprobtipo = 4  and agdescripcion ilike '%REVERSION%';

          ELSE 

	--MaLaPi 20-02-2018 Verifico el estado de la OPC
	SELECT INTO rverificaopc * FROM ordenpagocontableestado 
               WHERE idordenpagocontable = r_cursor.idordenpagocontable 
			AND idcentroordenpagocontable = r_cursor.idcentroordenpagocontable
			AND nullvalue(opcfechafin) AND idordenpagocontableestadotipo = 8;
	--Si el estado es Sincronizada no la puedo tocar
	IF NOT FOUND THEN 
		SELECT INTO rinfooperacion * FROM ordenpagocontablebancatransferencia 
				 NATURAL JOIN bancatransferencia
				 NATURAL JOIN bancaoperacion
				 NATURAL JOIN ordenpagocontable
                                 NATURAL JOIN pagoordenpagocontable 
				 WHERE idordenpagocontable = r_cursor.idordenpagocontable 
					AND idcentroordenpagocontable = r_cursor.idcentroordenpagocontable
				LIMIT 1;
		IF FOUND THEN 
                    IF rinfooperacion.opcfechaingreso <> rinfooperacion.bofechapago THEN
			UPDATE pagoordenpagocontable
			SET popobservacion = concat(popobservacion
                                             , E'\n', 'Se Modifico la fecha de pago usando informacion de la banca.' ,' Fecha Pago :',rinfooperacion.bofechapago
                                             , ' Fecha Anterior: ',   rinfooperacion.opcfechaingreso
                                              )
			WHERE idpagoordenpagocontable = rinfooperacion.idpagoordenpagocontable
                            and idcentropagoordenpagocontable = rinfooperacion.idcentropagoordenpagocontable;

			UPDATE ordenpagocontable
				SET opcfechaingreso = rinfooperacion.bofechapago
				WHERE idordenpagocontable = rinfooperacion.idordenpagocontable
					and idcentroordenpagocontable =
                                        rinfooperacion.idcentroordenpagocontable;
                        --VAS 27-06-2019 actualizo la fecha del movimiento en la ctacteprestador
                        
                        UPDATE ctactepagoprestador SET fechacomprobante = rinfooperacion.bofechapago
                        WHERE ctactepagoprestador.idcomprobante = rinfooperacion.idordenpagocontable*10+rinfooperacion.idcentroordenpagocontable  
                              and idcomprobantetipos=40;

   
 /*Agrego Dani 2019-01-11 para q cuando modifica la fecha de la OPC tmb modifique la de la retencion si es q la tiene*/
                        SELECT into datoretencion * FROM ordenpagocontable
                                                         left join retencionprestador
                            on(retencionprestador.idordenpagocontable=ordenpagocontable.idordenpagocontable
                            and 
         retencionprestador.idcentroordenpagocontable=ordenpagocontable.idcentroordenpagocontable )
         WHERE ordenpagocontable.idordenpagocontable = rinfooperacion.idordenpagocontable
	 and ordenpagocontable.idcentroordenpagocontable =rinfooperacion.idcentroordenpagocontable
         and not nullvalue(retencionprestador.idretencionprestador);

                         IF FOUND THEN 
                               UPDATE retencionprestador
                               SET rpfecha = rinfooperacion.bofechapago
			       WHERE idordenpagocontable = rinfooperacion.idordenpagocontable
                               and idcentroordenpagocontable = rinfooperacion.idcentroordenpagocontable;

                        END IF;
     /*Fin de agrego Dani 2019-01-11*/            

	UPDATE asientogenerico SET agfechacontable = rinfooperacion.bofechapago
	,agdescripcion = concat(agdescripcion
        , E'\n', 'Se Modifico la fecha de pago usando informacion de la banca.' ,' Fecha Pago :',rinfooperacion.bofechapago, ' Fecha Anterior: ',   rinfooperacion.opcfechaingreso
                                              )
	WHERE idcomprobantesiges = 
        concat(rinfooperacion.idordenpagocontable,'|',rinfooperacion.idcentroordenpagocontable);
		END IF;
	     END IF;
	END IF;
           END IF;  -- cierra el if del asiento generico
       
	FETCH c_cursor into r_cursor;
     END LOOP;
     CLOSE c_cursor;

  RETURN TRUE;
END;
$function$
