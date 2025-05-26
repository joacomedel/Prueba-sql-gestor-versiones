CREATE OR REPLACE FUNCTION public.w_app_usuariowebaccesso(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
* Recite el json con informacion del accesso y carga en la tabla "w_app_usuariowebaccesso_log"
*{"respuesta":true,"mensaje":"Ok","resultado":[{"afiliado":[{"nro":470,"dpto":"","mutu":null,"piso":"","sexo":"M","tira":"","barra":32,"calle":"RIVADAVIA","carct":"0299","email":"sebileg@hotmail.com","barrio":"","cbufin":"55109305684921","cbuini":"19100933","estado":"ACTIVO","idreci":null,"nrodoc":"43947118","osreci":null,"ingreso":null,"nombres":"SEBASTIAN NICOLAS","nromutu":null,"tipodoc":1,"trabaja":null,"apellido":"LEGNAZZI","estcivil":"1","fechanac":"2002-02-10","idctacte":439471181,"idestado":2,"idosreci":null,"nrobanco":"191","telefono":"155313602","legajosiu":198,"nrocuenta":"568492","nrodocjub":null,"osexterna":"ISSN","fechafinos":"2024-07-30","fechainios":"2023-04-18","idcertpers":null,"idresolbec":null,"nrocuildni":"43947118","nrocuilfin":"3","nrocuilini":"20","nrodocreal":null,"tipocuenta":"2","tipodocjub":null,"trabajaunc":null,"emailcuenta":"sebileg@hotmail.com","iddireccion":55830,"idlocalidad":6,"idosexterna":"16","idprovincia":2,"nrosucursal":"93","textoalerta":null,"fechavtoreci":null,"nroosexterna":43947118,"ctacteexpendio":"true","nrocuentaviejo":"nrocuenta:568492tipocuenta:2nrobanco:191nrosucursal:93digitoverificador:2cbu:19100933-55109305684921","reciprocidades":null,"tipodocjubides":null,"digitoverificador":"2","idcentrodireccion":1}]}]}
*{"respuesta":false,"mensaje":"ERROR:  R-006, El usuario \/ contrase\u00f1a ingresados no coinciden con ning\u00fan usuario registrado\nCONTEXT:  funci\u00f3n PL\/pgSQL w_crearusuarioafiliadoapp","resultado":[],"nombreusr":"20-28718951-7","fecha":"2023-08-17 13:54:30"}
*/
      rrespuesta RECORD;
	  rbuscoidusu RECORD;
	  fecha_actual TIMESTAMP;
      respuestajson jsonb;
	  elidusuarioweb bigint;
	  elidusuariowebaccesso bigint;
begin
	-- Verifico que siempre este "respuesta"
	IF nullvalue(parametro->>'respuesta') THEN 
		RAISE EXCEPTION 'R-001, Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;
	--Me fijo si estoy ingresando desde la tabla "w_log_mensajes" (SP) o desde "request.php" (app)
	IF nullvalue(parametro->>'fecha') THEN
		fecha_actual = now();
	ELSE
		fecha_actual = parametro->>'fecha';
	END IF;
	--RAISE EXCEPTION 'parametros:  %',parametro; sl 28/08 - DEBUG
	IF nullvalue(parametro->>'nombreusr') THEN
	-- Si no encuentra "nombreusr" significa que el log es tipo OK y tengo el usuario
		elidusuarioweb = parametro->'resultado'->0->'loginAfil'->>'idusuarioweb';
	ELSE
	-- Si encuentro "nombreusr" significa que el log ingresado fue tipo ERROR y tengo que buscar el usuario
		SELECT INTO elidusuarioweb idusuarioweb 
			FROM w_usuarioweb 
		WHERE uwnombre = (parametro->>'nombreusr');
	END IF;
	--RAISE NOTICE 'idusuarioweb:  %',elidusuarioweb; sl 28/08 - DEBUG
	-- Verifico que el "id" del usuario no sea nulo
	IF NOT nullvalue(elidusuarioweb) THEN
		SELECT INTO rrespuesta * FROM w_app_usuariowebaccesso_log WHERE idusuarioweb = elidusuarioweb;
		--Verifico si existe registros en la tabla
		IF FOUND THEN
			--RAISE NOTICE 'parametros - Respuesta:  %',rrespuesta; sl 28/08 - DEBUG
			IF (parametro->>'respuesta') THEN
				-- Si no existe actualizo los datos en "uwaultimoacceso" y "uwaprimeraccesso"
				IF(nullvalue(rrespuesta.uwaprimeraccesso) OR rrespuesta.uwaprimeraccesso >= fecha_actual) THEN
				-- Realiza el update si la fecha ingresada es mayor a la almacenada
					UPDATE w_app_usuariowebaccesso_log SET 
						uwaprimeraccesso = fecha_actual
					WHERE idusuarioweb = elidusuarioweb;
				END IF;
				-- Si existe actualizo los datos en "uwaultimoacceso"
				IF(nullvalue(rrespuesta.uwaultimoaccesso) OR rrespuesta.uwaultimoaccesso <= fecha_actual) THEN
				-- Realiza el update si la fecha ingresada es menor a la almacenada
					UPDATE w_app_usuariowebaccesso_log SET 
						uwaultimoaccesso = fecha_actual
					WHERE idusuarioweb = elidusuarioweb;
				END IF;
			ELSE
			--Si la respuesta no es 'true' fue un error
				IF(nullvalue(rrespuesta.uwaprimerafalla) OR rrespuesta.uwaprimerafalla >= fecha_actual) THEN
				-- Realiza el update si la fecha ingresada es mayor a la almacenada
					UPDATE w_app_usuariowebaccesso_log SET 
						uwaprimerafalla = fecha_actual,
						uwacantfallas = (rrespuesta.uwacantfallas + 1)
					WHERE idusuarioweb = elidusuarioweb;
				END IF;
				IF(nullvalue(rrespuesta.uwaultimafalla) OR rrespuesta.uwaultimafalla <= fecha_actual) THEN
				-- Realiza el update si la fecha ingresada es menor a la almacenada
					UPDATE w_app_usuariowebaccesso_log SET 
						uwaultimafalla = fecha_actual,
						uwacantfallas = (rrespuesta.uwacantfallas + 1)
					WHERE idusuarioweb = elidusuarioweb;
				END IF;
			END IF;
			elidusuariowebaccesso = rrespuesta.idusuariowebaccesso;
		ELSE
			-- En caso que no existan registros creo uno verificado que el "idusuarioweb" exista
			SELECT INTO rbuscoidusu FROM w_usuarioweb WHERE idusuarioweb = parametro->'resultado'->0->'loginAfil'->>'idusuarioweb';
			IF FOUND THEN
				IF (parametro->>'respuesta') THEN
						--Caso "OK"
						INSERT INTO w_app_usuariowebaccesso_log (idusuarioweb, uwaultimoaccesso, uwaprimeraccesso, uwacantfallas) VALUES (elidusuarioweb, fecha_actual, fecha_actual, 0);
				ELSE
						--Caso "Error"
						INSERT INTO w_app_usuariowebaccesso_log (idusuarioweb, uwaultimafalla, uwaprimerafalla, uwacantfallas) VALUES (elidusuarioweb, fecha_actual, fecha_actual, 1);
				END IF;
				--Obtengo el id del registro insertado
				elidusuariowebaccesso = currval('w_app_usuariowebaccesso_log_idusuariowebaccesso_seq');
				respuestajson = concat('{"idusuariowebaccesso":', elidusuariowebaccesso ,'}');
			ELSE
				respuestajson = '{"idusuariowebaccesso": 0}';
			END IF;
		END IF;
	ELSE
		respuestajson = '{"idusuariowebaccesso": 0}';
	END IF;
	return respuestajson;
end;
$function$
