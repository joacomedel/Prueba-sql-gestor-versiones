CREATE OR REPLACE FUNCTION public.incorporarbarra(integer, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	existebarra RECORD;
	barrita alias for $1;
	prioridades integer;
	nrodocumento alias for $2;
	tipodocumento alias for $3;
	
BEGIN
 SELECT INTO prioridades prioridad FROM prioridadesafil WHERE barra = barrita;
 SELECT INTO existebarra * FROM barras WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento AND barra = barrita;
 if NOT FOUND
    then
      INSERT INTO barras VALUES (barrita,prioridades,tipodocumento,nrodocumento);
  ELSE 
     UPDATE barras set prioridad = prioridades WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento AND barra = barrita;
 end if;
return 'true';
END;
$function$
