CREATE OR REPLACE FUNCTION public.centro()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$declare
       valor integer;
begin
       select into valor idcentroregional from centroregionaluso;
       return valor;
end;
$function$
