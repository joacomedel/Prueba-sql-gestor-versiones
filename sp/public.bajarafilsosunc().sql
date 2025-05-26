CREATE OR REPLACE FUNCTION public.bajarafilsosunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorafil CURSOR FOR SELECT * FROM tempafilsosunc;
	afil RECORD;
BEGIN

    OPEN cursorafil;
    FETCH cursorafil into afil;
    WHILE  found LOOP

        INSERT INTO afilsosunc VALUES(afil.nrodoc,afil.nrocuilini,afil.nrocuildni,afil.nrocuilfin,afil.nroosexterna,afil.idosexterna,afil.idctacte,afil.tipodoc,afil.idestado);

    fetch cursorafil into afil;
    END LOOP;
    close cursorafil;

return 'true';
END;
$function$
