CREATE OR REPLACE FUNCTION public.log_boolean_to_varchar(boolean)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare

begin
if $1 then
 return 'TRUE';
else
 return 'FALSE';
end if;
end;

$function$
