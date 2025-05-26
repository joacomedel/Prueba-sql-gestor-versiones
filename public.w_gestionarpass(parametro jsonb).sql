CREATE OR REPLACE FUNCTION public.w_gestionarpass(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
		
		SELECT * FROM public.w_gestionarPass(''{ "accion":"cambiar", "nombreusr":"', nombreusuario, '", "pass":"(TP O MD5)", "passAct":"(TP O MD5)", "idcliente":"web", "versionapp":"1.0.1" }'')
	*/
	/*
		El tipo usr 1 tiene que recibir el dni en public.usuario
		El tipo usr 2 tiene que recibir el idusuarioweb en public.w_usuarioweb
	*/
DECLARE
	respuestajson jsonb;
	vexito boolean;
	vuwlimpiar varchar;	
	jusuario jsonb;
	vupdate varchar;
	vaux varchar;
	vaccion varchar;
	vnombreusr varchar;
	vtipousr integer;
	vidusr varchar;
	vidusuarioweb integer;
	vpass varchar;
	vpassact varchar;
	vpassactMD5 varchar;
	versionapp varchar;
BEGIN
	versionapp = parametro->>'versionapp';	
	IF versionapp IS NULL THEN versionapp = '1.0.0'; END IF; /*Valor por defecto de la app si no lo envian en la llamada*/
	
	vaccion = parametro ->> 'accion';
	vnombreusr = parametro ->> 'nombreusr';	
	vpass = parametro ->> 'pass';
	vpassact = parametro ->> 'passAct';
	vpassactMD5 = parametro ->> 'passMD5';

	IF (vaccion IS NULL OR vnombreusr IS NULL OR vpass IS NULL OR vpassact IS NULL ) THEN 
		RAISE EXCEPTION	 'R-001 WS_CambiarPass: Parámetros  Inválidos %',vpassact;
	END IF;
	
	IF (vaccion = 'reenviar') THEN
		vuwlimpiar = true;
	ELSIF (vaccion = 'cambiar') THEN
		vuwlimpiar = '';
	ELSE 
		RAISE EXCEPTION 'R-006 WS_CambiarPass: Tipo de Acción Inválida, Recibido: %',vaccion;
	END IF;
	
	-- Se usa por defecto login afil, pero también contiene loginPrestador
	-- ds * agrego parámetros para enviar al login (passAct) 28/12/23 
	vaux := '{
    "accion":"loginAfil", 
    "nombreusr":"' || vnombreusr || '", 
    "contrasenaMD5":"' || vpassact || '", 
    "contrasenaTD":"' || vpassact || '", 
    "idcliente":"interno"
	}';

	SELECT INTO jusuario * FROM public.w_login(vaux::jsonb);
	jusuario = (jusuario->>'loginAfil')::jsonb;	
	
	vtipousr = jusuario->>'tipousr';
	vidusr = jusuario->>'idusr';
	vidusuarioweb = jusuario->>'idusuarioweb';

	-- Verifico que tipo de usuario es
	IF (vtipousr = 0) THEN
		--Es usuario de SIGES		
		UPDATE public.usuario SET contrasena = vpass WHERE dni = vidusr;
		
	--ELSE
	
	END IF;

		--Es UN AFILIADO que no es usuario de SIGES (prestador o afiliado)
		UPDATE public.w_usuarioweb SET uwcontrasenia = vpassactMD5
					 WHERE idusuarioweb = vidusr OR idusuarioweb = vidusuarioweb;
		--EXECUTE vupdate;

	
	--Suspendo todas las cuentas extendidas del usuario
	-- SELECT INTO vexito FROM public.suspendercuentas(vidusr); -- SL 26/02/24 - Permito que se pueda cambiar la contraseña y no desvincule el google

	IF (NOT vexito) THEN
		RAISE EXCEPTION 'R-005 WS_CambiarPass: No se pudieron desconectar las cuentas extendidas';
	END IF;
	
	respuestajson = '{"versionapp":"' ||versionapp|| '", "cambiarpass": true}';	

	RETURN respuestajson;
END;
$function$
