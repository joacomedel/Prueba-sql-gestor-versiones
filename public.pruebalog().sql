CREATE OR REPLACE FUNCTION public.pruebalog()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
perform logtp('Comenzo a ejecutarse actualizarfechafinosbenefsegunedad()');
end;
$function$
