CREATE OR REPLACE FUNCTION public.log_quitar_tabla_todas()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
   tablaslog cursor for select * from log_tablas;
   tablalog record;
begin
open tablaslog;
fetch tablaslog into tablalog;
while FOUND loop
   perform log_quitar_tabla(tablalog.esquema,tablalog.tabla);
   fetch tablaslog into tablalog;
end loop;
end;
$function$
