CREATE OR REPLACE FUNCTION public.ingresarmensuales()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	alta CURSOR FOR SELECT * FROM mensuales;
	elem RECORD;
	aux RECORD;
	resultado BOOLEAN;
	
BEGIN

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
	SELECT INTO aux * FROM cmensuales where elem.idcontrol = idcontrol and finvigencia > current_timestamp;    
 	if NOT FOUND
 		then
 			INSERT INTO cmensuales VALUES(elem.idcontrol,elem.inivigencia,elem.finvigencia,elem.hora,elem.dia,elem.plazo);
 		else
 	   		UPDATE cmensuales SET finvigencia = elem.inivigencia WHERE idcontrol = elem.idcontrol and finvigencia > current_timestamp;
			INSERT INTO cmensuales VALUES(elem.idcontrol,elem.inivigencia,elem.finvigencia,elem.hora,elem.dia,elem.plazo);
    end if;
fetch alta into elem;
END LOOP;
CLOSE alta;
return 'true';
END;
$function$
