CREATE OR REPLACE FUNCTION public.isdate(text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
     if ($1 is null) then
         return false;
     end if;
     perform $1::date;
     return true;
exception when others then
     return false;
end;
$function$
