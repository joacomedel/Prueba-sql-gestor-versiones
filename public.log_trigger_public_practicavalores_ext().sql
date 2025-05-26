CREATE OR REPLACE FUNCTION public.log_trigger_public_practicavalores_ext()
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
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['idcapitulo','idsubcapitulo','idpractica','idsubespecialidad','internacion','idasocconv'],ARRAY[coalesce(NEW.idcapitulo::varchar,'NULL'),coalesce(NEW.idsubcapitulo::varchar,'NULL'),coalesce(NEW.idpractica::varchar,'NULL'),coalesce(NEW.idsubespecialidad::varchar,'NULL'),coalesce(NEW.internacion::varchar,'NULL'),coalesce(NEW.idasocconv::varchar,'NULL')],ARRAY['idcapitulo','idsubcapitulo','idpractica','idsubespecialidad','importe','internacion','idasocconv','pvidusuario'],ARRAY[coalesce(NEW.idcapitulo::varchar,'NULL'),coalesce(NEW.idsubcapitulo::varchar,'NULL'),coalesce(NEW.idpractica::varchar,'NULL'),coalesce(NEW.idsubespecialidad::varchar,'NULL'),coalesce(NEW.importe::varchar,'NULL'),coalesce(NEW.internacion::varchar,'NULL'),coalesce(NEW.idasocconv::varchar,'NULL'),coalesce(NEW.pvidusuario::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return NEW;
else
if TG_OP='DELETE' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname,ARRAY['idcapitulo','idsubcapitulo','idpractica','idsubespecialidad','internacion','idasocconv'],ARRAY[coalesce(OLD.idcapitulo::varchar,'NULL'),coalesce(OLD.idsubcapitulo::varchar,'NULL'),coalesce(OLD.idpractica::varchar,'NULL'),coalesce(OLD.idsubespecialidad::varchar,'NULL'),coalesce(OLD.internacion::varchar,'NULL'),coalesce(OLD.idasocconv::varchar,'NULL')],ARRAY['idcapitulo','idsubcapitulo','idpractica','idsubespecialidad','importe','internacion','idasocconv','pvidusuario'],ARRAY[coalesce(OLD.idcapitulo::varchar,'NULL'),coalesce(OLD.idsubcapitulo::varchar,'NULL'),coalesce(OLD.idpractica::varchar,'NULL'),coalesce(OLD.idsubespecialidad::varchar,'NULL'),coalesce(OLD.importe::varchar,'NULL'),coalesce(OLD.internacion::varchar,'NULL'),coalesce(OLD.idasocconv::varchar,'NULL'),coalesce(OLD.pvidusuario::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return OLD;
else
if TG_OP='UPDATE' then
select into rec * from log_getcambios_public_practicavalores(OLD,NEW);
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['idcapitulo','idsubcapitulo','idpractica','idsubespecialidad','internacion','idasocconv'],ARRAY[coalesce(NEW.idcapitulo::varchar,'NULL'),coalesce(NEW.idsubcapitulo::varchar,'NULL'),coalesce(NEW.idpractica::varchar,'NULL'),coalesce(NEW.idsubespecialidad::varchar,'NULL'),coalesce(NEW.internacion::varchar,'NULL'),coalesce(NEW.idasocconv::varchar,'NULL')],rec.campos,rec.valores,coalesce(idusuarioactual.referencia,''));
return NEW;
end if;
end if;
end if;
end;
$function$
