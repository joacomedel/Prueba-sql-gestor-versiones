CREATE OR REPLACE FUNCTION public.actualizafechafinosconresolbec()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorafil CURSOR FOR SELECT * FROM resolbec WHERE resolbec.fechafinlab >= CURRENT_DATE;
	afil RECORD;
	pers RECORD;
	fechafin DATE;
BEGIN
    OPEN cursorafil;
    FETCH cursorafil into afil;
    WHILE  found LOOP

    SELECT INTO pers * FROM persona
                natural join afilsosunc
                natural join afilibec WHERE afilibec.idresolbe = afil.idresolbe;
    IF FOUND THEN
       fechafin = afil.fechafinlab + INTEGER '90';
        UPDATE persona SET fechafinos = fechafin
                WHERE nrodoc = pers.nrodoc AND tipodoc = pers.tipodoc;
    END IF;

    fetch cursorafil into afil;
    END LOOP;
    close cursorafil;

return 'true';
END;
$function$
