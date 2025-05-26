CREATE OR REPLACE FUNCTION public.xor(boolean, boolean)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
RETURN ( $1 and not $2) or ( not $1 and $2);
end;
$function$
