CREATE OR REPLACE FUNCTION public.w_login(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*select from w_login('{"nombreusr":"Karina","accion":"loginAfil","uwmail":null}'::jsonb);*/
 /*sl 16/08/23 - Se cambia consulta para que verifique la contraseña el back select from w_login('{"nombreusr":"SebastianL","contrasenaMD5":"e1a1017f676584c47049d4ee6d448874","contrasenaTD":"AqorQl0H0bKCB+pdPhml/Q==", "accion":"loginAfil","uwmail":null}'::jsonb);*/
/*ds 10/05/24 - cambio la forma en que se piden los permisos para poder hacer menus desplegables en la APP*/
DECLARE 
--RECORD
	respuestajson jsonb;
	versionappjson jsonb;
	respdatosafiljson jsonb;
	respctaextendidajson jsonb;
	respnotifpushjson jsonb;
	rdatos RECORD;
	rdatostodos RECORD;
	vaccion varchar;      
	vcontraMD5 varchar;      
	vcontraTD varchar;     
	vnrodoc varchar;
	vcliente varchar;
	---idturno
BEGIN
	vaccion = parametro->>'accion';
	vcliente = parametro->>'idcliente';
	vcontraMD5 = parametro->>'contrasenaMD5';
	vcontraTD = parametro->>'contrasenaTD';
			
	IF (((parametro ->> 'nombreusr') IS NULL AND NOT (vaccion = 'loginExtendido')) OR vaccion IS NULL OR vcliente IS NULL) THEN
		RAISE EXCEPTION 'R-005 WS_Login, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	IF (vaccion = 'loginSosunc' OR vaccion = 'loginAfil' OR vaccion = 'loginPrestador') THEN 
		 /* 1 ======================= Me fijo si es un Empleado. ======================= */
        SELECT INTO rdatos pe.email AS uwmail, w_obtener_archivo(jsonb_build_object('idarchivo', uwa.idarchivo, 'idcentroarchivo', uwa.idcentroarchivo)) ->> 'arubicacioncompleta' AS warchivo, uwemailverificado, usuario.dni, usuario.dni AS nrodoc, usuario.tipodoc, usuario.apellido, usuario.nombre, concat (usuario.apellido,', ',usuario.nombre) as apeynom,
            uw.idusuarioweb, pe.telefono, usuario.login AS uwnombre, idrolweb, rodescripcion, rodescripcion, peactivo, text_concatenar(concat(idpermiso::varchar,'-', pepagina ,'ç')) AS paginas, centroregional.idcentroregional AS idcentroregional, centroregional.crdescripcion AS crdescripcion, 0 AS tipousr, usuario.dni AS idusr
        FROM usuario NATURAL JOIN usuarioconfiguracion NATURAL JOIN w_usuariorolwebsiges NATURAL JOIN w_rolweb NATURAL JOIN w_permisorolweb NATURAL JOIN w_permiso
            JOIN ca.persona AS p ON (usuario.dni=p.penrodoc and usuario.tipodoc=p.idtipodocumento) 
            LEFT JOIN personacentroregional AS pc ON (usuario.dni=pc.nrodoc and usuario.tipodoc=pc.tipodoc)
            LEFT JOIN centroregional ON  (centroregional.idcentroregional=pc.idcentroregional)
            LEFT JOIN persona AS pe ON (usuario.dni=pe.nrodoc and usuario.tipodoc=pe.tipodoc)
            LEFT JOIN w_usuarioweb AS uw USING (idusuarioweb)
            LEFT JOIN w_usuariowebarchivo uwa ON uwa.idusuarioweb = uw.idusuarioweb	
        WHERE ucactivo 
            AND peactivo   
            AND (TRIM(LOWER(login)) = TRIM(LOWER(parametro->>'nombreusr')) 
                    OR (TRIM(LOWER(uwmail)) = TRIM(LOWER(parametro->>'nombreusr')) 
                    AND NOT nullvalue(uwemailverificado))
                )
            AND (contrasena = vcontraTD)
            AND uwa.uwaeliminado IS NULL
        GROUP BY uw.idusuarioweb, pe.email, uwemailverificado, usuario.login, roprioridad, pe.telefono, usuario.dni, usuario.tipodoc, usuario.nombre, usuario.apellido, usuario.dni, uwnombre, idrolweb, rodescripcion, rodescripcion, peactivo, peemail, centroregional.idcentroregional, centroregional.crdescripcion, uwa.idcentroarchivo, uwa.idarchivo
        ORDER BY roprioridad;

        /* 2 ======================= Me fijo si es un afiliado. ======================= */
        IF NOT FOUND THEN   
			SELECT INTO rdatos p.nrodoc, uwmail, w_obtener_archivo(jsonb_build_object('idarchivo', uwa.idarchivo, 'idcentroarchivo', uwa.idcentroarchivo)) ->> 'arubicacioncompleta' AS warchivo, uwemailverificado, p.telefono, p.tipodoc,apellido, nombres,apellido||', '||nombres AS apeynom, w_usuarioweb.idusuarioweb, uwnombre, uwmail, idrolweb, rodescripcion, peactivo, text_concatenar(concat(idpermiso::varchar,'-', pepagina ,'ç')) AS paginas,
				case WHEN nullvalue(centroregional.crdescripcion) THEN 1 ELSE centroregional.idcentroregional END AS idcentroregional, case WHEN nullvalue(centroregional.crdescripcion) THEN 'NEUQUEN' ELSE centroregional.crdescripcion END AS crdescripcion, uwtipo AS tipousr, w_usuarioweb.idusuarioweb AS idusr
			FROM w_usuarioweb NATURAL JOIN w_usuariorolweb NATURAL JOIN w_rolweb NATURAL JOIN w_permisorolweb NATURAL JOIN  w_permiso
				LEFT JOIN w_usuarioafiliado USING (idusuarioweb)
				LEFT JOIN persona AS p USING (nrodoc,tipodoc)
				LEFT JOIN personacentroregional AS pc ON (p.nrodoc=pc.nrodoc AND p.tipodoc=pc.tipodoc )
				LEFT JOIN centroregional ON  (centroregional.idcentroregional=pc.idcentroregional)
				LEFT JOIN w_usuariowebarchivo uwa ON uwa.idusuarioweb = w_usuarioweb.idusuarioweb
			WHERE uwactivo AND peactivo  AND uwtipo <> 3 AND uwtipo <> 4 AND ((TRIM(LOWER(uwnombre)) = TRIM(LOWER(parametro->>'nombreusr')) OR nullvalue( parametro->>'nombreusr') OR (TRIM(LOWER(uwmail)) = TRIM(LOWER(parametro->>'nombreusr')) AND NOT nullvalue(uwemailverificado)))  
				OR (p.nrodoc  = parametro->>'nombreusr' ))
				AND (uwcontrasenia = vcontraMD5)
				AND uwa.uwaeliminado IS NULL
			GROUP BY uwmail, uwcontrasenia, p.nrodoc, p.tipodoc, nombres, apellido,  w_usuarioweb.idusuarioweb, uwnombre, uwmail, idrolweb, rodescripcion, peactivo, centroregional.idcentroregional, centroregional.crdescripcion, uwa.idarchivo, uwa.idcentroarchivo
            ORDER BY idrolweb;
        END IF;

        /* 3 ======================= Me fijo si es un prestador. ======================= */
        IF NOT FOUND THEN 		
            SELECT INTO rdatos uwmail, idprestador AS nrodoc, idprestador, pcuit, w_obtener_archivo(jsonb_build_object('idarchivo', uwa.idarchivo, 'idcentroarchivo', uwa.idcentroarchivo)) ->> 'arubicacioncompleta' AS warchivo, uwemailverificado, 'CUIT' AS tipodoc, '' AS apellido, pnombrefantasia AS nombre, 
                    pnombrefantasia AS apeynom, w_usuarioweb.idusuarioweb, uwnombre, idrolweb, rodescripcion, uwmail, peactivo, text_concatenar(concat(idpermiso::varchar,'-', pepagina ,'ç')) AS paginas, 1 AS idcentroregional, 'NEUQUEN' AS crdescripcion, uwtipo AS tipousr, w_usuarioweb.idusuarioweb AS idusr
                FROM w_usuarioweb NATURAL JOIN w_usuarioprestador 
                    NATURAL JOIN w_usuariorolweb NATURAL JOIN w_rolweb 
                    NATURAL JOIN w_permisorolweb NATURAL JOIN w_permiso
                    NATURAL JOIN prestador 
                    LEFT JOIN w_usuariowebarchivo uwa ON uwa.idusuarioweb = w_usuarioweb.idusuarioweb
                WHERE uwactivo AND uwtipo = 3 AND (TRIM(LOWER(uwnombre)) = TRIM(LOWER(parametro->>'nombreusr')) OR (uwmail = TRIM(LOWER(parametro->>'nombreusr')) AND NOT nullvalue(uwemailverificado))) 
                    AND (uwcontrasenia = vcontraMD5)
                    AND uwa.uwaeliminado IS NULL
                GROUP BY  uwmail, idprestador, pcuit, uwa.idarchivo, pnombrefantasia, w_usuarioweb.idusuarioweb, uwnombre, uwmail, idrolweb, rodescripcion, peactivo, uwa.idarchivo, uwa.idcentroarchivo
                ORDER BY idrolweb; 		
        END IF;	
		
        /* 4 =======================  Me fijo si es un GESTOR DE PRESTADORES. ======================= */
        IF NOT FOUND THEN
            SELECT INTO rdatos uwmail, w_usuarioweb.idusuarioweb AS nrodoc, uwemailverificado, 'CUIT' AS tipodoc, '' AS apellido, uwgdescripcion AS nombre, 
                uwgdescripcion AS apeynom, w_usuarioweb.idusuarioweb, uwnombre, 1 AS idcentroregional, 'NEUQUEN' AS crdescripcion, uwtipo AS tipousr, w_usuarioweb.idusuarioweb AS idusr,
                w_obtener_archivo(jsonb_build_object('idarchivo', uwa.idarchivo, 'idcentroarchivo', uwa.idcentroarchivo)) ->> 'arubicacioncompleta' AS warchivo
                FROM w_usuarioweb 
                NATURAL JOIN w_usuariowebgestor 
                LEFT JOIN w_usuariowebarchivo uwa ON uwa.idusuarioweb = w_usuarioweb.idusuarioweb
            WHERE uwactivo AND uwtipo = 4 AND (TRIM(LOWER(uwnombre)) = TRIM(LOWER(parametro->>'nombreusr')) OR nullvalue( parametro->>'nombreusr') OR (uwmail = TRIM(LOWER(parametro->>'nombreusr')) AND NOT nullvalue(uwemailverificado))) 
                AND (uwcontrasenia = vcontraMD5)
                AND uwa.uwaeliminado IS NULL
            GROUP BY  uwmail, w_usuarioweb.idusuarioweb, uwnombre, uwgdescripcion, uwa.idarchivo, uwa.idcentroarchivo; 			
        END IF;
    END IF;

    /* 5 =======================  Ingreso con segundo factor ======================= */
	IF (parametro->>'accion' = 'loginExtendido') THEN
		IF ((parametro->>'cuentaid') IS NULL) THEN
			RAISE EXCEPTION 'R-003 WS_Login, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %', parametro;
		END IF;
			SELECT INTO rdatos 
				CASE WHEN (nrodoc IS NULL) THEN idprestador::text ELSE  nrodoc::text END AS nrodoc,
				CASE WHEN (login IS NULL) THEN uwnombre ELSE login END AS uwnombre, idusuarioweb, telefono, uwmail, cuentaid, 
				CASE WHEN apellido IS NULL AND nombres IS NULL AND pnombrefantasia IS NULL THEN uwgdescripcion WHEN pnombrefantasia IS NOT NULL THEN pnombrefantasia ELSE COALESCE(apellido, '') || COALESCE(', ' || nombres, '') END AS apeynom,
				CASE WHEN (tipodoc IS NULL) THEN 'CUIT' ELSE tipodoc::text END AS tipodoc,
				datoscuenta, warchivo, uwemailverificado, pcuit
				FROM (
					SELECT ua.nrodoc, uwgdescripcion, up.idprestador, p.apellido as apellido, nombres, pnombrefantasia, uwemailverificado,
                    p.tipodoc, p.telefono, login, datoscuenta, uw.idusuarioweb as idusuarioweb, uwmail, cuentaid, uwnombre, pcuit,
                    w_obtener_archivo(jsonb_build_object('idarchivo', uwa.idarchivo, 'idcentroarchivo', uwa.idcentroarchivo)) ->> 'arubicacioncompleta' AS warchivo					FROM w_cuentaextendida
						JOIN w_usuariocuentaextendida ON (idcuenta = idcuentaextendida)
						NATURAL JOIN w_usuarioweb AS uw
						LEFT JOIN w_usuarioprestador AS up ON (up.idusuarioweb =  uw.idusuarioweb)
						LEFT JOIN prestador AS pre ON (pre.idprestador = up.idprestador)
						LEFT JOIN w_usuariowebgestor AS uwp ON (uwp.idusuarioweb = uw.idusuarioweb)
						LEFT JOIN w_usuarioafiliado AS ua ON (ua.idusuarioweb = uw.idusuarioweb)
						LEFT JOIN persona AS p ON (p.nrodoc = ua.nrodoc AND p.tipodoc = ua.tipodoc)
						LEFT JOIN usuario AS usu ON (p.nrodoc = usu.dni AND p.tipodoc = usu.tipodoc)
						LEFT JOIN w_usuariowebarchivo uwa ON uwa.idusuarioweb = uw.idusuarioweb
					WHERE cuentaid = parametro->>'cuentaid' 
						AND uwactivo 
						AND activa 
						AND NOT suspendida
						AND uwa.uwaeliminado IS NULL
                ) AS f;
	END IF;

    IF rdatos.idusuarioweb IS NULL THEN
        RAISE EXCEPTION 'R-006, El usuario / contraseña ingresados no coinciden con ningún usuario registrado'; 
    ELSE
        -- Version para APP
        SELECT json_agg(ropermiso) AS roles INTO rdatostodos
        FROM (	
            -- ds 29/11/23 Creo version que devuelve la descripción del los permisos (pelinkdescrip) y saco datos de los usuarios 
            SELECT jsonb_build_object(
            'rodescripcion', rodescripcion, 
            'fechadesde', urwfechadesde, 
            'fechahasta', urwfechahasta, 
            'idrolweb', idrolweb, 
            'permiso', jsonb_agg(
                            jsonb_build_object(
                                'peicono', peicono, 
                                'pmenu', pmenu, 
                                'idpermiso', idpermiso, 
                                'pelinkdescrip', pelinkdescrip, 
                                'panombrecomponente', panombrecomponente, 
                                --'permisopadre', idpermisopadre,
                                'permisoshijos', (
                                        SELECT COALESCE(json_agg(
                                            jsonb_build_object(
                                                'peicono', aph.peicono,
                                                'pmenu', aph.pmenu,
                                                'idpermiso', ph.idpermiso,
                                                'pelinkdescrip', ph.pelinkdescrip,
                                                'panombrecomponente', aph.panombrecomponente,
                                                'permisopadre', aph.idpermisopadre
                                            ) ORDER BY ph.peorden
                                        ), '[]'::json)
                                        FROM w_permiso AS ph
                                        JOIN w_app_permiso AS aph USING (idpermiso)
                                        JOIN w_permisorolweb AS prwh ON ph.idpermiso = prwh.idpermiso
                                        WHERE aph.idpermisopadre = f.idpermiso 
                                        AND prwh.idrolweb = f.idrolweb
                                        AND ph.peactivo = true
                                    )
                                ) 
                        ORDER BY peorden)
            ) AS ropermiso
            FROM (
                SELECT urw.idrolweb, urwfechadesde, urwfechahasta, rodescripcion, peactivo, idpermiso, pmenu, panombrecomponente, peicono, pelinkdescrip AS pelinkdescrip, peorden, ap.idpermisopadre
                FROM w_usuarioweb 
                NATURAL JOIN w_usuariorolweb AS urw
                NATURAL JOIN w_rolweb AS rw 
                NATURAL JOIN w_permisorolweb AS prw 
                NATURAL JOIN w_permiso AS pe
                JOIN w_app_permiso AS ap USING (idpermiso)
                WHERE idusuarioweb = rdatos.idusuarioweb 
                AND ap.idpermisopadre IS NULL
                AND (urwfechahasta >= NOW() OR urwfechahasta IS NULL)
                ORDER BY urw.idrolweb, idpermiso
            ) as f
        GROUP BY rodescripcion, idrolweb, urwfechadesde, urwfechahasta 
        ORDER BY idrolweb
        ) as t;
    END IF;

    IF (rdatostodos IS NOT NULL AND rdatos.idusuarioweb IS NOT NULL) THEN
        --Busco datos para la aplicacion
        SELECT INTO respdatosafiljson * FROM w_datoafiliado(CONCAT('{"doc":"', rdatos.nrodoc, '"}')::JSONB);
        SELECT INTO respctaextendidajson * FROM w_gestioncuentaextendida(CONCAT('{"accion":"obtenerCuentasExtendidas", "datosws":{"nombreusr": "', rdatos.uwnombre, '"}}')::JSONB);
        SELECT INTO respnotifpushjson * FROM w_gestionnotifpush(CONCAT('{"accion":"getNotificaciones", "datosws":{"nombreusr": "', rdatos.uwnombre, '"}}')::JSONB);
        SELECT INTO versionappjson * FROM w_app_getversion();

        respuestajson = concat('{ 
        "versionapp":"', versionappjson->>'version', '", 
        "idcliente":"', vcliente, '", 
        "ctaextendida":', respctaextendidajson->'obtenerCuentasExtendidas', ', 
        "notificaciones":', respnotifpushjson->'getNotificaciones'->'notificaciones', ', 
        "grupofam":',respdatosafiljson, ', 
        "usuario":', row_to_json(rdatos), ', 
        "roles":', rdatostodos.roles, '}');
    ELSE
        RAISE EXCEPTION 'R-007, Error al procesar la respuesta del login'; 
    END IF;

	RETURN respuestajson;
	
END;
$function$
