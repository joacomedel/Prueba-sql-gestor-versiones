CREATE OR REPLACE FUNCTION public.log_trigger_public_orden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$    declare
    regtabla record;
    idusuarioactual log_tconexiones;
    begin
    select into idusuarioactual * from log_obtenerusuarioactual();
select into regtabla * from pg_class join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) where pg_class.oid=TG_RELID;
if TG_OP<>'DELETE' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['nroorden','centro'], ARRAY[coalesce(NEW.nroorden::varchar,'NULL'),coalesce(NEW.centro::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return NEW;
else
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['nroorden','centro'], ARRAY[coalesce(OLD.nroorden::varchar,'NULL'),coalesce(OLD.centro::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return OLD;
end if;
end;
$function$
