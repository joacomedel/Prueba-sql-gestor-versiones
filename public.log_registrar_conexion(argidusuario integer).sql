CREATE OR REPLACE FUNCTION public.log_registrar_conexion(argidusuario integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$    declare
    aux record;
    begin
        select into aux * from log_tconexiones where idusuario=argidusuario and idconexion=current_timestamp;
        if not FOUND then
               insert into log_tconexiones(idusuario) values(argidusuario);
        end if;
    end;
$function$
