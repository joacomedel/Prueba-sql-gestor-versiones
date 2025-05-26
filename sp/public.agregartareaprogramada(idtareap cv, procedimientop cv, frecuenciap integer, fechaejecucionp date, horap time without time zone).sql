CREATE OR REPLACE FUNCTION public.agregartareaprogramada(idtareap character varying, procedimientop character varying, frecuenciap integer, fechaejecucionp date, horap time without time zone)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
	begin
		insert into tareaprogramada(idtarea, hora, frecuencia, procedimiento,fechaejecucion) values(idtareap, horap, frecuenciap, procedimientop, fechaejecucionp);
	end;
$function$
