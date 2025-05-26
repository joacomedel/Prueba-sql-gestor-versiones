CREATE OR REPLACE FUNCTION public.guardarpagoordenpagocontablevaseliminar(bigint, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
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
BEGIN
     

     elidordenpagocontable = $1;
     elidcentroordenpagocontable = $2;

     --- Recupero informacion de la orden de pago
     SELECT INTO rordenpagocontable * FROM ordenpagocontable
             WHERE  idordenpagocontable = elidordenpagocontable AND  idcentroordenpagocontable= elidcentroordenpagocontable;

     --- Cambio el estado a la OPC Pagada
     SELECT INTO resp cambiarestadoordenpagocontable(elidordenpagocontable, elidcentroordenpagocontable, 2, 'Generado automaticamente guardarpagoordenpagocontable') ;

     -- Actualizo la informacion de los datos del pago
     UPDATE ordenpagocontable    SET opcfechaingreso  = '2017-10-13'
     WHERE idcentroordenpagocontable = elidcentroordenpagocontable
                  and  idordenpagocontable = elidordenpagocontable ;

     -- Ingreso la informacion del pago
      INSERT INTO pagoordenpagocontable(idordenpagocontable, idcentroordenpagocontable, popmonto, popobservacion,idvalorescaja)
            VALUES(elidordenpagocontable,elidcentroordenpagocontable,rordenpagocontable.opcmontototal ,'Credicoop (Nqn) 24917/1'	,45  );

      elidpagoordenpagocontable =  currval('public.pagoordenpagocontable_idpagoordenpagocontable_seq');


IF (not iftableexistsparasp('tasientogenerico') ) THEN

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
           select into xobs concat('O/P ',idcentroordenpagocontable,'-',idordenpagocontable,
                        case when (idprestador=2608 OR nullvalue(rordenpagocontable.idprestador)) then ': ' else concat(': ',pdescripcion,' (P.',idprestador,') - ') end,
                        ' | ',opcobservacion)
           from ordenpagocontable
                 natural join prestador
                 where idordenpagocontable=elidordenpagocontable and idcentroordenpagocontable=elidcentroordenpagocontable;
           INSERT INTO tasientogenerico(idoperacion,operacion,fechaimputa,obs,centrocosto)
           VALUES(	elidordenpagocontable*100+elidcentroordenpagocontable,'pago',now(),  xobs, centro());

PERFORM asientogenerico_crear();

-----------------------------------------------------------------------------------

     RETURN concat(elidpagoordenpagocontable,'|',centro());
END;
$function$
