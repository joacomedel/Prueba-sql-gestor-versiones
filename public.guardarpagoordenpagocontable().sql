CREATE OR REPLACE FUNCTION public.guardarpagoordenpagocontable()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rordenpagocontable record;
       rchequera record;
       ctempagoordenpago refcursor;
       runpago record;
       elidordenpagocontable  bigint;
       elidcentroordenpagocontable integer;
       elidpagoordenpagocontable bigint;
       elidcheque bigint;
       elidcentrocheque integer;
       resultado boolean;
       resp boolean;
       xobs varchar;
       robs RECORD;
       descriptpago varchar;
       infofechas varchar;
       rlaminuta RECORD;
       ropreintegro RECORD;
       datoaux record;
       robsaux record;
       rvcop record;
BEGIN
     --- Recupero informacion de la orden de pago
     SELECT INTO rordenpagocontable * FROM tempordenpagocontable ;
     
     SELECT INTO elidordenpagocontable split_part(rordenpagocontable.claveordenpagocontable, '-',1);
     SELECT INTO elidcentroordenpagocontable split_part(rordenpagocontable.claveordenpagocontable, '-',2);
     
     --- Cambio el estado a la OPC Pagada
     SELECT INTO resp cambiarestadoordenpagocontable(elidordenpagocontable, elidcentroordenpagocontable, 2, 'Generado automaticamente guardarpagoordenpagocontable') ;
     
     -- Actualizo la informacion de los datos del pago
     UPDATE ordenpagocontable
     SET idprestador = rordenpagocontable.idprestador ,
         opcmontocontadootra = rordenpagocontable.opcmontocontadootra,
         opcmontochequeprop = rordenpagocontable.opcmontochequeprop,
         opcmontochequetercero = rordenpagocontable.opcmontochequetercero,
         opcobservacion = rordenpagocontable.opcobservacion
         --opcfechaingreso  = rordenpagocontable.opcfechaingreso
     WHERE idcentroordenpagocontable = elidcentroordenpagocontable
          and  idordenpagocontable = elidordenpagocontable ;

     if existecolumtemp('tempordenpagocontable','opcfechaingreso') THEN
                 UPDATE ordenpagocontable    SET opcfechaingreso  = rordenpagocontable.opcfechaingreso
                 WHERE idcentroordenpagocontable = elidcentroordenpagocontable
                        and  idordenpagocontable = elidordenpagocontable ;
     END IF;

     OPEN ctempagoordenpago FOR  SELECT * FROM temppagoordenpagocontable ;
     FETCH ctempagoordenpago into runpago;
     WHILE FOUND LOOP
           elidcheque = 0;
           
            -- Ingreso la informacion del pago
            INSERT INTO pagoordenpagocontable
            (idordenpagocontable, idcentroordenpagocontable, popmonto, popobservacion,idvalorescaja)
            VALUES(elidordenpagocontable,elidcentroordenpagocontable,runpago.monto ,runpago.observacion ,runpago.idvalorescaja  );

            elidpagoordenpagocontable =  currval('public.pagoordenpagocontable_idpagoordenpagocontable_seq');

           
           IF (runpago.tipo like 'CT/TRANS' and not nullvalue(runpago.idcuentabancaria)  ) THEN  -- Pago contado o transferencia
                 
                 UPDATE pagoordenpagocontable
                 SET idcuentabancaria = runpago.idcuentabancaria
                 WHERE idpagoordenpagocontable = elidpagoordenpagocontable and idcentropagoordenpagocontable = centro();
            END IF;
            IF runpago.tipo like 'CHPROP' THEN -- pago con cheques propios
                 -- Tengo que crear el nuevo cheque
                 -- Recupero la informacion de la chequera
                 SELECT INTO rchequera *
                 FROM chequera
                 JOIN cuentabancariasosunc USING (idcuentabancaria)
                 JOIN valorescaja ON (idvalorescajacuentab = idvalorescaja)
                 WHERE chnumero = runpago.idchequera;
                 
                 --- Creo el cheque
                 INSERT INTO cheque (cdenominacion, cnumero,cmonto,cfechaconfeccion,cfechacobro, idcuentabancaria,chnumero)
                 VALUES('S.O.S.U.N.C',
--KR 07-03-22 CAMBIO debido al tkt Nro. 4892
                  CASE WHEN nullvalue(rchequera.chnumerochequesig) THEN runpago.nrochequebanca ELSE rchequera.chnumerochequesig END
                  ,runpago.monto,runpago.fechaemision::date,runpago.fechacobro ::date,runpago.idcuentabancaria, runpago.idchequera );
                 elidcheque = currval('cheque_idcheque_seq');
                 elidcentrocheque = centro();
                 
                 -- actualizo el siguiente cheque
                 UPDATE chequera SET chnumerochequesig = chnumerochequesig +1
                 WHERE chnumero = runpago.idchequera 
              --KR 07-03-22 CAMBIO debido al tkt Nro. 4892 
                 and not nullvalue(chnumerochequesig);
                 
                IF(rchequera.idchequeratipo = 1 ) THEN  --idchequeratipo= 1 Continuo
                            infofechas = concat(' F.Emision:',runpago.fechaemision);
                END IF;
                IF(rchequera.idchequeratipo = 2 )THEN --  	idchequeratipo= 2 Diferido ///
                            infofechas = concat(' F.Emision:',runpago.fechaemision,' F.Cobro:',runpago.fechacobro);
                END IF;
               
                 -- Descripcion del pago en cheque
                descriptpago = concat('#',rchequera.descripcion,' CH:',
                --KR 07-03-22 CAMBIO debido al tkt Nro. 4892 
               CASE WHEN nullvalue(rchequera.chnumerochequesig) THEN runpago.nrochequebanca ELSE rchequera.chnumerochequesig END::varchar,
               ', Chra:',rchequera.chnumero,infofechas);

            END IF;
            IF  ( runpago.tipo like 'CHTERC' ) THEN   
                   SELECT INTO descriptpago concat('CH',': ',cnumero,' ', nombrebanco)
                   FROM  cheque 
                   NATURAL JOIN banco 
                   WHERE idcheque = runpago.idcheque and idcentrocheque = runpago.idcentrocheque;
            END IF;
	    IF  ( runpago.tipo like 'CHPROPE' ) THEN  
                  descriptpago = runpago.observacion;
            END IF;
            IF  ( runpago.tipo like 'CHPROP' or runpago.tipo like 'CHPROPE'  or runpago.tipo like 'CHTERC' ) THEN
                    --- tengo que guardar la vinvulacion entre el cheque y la orden de pago contable
                    -- actualizar la info del pago
                    if (elidcheque=0) THEN elidcheque =runpago.idcheque; elidcentrocheque = runpago.idcentrocheque; END IF;
                    UPDATE pagoordenpagocontable
                    SET idcentrocheque = elidcentrocheque , idcheque =elidcheque , popobservacion = descriptpago
                    WHERE idpagoordenpagocontable = elidpagoordenpagocontable and idcentropagoordenpagocontable = centro();
