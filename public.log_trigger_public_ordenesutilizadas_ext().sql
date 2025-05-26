CREATE OR REPLACE FUNCTION public.log_trigger_public_ordenesutilizadas_ext()
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
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['nroorden','centro','tipo'],ARRAY[coalesce(NEW.nroorden::varchar,'NULL'),coalesce(NEW.centro::varchar,'NULL'),coalesce(NEW.tipo::varchar,'NULL')],ARRAY['nroorden','centro','idosreci','idprestador','fechauso','importe','fechaauditoria','nromatricula','malcance','mespecialidad','idplancobertura','nrodocuso','tipodocuso','tipo','ordenesutilizadascc'],ARRAY[coalesce(NEW.nroorden::varchar,'NULL'),coalesce(NEW.centro::varchar,'NULL'),coalesce(NEW.idosreci::varchar,'NULL'),coalesce(NEW.idprestador::varchar,'NULL'),coalesce(NEW.fechauso::varchar,'NULL'),coalesce(NEW.importe::varchar,'NULL'),coalesce(NEW.fechaauditoria::varchar,'NULL'),coalesce(NEW.nromatricula::varchar,'NULL'),coalesce(NEW.malcance::varchar,'NULL'),coalesce(NEW.mespecialidad::varchar,'NULL'),coalesce(NEW.idplancobertura::varchar,'NULL'),coalesce(NEW.nrodocuso::varchar,'NULL'),coalesce(NEW.tipodocuso::varchar,'NULL'),coalesce(NEW.tipo::varchar,'NULL'),coalesce(NEW.ordenesutilizadascc::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return NEW;
else
if TG_OP='DELETE' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname,ARRAY['nroorden','centro','tipo'],ARRAY[coalesce(OLD.nroorden::varchar,'NULL'),coalesce(OLD.centro::varchar,'NULL'),coalesce(OLD.tipo::varchar,'NULL')],ARRAY['nroorden','centro','idosreci','idprestador','fechauso','importe','fechaauditoria','nromatricula','malcance','mespecialidad','idplancobertura','nrodocuso','tipodocuso','tipo','ordenesutilizadascc'],ARRAY[coalesce(OLD.nroorden::varchar,'NULL'),coalesce(OLD.centro::varchar,'NULL'),coalesce(OLD.idosreci::varchar,'NULL'),coalesce(OLD.idprestador::varchar,'NULL'),coalesce(OLD.fechauso::varchar,'NULL'),coalesce(OLD.importe::varchar,'NULL'),coalesce(OLD.fechaauditoria::varchar,'NULL'),coalesce(OLD.nromatricula::varchar,'NULL'),coalesce(OLD.malcance::varchar,'NULL'),coalesce(OLD.mespecialidad::varchar,'NULL'),coalesce(OLD.idplancobertura::varchar,'NULL'),coalesce(OLD.nrodocuso::varchar,'NULL'),coalesce(OLD.tipodocuso::varchar,'NULL'),coalesce(OLD.tipo::varchar,'NULL'),coalesce(OLD.ordenesutilizadascc::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return OLD;
else
if TG_OP='UPDATE' then
select into rec * from log_getcambios_public_ordenesutilizadas(OLD,NEW);
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['nroorden','centro','tipo'],ARRAY[coalesce(NEW.nroorden::varchar,'NULL'),coalesce(NEW.centro::varchar,'NULL'),coalesce(NEW.tipo::varchar,'NULL')],rec.campos,rec.valores,coalesce(idusuarioactual.referencia,''));
return NEW;
end if;
end if;
end if;
end;
$function$
