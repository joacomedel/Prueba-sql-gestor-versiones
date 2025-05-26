CREATE OR REPLACE FUNCTION public.agregaresquema(nombreesquema character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
insert into esquemasasincronizar values(nombreesquema);
execute concat ( 'create schema ' , nombreesquema , ';');
end;
$function$
