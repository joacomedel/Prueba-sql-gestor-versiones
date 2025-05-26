CREATE OR REPLACE FUNCTION public.pruebaarray(nodos character varying[])
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
begin
return nodos[2];
end;
$function$
