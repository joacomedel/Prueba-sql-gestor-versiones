CREATE OR REPLACE FUNCTION public.pruebaarray(nodos character varying[], tablas character varying[])
 RETURNS character varying[]
 LANGUAGE plpgsql
AS $function$
begin
return array[tablas[1]];
end;
$function$
