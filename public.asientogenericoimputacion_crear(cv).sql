CREATE OR REPLACE FUNCTION public.asientogenericoimputacion_crear(character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	-- pidoperacion formato: 'iddeuda|idcentrodeuda|idpago|idcentropago'
       xidasiento numeric;

BEGIN

IF (iftableexists('tasientogenerico') ) THEN
   DROP TABLE tasientogenerico;

CREATE TEMP TABLE tasientogenerico	(
            idoperacion varchar,
            idcentroasientogenerico integer,
            idasientogenericocomprobtipo int DEFAULT 9,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
	    fechaimputa date,
	    obs varchar,
            idcomprobantesiges varchar,
            idasientogenerico bigint,
	    centrocosto int
                                  );

    DELETE FROM tasientogenerico;
--END IF;
ELSE 

 CREATE TEMP TABLE tasientogenerico	(
            idoperacion varchar,
            idcentroasientogenerico integer,
            idasientogenericocomprobtipo int DEFAULT 9,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
	    fechaimputa date,
	    obs varchar,
            idcomprobantesiges varchar,
            idasientogenerico bigint,
	    centrocosto int
          
                        );
END IF;



INSERT INTO tasientogenerico(idoperacion,idasientogenericocomprobtipo)
VALUES ($1,9);


select into xidasiento asientogenerico_crear();

return xidasiento;
END;

$function$
