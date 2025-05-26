CREATE OR REPLACE FUNCTION public.contabilidad_ejerciciocontable_abm(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
       
	rparam RECORD;
    respuesta character varying; 

	
	/* 
	Crear un SP contabilidad_ejerciciocontable_abm
	Que reciba por parámetro una cadena de caracteres correspondientes a todos los datos 
	enviados desde la interface junto a la acción que se desea realizar (abrir, cerrar)
	*/

	vaccion character varying; -- cerrar / abrir
	videjerciciocontable integer;
BEGIN
	
	respuesta = '';
	EXECUTE sys_dar_filtros($1) INTO rparam;
	vaccion = rparam.accion;
	videjerciciocontable =rparam.idejerciciocontable;

	IF vaccion = 'cerrar' THEN
		UPDATE contabilidad_ejerciciocontable SET eccerrado=now() WHERE idejerciciocontable= videjerciciocontable;
		respuesta = 'Contabiliad cerrada';
	ELSE
		IF vaccion = 'abrir' THEN
			UPDATE contabilidad_ejerciciocontable SET eccerrado=null WHERE idejerciciocontable=videjerciciocontable;
			respuesta = 'Contabiliad abierta';
		ELSE
			respuesta = 'No se realizo ninguna accion';
		END IF;
	END IF;

	

	return respuesta;

END;
$function$
