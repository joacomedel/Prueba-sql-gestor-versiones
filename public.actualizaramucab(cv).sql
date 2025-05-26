CREATE OR REPLACE FUNCTION public.actualizaramucab(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	alta CURSOR FOR SELECT * FROM altabeneficiario;
	elem RECORD;
	aux RECORD;
	resultado BOOLEAN;
	
BEGIN

--KR 22-07-21 no existe la tabla, se ve antes era fisica. 
IF (NOT iftableexists('rerrorab')) THEN
    CREATE TEMP TABLE rerrorab( 
		legajosiu int8, 
		nombre varchar,
		nromutu int8,
		nrodoc varchar,
                idusuario varchar);
else 
   delete from rerroraa;
END IF;

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP

SELECT INTO aux * FROM benefsosunc WHERE nrodoc = elem.nrodoc AND nrodoctitu = elem.nrodoctitu;
if NOT FOUND
	then
	   	resultado = 'true';
	else
		resultado = 'false';
		UPDATE benefsosunc SET barramutu = elem.barramutu, mutual= 'true', nromututitu = elem.nromututitu
		WHERE nrodoc = elem.nrodoc AND nrodoctitu = elem.nrodoctitu; 
end if;

if resultado
	then

		INSERT INTO rerrorab VALUES(elem.legajosiu,elem.nombretitu,elem.nombre,elem.nromututitu,elem.barramutu,elem.nrodoctitu,elem.nrodoc,$1);
end if;

fetch alta into elem;
END LOOP;
CLOSE alta;
return 'true';
END;
$function$
