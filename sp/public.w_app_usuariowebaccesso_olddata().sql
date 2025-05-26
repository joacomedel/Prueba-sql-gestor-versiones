CREATE OR REPLACE FUNCTION public.w_app_usuariowebaccesso_olddata()
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
* SP que recorre toda la tabla "w_log_mensajes" e inserta en "w_app_usuariowebaccesso_log"
* SELECT w_app_usuariowebaccesso_olddata() CORRER UNA SOLA VEZ
*{"respuesta":true,"mensaje":"Ok","resultado":[{"afiliado":[{"nro":470,"dpto":"","mutu":null,"piso":"","sexo":"M","tira":"","barra":32,"calle":"RIVADAVIA","carct":"0299","email":"sebileg@hotmail.com","barrio":"","cbufin":"55109305684921","cbuini":"19100933","estado":"ACTIVO","idreci":null,"nrodoc":"43947118","osreci":null,"ingreso":null,"nombres":"SEBASTIAN NICOLAS","nromutu":null,"tipodoc":1,"trabaja":null,"apellido":"LEGNAZZI","estcivil":"1","fechanac":"2002-02-10","idctacte":439471181,"idestado":2,"idosreci":null,"nrobanco":"191","telefono":"155313602","legajosiu":198,"nrocuenta":"568492","nrodocjub":null,"osexterna":"ISSN","fechafinos":"2024-07-30","fechainios":"2023-04-18","idcertpers":null,"idresolbec":null,"nrocuildni":"43947118","nrocuilfin":"3","nrocuilini":"20","nrodocreal":null,"tipocuenta":"2","tipodocjub":null,"trabajaunc":null,"emailcuenta":"sebileg@hotmail.com","iddireccion":55830,"idlocalidad":6,"idosexterna":"16","idprovincia":2,"nrosucursal":"93","textoalerta":null,"fechavtoreci":null,"nroosexterna":43947118,"ctacteexpendio":"true","nrocuentaviejo":"nrocuenta:568492tipocuenta:2nrobanco:191nrosucursal:93digitoverificador:2cbu:19100933-55109305684921","reciprocidades":null,"tipodocjubides":null,"digitoverificador":"2","idcentrodireccion":1}]}]}
*{"respuesta":false,"mensaje":"ERROR:  R-006, El usuario \/ contrase\u00f1a ingresados no coinciden con ning\u00fan usuario registrado\nCONTEXT:  funci\u00f3n PL\/pgSQL w_crearusuarioafiliadoapp","resultado":[],"nombreusr":"20-28718951-7","fecha":"2023-08-17 13:54:30"}
*/
		--CURSORES
		cfdatos CURSOR FOR SELECT * 
			FROM w_log_mensajes 
			WHERE lmoperacion ilike 'datosLogin%' AND lmentrada ILIKE '%movil%'
			ORDER BY idlogmensajes DESC;

		paramjson jsonb;
		respuestajson jsonb;
		rdatos RECORD;
		cant INTEGER;
begin
	--Inicio contador para ver cuantos insert realiza
	cant = 0;
	-- Abro el cursor
	OPEN cfdatos;
	FETCH cfdatos INTO rdatos;
		WHILE FOUND LOOP
			--RAISE NOTICE 'parametro:  %',rdatos;	-- sl 22/08 - DEBUG
			-- Inserto los parametros de salida con formato JSON
			paramjson = rdatos.lmsalida::jsonb;
			-- Filtro por los casos que me interesan guardar
			IF NOT nullvalue(rdatos.lmentrada::jsonb->>'nombreusr') AND NOT (rdatos.lmentrada::jsonb->>'nombreusr' = '') AND NOT nullvalue(rdatos.lmsalida) AND nullvalue(paramjson->'resultado'->0->>'loginExtendido') THEN
				-- Agrego "Fecha" a el paramjson
				paramjson = paramjson || jsonb_build_object('fecha', rdatos.lmfechaingreso);
				--RAISE NOTICE 'ENTRADA:  %',rdatos.lmentrada;  -- sl 22/08 - DEBUG
				--RAISE NOTICE 'SALIDA:  %',rdatos.lmsalida;	-- sl 22/08 - DEBUG
				-- Si la respuesta es "false" agrego el nombreusr a el json
				IF NOT (paramjson->>'respuesta')::BOOLEAN THEN
					paramjson = paramjson || jsonb_build_object('nombreusr', rdatos.lmentrada::jsonb->>'nombreusr');
				END IF;
				--RAISE NOTICE 'json con valor agregado:  %',paramjson;	-- sl 22/08 - DEBUG
				SELECT INTO rdatos w_app_usuariowebaccesso(paramjson);
				--RAISE NOTICE 'info w_app_usuariowebaccesso:  %',rdatos;	-- sl 22/08 - DEBUG
				IF FOUND THEN
					cant = cant + 1;
				ELSE
					RAISE EXCEPTION 'Error en el SP w_app_usuariowebaccesso: %',paramjson;
				END IF;
			END IF;
			FETCH cfdatos into rdatos;
		END LOOP;
	CLOSE cfdatos;
	respuestajson = concat('{ "resp":', cant, '}');
	return respuestajson;
end;
$function$
