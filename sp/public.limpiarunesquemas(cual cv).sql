CREATE OR REPLACE FUNCTION public.limpiarunesquemas(cual character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	
	esquema record;
begin
	select into esquema  * from esquemasasincronizar where nombre = cual;
        IF FOUND THEN     
   
		RAISE NOTICE ' esquema (%)',esquema.nombre;
		execute concat('DROP SCHEMA  IF EXISTS  ',esquema.nombre,' CASCADE ',';');
	END IF;
return 'true';
end;
$function$
