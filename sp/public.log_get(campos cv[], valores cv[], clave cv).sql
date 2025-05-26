CREATE OR REPLACE FUNCTION public.log_get(campos character varying[], valores character varying[], clave character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$declare
i integer;
encontrado boolean;
dim integer;
begin

i:= 1;
encontrado:= false;
dim:= array_upper(campos,1);

while(i<=dim and campos[i]<>clave and not encontrado) loop
       i:=i+1;
end loop;

if i<=dim then
     return valores[i];
else
     return NULL;
end if;

end;
$function$
