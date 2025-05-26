CREATE OR REPLACE FUNCTION public.amtipounidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza un tipo de unidad */
/*amtipounidad()*/
DECLARE
    alta CURSOR FOR SELECT * FROM temptipounidad WHERE nullvalue(temptipounidad.error) ;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado boolean;
BEGIN
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
SELECT INTO anterior * FROM tipounidad WHERE tipounidad.tudescripcion = elem.tudescripcion;
IF NOT FOUND THEN
  INSERT INTO tipounidad (tudescripcion)
                 VALUES (elem.tudescripcion);
ELSE
  UPDATE tipounidad SET
                      tudescripcion= elem.tudescripcion
  WHERE  idtipounidad = anterior.idtipounidad;
END IF;
DELETE FROM temptipounidad WHERE temptipounidad.tudescripcion = elem.tudescripcion;
FETCH alta INTO elem;
END LOOP;
CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
