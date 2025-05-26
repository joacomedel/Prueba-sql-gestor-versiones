CREATE OR REPLACE FUNCTION public.rrhh_abm_alertas_usuarios(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	ruso RECORD;
	ralerta RECORD;
	rusuario RECORD;
        resultado boolean;
        rfiltros RECORD;
	cusuarios refcursor;
	runo RECORD;
        

BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
        OPEN cusuarios FOR SELECT * FROM temp_usuarios;
       FETCH cusuarios INTO runo;
       WHILE  found LOOP
	
	IF runo.accion = 'alta' THEN
		INSERT INTO usuario_alertado(idusuarioalertado,idusuarioalerto,uatexto)
		VALUES(runo.idusuario,rusuario.idusuario,runo.texto_alerta);
	END IF;
	IF runo.accion = 'notificarse' THEN
		UPDATE usuario_alertado SET uanotificado = now()
		WHERE idusuarioalertado = rusuario.idusuario
			AND nullvalue(uanotificado);
		
	END IF;
  FETCH cusuarios INTO runo;
       END LOOP;
      CLOSE cusuarios;


resultado = true;
return resultado;
END;$function$
