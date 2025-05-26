CREATE OR REPLACE FUNCTION public.anularminutapago(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD 
	rlaminuta RECORD; 
        restadominuta RECORD;
        rtieneopc RECORD;
--VARIABLES  
	respuesta BOOLEAN;
	rtaspestadominuta BOOLEAN; 
BEGIN
	respuesta = true;
        SELECT INTO rlaminuta * FROM ordenpago WHERE nroordenpago= $1 AND idcentroordenpago = $2;
        --VAS 020223 si la minuta esta viculada con comprobantes se marcan como desvinculados
        UPDATE reclibrofactordenpago  SET rlopdesvinculado = now() WHERE nroordenpago= $1 AND idcentroordenpago = $2 ;
        --VAS 020223


--KR 30-08-22 si la MP tiene una OPC vinculada no anulada no permito la anulacion
        SELECT INTO rtieneopc * FROM  ordenpagocontableordenpago NATURAL JOIN  ordenpagocontableestado
          WHERE nroordenpago= $1 AND idcentroordenpago = $2 AND nullvalue(opcfechafin) and idordenpagocontableestadotipo<>6 ;
        IF FOUND THEN 
           RAISE EXCEPTION 'No es posible anular el comprobante, se encuentra vinculado a una OPC activa !!!  ' USING HINT = 'Informar al Sector de Tesoreria.'; 
        ELSE 
               --si es cualquier otra minuta por ahora se revierten los asientos y se anular las MP 
		--revierto los asientos contables 
			 
                        IF (iftableexists('tasientogenerico') ) THEN
                              DROP TABLE tasientogenerico;
                        END IF;

                        --VAS 08/08/2022 elimino la tabla si existo y la vuelvo a crear
	                CREATE TEMP TABLE tasientogenerico	(
					idasientogenerico bigint,
					idcentroasientogenerico integer,
					operacion varchar DEFAULT 'reversion',
			 		idcomprobantesiges varchar,
					idasientogenericocomprobtipo integer	)WITHOUT OIDS;

			INSERT INTO tasientogenerico(idcomprobantesiges,idasientogenericocomprobtipo)
			VALUES(concat(rlaminuta.nroordenpago,'|',rlaminuta.idcentroordenpago),4);

			PERFORM asientogenerico_revertir();
			SELECT INTO respuesta  cambiarestadoordenpago($1,$2,4,'Generado automaticamente anularminutapago ');
	END IF;	
  -- END IF;

  return respuesta;

END;
$function$
