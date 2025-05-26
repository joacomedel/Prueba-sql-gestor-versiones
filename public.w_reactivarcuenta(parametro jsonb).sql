CREATE OR REPLACE FUNCTION public.w_reactivarcuenta(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ /*
	SELECT * FROM public.w_reactivarcuenta('{"nombreusr":"NOMBREUSR","cuentaid":"CUENTAID"}')
*/
DECLARE	
	respuestajson jsonb;
	extendida record;
	
	vcuentaid text;
	vnombreusr varchar;
	vidusr int;	
BEGIN
	vnombreusr = parametro ->> 'nombreusr';
	vcuentaid = parametro ->> 'cuentaid';
	
	IF (vnombreusr IS NULL OR vcuentaid IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos reactivarCuentaExtendida, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;
	
	SELECT INTO vidusr idusuarioweb
		FROM public.w_usuarioweb
			NATURAL JOIN public.w_usuarioafiliado
			NATURAL JOIN public.persona AS p
			LEFT JOIN public.usuario ON (p.nrodoc = usuario.dni AND p.tipodoc = usuario.tipodoc)		
		WHERE uwactivo AND uwtipo <> 3 AND (login = vnombreusr OR uwnombre = vnombreusr);
	IF NOT FOUND THEN
		RAISE EXCEPTION 'R-002, Usuario Inválido, intentelo nuevamente o comuniquese con soporte.';
	END IF;
	
	SELECT INTO extendida *
		FROM public.w_usuariocuentaextendida
			JOIN public.w_cuentaextendida ON (idcuenta = idcuentaextendida)
		WHERE idusuarioweb = vidusr AND cuentaid = vcuentaid
		ORDER BY fechaini DESC;
	IF FOUND THEN
		IF (extendida.activa AND extendida.suspendida) THEN
			BEGIN
				UPDATE public.w_usuariocuentaextendida SET suspendida = false
					WHERE idcuentaextendida = extendida.idcuentaextendida
						AND idusuarioweb = extendida.idusuarioweb AND fechaini = extendida.fechaini;
			EXCEPTION
				WHEN OTHERS THEN
					RAISE EXCEPTION 'R-005, Error al reactivar la cuenta, código %. Intente nuevamente o comuniquese con soporte. INFO: %', SQLSTATE, SQLERRM;
			END;
			respuestajson = '{ "mensaje" : "Cuenta reactivada!" }';
		ELSE
			RAISE EXCEPTION 'R-004, No es necesario reactivar la cuenta.';					
		END IF;				
	ELSE
		RAISE EXCEPTION 'R-003, No se encontro la cuenta a reactivar.';
	END IF;
		
	RETURN respuestajson;	
END
$function$
