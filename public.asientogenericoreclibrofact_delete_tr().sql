CREATE OR REPLACE FUNCTION public.asientogenericoreclibrofact_delete_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$

DECLARE
	xidasiento bigint;
BEGIN
	select into xidasiento idasientogenerico*100+idcentroasientogenerico from asientogenerico where idasientogenericocomprobtipo = 7 and idcomprobantesiges = concat(OLD.numeroregistro,'|',OLD.anio);
	if found then
		perform asientogenerico_revertir(xidasiento);
	end if;

	return OLD;
END;
$function$
