CREATE OR REPLACE FUNCTION public.desactivartareaprogramada(idtareap character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
	begin
		update tareaprogramada set activa=false where idtarea=idtareap;
	end;
$function$
