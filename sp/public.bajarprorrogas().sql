CREATE OR REPLACE FUNCTION public.bajarprorrogas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorafil CURSOR FOR SELECT * FROM tempprorroga;
	afil RECORD;
BEGIN

    OPEN cursorafil;
    FETCH cursorafil into afil;
    WHILE  found LOOP

    INSERT INTO prorroga (idprorr,tipoprorr,fechaemision,fechavto,certestudio,declarajurada,nrodoc,tipodoc)
        VALUES(afil.idprorr,afil.tipoprorr,afil.fechaemision,afil.fechavto,afil.certestudio,afil.declarajurada,afil.nrodoc,afil.tipodoc);

    fetch cursorafil into afil;
    END LOOP;
    close cursorafil;

return 'true';
END;
$function$
