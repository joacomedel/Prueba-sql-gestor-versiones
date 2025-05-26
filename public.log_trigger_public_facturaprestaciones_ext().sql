CREATE OR REPLACE FUNCTION public.log_trigger_public_facturaprestaciones_ext()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$    declare
    regtabla record;
    idusuarioactual log_tconexiones;
        rec record;
	viejos varchar[];
	nuevos varchar[];
    begin
    select into idusuarioactual * from log_obtenerusuarioactual();
select into regtabla * from pg_class join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) where pg_class.oid=TG_RELID;
if TG_OP='INSERT' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['anio','nroregistro','fidtipoprestacion'],ARRAY[coalesce(NEW.anio::varchar,'NULL'),coalesce(NEW.nroregistro::varchar,'NULL'),coalesce(NEW.fidtipoprestacion::varchar,'NULL')],ARRAY['anio','nroregistro','fidtipoprestacion','importe','observacion','debito','facturaprestacionescc'],ARRAY[coalesce(NEW.anio::varchar,'NULL'),coalesce(NEW.nroregistro::varchar,'NULL'),coalesce(NEW.fidtipoprestacion::varchar,'NULL'),coalesce(NEW.importe::varchar,'NULL'),coalesce(NEW.observacion::varchar,'NULL'),coalesce(NEW.debito::varchar,'NULL'),coalesce(NEW.facturaprestacionescc::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return NEW;
else
if TG_OP='DELETE' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname,ARRAY['anio','nroregistro','fidtipoprestacion'],ARRAY[coalesce(OLD.anio::varchar,'NULL'),coalesce(OLD.nroregistro::varchar,'NULL'),coalesce(OLD.fidtipoprestacion::varchar,'NULL')],ARRAY['anio','nroregistro','fidtipoprestacion','importe','observacion','debito','facturaprestacionescc'],ARRAY[coalesce(OLD.anio::varchar,'NULL'),coalesce(OLD.nroregistro::varchar,'NULL'),coalesce(OLD.fidtipoprestacion::varchar,'NULL'),coalesce(OLD.importe::varchar,'NULL'),coalesce(OLD.observacion::varchar,'NULL'),coalesce(OLD.debito::varchar,'NULL'),coalesce(OLD.facturaprestacionescc::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return OLD;
else
if TG_OP='UPDATE' then
select into rec * from log_getcambios_public_facturaprestaciones(OLD,NEW);
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['anio','nroregistro','fidtipoprestacion'],ARRAY[coalesce(NEW.anio::varchar,'NULL'),coalesce(NEW.nroregistro::varchar,'NULL'),coalesce(NEW.fidtipoprestacion::varchar,'NULL')],rec.campos,rec.valores,coalesce(idusuarioactual.referencia,''));
return NEW;
end if;
end if;
end if;
end;
$function$
