CREATE OR REPLACE FUNCTION public.ctacteexentos_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM agregarmontosdedescuentos(CONCAT('{nrodoc =',NEW.nrodoc,',', 'tipodoc =', NEW.tipodoc,'}'));

	RETURN NEW;
END;
$function$
