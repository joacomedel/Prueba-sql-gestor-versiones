CREATE OR REPLACE FUNCTION public.temp_agregarhistobarrassincro()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
select * from agregarsincronizable('histobarras');
end;
$function$
