CREATE OR REPLACE FUNCTION public.actualizafechafinoscontemporalpersona()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorafil refcursor;

	afil RECORD;
	pers RECORD;
	fechafin DATE;
BEGIN
     
 /*Temporal*/
    OPEN cursorafil FOR SELECT * FROM temporalpersona;
    FETCH cursorafil into afil;
    WHILE  found LOOP

    IF FOUND THEN
         UPDATE persona SET fechafinos = afil.fechafinos
          WHERE nrodoc = afil.nrodoc AND tipodoc = afil.tipodoc;
    END IF;
    fetch cursorafil into afil;
    END LOOP;
    close cursorafil;
return 'true';
END;
$function$
