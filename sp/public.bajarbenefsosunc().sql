CREATE OR REPLACE FUNCTION public.bajarbenefsosunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorafil CURSOR FOR SELECT * FROM tempbenefsosunc;
	afil RECORD;
	resultado1 boolean;
	titu RECORD;
	
BEGIN
    CREATE TEMP TABLE bene (barramutu int2,nroosexterna int8,idosexterna varchar(10),nrodoc varchar(8) NOT NULL CONSTRAINT clavebene PRIMARY KEY,mutual bool,nrodoctitu varchar(8) NOT NULL,nromututitu int8,idestado int2 NOT NULL,tipodoc int2 NOT NULL,tipodoctitu int2 NOT NULL,idvin int2) WITHOUT OIDS;
    OPEN cursorafil;
    FETCH cursorafil into afil;
    WHILE  found LOOP
        INSERT INTO benefsosunc VALUES(afil.barramutu,afil.nroosexterna,afil.idosexterna,afil.nrodoc,afil.mutual,afil.nrodoctitu,afil.nromututitu,afil.idestado,afil.tipodoc,afil.tipodoctitu,afil.idvin);
	    INSERT INTO bene VALUES(afil.barramutu,afil.nroosexterna,afil.idosexterna,afil.nrodoc,afil.mutual,afil.nrodoctitu,afil.nromututitu,afil.idestado,afil.tipodoc,afil.tipodoctitu,afil.idvin);
	SELECT INTO resultado1 * FROM insertarbarra();
	SELECT INTO titu * FROM afilsosunc WHERE afilsosunc.nrodoc = afil.nrodoctitu AND afilsosunc.tipodoc = afil.tipodoctitu;
	IF FOUND THEN
       UPDATE benefsosunc SET barratitu = titu.barra WHERE nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc;
    END IF;
	DELETE FROM bene;
    fetch cursorafil into afil;
    END LOOP;
    close cursorafil;

	/*OPEN cursortitu;
	FETCH cursortitu into titu;
	WHILE found LOOP
		UPDATE benefsosunc SET barratitu = titu.barra WHERE nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc;
	fetch cursortitu into titu;
	END LOOP;
	close cursortitu;*/

return 'true';
END;
$function$