SELECT INTO rlaminuta  (MIN(importetotal) - SUM(popmonto)) as diferencia,  nroordenpago, idcentroordenpago
                  FROM ordenpagocontableordenpago JOIN pagoordenpagocontable using(idordenpagocontable,idcentroordenpagocontable)
                  JOIN ordenpago using (nroordenpago,idcentroordenpago) JOIN ordenpagocontableestado using (idordenpagocontable,idcentroordenpagocontable)
                  WHERE nullvalue(opcfechafin) AND idordenpagocontableestadotipo <> 7 AND idordenpagocontable = elidordenpagocontable  AND idcentroordenpagocontable = elidcentroordenpagocontable
                  GROUP BY nroordenpago,idcentroordenpago;
      IF (rlaminuta.diferencia <1) THEN
                    --KR 26-03-18 todas las OPC pagadas con CH pasan al estado ASENTADA, ya están pagas
	  SELECT INTO resp  cambiarestadoordenpago(rlaminuta.nroordenpago::bigint,rlaminuta.idcentroordenpago,3,'Generado automaticamente guardarpagoordenpagocontable. ');
    end if;
                    SELECT INTO resp  cambiarestadoordenpagocontable(elidordenpagocontable::bigint,elidcentroordenpagocontable::integer, 7, 'Generado desde SP guardarpagoordenpagocontable') ;

                    SELECT INTO resp cambiarestadocheque(runpago.idcheque ,runpago.idcentrocheque,1,'Desde SP guardarpagoordenpagocontable ');

            END IF;
            --KR 14-10-22 TKT 5323
            SELECT INTO rvcop * FROM opvcasentada WHERE idvalorescaja = runpago.idvalorescaja AND nullvalue(opvcafechafin);
            IF FOUND THEN 
                 SELECT INTO resp  cambiarestadoordenpagocontable(elidordenpagocontable::bigint,elidcentroordenpagocontable::integer, 7, 'Generado desde SP guardarpagoordenpagocontable') ;
            END IF;

            FETCH ctempagoordenpago into runpago;
     END LOOP;
     close ctempagoordenpago;
   
     SELECT INTO ropreintegro * 
         FROM ordenpagocontablereintegro 
          WHERE idcentroordenpagocontable = elidcentroordenpagocontable
          and  idordenpagocontable = elidordenpagocontable ;
