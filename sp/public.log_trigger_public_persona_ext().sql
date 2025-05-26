CREATE OR REPLACE FUNCTION public.log_trigger_public_persona_ext()
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
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['nrodoc','tipodoc'],ARRAY[coalesce(NEW.nrodoc::varchar,'NULL'),coalesce(NEW.tipodoc::varchar,'NULL')],ARRAY['nrodoc','apellido','nombres','fechanac','sexo','estcivil','telefono','email','fechainios','fechafinos','iddireccion','tipodoc','carct','barra','contcarencia','idcentrodireccion','nrodocreal','personacc'],ARRAY[coalesce(NEW.nrodoc::varchar,'NULL'),coalesce(NEW.apellido::varchar,'NULL'),coalesce(NEW.nombres::varchar,'NULL'),coalesce(NEW.fechanac::varchar,'NULL'),coalesce(NEW.sexo::varchar,'NULL'),coalesce(NEW.estcivil::varchar,'NULL'),coalesce(NEW.telefono::varchar,'NULL'),coalesce(NEW.email::varchar,'NULL'),coalesce(NEW.fechainios::varchar,'NULL'),coalesce(NEW.fechafinos::varchar,'NULL'),coalesce(NEW.iddireccion::varchar,'NULL'),coalesce(NEW.tipodoc::varchar,'NULL'),coalesce(NEW.carct::varchar,'NULL'),coalesce(NEW.barra::varchar,'NULL'),coalesce(NEW.contcarencia::varchar,'NULL'),coalesce(NEW.idcentrodireccion::varchar,'NULL'),coalesce(NEW.nrodocreal::varchar,'NULL'),coalesce(NEW.personacc::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return NEW;
else
if TG_OP='DELETE' then
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname,ARRAY['nrodoc','tipodoc'],ARRAY[coalesce(OLD.nrodoc::varchar,'NULL'),coalesce(OLD.tipodoc::varchar,'NULL')],ARRAY['nrodoc','apellido','nombres','fechanac','sexo','estcivil','telefono','email','fechainios','fechafinos','iddireccion','tipodoc','carct','barra','contcarencia','idcentrodireccion','nrodocreal','personacc'],ARRAY[coalesce(OLD.nrodoc::varchar,'NULL'),coalesce(OLD.apellido::varchar,'NULL'),coalesce(OLD.nombres::varchar,'NULL'),coalesce(OLD.fechanac::varchar,'NULL'),coalesce(OLD.sexo::varchar,'NULL'),coalesce(OLD.estcivil::varchar,'NULL'),coalesce(OLD.telefono::varchar,'NULL'),coalesce(OLD.email::varchar,'NULL'),coalesce(OLD.fechainios::varchar,'NULL'),coalesce(OLD.fechafinos::varchar,'NULL'),coalesce(OLD.iddireccion::varchar,'NULL'),coalesce(OLD.tipodoc::varchar,'NULL'),coalesce(OLD.carct::varchar,'NULL'),coalesce(OLD.barra::varchar,'NULL'),coalesce(OLD.contcarencia::varchar,'NULL'),coalesce(OLD.idcentrodireccion::varchar,'NULL'),coalesce(OLD.nrodocreal::varchar,'NULL'),coalesce(OLD.personacc::varchar,'NULL')],coalesce(idusuarioactual.referencia,''));
return OLD;
else
if TG_OP='UPDATE' then
select into rec * from log_getcambios_public_persona(OLD,NEW);
insert into log_usuarios(idusuario,op,fechahora,esquema,tabla,camposclave,valoresclave,campos,valores,referencia) values(coalesce(idusuarioactual.idusuario,0), TG_OP, current_timestamp, regtabla.nspname, regtabla.relname, ARRAY['nrodoc','tipodoc'],ARRAY[coalesce(NEW.nrodoc::varchar,'NULL'),coalesce(NEW.tipodoc::varchar,'NULL')],rec.campos,rec.valores,coalesce(idusuarioactual.referencia,''));
return NEW;
end if;
end if;
end if;
end;
$function$
