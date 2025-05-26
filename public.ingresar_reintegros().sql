CREATE OR REPLACE FUNCTION public.ingresar_reintegros()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	tuplas CURSOR FOR SELECT * FROM reintegros_temp;
	
	tupla RECORD;
	aux VARCHAR;
	resultado boolean;
	
BEGIN
	
	OPEN tuplas;	
	FETCH tuplas INTO tupla;

	WHILE  found LOOP

		if tupla.idafil <> '' then --1° if
			
			SELECT INTO aux idafil
			FROM cuentas
			WHERE tupla.idafil = idafil;

			if FOUND then -- 2° if
				IF tupla.importe > 0 THEN --3° if
		          INSERT INTO reintegros (importe,idafil)
			      VALUES (tupla.importe, tupla.idafil);
    		   ELSE --3° if
    		       INSERT INTO reintegros_error (importe,idafiliado)
             	   VALUES (tupla.importe, tupla.idafil);
         	   END IF; -- 3° if
               		
            ELSE -- 2° if
			     INSERT INTO reintegros_error (importe,idafiliado)
			     VALUES (tupla.importe, tupla.idafil);
			end if; -- 2° if
		ELSE -- 1° if
            INSERT INTO reintegros_error (importe,idafiliado)
			VALUES (tupla.importe, tupla.idafil);	
		end if; -- 1° if
		
		FETCH tuplas INTO tupla;
	END LOOP;
	CLOSE tuplas;
    return resultado;
END;
$function$
