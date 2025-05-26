CREATE OR REPLACE FUNCTION public.w_registrocuentaextendida(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ /*SELECT * FROM 
	public.w_registrocuentaextendida('{
	"nombreusr":"usuarioSOSUNC", "uwmail":null,
	"tipocuenta":"GO",
	"datoscuenta":{"apellido": "apeGoogle", "email": "mail@gmail.com", "googleId": "GoogleID", "nombre": "nombreGoogle", "nombreUsuario": "nombreUsrGoogle","urlFoto": ""},
	"idcliente":"movil", "versionapp":"0.1.0"}'::jsonb);
	--La versión 0.1.0, es para prueba, los usuarios usan de la 1.0.0 en adelante
	*/
DECLARE
	respuestajson jsonb;
	respuestajson_info jsonb;
	rdatos RECORD;
	aux RECORD;
	cuentaextendida RECORD;	
	rtiposcuenta RECORD;
	
	nombreUsr varchar;
	tipoCuenta varchar;	
	vdatosCuenta jsonb;	
	vcliente varchar;
	versionapp varchar;	
	vcuentaid text;
BEGIN	
	nombreUsr = parametro->>'nombreusr';
	tipoCuenta = parametro->>'tipocuenta';
	vdatosCuenta = parametro->>'datoscuenta';
	
	versionapp = parametro->>'versionapp';	
	IF versionapp IS NULL THEN
		versionapp = '1.0.0'; /*Valor por defecto de la app si no lo envian en la llamada*/
	END IF;
	/* vcliente = parametro->>'idcliente'; */
	
	--Verificación y extracción de parámetros
	IF (nombreUsr IS NULL OR tipoCuenta IS NULL OR vdatosCuenta IS NULL) THEN
		RAISE EXCEPTION 'R-002, Parámetros inválidos registrarCuentaExtendida, revíselos y envíelos nuevamente. Parámetros: %', parametro;
	END IF;
	
	
	--Verifico tipo cuenta existe y está activo
	SELECT INTO rtiposcuenta *
		FROM public.w_tipocuentaextendida
		WHERE tipoCuenta = idtipocuentaextendida AND activo;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'R-003, Se recibió un tipo de cuenta inválido o inactivo, inténtelo nuevamente. Recibido: %.', tipocuenta;
	END IF;
	
	--Extraigo el respectivo cuentaid
	CASE tipoCuenta
		WHEN 'GO' THEN
			/*Restricciones propias de Google*/
			IF ((vdatosCuenta->>'googleId') IS NULL OR (vdatosCuenta->>'email') IS NULL OR (vdatosCuenta->>'nombreUsuario') IS NULL) THEN
				RAISE EXCEPTION 'R-004, Datos de Google Inválidos, revíselos y envíelos nuevamente. %', parametro;
			END IF;
			vcuentaid = vdatosCuenta->>'googleId';
		ELSE RAISE EXCEPTION 'R-005, Tipo de Cuenta Inválido.';
	END CASE;
	-- sl 11/08/23 - Verifico que sea afiliado o un prestador
	SELECT INTO rdatos idusuarioweb, uwnombre, uwmail, login
	FROM  w_usuarioweb
	LEFT JOIN ( SELECT *
	            FROM  w_usuarioafiliado
		        NATURAL JOIN persona
		        LEFT JOIN usuario ON (persona.nrodoc = usuario.dni AND persona.tipodoc = usuario.tipodoc)
	)AS TA USING(idusuarioweb)
	LEFT JOIN ( SELECT *
				FROM w_usuarioprestador
				NATURAL JOIN prestador
	) as TP USING(idusuarioweb)
	WHERE (uwnombre = nombreUsr OR login = nombreUsr OR nullvalue(nombreUsr)) AND uwactivo
	GROUP BY login, idusuarioweb, uwnombre, uwmail;		-- SL 26/02/24 - Agrego login para el orden de la consulta y poder asociar correctamente a los usuarios de SIGES
	IF FOUND THEN
		SELECT INTO cuentaextendida idcuenta
			FROM public.w_cuentaextendida
			WHERE cuentaid = vcuentaid;
		IF FOUND THEN
			SELECT INTO aux *
				FROM public.w_usuariocuentaextendida
				WHERE activa AND idcuentaextendida = cuentaextendida.idcuenta;
			IF FOUND THEN
				--si la cuenta esta activa, entonces se cancela la creación
				RAISE EXCEPTION 'R-006, La cuenta ingresada, ya se encuentra registrada. Si usted no lo hizo, contacte con soporte y presente su nombre de usuario.';								
			END IF;			
			UPDATE public.w_cuentaextendida SET datoscuenta = vdatoscuenta WHERE cuentaid = vcuentaid;
		ELSE
		--Si no existe la cuenta extendida, se crea la cuenta y se asocia
			/*Eliminar id de cada tipo de cuenta (para que no se repita con la tabla), no lo soporta postgres 9.4 si postgres 13 (9.5+) -> datosCuenta - "googleId";*/
			/*Actualmente se guardan todos los datos recibidos en el campo datoscuenta*/
			WITH extendida_creada AS (
				INSERT INTO public.w_cuentaextendida (cuentaid, datoscuenta, idtipocuentaextendida)
					VALUES (vcuentaid, vdatosCuenta, tipocuenta) RETURNING idcuenta
			)
			SELECT INTO cuentaextendida * FROM extendida_creada;
		END IF;
		-- Si se creó la cuenta, o la cuenta existe y ninguno la tiene asociada activa => se hace la nueva asociación
		INSERT INTO public.w_usuariocuentaextendida (idcuentaextendida, idusuarioweb, activa, suspendida)
			VALUES (cuentaextendida.idcuenta, rdatos.idusuarioweb, true, false); 
		
		SELECT INTO rdatos cuentaid, datoscuenta->>'email' AS email, idtipocuentaextendida AS tipocuenta, datoscuenta->>'nombreUsuario' AS nombreusr, suspendida
			FROM public.w_cuentaextendida NATURAL JOIN public.w_usuariocuentaextendida
			WHERE vcuentaid = cuentaid AND rdatos.idusuarioweb = idusuarioweb;
	
		respuestajson_info = concat('{ "res" : ', row_to_json(rdatos), ' ,"mensaje" : "Registro exitoso de cuenta secundaria." }');
		respuestajson = respuestajson_info;
	ELSE
		RAISE EXCEPTION 'R-001, Los datos informados no existen en el sistema. %', parametro;
	END IF;		
	
	return respuestajson;
END$function$
