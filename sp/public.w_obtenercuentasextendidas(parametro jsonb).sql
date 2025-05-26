CREATE OR REPLACE FUNCTION public.w_obtenercuentasextendidas(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
 /*
	SELECT FROM public.w_obtenercuentasextendidas('{"nombreusr":"usuarioSOSUNC"}');
*/
DECLARE
	respuestajson jsonb;
	cuentas jsonb;
	
	vnombreusr varchar;	
	vidusr varchar;
BEGIN
	vnombreusr = parametro->>'nombreusr';
	IF vnombreusr IS NULL THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos obtenerCuentaExtendida, revíselos y envíelos nuevamente. Parámetros: %', parametro;
	END IF;
	-- sl 11/08/23 - Agrego  si es afiliado o prestador
	SELECT INTO vidusr idusuarioweb 
		FROM public.w_usuarioweb
			LEFT JOIN public.w_usuarioafiliado as ua USING (idusuarioweb)
			LEFT JOIN public.usuario ON (ua.nrodoc = usuario.dni AND ua.tipodoc = usuario.tipodoc)
		WHERE (uwnombre = vnombreusr OR uwnombre = CONCAT(vnombreusr, '_siges') OR login = vnombreusr) AND uwactivo;
        -- SL 01/10/24 - Agrego "CONCAT(vnombreusr, '_siges')" para los empleados que no tienen cuenta tipo afiliado
	IF NOT FOUND THEN
		RAISE EXCEPTION 'R-002, Usuario Inválido, inténtelo nuevamente o comuníquese con soporte.';
	END IF;
	SELECT INTO cuentas json_agg(tablaCuentas)
	FROM (
		SELECT cuentaid, idtipocuentaextendida AS tipocuenta, datoscuenta->>'nombreUsuario' AS nombreusr, datoscuenta->>'email' AS email, suspendida
		FROM public.w_cuentaextendida
			JOIN public.w_usuariocuentaextendida ON (idcuenta = idcuentaextendida)
			NATURAL JOIN public.w_usuarioweb
			LEFT JOIN public.w_usuarioafiliado as ua USING (idusuarioweb)
			LEFT JOIN public.usuario ON (ua.nrodoc = usuario.dni AND ua.tipodoc = usuario.tipodoc)
		WHERE activa AND (uwnombre = vnombreusr OR login = vnombreusr)
		ORDER BY fechaini ASC
	) AS tablaCuentas;
	IF cuentas IS NOT NULL THEN
		respuestajson = concat('{"cuentas":',cuentas,'}');
	ELSE 
		respuestajson = '{"cuentas":[]}';
	END IF;
	
	RETURN respuestajson;
END
$function$
