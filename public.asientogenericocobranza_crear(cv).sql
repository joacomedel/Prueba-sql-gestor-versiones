CREATE OR REPLACE FUNCTION public.asientogenericocobranza_crear(character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	-- pidoperacion formato: ''1000111255|1'
       xidasiento numeric;

BEGIN

--IF (iftableexistsparasp('tasientogenerico') ) THEN modifico pq da error desde java, cambiar nuevamente a esto al terminar procesos. 
IF (iftableexists('tasientogenerico') ) THEN
    DROP TABLE tasientogenerico;
END IF;

CREATE TEMP TABLE tasientogenerico	(
            idoperacion varchar,
            idasientogenericocomprobtipo int DEFAULT 8,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
	    fechaimputa date,
	    obs varchar,
	    centrocosto int
                        );

INSERT INTO tasientogenerico(idoperacion,idasientogenericocomprobtipo)
VALUES ($1,8);


select into xidasiento asientogenerico_crear();

return xidasiento;
END;

$function$
