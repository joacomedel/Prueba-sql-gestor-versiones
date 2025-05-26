CREATE OR REPLACE FUNCTION public.generarordenpagoconsumoturismo_arreglopreviosemanamarzo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	consumoturismoOP refcursor;
	rordenpago record;
	unconsumot RECORD;
	rconsumoturismo record;
	resultado boolean;
	resp2 bigint;
BEGIN

	OPEN consumoturismoOP FOR SELECT   distinct nroordenpago, idcentroordenpago 
		from consumoturismoordenpago natural join cambioestadoordenpago natural join ordenpago
			where nullvalue(ceopfechafin) and  idtipoestadoordenpago =1 and fechaingreso >='2018-01-01'	
 
			order by nroordenpago;
	
	FETCH consumoturismoOP into rordenpago;
	WHILE  FOUND LOOP

		perform cambiarestadoordenpago(rordenpago.nroordenpago,rordenpago.idcentroordenpago ,2,'Estado generado desde manualmente para que tesoreria pueda genera la OP de minutas creadas previo a la modificacion de la primer semana de marzo. Se generan tambien los asientos genericos.  ');


	 SELECT INTO rconsumoturismo MAX(ctfehcingreso) as ctfehcingreso
   FROM consumoturismo
   NATURAL JOIN consumoturismoordenpago
   WHERE nroordenpago =rordenpago.nroordenpago   and  idcentroordenpago = rordenpago.idcentroordenpago
   group by nroordenpago,idcentroordenpago;
   
   UPDATE ordenpago SET fechaingreso = rconsumoturismo.ctfehcingreso
   WHERE nroordenpago = rordenpago.nroordenpago and  idcentroordenpago = rordenpago.idcentroordenpago;


	 IF (not iftableexistsparasp('tasientogenerico') ) THEN

      CREATE TEMP TABLE tasientogenerico (
	        idoperacion bigint,
	        idcentroperacion integer DEFAULT centro(),
	        operacion varchar,
	        fechaimputa date,
		    obs varchar,
		centrocosto int,
                idasientogenericocomprobtipo integer DEFAULT 4
      )WITHOUT OIDS;
	ELSE 
		DELETE FROM tasientogenerico;
	END IF;
 
       
	 INSERT INTO tasientogenerico(idoperacion,operacion,fechaimputa,obs,centrocosto)
            VALUES(	rordenpago.nroordenpago*100+rordenpago.idcentroordenpago,'otp',rconsumoturismo.ctfehcingreso, concat('MP - Turismo :',rordenpago.nroordenpago ,'-',rordenpago.idcentroordenpago), centro());

     SELECT INTO resp2 public.asientogenerico_crear();

	FETCH consumoturismoOP into rordenpago;
	END LOOP;
	CLOSE consumoturismoOP;


   resultado = 'true';
 
RETURN resultado;
END;
$function$
