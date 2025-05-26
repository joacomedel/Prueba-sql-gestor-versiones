CREATE OR REPLACE FUNCTION public.log_registrar_conexion(argidusuario integer, argreferencia character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$    declare
    aux record;
    begin
        select into aux * from log_tconexiones where idusuario=argidusuario and idconexion=current_timestamp;
        if not FOUND then
               insert into log_tconexiones(idusuario,referencia) values(argidusuario,argreferencia);
        end if;
    end;
$function$
