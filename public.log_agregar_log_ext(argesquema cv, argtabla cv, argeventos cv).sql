CREATE OR REPLACE FUNCTION public.log_agregar_log_ext(argesquema character varying, argtabla character varying, argeventos character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
    arrayclavesnew varchar;
    arrayclavesold varchar;
    arraycampos varchar;
    arraytodoscampos varchar;
    arraytodosvaloresnew varchar;
    arraytodosvaloresold varchar;
    claves cursor for select attname from pg_constraint join pg_class on (conrelid = pg_class.oid) join pg_attribute on(attrelid=pg_class.oid) join pg_namespace on(pg_namespace.oid = relnamespace) where contype='p' and attnum = ANY(conkey) and relname=argtabla and nspname=argesquema;
    campos cursor for select attname from pg_class join pg_attribute on(attrelid=pg_class.oid) join pg_namespace on(pg_namespace.oid = relnamespace) where attnum>0 and not attisdropped and relname=argtabla and nspname=argesquema order by attnum;
    clave record;
    campo record;
    creacion varchar;
    creacionget varchar;
    tieneclaves boolean;
    tienecampos boolean;
    
    
begin
arrayclavesnew:='ARRAY[';
arrayclavesold:='ARRAY[';
arraycampos:='ARRAY[';
arraytodoscampos:= 'ARRAY[';
arraytodosvaloresnew:= 'ARRAY[';
arraytodosvaloresold:= 'ARRAY[';
tieneclaves:=false;
tienecampos:=false;

open claves;
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

open campos;
fetch campos into campo;
while FOUND loop
	tienecampos:=true;
	arraytodosvaloresnew:=concat(arraytodosvaloresnew,'coalesce(NEW.',campo.attname,'::varchar,''NULL'')');
	arraytodosvaloresold:=concat(arraytodosvaloresold,'coalesce(OLD.',campo.attname,'::varchar,''NULL'')');
	arraytodoscampos:=concat(arraytodoscampos,quote_literal(campo.attname));
	fetch campos into campo;
	if FOUND then
		arraytodosvaloresnew:=concat(arraytodosvaloresnew,',');
		arraytodosvaloresold:=concat(arraytodosvaloresold,',');
		arraytodoscampos:=concat(arraytodoscampos,',');
	end if;
end loop;
close campos;
if tienecampos then
arraytodosvaloresnew:=concat(arraytodosvaloresnew,']');
arraytodosvaloresold:=concat(arraytodosvaloresold,']');	
arraytodoscampos:=concat(arraytodoscampos,']');
else
arraytodosvaloresnew:=concat(arraytodosvaloresnew,'''NULL'']');
arraytodosvaloresold:=concat(arraytodosvaloresold,'''NULL'']');	
arraytodoscampos:=concat(arraytodoscampos,'''NULL'']');
end if;

creacionget:= log_generar_arrays_cambios(argtabla, argesquema);

creacion:= 
'CREATE OR REPLACE FUNCTION log_trigger_$esq_$tab_ext()
  RETURNS "trigger" AS
$BODY$    declare
    regtabla record;
    idusuarioactual log_tconexiones;
        rec record;
	viejos varchar[];
	nuevos varchar[];
    begin
    select into idusuarioactual * from log_obtenerusuarioactual();
select into regtabla * from pg_class join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) where pg_class.oid=TG_RELID;
if TG_OP=''INSERT'' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, $ac,$avn,$acampos,$avalores,coalesce(idusuarioactual.referencia,''''));
return NEW;
else
if TG_OP=''DELETE'' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname,$ac,$avo,$acampos,$ovalores,coalesce(idusuarioactual.referencia,''''));
return OLD;
else
if TG_OP=''UPDATE'' then
select into rec * from log_getcambios_$esq_$tab(OLD,NEW);
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, $ac,$avn,rec.campos,rec.valores,coalesce(idusuarioactual.referencia,''''));
return NEW;
end if;
end if;
end if;
end;
$BODY$
  LANGUAGE ''plpgsql'' VOLATILE;
ALTER FUNCTION log_trigger_$esq_$tab_ext() OWNER TO postgres;
create trigger log_trigger_$esq_$tab_ext AFTER $ev ON $esq.$tab FOR EACH ROW EXECUTE PROCEDURE log_trigger_$esq_$tab_ext();';

creacion:= replace(creacion,'$acampos',arraytodoscampos);
creacion:= replace(creacion,'$esq',argesquema);
creacion:= replace(creacion,'$tab',argtabla);
creacion:= replace(creacion,'$ac',arraycampos);
creacion:= replace(creacion,'$avn',arrayclavesnew);
creacion:= replace(creacion,'$avo',arrayclavesold);
creacion:= replace(creacion,'$avalores',arraytodosvaloresnew);
creacion:= replace(creacion,'$ovalores',arraytodosvaloresold);
creacion:= replace(creacion,'$ev',argeventos);

execute concat(creacionget,creacion);
insert into log_tablas(esquema, tabla, tipo, eventos) values(argesquema, argtabla, 'e',argeventos);




end;
$function$
