CREATE OR REPLACE FUNCTION public.eliminaresquema(nombreesquema character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
delete from esquemasasincronizar where nombre=nombreesquema;
execute concat('drop schema ',nombreesquema,' cascade;');
end;
$function$
