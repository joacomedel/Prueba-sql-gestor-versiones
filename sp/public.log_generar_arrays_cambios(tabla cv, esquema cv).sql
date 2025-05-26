CREATE OR REPLACE FUNCTION public.log_generar_arrays_cambios(tabla character varying, esquema character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$declare
   atributos cursor for select attname from pg_class join pg_attribute on(attrelid=pg_class.oid) join pg_namespace on(pg_namespace.oid = relnamespace) where attnum>0 and not attisdropped and relname=tabla and nspname=esquema order by attnum;
   atributo record;
   comienzo varchar;
   cuerpo varchar;
   final varchar;

begin

comienzo:= 'CREATE OR REPLACE FUNCTION log_getcambios_esquema_tabla(IN viejo esquema.tabla, IN nuevo esquema.tabla, OUT campos character varying[], OUT valores character varying[])
  RETURNS record AS
$BODY$
declare indice integer:=1;
begin ';

cuerpo:= '';
open atributos;
fetch atributos into atributo;
while FOUND loop
        cuerpo:= concat(cuerpo , replace('if viejo.field <> nuevo.field OR nullvalue(viejo.field) OR nullvalue(nuevo.field) then
	       campos[indice] = ''field'';
	       valores[indice] = viejo.field;
	       indice:=indice+1;
	end if;','field',atributo.attname));
	fetch atributos into atributo;
end loop;
close atributos;
final:= 'end;
$BODY$
  LANGUAGE ''plpgsql'' VOLATILE;
ALTER FUNCTION log_getcambios_esquema_tabla(esquema.tabla, esquema.tabla) OWNER TO postgres;';

return(replace(replace(concat(comienzo,cuerpo,final),'esquema',esquema),'tabla',tabla));
end;
$function$
