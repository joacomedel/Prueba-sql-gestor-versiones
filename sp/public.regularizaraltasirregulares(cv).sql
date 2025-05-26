CREATE OR REPLACE FUNCTION public.regularizaraltasirregulares(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	altairregular CURSOR FOR SELECT * FROM altasirregulares;
	elem RECORD;
	aux RECORD;
	
BEGIN

OPEN altairregular;
FETCH alta INTO elem;
WHILE  found LOOP
SELECT INTO aux * FROM afilsosunc WHERE nrodoc = elem.nrodoc;
if elem.activar
	then
		INSERT INTO certpagounc VALUES(elem.nronota,elem.fechanota,elem.nrodoc,aux.tipodoc,elem.nrodesignacion,elem.fechainilab,elem.fechafinlab);
		UPDATE afilsosunc SET idestado = 2 WHERE nrodoc = elem.nrodoc AND tipodoc = aux.tipodoc;
	else
		UPDATE afilsosunc SET idestado = 4 WHERE nrodoc = elem.nrodoc AND tipodoc = aux.tipodoc;
end if;
DELETE FROM verificacion WHERE codigo = $1 AND nrodoc = elem.nrodoc;

fetch altairregular into elem;
END LOOP;
CLOSE altairregular;
return 'true';
END;
$function$
