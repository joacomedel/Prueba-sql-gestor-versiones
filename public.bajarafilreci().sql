CREATE OR REPLACE FUNCTION public.bajarafilreci()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorafil CURSOR FOR SELECT * FROM tempafilreci;
	afil RECORD;
	barrareciprocidad integer;
	existe RECORD;
	etb RECORD;
	
BEGIN

    OPEN cursorafil;
    FETCH cursorafil into afil;
    WHILE  found LOOP

        INSERT INTO afilreci VALUES(afil.fechavtoreci,afil.nrodoc,afil.idosreci,afil.idestado,afil.idreci,afil.tipodoc);
        barrareciprocidad =(afil.idosreci + 129);
        SELECT INTO existe * FROM barras WHERE nrodoc = afil.nrodoc AND tipodoc = afil.tipodoc;
        if NOT FOUND
        	then
		        INSERT INTO barras VALUES(barrareciprocidad,1,afil.tipodoc,afil.nrodoc);
		end if;
		
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
