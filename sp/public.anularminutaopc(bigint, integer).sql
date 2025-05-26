CREATE OR REPLACE FUNCTION public.anularminutaopc(bigint, integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
       unc record;
--VARIABLES
   rtaspestadominuta boolean;

BEGIN
--KR 15-11-17 idordenpagotipo=4 ???????
		select into unc * from ordenpagocontableordenpago
			natural join ordenpago  natural join cambioestadoordenpago
		where /*idordenpagotipo=4 and*/
               idordenpagocontable=$1 and idcentroordenpagocontable=$2 and nullvalue(ceopfechafin);

   /*   IF FOUND THEN 
   --Verifico que todas las OPC de la minuta esten anuladas y que el estado de la minuta vinculada a la OPC sea 3 (Liquidada)
         SELECT INTO rtaspestadominuta * FROM verificarestadoordenpago(unc.nroordenpago, unc.idcentroordenpago, 3);
         
         IF (rtaspestadominuta) THEN 

	*/
	if found and unc.idtipoestadoordenpago=3 then 
               --KR 15-11-17 significa que el estado vigente de la minuta es Liquidada, y la vuelvo a estado 2 Liquidable para que se vuelva a trabajar con la minuta
                        perform cambiarestadoordenpago(unc.nroordenpago,unc.idcentroordenpago,2,'Estado generado desde anularordenpagocontable');
			/* KR 15-11-17 comente porque ya no es siempre correcto que se anula la minuta si se anula la opc vinculada
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
*/		
	   end if;               
   --    END IF;        
     	return null;
END;
$function$
