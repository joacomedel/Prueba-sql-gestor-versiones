CREATE OR REPLACE FUNCTION public.bisiesto(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
 if (((($1 % 4) = 0) AND (($1 % 100) <> 0)) OR (($1 % 400) = 0)) THEN
   return true;
 end if;
 return false;
end;
$function$
