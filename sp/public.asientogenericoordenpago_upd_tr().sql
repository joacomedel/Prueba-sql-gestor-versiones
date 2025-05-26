CREATE OR REPLACE FUNCTION public.asientogenericoordenpago_upd_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
	xidasiento bigint;
        roptipo record;
         rasiento_nuevo numeric;
        elidasientogenerico bigint;
        elidcentroasientogenerico integer;
BEGIN
       -- Corroboro que la minuta genera contabilidad
        SELECT INTO roptipo * FROM ordenpagotipo WHERE idordenpagotipo = OLD.idordenpagotipo AND  	optgeneracontabilidad ;
        IF FOUND THEN 
	             SELECT  into xidasiento idasientogenerico*100+idcentroasientogenerico 
                     FROM asientogenerico 
                     WHERE idasientogenericocomprobtipo = 4 and idcomprobantesiges = concat(OLD.nroordenpago,'|',OLD.idcentroordenpago)
                     AND nullvalue(idasientogenericorevertido) -- No es un asiento que se encuentra revertido
                     AND agdescripcion not like '%REVERSION%' ;-- no es un asiento de reversion ;

	             -- MaLaPi 02-05-2022 CAmbio para verificar si cambio el asiento antes de ser revertido
                     -- if found then
		     --	       perform asientogenerico_revertir(xidasiento);
		     -- end if;
		     --perform asientogenericoordenpago_crear(NEW.nroordenpago*100+NEW.idcentroordenpago);
                     

                    IF found THEN
                        -- Genero el nuevo asiento
                    SELECT INTO rasiento_nuevo asientogenericoordenpago_crear(NEW.nroordenpago*100+NEW.idcentroordenpago);
                    RAISE NOTICE '>>>>>>>>>>>>>>> rasiento_nuevo(%)',rasiento_nuevo;
                    elidasientogenerico = (rasiento_nuevo/100) ::bigint;
                    RAISE NOTICE '>>>>>>>>>>>>>>> idasiento(%)',elidasientogenerico;
                    elidcentroasientogenerico = mod (rasiento_nuevo,10)::integer ;
                    RAISE NOTICE '>>>>>>>>>>>>>>> idcentro(%)',elidcentroasientogenerico;
                    IF asientogenerico_esigual(concat(OLD.nroordenpago,'|',OLD.idcentroordenpago),4,elidasientogenerico,elidcentroasientogenerico)  THEN
                               -- Si son iguales debo eliminar el nuevo asiento
                               perform contabilidad_eliminarasiento(elidasientogenerico,elidcentroasientogenerico);
                               RAISE NOTICE 'eliminado ';
                    ELSE
		               perform asientogenerico_revertir(xidasiento);
                               RAISE NOTICE 'asientogenericoordenpago_upd_tr revertido ';
	            END IF;
                    ELSE 
                       RAISE NOTICE '>>>>>>>>>>>>>>> NO TIENE ASIENTO ';
                       SELECT INTO rasiento_nuevo asientogenericoordenpago_crear(NEW.nroordenpago*100+NEW.idcentroordenpago);
                    END IF;

        END IF;
	return NEW;
END;$function$
