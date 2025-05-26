CREATE OR REPLACE FUNCTION public.reestablecersecuencias()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
    consulta record;
begin
   for consulta in select * from backupsecuencias loop
            EXECUTE consulta.valor;
   end loop;
return 'true';
end;
$function$
