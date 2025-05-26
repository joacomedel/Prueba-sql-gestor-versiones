CREATE OR REPLACE FUNCTION public.bajarpersona()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorpers CURSOR FOR SELECT * FROM temppersona;
	pers RECORD;
BEGIN

    OPEN cursorpers;
    FETCH cursorpers into pers;
    WHILE  found LOOP

        INSERT INTO persona VALUES(pers.nrodoc,pers.apellido,pers.nombres,pers.fechanac,pers.sexo,pers.estcivil,pers.telefono,pers.email,pers.fechainios,pers.fechafinos,pers.iddireccion,pers.tipodoc);

    fetch cursorpers into pers;
    END LOOP;
    close cursorpers;

return 'true';
END;
$function$
