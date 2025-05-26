CREATE OR REPLACE FUNCTION public.actualizarpersona()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorpers CURSOR FOR SELECT * FROM temppersona;
	pers RECORD;
BEGIN

	UPDATE temppersona SET nrodoc = trim(' ' from to_char(to_number(nrodoc,'99999999'),'00000000'));
    OPEN cursorpers;
    FETCH cursorpers into pers;
    WHILE  found LOOP

        UPDATE persona SET fechafinos = pers.fechafinos WHERE nrodoc= pers.nrodoc AND tipodoc=pers.tipodoc;

    fetch cursorpers into pers;
    END LOOP;
    close cursorpers;

return 'true';
END;
$function$
