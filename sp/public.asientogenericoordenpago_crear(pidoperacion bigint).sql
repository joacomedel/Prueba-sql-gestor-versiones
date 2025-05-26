CREATE OR REPLACE FUNCTION public.asientogenericoordenpago_crear(pidoperacion bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	-- pidoperacion formato: '13420101' nroordenpago*100+idcentroordenpago
        xidasiento numeric;

BEGIN

IF iftableexistsparasp('tasientogenerico')  THEN
    DROP TABLE tasientogenerico;
END IF;

   CREATE TEMP TABLE tasientogenerico	(
            idoperacion bigint,
            idasientogenericocomprobtipo int DEFAULT 4,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
            obs varchar,
	    centrocosto int DEFAULT 1,
            idasientogenerico bigint,
            idcentroasientogenerico integer,
            idmultivac varchar
                        );

INSERT INTO tasientogenerico(idoperacion)
VALUES (pidoperacion);


select into xidasiento asientogenerico_crear();


DROP TABLE tasientogenerico;
return xidasiento;

END;

$function$
