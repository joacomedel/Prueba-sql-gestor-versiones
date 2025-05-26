CREATE OR REPLACE FUNCTION public.log_trigger_public_practica()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$    declare
    regtabla record;
    idusuarioactual log_tconexiones;
    begin
    select into idusuarioactual * from log_obtenerusuarioactual();
select into regtabla * from pg_class join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) where pg_class.oid=TG_RELID;
if TG_OP<>'DELETE' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['idnomenclador','idcapitulo','idsubcapitulo','idpractica'], ARRAY[coalesce(NEW.idnomenclador::varchar,'NULL'),coalesce(NEW.idcapitulo::varchar,'NULL'),coalesce(NEW.idsubcapitulo::varchar,'NULL'),coalesce(NEW.idpractica::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return NEW;
else
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['idnomenclador','idcapitulo','idsubcapitulo','idpractica'], ARRAY[coalesce(OLD.idnomenclador::varchar,'NULL'),coalesce(OLD.idcapitulo::varchar,'NULL'),coalesce(OLD.idsubcapitulo::varchar,'NULL'),coalesce(OLD.idpractica::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return OLD;
end if;
end;
$function$
