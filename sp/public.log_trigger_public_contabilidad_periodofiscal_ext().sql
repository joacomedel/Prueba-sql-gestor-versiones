CREATE OR REPLACE FUNCTION public.log_trigger_public_contabilidad_periodofiscal_ext()
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
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['idperiodofiscal'],ARRAY[coalesce(NEW.idperiodofiscal::varchar,'NULL')],ARRAY['idperiodofiscal','pffechadesde','pffechahasta','pfcerrado','pftipoiva','pffechacreacion'],ARRAY[coalesce(NEW.idperiodofiscal::varchar,'NULL'),coalesce(NEW.pffechadesde::varchar,'NULL'),coalesce(NEW.pffechahasta::varchar,'NULL'),coalesce(NEW.pfcerrado::varchar,'NULL'),coalesce(NEW.pftipoiva::varchar,'NULL'),coalesce(NEW.pffechacreacion::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return NEW;
else
if TG_OP='DELETE' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname,ARRAY['idperiodofiscal'],ARRAY[coalesce(OLD.idperiodofiscal::varchar,'NULL')],ARRAY['idperiodofiscal','pffechadesde','pffechahasta','pfcerrado','pftipoiva','pffechacreacion'],ARRAY[coalesce(OLD.idperiodofiscal::varchar,'NULL'),coalesce(OLD.pffechadesde::varchar,'NULL'),coalesce(OLD.pffechahasta::varchar,'NULL'),coalesce(OLD.pfcerrado::varchar,'NULL'),coalesce(OLD.pftipoiva::varchar,'NULL'),coalesce(OLD.pffechacreacion::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return OLD;
else
if TG_OP='UPDATE' then
select into rec * from log_getcambios_public_contabilidad_periodofiscal(OLD,NEW);
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['idperiodofiscal'],ARRAY[coalesce(NEW.idperiodofiscal::varchar,'NULL')],rec.campos,rec.valores,coalesce(idusuarioactual.referencia,''));
return NEW;
end if;
end if;
end if;
end;
$function$
