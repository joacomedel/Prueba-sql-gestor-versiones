CREATE OR REPLACE FUNCTION public.log_quitar_tabla(argesquema character varying, argtabla character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
 existente record;

begin
select into existente * from log_tablas where esquema=argesquema and tabla = argtabla;
if FOUND then
      if existente.tipo='s' then
          execute concat('drop trigger log_trigger_',argesquema,'_',argtabla,' on ',argesquema,'.',argtabla);
      else
          execute concat('drop trigger log_trigger_',argesquema,'_',argtabla,'_ext on ',argesquema,'.',argtabla);
          execute concat('drop function log_getcambios_',argesquema,'_',argtabla,'(',argesquema,'.',argtabla,', ' ,argesquema,'.',argtabla,')');
      end if;
      delete from log_tablas where esquema=argesquema and tabla=argtabla;
end if;
end;
$function$
