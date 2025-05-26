CREATE OR REPLACE FUNCTION public.activartareaprogramada(idtareap character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
	begin
		update tareaprogramada set activa=true where idtarea=idtareap;
	end;
$function$
