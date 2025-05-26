CREATE OR REPLACE FUNCTION public.asientogenericoreclibrofact_actualizar_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
	xidasiento bigint;
        rasiento_nuevo numeric;
        elidasientogenerico bigint;
        elidcentroasientogenerico integer;
BEGIN
	
       
       SELECT INTO xidasiento idasientogenerico*100+idcentroasientogenerico from asientogenerico 
       where idasientogenericocomprobtipo = 7 
             and idcomprobantesiges = concat(OLD.numeroregistro,'|',OLD.anio)
             AND nullvalue(idasientogenericorevertido) -- No es un asiento que se encuentra revertido
             AND agdescripcion not like '%REVERSION%' ;-- no es un asiento de reversion 
       IF found THEN
                    -- Genero el nuevo asiento 
                    SELECT INTO rasiento_nuevo asientogenericoreclibrofact_crear(OLD.numeroregistro*10000+OLD.anio);
                 --   xidasiento*100+centro()::numeric
                     RAISE NOTICE '>>>>>>>>>>>>>>> rasiento_nuevo(%)',rasiento_nuevo;
                    elidasientogenerico = (rasiento_nuevo/100) ::bigint;
  RAISE NOTICE '>>>>>>>>>>>>>>> idasiento(%)',elidasientogenerico;
                    elidcentroasientogenerico = mod (rasiento_nuevo,10)::integer ;
  RAISE NOTICE '>>>>>>>>>>>>>>> idcentro(%)',elidcentroasientogenerico;
                    IF asientogenerico_esigual(concat(OLD.numeroregistro,'|',OLD.anio),7,elidasientogenerico,elidcentroasientogenerico)  THEN
                               -- Si son iguales debo eliminar el nuevo asiento
                               perform contabilidad_eliminarasiento(elidasientogenerico,elidcentroasientogenerico);
                               RAISE NOTICE 'eliminado ';
                    ELSE
		               perform asientogenerico_revertir(xidasiento);
                               RAISE NOTICE 'asientogenericoreclibrofact_actualizar_tr revertido ';
	            END IF;
       ELSE 
            RAISE NOTICE '>>>>>>>>>>>>>>> NO TIENE ASIENTO ';
            perform asientogenericoreclibrofact_crear(OLD.numeroregistro*10000+OLD.anio);
       END IF;

       return NEW;
END;
$function$
