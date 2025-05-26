CREATE OR REPLACE FUNCTION public.bajarafilijub()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorafil CURSOR FOR SELECT * FROM tempafilijub;
	afil RECORD;
	aux RECORD;
	etb RECORD;
BEGIN

    OPEN cursorafil;
    FETCH cursorafil into afil;
    WHILE  found LOOP

        INSERT INTO afiljub VALUES(afil.nrodoc,afil.idcertpers,afil.trabaja,afil.trabajaunc,afil.tipodoc,afil.ingreso);
        SELECT INTO aux * FROM prioridadesafil WHERE barra = 35;
        INSERT INTO barras VALUES(35,aux.prioridad,afil.tipodoc,afil.nrodoc);
   	SELECT INTO etb * FROM tbarras WHERE nrodoctitu = afil.nrodoc AND tipodoctitu = afil.tipodoc;
    if NOT FOUND
        then
		  INSERT INTO tbarras VALUES (afil.nrodoc,afil.tipodoc,2);
    end if;


    fetch cursorafil into afil;
    END LOOP;
    close cursorafil;

return 'true';
END;
$function$
