CREATE OR REPLACE FUNCTION public.sucursal()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
declare
       valor integer;
begin
       select into valor  nrosucursal 
       from centroregionaluso
       NATURAL JOIN (SELECT centro as idcentroregional,nrosucursal FROM talonario GROUP BY centro,nrosucursal) as t;
       return valor;
end;
$function$
