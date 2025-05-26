CREATE OR REPLACE FUNCTION public.actualizaramucbb(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	baja CURSOR FOR SELECT * FROM bajabeneficiario;
	elem RECORD;
	aux RECORD;
	resultado BOOLEAN;
	
BEGIN

--KR 22-07-21 no existe la tabla, se ve antes era fisica. 
IF (NOT iftableexists('rerrorbb')) THEN
    CREATE TEMP TABLE rerrorbb( 
		legajosiu int8, 
		nombre varchar,
		nromutu int8,
		nrodoc varchar,
                idusuario varchar);
else 
   delete from rerroraa;
END IF;


OPEN baja;
FETCH baja INTO elem;
WHILE  found LOOP
SELECT INTO aux * FROM benefsosunc WHERE nrodoc = elem.nrodoc AND nrodoctitu = elem.nrodoctitu; 
if NOT FOUND
	then
	   	resultado = 'true';
	else
		resultado = 'false';
		UPDATE benefsosunc SET barramutu = 0, mutual= 'false', nromututitu = 0
		WHERE nrodoc = elem.nrodoc AND nrodoctitu = elem.nrodoctitu; 
end if;

if resultado
	then

		INSERT INTO rerrorbb VALUES(elem.legajosiu,elem.nombretitu,elem.nombre,elem.nromututitu,elem.barramutu,elem.nrodoctitu,elem.nrodoc,$1);
end if;

fetch baja into elem;
END LOOP;
CLOSE baja;
return 'true';
END;
$function$
