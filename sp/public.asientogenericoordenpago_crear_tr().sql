CREATE OR REPLACE FUNCTION public.asientogenericoordenpago_crear_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
 genera boolean;
 xidasiento numeric;
BEGIN
        
	-- Verifico si el comprobante debe generar contabilidad
	select into genera optgeneracontabilidad from ordenpagotipo where idordenpagotipo = NEW.idordenpagotipo;
	if genera then
		SELECT INTO xidasiento asientogenericoordenpago_crear(NEW.nroordenpago*100+NEW.idcentroordenpago);
	end if;
	return NEW;
END;
$function$
