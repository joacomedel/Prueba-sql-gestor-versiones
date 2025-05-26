CREATE OR REPLACE FUNCTION public.concatenarsinrepetir(text, text)
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
   if position($1 in $2) = 0 AND position($2 in $1) = 0	then
      return concat($1 , ' ' , $2);
   else
       if position($1 in $2) > 0 then
          return $2;
       else
           return $1;
       end if;
   end if;
end
$function$
