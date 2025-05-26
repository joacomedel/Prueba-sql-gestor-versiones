CREATE OR REPLACE FUNCTION public.log_agregar_log(argesquema character varying, argtabla character varying, argeventos character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$declare
    arrayclavesnew varchar;
    arrayclavesold varchar;
    arraycampos varchar;
    claves cursor for select attname from pg_constraint join pg_class on (conrelid = pg_class.oid) join pg_attribute on(attrelid=pg_class.oid) join pg_namespace on(pg_namespace.oid = relnamespace) where contype='p' and attnum = ANY(conkey) and relname=argtabla and nspname=argesquema;
    clave record;
    creacion varchar;
tieneclaves boolean;
begin
tieneclaves:= false;
open claves;
arrayclavesnew:='ARRAY[';
arrayclavesold:='ARRAY[';
arraycampos:='ARRAY[';
fetch claves into clave;
while FOUND loop
	tieneclaves:=true;
	arrayclavesnew:=concat(arrayclavesnew,'coalesce(NEW.',clave.attname,'::varchar,''NULL'')');
	arrayclavesold:=concat(arrayclavesold,'coalesce(OLD.',clave.attname,'::varchar,''NULL'')');
	arraycampos:=concat(arraycampos,quote_literal(clave.attname));
	fetch claves into clave;
	if FOUND then
		arrayclavesnew:=concat(arrayclavesnew,',');
		arrayclavesold:=concat(arrayclavesold,',');
		arraycampos:=concat(arraycampos,',');
	end if;
end loop;
close claves;
if tieneclaves then
arrayclavesnew:=concat(arrayclavesnew,']');
arrayclavesold:=concat(arrayclavesold,']');
arraycampos:=concat(arraycampos,']');	
else
arrayclavesnew:=concat(arrayclavesnew,'''NULL'']');
arrayclavesold:=concat(arrayclavesold,'''NULL'']');
arraycampos:=concat(arraycampos,'''NULL'']');	
end if;
creacion:= concat(
'CREATE OR REPLACE FUNCTION log_trigger_',argesquema,'_',argtabla,'()
  RETURNS "trigger" AS
$BODY$    declare
    regtabla record;
    idusuarioactual log_tconexiones;
    begin
    select into idusuarioactual * from log_obtenerusuarioactual();
select into regtabla * from pg_class join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) where pg_class.oid=TG_RELID;
if TG_OP<>''DELETE'' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ', arraycampos , ', ',arrayclavesnew,',coalesce(idusuarioactual.referencia,''''));
return NEW;
else
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ', arraycampos , ', ',arrayclavesold,',coalesce(idusuarioactual.referencia,''''));
return OLD;
end if;
end;
$BODY$
  LANGUAGE ''plpgsql'' VOLATILE;
ALTER FUNCTION log_trigger_',argesquema,'_',argtabla,'() OWNER TO postgres;
create trigger log_trigger_',argesquema,'_',argtabla,' AFTER ',argeventos,' ON ',argesquema,'.',argtabla, ' FOR EACH ROW EXECUTE PROCEDURE log_trigger_',argesquema,'_',argtabla,'();');

execute creacion;
insert into log_tablas(esquema,tabla,tipo,eventos) values(argesquema,argtabla,'s',argeventos);


end;$function$
