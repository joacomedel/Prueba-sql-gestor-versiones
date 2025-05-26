CREATE OR REPLACE FUNCTION public.bajarbenefreci()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorafil CURSOR FOR SELECT * FROM tempbenefreci;
	afil RECORD;
	resultado1 boolean;
	cursortitu CURSOR FOR SELECT * FROM afilreci;
	titu RECORD;
	
BEGIN
    CREATE TEMP TABLE bene (nrodoc varchar(8) NOT NULL CONSTRAINT clavebene PRIMARY KEY,fechavtoreci date NOT NULL,nrodoctitu varchar(8),idestado int2 NOT NULL,idreci int2 NOT NULL,tipodoctitu int2,tipodoc int2 NOT NULL,idvin int2) WITHOUT OIDS;
    OPEN cursorafil;
    FETCH cursorafil into afil;
    WHILE  found LOOP
        INSERT INTO benefreci VALUES(afil.nrodoc,afil.fechavtoreci,afil.nrodoctitu,afil.idestado,afil.idreci,afil.tipodoctitu,afil.tipodoc,afil.idvin);        
        INSERT INTO bene VALUES(afil.nrodoc,afil.fechavtoreci,afil.nrodoctitu,afil.idestado,afil.idreci,afil.tipodoctitu,afil.tipodoc,afil.idvin);
	SELECT INTO resultado1 * FROM insertarbarrareciprocidad();
	DELETE FROM bene;

    fetch cursorafil into afil;
    END LOOP;
    close cursorafil;
    
    OPEN cursortitu;
	FETCH cursortitu into titu;
	WHILE found LOOP
		UPDATE benefreci SET barratitu = titu.barra WHERE nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc;
	fetch cursortitu into titu;
	END LOOP;
	close cursortitu;

return 'true';
END;
$function$
