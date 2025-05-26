CREATE OR REPLACE FUNCTION public.anularordenpagocontable()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
	ctempcomprobante refcursor;
    unc record;
	idcenopc integer;
	nroopc bigint;
	rpago record;
	resp boolean;

BEGIN

	
	OPEN ctempcomprobante FOR  SELECT * FROM tempcomprobante;
	FETCH ctempcomprobante into unc;
	WHILE FOUND LOOP
		nroopc = unc.idordenpagocontable;
		idcenopc = unc.idcentroordenpagocontable;
	
		--VAS 15-11-2017 KR 15-11-2017 lo hablamos vivi y acordamos llamar al sp que ahora cambia el estado de la minuta solo si el ultimo estado es 3 (Liquidable)
                 perform anularminutaopc(nroopc,idcenopc);
		perform cambiarestadoordenpagocontable(nroopc,idcenopc,6,'Anulada desde Usuario');
        perform ordenpagocontablerevertirctacte(nroopc,idcenopc);

        -- Analizo si el pago tenia vinculado un cheque
        SELECT INTO rpago *
        FROM pagoordenpagocontable
        JOIN cheque  USING (idcheque,idcentrocheque)
        WHERE idordenpagocontable = nroopc AND idcentroordenpagocontable = idcenopc;
        IF FOUND THEN
                -- libero el cheque para que pueda ser utilizado en otra opc
                SELECT INTO resp cambiarestadocheque(rpago.idcheque,rpago.idcentrocheque,2,'Desde SP anularordenpagocontable ');
                -- $1 idcheque $2 idcentrocheque  $3 idchequeestado $4 comentario
         END IF;

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
		VALUES(concat(nroopc,'|',idcenopc),1);

		PERFORM asientogenerico_revertir();
		--------------------------------				
               
		FETCH ctempcomprobante into unc;
	END LOOP;
     	close ctempcomprobante;
     	return concat(nroopc,'|',idcenopc);
END;
$function$
