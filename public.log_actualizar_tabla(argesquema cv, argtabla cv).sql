CREATE OR REPLACE FUNCTION public.log_actualizar_tabla(argesquema character varying, argtabla character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
registro record;
begin
select into registro * from log_tablas where esquema= argesquema and tabla=argtabla;
if FOUND then
      perform log_quitar_tabla(argesquema, argtabla);
      if registro.tipo='s' then
            perform log_agregar_tabla(argesquema, argtabla, registro.eventos, false,false);
      else
            perform log_agregar_tabla(argesquema, argtabla, registro.eventos, true,false);
      end if;
end if;
end;
$function$
