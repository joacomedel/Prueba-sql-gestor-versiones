CREATE OR REPLACE FUNCTION public.w_desvincularcuenta(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ /*
	SELECT * FROM public.w_desvincularcuenta('{"nombreusr":"NOMBREUSR","cuentaid":"CUENTAID"}')
*/
DECLARE	
	respuestajson jsonb;
	extendida record;
	
	vcuentaid text;
	vnombreusr varchar;
	vidusr BIGINT;	
BEGIN
	vnombreusr = parametro ->> 'nombreusr';
	vcuentaid = parametro ->> 'cuentaid';
	
	IF (vnombreusr IS NULL OR vcuentaid IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos desvincularCuentaExtendia, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;
	
	SELECT INTO vidusr idusuarioweb
		FROM public.w_usuarioweb
			LEFT JOIN ( SELECT *
	            FROM  w_usuarioafiliado
		        NATURAL JOIN persona
		        LEFT JOIN usuario ON (persona.nrodoc = usuario.dni AND persona.tipodoc = usuario.tipodoc)
	)AS TA USING(idusuarioweb)
	LEFT JOIN ( SELECT *
				FROM w_usuarioprestador
				NATURAL JOIN prestador
	) as TP USING(idusuarioweb)
        WHERE (uwnombre = vnombreusr OR login = vnombreusr OR nullvalue(vnombreusr)) AND uwactivo;


    -- SELECT INTO rdatos idusuarioweb, uwnombre, uwmail
	-- FROM  w_usuarioweb
	-- LEFT JOIN ( SELECT *
	--             FROM  w_usuarioafiliado
	-- 	        NATURAL JOIN persona
	-- 	        LEFT JOIN usuario ON (persona.nrodoc = usuario.dni AND persona.tipodoc = usuario.tipodoc)
	-- )AS TA USING(idusuarioweb)
	-- LEFT JOIN ( SELECT *
	-- 			FROM w_usuarioprestador
	-- 			NATURAL JOIN prestador
	-- ) as TP USING(idusuarioweb)
	-- WHERE (uwnombre = nombreUsr OR login = nombreUsr OR nullvalue(nombreUsr)) AND uwactivo
	-- GROUP BY idusuarioweb, uwnombre, uwmail;


	IF NOT FOUND THEN
		RAISE EXCEPTION 'R-002, Usuario Inválido, inténtelo nuevamente o comuníquese con soporte.';
	END IF;
	
	SELECT INTO extendida *
		FROM public.w_usuariocuentaextendida
			JOIN public.w_cuentaextendida ON (idcuenta = idcuentaextendida)
		WHERE idusuarioweb = vidusr AND cuentaid = vcuentaid
		ORDER BY fechaini DESC;
	IF FOUND THEN
		IF (extendida.activa) THEN
			BEGIN
				UPDATE public.w_usuariocuentaextendida
					SET activa = false, fechafin = now()
					WHERE idcuentaextendida = extendida.idcuentaextendida
						AND idusuarioweb = extendida.idusuarioweb AND fechaini = extendida.fechaini;
			EXCEPTION
				WHEN OTHERS THEN
					RAISE EXCEPTION 'R-005, Error al desvincular la cuenta, código %. Intente nuevamente o comuníquese con soporte. INFO: %', SQLSTATE, SQLERRM;
			END;
			respuestajson = '{ "mensaje" : "Cuenta desvinculada!" }';
		ELSE
			RAISE EXCEPTION 'R-004, La cuenta ya está desvinculada.';					
		END IF;				
	ELSE
		RAISE EXCEPTION 'R-003, No se encontró la cuenta a desvincular.';
	END IF;
		
	RETURN respuestajson;	
END
$function$
