CREATE OR REPLACE FUNCTION public.insertar_ar(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	activ_realiz CURSOR FOR SELECT * 
		       FROM actividades_realizadores	
	              WHERE actividades_realizadores.idactividad = $1;
	act_realizador RECORD;

BEGIN

	OPEN activ_realiz;	
	FETCH activ_realiz INTO act_realizador;

		WHILE  found LOOP
			INSERT INTO actividades_has_realizadores (idactividad, idrealizador)
			VALUES ($2, act_realizador.idrealizador);
		fetch activ_realiz into act_realizador;
		END LOOP;
		CLOSE activ_realiz;
	
	return 'true';
END;
$function$
