CREATE OR REPLACE FUNCTION public."anularMinutaOPC_borrar"(bigint, integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
       unc record;
BEGIN
		select into unc * from ordenpagocontableordenpago
			natural join ordenpago
		where idordenpagotipo=4 and idordenpagocontable=$1 and idcentroordenpagocontable=$2;

		if found then
			perform cambiarestadoordenpago(unc.nroordenpago,unc.idcentroordenpago,4,'Anulada desde anularordenpagocontable');
			-- Anula los asientos contables
			If (not iftableexistsparasp('tasientogenerico') ) THEN			  
       	                	CREATE TEMP TABLE tasientogenerico	(
					idasientogenerico bigint,
					idcentroasientogenerico integer,
					operacion varchar DEFAULT 'reversion',
			 		idcomprobantesiges varchar,
					idasientogenericocomprobtipo integer	)WITHOUT OIDS;
			end if;

			INSERT INTO tasientogenerico(idcomprobantesiges,idasientogenericocomprobtipo)
			VALUES(concat(unc.nroordenpago,'|',unc.idcentroordenpago),4);

			PERFORM asientogenerico_revertir();
			--------------------------------			
		end if;               
               
     	return null;
END;$function$
