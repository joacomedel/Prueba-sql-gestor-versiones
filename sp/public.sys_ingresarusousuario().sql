CREATE OR REPLACE FUNCTION public.sys_ingresarusousuario()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	ruso RECORD;
	ralerta RECORD;
	rusuario RECORD;
        radmitemusousuario RECORD;
	resultado boolean;
        

BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

SELECT INTO ruso * FROM uso;
IF FOUND THEN 
	UPDATE admitemusousuario SET aiuucantidad = aiuucantidad + 1 WHERE idusuario = rusuario.idusuario AND iditem = ruso.iditem;
	IF NOT FOUND THEN
		INSERT INTO admitemusousuario(idusuario,iditem,aiuucantidad) VALUES( rusuario.idusuario,ruso.iditem,1);
	END IF;
        UPDATE admitemusousuariodiario SET aiuudcantidad = aiuudcantidad + 1 WHERE idusuario = rusuario.idusuario AND iditem = ruso.iditem AND aiuudfecha = CURRENT_DATE;
	IF NOT FOUND THEN
		INSERT INTO admitemusousuariodiario(idusuario,iditem,aiuudcantidad,aiuudfecha) VALUES( rusuario.idusuario,ruso.iditem,1,CURRENT_DATE);
	END IF;

END IF;


resultado = true;
return resultado;
END;$function$
