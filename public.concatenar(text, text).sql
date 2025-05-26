CREATE OR REPLACE FUNCTION public.concatenar(text, text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
begin
   if $1 is null then
     return $2;
   end if;
   if $2 is null then
     return $1;
   end if;
   return concat($1 , ' ' , $2);
  end
$function$
