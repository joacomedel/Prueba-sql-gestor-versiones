CREATE OR REPLACE FUNCTION public.pruebatar()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
insert into pruebatareas(descr) values('hola');
end;
$function$
