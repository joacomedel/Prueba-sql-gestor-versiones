CREATE OR REPLACE FUNCTION public.asientogenericoreclibrofact_crear(pidoperacion character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	-- pidoperacion formato: '1342012018' nroregistro*10000+anio
        xidasiento numeric;

BEGIN

IF (not iftableexistsparasp('tasientogenerico') ) THEN

   CREATE TEMP TABLE tasientogenerico	(
            idoperacion varchar,
            idasientogenericocomprobtipo int DEFAULT 7,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
--	    fechaimputa date,
--	    obs varchar,
	    centrocosto int DEFAULT 1
                        );
END IF;

INSERT INTO tasientogenerico(idoperacion,idasientogenericocomprobtipo)
VALUES (pidoperacion,7);


select into xidasiento asientogenerico_crear();

-- CS 2018-06-13 ------------------------------------------------------
-- Esto es Temporal, solo durante el periodo de pruebas
perform	cambiarestadoasientogenerico((xidasiento/100)::bigint,(xidasiento%100)::integer,11);
-- --------------------------------------------------------------------
DROP TABLE tasientogenerico;
return xidasiento;
END;

$function$
