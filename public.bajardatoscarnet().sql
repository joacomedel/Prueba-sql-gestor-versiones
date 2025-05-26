CREATE OR REPLACE FUNCTION public.bajardatoscarnet()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorCarnet CURSOR FOR SELECT * FROM tempdatosAfil;
	loca RECORD;
BEGIN

    OPEN cursorCarnet;
    FETCH cursorCarnet into loca;
    WHILE  found LOOP


    INSERT INTO tafiliado VALUES(loca.benef,loca.legajo,loca.idafiliado,loca.nrodoc,loca.tipodoc,loca.finlab,loca.barra,loca.feinlab,loca.cargo,loca.tipoAfil);

    fetch cursorCarnet into loca;
    END LOOP;
    close cursorCarnet;

return 'true';
END;
$function$
