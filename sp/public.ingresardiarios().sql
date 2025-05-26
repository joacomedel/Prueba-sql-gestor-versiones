CREATE OR REPLACE FUNCTION public.ingresardiarios()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	alta CURSOR FOR SELECT * FROM diarios;
	elem RECORD;
	aux RECORD;
	resultado BOOLEAN;
	
BEGIN

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
	SELECT INTO aux * FROM cdiarios where elem.idcontrol = idcontrol and finvigencia > current_timestamp;    
 	if NOT FOUND
 		then
 			INSERT INTO cdiarios VALUES(elem.idcontrol,elem.inivigencia,elem.finvigencia,elem.hora,elem.plazo);
 		else
 	   		UPDATE cdiarios SET finvigencia = elem.inivigencia WHERE idcontrol = elem.idcontrol and finvigencia > current_timestamp;
			INSERT INTO cdiarios VALUES(elem.idcontrol,elem.inivigencia,elem.finvigencia,elem.hora,elem.plazo);
    end if;
fetch alta into elem;
END LOOP;
CLOSE alta;
return 'true';
END;
$function$
