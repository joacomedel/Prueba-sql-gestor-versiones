CREATE OR REPLACE FUNCTION public.eliminartareaprogramada(idtareap character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
	begin
		delete from tareaprogramada where idtarea=idtareap;
	end;
$function$
