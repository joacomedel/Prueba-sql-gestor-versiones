CREATE OR REPLACE FUNCTION public.asientogenerico_revertir(idasientogenerico bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
    	
	xidasiento bigint;
	xidasiento_new bigint;
	xidcentro integer;
	
   
BEGIN

xidasiento = $1/100;
xidcentro = $1%100;
-- MaLaPi 09-09-2022 Modifico porque sino el proceso de Anular Factura da error (DROP TABLE en «tasientogenerico» porque está siendo usada por consultas activas en esta sesión)
--  DROP TABLE tasientogenerico;
IF iftableexists('tasientogenerico')  THEN
    DELETE FROM  tasientogenerico;
 -- DROP TABLE tasientogenerico;

ELSE
     CREATE TEMP TABLE tasientogenerico	(
		idasientogenerico bigint,
		idcentroasientogenerico integer,
		idmultivac varchar,
		operacion varchar,
                obs varchar,   	
		agerror varchar,	
                idoperacion bigint,
                idasientogenericocomprobtipo int DEFAULT 7,				
  	        idcentroperacion integer DEFAULT centro(),
	        centrocosto int DEFAULT 1			
		);
END IF; 

INSERT INTO tasientogenerico(idasientogenerico,idcentroasientogenerico,operacion)
VALUES(xidasiento,xidcentro,'reversion');

select into xidasiento_new asientogenerico_revertir();

--DROP TABLE tasientogenerico;
 DELETE FROM tasientogenerico;

RETURN xidasiento_new;

END;$function$
