CREATE OR REPLACE FUNCTION public.w_app_perfil(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
*{"idusuarioweb":5538,
	"uwnombreusuario":"DarianaS",
	"uwmail": "darianagsm@gmail.com",
	"nrodoc": "43947118", 
	"contrasenaViejaTD": "NLTxSCknLPuCB+pdPhml/Q==	", 
	"contrasenaViejaMD5": "f39c39aa7630dbfd1d23865f0cf31610", 
	"contrasenaNuevaTD": "NLTxSCknLPuCB+pdPhml/Q==	",
	"contrasenaNuevaMD5": "f39c39aa7630dbfd1d23865f0cf31610", 
	"arubicacion": "beluansola@gmail.com", 
	"perfil_accion": "editar", 
	"telefono": 12345678 }
*/
DECLARE
--VARIABLES 
   eluwnombre varchar;
   eluwmail varchar;
   vaccion varchar;    
   elnrodoc varchar;
   contrasenaViejaTD varchar;
   contrasenaViejaMD5 varchar;
   contrasenaNuevaTD varchar;
   contrasenaNuevaMD5 varchar;
   elidusuarioweb bigint;
   eltelefono bigint;
   losarchivos varchar;
   contrasenaweb varchar;
   contrasenaact varchar;
   respuestajson jsonb;
--RECORD
    uwnombreusuario  RECORD;
    esusuario RECORD;
	contrasena RECORD;
	espersona RECORD;
	nombreusuario varchar;
	mi_variable RECORD;
    emailrepetido RECORD;
    wusuario RECORD;
	wusuario_old RECORD;
	
BEGIN
	elidusuarioweb = parametro->>'idusuarioweb';
	elnrodoc = parametro ->> 'nrodoc';
	eluwnombre  = parametro->>'uwnombreusuario';
	eluwmail = parametro ->>'uwmail';
	vaccion = parametro ->>'perfil_accion';
	contrasenaViejaTD = parametro ->>'contrasenaViejaTD';
	contrasenaViejaMD5 = parametro ->>'contrasenaViejaMD5';
	contrasenaNuevaTD = parametro ->>'contrasenaNuevaTD';
	contrasenaNuevaMD5 = parametro ->>'contrasenaNuevaMD5';
	losarchivos = parametro ->>'archivos';
	eltelefono = parametro ->>'telefono';

	

	-- Verifica si es usuario 
	SELECT login INTO esusuario
	FROM usuario
	WHERE dni = elnrodoc;

	-- Verifica si esta en persona
	SELECT nrodoc INTO espersona
	FROM persona
	WHERE nrodoc = elnrodoc;

    IF (vaccion = 'editar') THEN 

		SELECT uwnombre, uwmail, w_obtener_archivo(jsonb_build_object('idarchivo', uwa.idarchivo, 'idcentroarchivo', uwa.idcentroarchivo)) AS warchivo, uwemailverificado, telefono, idarchivo
		INTO wusuario_old
		FROM w_usuarioweb as uw
		LEFT JOIN w_usuariowebarchivo uwa ON uwa.idusuarioweb = uw.idusuarioweb
		JOIN persona pe ON pe.nrodoc = elnrodoc
		WHERE uw.idusuarioweb = elidusuarioweb AND nrodoc = elnrodoc;

		IF elidusuarioweb IS NULL THEN
			RAISE EXCEPTION 'R-001 editarperfil: parametro idsuariowebinvalido. Parámetros: %',elidusuarioweb;
		END IF;	
		
		-- Si el uwnombre no es null procede a actualizarlo
		IF eluwnombre IS NOT NULL THEN

                 --DS 03-04-24 agrego if para verificar que el usuario tenga su email verificado antes de cambiar su nombre de usuario
                 IF wusuario_old.uwemailverificado IS NULL THEN
                  RAISE EXCEPTION 'R-003: Primero verifica tu email para poder cambiar tu nombre de usuario: %', eluwnombre;
                 END IF;

			BEGIN
			
				-- Si no es nulo, es empleado y actualiza el nombre de usuario (login) en la tabla usuario
				IF esusuario IS NOT NULL THEN				
					UPDATE usuario 
					SET login = eluwnombre
					WHERE dni = elnrodoc;
				
				-- Si es nulo, no es usuario y busca si el nuevo nombre de usuario existe o no en la tabla usuario
				ELSE
					SELECT INTO uwnombreusuario login FROM usuario WHERE login = eluwnombre;
					IF uwnombreusuario IS NOT NULL THEN
						RAISE EXCEPTION 'R-002: El nombre de usuario ya existe: %', eluwnombre;
					END IF;
				END IF;

				-- Se actualiza el campo uwnombre en w_usuarioweb independientemente del resultado
				UPDATE w_usuarioweb 
				SET uwnombre = eluwnombre
				WHERE idusuarioweb = elidusuarioweb;
				EXCEPTION WHEN unique_violation THEN RAISE EXCEPTION 'R-003: El nombre de usuario ya existe: %', eluwnombre;
			END;
		END IF;

		-- Si el eluwmail no es null procede a actualizarlo
		IF eluwmail IS NOT NULL THEN
		
			-- Verifico si ya existe un email igual y que ya esté verificado
			SELECT uwmail INTO emailrepetido
			FROM w_usuarioweb w
			WHERE (w.uwmail = eluwmail) AND w.uwemailverificado IS NOT NULL;

			-- Si el email existe se envia una excepción de que ya existe
			IF emailrepetido IS NOT NULL THEN				
				RAISE EXCEPTION 'R-004: El email ya se encuentra en uso: %', eluwmail;

			-- Si el email no existe lo actualizo 
			ELSE 
				-- Si es usuario actualizo en usuario el email 
				IF esusuario IS NOT NULL THEN	
					UPDATE usuario 
					SET umail = eluwmail
					WHERE dni = elnrodoc;
				END IF;

				-- Si es una persona actualizo en el email en persona
				IF espersona IS NOT NULL THEN	
					UPDATE persona 
					SET email = eluwmail
					WHERE nrodoc = elnrodoc;
				END IF;

				-- actalizo el email
				UPDATE w_usuarioweb 
				SET uwmail = eluwmail, uwemailverificado = null, uwverificador = NULL
				WHERE idusuarioweb = elidusuarioweb;

				SELECT uwnombre INTO eluwnombre FROM w_usuarioweb WHERE idusuarioweb = elidusuarioweb;

				-- SELECT FROM w_enviarNotificacionPush(jsonb_build_object(
            	-- 'nombreusr', 'DarianaS',
            	-- 'tag', 'tagNotif',
				-- 'interno', true,
            	-- 'mensaje', '¡Verifica tu correo en la app para una mayor seguridad! Ahora puedes verificar tu correo en la app para proteger tu cuenta. Esto te permitirá recuperar y cambiar tu contraseña, así como iniciar sesión con tu correo electrónico. ¡Mantén tu cuenta protegida!',
            	-- 'link', 'editar_perfil',
            	-- 'sensible', false
        		-- ));

			END IF;

    	END IF;

		-- Si el eltelefono no es null procede a actualizarlo
		IF eltelefono IS NOT NULL THEN

			-- Si es una persona actualizo el telefono en persona
			IF espersona IS NOT NULL THEN	
				UPDATE persona 
				SET telefono = eltelefono
				WHERE nrodoc = elnrodoc;
			END IF;

		END IF;

		-- Si tiene archivos actualiza la imagen
		IF losarchivos IS NOT NULL THEN

			-- Si tiene un archivo anterior lo elimina
			IF wusuario_old.idarchivo IS NOT NULL THEN
				UPDATE w_usuariowebarchivo 
					SET uwaeliminado = now()
				WHERE idusuarioweb = elidusuarioweb;
			END IF; 

			-- RAISE EXCEPTION 'R-004: El email ya se encuentra en uso: %', losarchivos::json->0->>'idarchivo';
			
			-- Inserta el nuevo archivo
			INSERT INTO w_usuariowebarchivo (idusuarioweb, idarchivo, idcentroarchivo) VALUES 
                (elidusuarioweb, CAST(losarchivos::json->0->>'idarchivo' AS BIGINT), CAST(losarchivos::json->0->>'idcentroarchivo' AS BIGINT));			

		END IF;
		
		SELECT uwnombre, uwmail, telefono, uwemailverificado, 
			   w_obtener_archivo(jsonb_build_object('idarchivo', uwa.idarchivo, 'idcentroarchivo', uwa.idcentroarchivo)) AS warchivo
		INTO wusuario
		FROM w_usuarioweb as uw
		LEFT JOIN w_usuariowebarchivo uwa ON uwa.idusuarioweb = uw.idusuarioweb
		--JOIN w_archivo as wa ON uwa.idarchivo = wa.idarchivo AND uwa.idcentroarchivo = wa.idcentroarchivo
		LEFT JOIN persona pe ON pe.nrodoc = elnrodoc
		WHERE uwa.uwaeliminado IS NULL AND uw.idusuarioweb = elidusuarioweb;

		respuestajson = jsonb_build_object(
			'wusuario', wusuario,
			'wusuario_old', jsonb_build_object(
				'uwnombre', wusuario_old.uwnombre,
				'uwmail', wusuario_old.uwmail,
				'telefono', wusuario_old.telefono
			)
		);

		-- respuestajson = row_to_json(wusuario);	

	ELSE 

		-- verifica que la accion sea un cambio de contraseña
		IF (vaccion = 'cambiocontrasena') THEN 

					-- se fija si no es un usuario
					IF (esusuario  IS NOT NULL) THEN
						SELECT login, usuario.contrasena INTO nombreusuario, eluwnombre
						FROM usuario
						WHERE dni = elnrodoc;
						contrasenaweb := contrasenaNuevaTD;
						
						-- en caso de que sea para recuperar la contraseña en TD la obtengo para después enviarla a w_gestionarpass
						IF(parametro->>'vaccionn' = 'contrasenanuevatoken') THEN 
						contrasenaact := eluwnombre;
						ELSE
						contrasenaact := contrasenaViejaTD;
						END IF;

					ELSE
						SELECT uwnombre, uwcontrasenia INTO nombreusuario, eluwnombre
        				FROM w_usuarioweb
        				WHERE idusuarioweb = elidusuarioweb;
						contrasenaweb := contrasenaNuevaMD5;

						-- en caso de que sea para recuperar la contraseña en MD5 la obtengo para después enviarla a w_gestionarpass
						IF(parametro->>'vaccionn' = 'contrasenanuevatoken') THEN 
						contrasenaact := eluwnombre;
						ELSE
						contrasenaact := contrasenaViejaMD5;
						END IF;

					END IF;	
					
					-- llamo a gestionarPass vcon el nombre de usaurio, contraseña nueva y actual
					SELECT * INTO mi_variable FROM w_gestionarPass(
                        jsonb_build_object(
                            'accion', 'cambiar',
                            'nombreusr', nombreusuario,
                            'pass', contrasenaweb,
                            'passAct', contrasenaact,
                            'passMD5', contrasenaNuevaMD5,
                            'idcliente', 'web',
                            'versionapp', '1.0.1'
                        )
                    );
		END IF;

	END IF;
	
	RETURN respuestajson;

END;
$function$