--KR 21-03-18 Si es una OP de reintegro no guardo el movimiento es la tabla ctacteprestador
     IF NOT FOUND AND (not nullvalue(rordenpagocontable.idprestador) ) THEN

--Analizar si el prestador es sosunc si se debe guardar el movimiento en la ctacte del prestador. 
    -- if (not nullvalue(rordenpagocontable.idprestador) )THEN
              
          -- Se guarda la info del pago de retenciones
          -- VAS 16-9 OJO!!!! no se esta mandando la clave completa de la OPC !!!!!
          select into resultado * from guardarretencionordenpagocontable(elidordenpagocontable);

          -- Se registran los pagos en la ctacte del prestador
          select into resultado * from generarpagoctacte(concat(elidordenpagocontable,'-',elidcentroordenpagocontable));
     END IF;

-----------------------------------------------------------------
-- CS 2017-05-04 Agrega Asiento Generico
-----------------------------------------------------------------

IF (not iftableexistsparasp('tasientogenerico') ) THEN 
                 RAISE NOTICE '>>>>>>>>entro por el sino existe tasientogenerico de guardarpagoordenpagocontable';
                 CREATE TEMP TABLE tasientogenerico (
		                idoperacion bigint,
		                idcentroperacion integer DEFAULT centro(),
		                operacion varchar,
		                fechaimputa date,
		                obs varchar,
		                centrocosto int,
                        idasientogenericocomprobtipo integer DEFAULT 1
                 )WITHOUT OIDS;
ELSE 
     DELETE FROM tasientogenerico;
END IF;
select into robs concat('O/P ',idcentroordenpagocontable,'-',idordenpagocontable,
                        case when (idprestador=2608 OR nullvalue(rordenpagocontable.idprestador)) then ': ' else concat(': ',pdescripcion,' (P.',idprestador,') - ') end,
                        ' | ',opcobservacion) as obs,opcfechaingreso
                 from ordenpagocontable
                 natural join prestador
                 where idordenpagocontable=elidordenpagocontable and idcentroordenpagocontable=elidcentroordenpagocontable;
select into robsaux concat('O/P ',idcentroordenpagocontable,'-',idordenpagocontable) as obs,opcfechaingreso
                 from ordenpagocontable
                 --natural join prestador
                 where idordenpagocontable=elidordenpagocontable and idcentroordenpagocontable=elidcentroordenpagocontable;

RAISE NOTICE '>>>>>>>>inserta en robsaux de gopc % %',robsaux.obs,robsaux.opcfechaingreso;              
INSERT INTO tasientogenerico(idasientogenericocomprobtipo,idoperacion,operacion,fechaimputa,obs,centrocosto) 
              VALUES(1,elidordenpagocontable*100+elidcentroordenpagocontable,'pago',robs.opcfechaingreso,  robs.obs, centro());
select into datoaux * from tasientogenerico;
 

RAISE NOTICE '>>>>>>>>inserta en tasientogenerico de gopc %',datoaux;

PERFORM asientogenerico_crear();
 
-----------------------------------------------------------------------------------

     --KR 09-03-18 cambio el estado a la orden 3 liquidado si la suma de todos los pagos de la minuta coindice con el  importe total de la minuta
	 
      SELECT INTO rlaminuta  (MIN(importetotal) - SUM(popmonto)) as diferencia,  nroordenpago, idcentroordenpago
                  FROM ordenpagocontableordenpago JOIN pagoordenpagocontable using(idordenpagocontable,idcentroordenpagocontable)
                  JOIN ordenpago using (nroordenpago,idcentroordenpago) JOIN ordenpagocontableestado using (idordenpagocontable,idcentroordenpagocontable)
                  WHERE nullvalue(opcfechafin) AND idordenpagocontableestadotipo <> 7 AND idordenpagocontable = elidordenpagocontable  AND idcentroordenpagocontable = elidcentroordenpagocontable
                  GROUP BY nroordenpago,idcentroordenpago;
      IF (rlaminuta.diferencia <1) THEN
           	  SELECT INTO resp  cambiarestadoordenpago(rlaminuta.nroordenpago::bigint,rlaminuta.idcentroordenpago,3,'Generado automaticamente guardarpagoordenpagocontable. ');
      END IF;  

  
     RETURN concat(elidpagoordenpagocontable,'|',centro());
END;
$function$
