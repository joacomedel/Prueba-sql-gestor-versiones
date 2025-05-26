CREATE OR REPLACE FUNCTION public.log_obtenerusuarioactual()
 RETURNS log_tconexiones
 LANGUAGE plpgsql
AS $function$declare
	regusuario log_tconexiones;
begin
   select into regusuario * from log_tconexiones where idconexion=current_timestamp;
   if FOUND then
	delete from log_tconexiones where idconexion<current_timestamp and idusuario=regusuario.idusuario;
        return regusuario;
   else
	return null;
   end if;
end;

$function$
