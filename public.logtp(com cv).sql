CREATE OR REPLACE FUNCTION public.logtp(com character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	insert into logtareasprogramadas(comentario) values (com);
end;
$function$
