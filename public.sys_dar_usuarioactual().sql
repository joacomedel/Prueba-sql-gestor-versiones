CREATE OR REPLACE FUNCTION public.sys_dar_usuarioactual()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$declare
	regusuario log_tconexiones;
begin
   select into regusuario * from log_tconexiones where idconexion=current_timestamp;
   if FOUND then
	return regusuario.idusuario;

   else
	return 25;
   end if;
end;

$function$
