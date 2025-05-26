CREATE OR REPLACE FUNCTION public.suspendercuentas(idusr text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	exito boolean;
BEGIN
	exito = true;
	BEGIN
		UPDATE public.w_usuariocuentaextendida SET suspendida=true WHERE (idcuentaextendida, idusuarioweb, fechaini) IN
			(SELECT idcuentaextendida, idusuarioweb, fechaini 
			FROM w_cuentaextendida
				JOIN w_usuariocuentaextendida ON (idcuenta = idcuentaextendida)
				NATURAL JOIN w_usuarioweb
				NATURAL JOIN w_usuarioafiliado
				NATURAL JOIN persona as p
				LEFT JOIN usuario ON (p.nrodoc = usuario.dni AND p.tipodoc = usuario.tipodoc)
			WHERE (usuario.dni = idusr OR w_usuarioweb.idusuarioweb = idusr)
				AND uwactivo AND uwtipo <> 3 AND activa);
	EXCEPTION
		WHEN OTHERS THEN
			exito = false;
	END;
	RETURN exito;
END;
$function$
