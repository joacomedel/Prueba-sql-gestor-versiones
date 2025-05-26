CREATE OR REPLACE FUNCTION public.w_enviarnotificacionpush(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*	SELECT * FROM w_enviarNotificacionPush('{"idusuarioweb":"5538","tag":"tag","mensaje":"mensaje", "link":"https://www.google.com/","sensible":true, "interno": false}')
*/
DECLARE
	vidusuarioweb text;
	vtag varchar(20);
	vmensaje text;
	
	vdispo record;
	cdispositivos refcursor;
	rusuario record;
	vexito boolean = true;
	vsensible boolean;
	vinterno boolean;
	vnotif jsonb;
	vpayload jsonb;
	vnombre text;
	vapellido text;
	vlink text;
	respuestajson jsonb;
	vmensajeResp text;
BEGIN
	vtag = parametro ->> 'tag';
	vidusuarioweb = parametro ->> 'idusuarioweb';
	vmensaje = parametro ->> 'mensaje';
	vsensible = parametro ->> 'sensible';
	vinterno = parametro ->> 'interno';
	vlink = parametro ->> 'link';
	IF vtag IS NULL OR vidusuarioweb IS NULL OR vmensaje IS NULL  OR vsensible IS NULL OR vinterno IS NULL OR vlink IS NULL  THEN
		RAISE EXCEPTION 'R-001 enviarNotifPush, Parámetros Inválidos, se requiere {"nombreusr":"nombreusr","tag":"tag","mensaje","mensaje", "link":"link","sensible":true, "interno": false}';
	END IF;
	-- SL 11/04/24 - Cambio consulta para que utilice idusuarioweb
	SELECT INTO rusuario uw.idusuarioweb, p.apellido, (case when nullvalue(nombres) then pdescripcion else nombres end) AS nombres
		FROM w_usuarioweb uw
			LEFT JOIN w_usuarioafiliado USING (idusuarioweb)
			LEFT JOIN w_usuarioprestador AS up ON (uw.idusuarioweb = up.idusuarioweb)
			LEFT JOIN prestador AS pr ON (pr.idprestador = up.idusuarioweb)
			LEFT JOIN persona as p USING (nrodoc)
			LEFT JOIN usuario ON (p.nrodoc = usuario.dni AND p.tipodoc = usuario.tipodoc)
		WHERE uw.idusuarioweb = vidusuarioweb
		GROUP BY uw.idusuarioweb,nombres,p.apellido, pr.pdescripcion;
		
	IF FOUND THEN	
    --Se agrega el nombre Y apellido del usuario para que se muestre en la notificacion
        IF nullvalue(rusuario.apellido) THEN
            vnombre = split_part(rusuario.nombres,' ',2);
            vapellido = split_part(rusuario.nombres,' ',1);
        ELSE
            vnombre = split_part(rusuario.nombres,' ',1);
            vapellido = split_part(rusuario.apellido,' ',1);
        END IF;
        vnotif = concat('{"idusuarioweb": "', vidusuarioweb, '"',
            ', "tag": "', vtag , '"'
            ', "mensaje": "', vmensaje, '"', 
            ', "link": "', vlink , '"'
            '}')::jsonb;
    /* SL 03/12/24 - Comento ya que ahora el "notificarListener" funciona distinto y no hace falta realizar el "pg_notify"
		OPEN cdispositivos for SELECT * 
			 FROM suscripcionNotifPush NATURAL JOIN suscripcionNotifAfiliado
			 WHERE idusuarioweb = rusuario.idusuarioweb;
		LOOP
			FETCH cdispositivos INTO vdispo;		
			EXIT WHEN NOT FOUND;
			vpayload = vnotif || concat('{"suscripcion":', vdispo.snpdatossuscripcion, '}')::jsonb;
			PERFORM pg_notify('notifSosunc', vpayload::text);		
			RAISE NOTICE 'vpayload %',vpayload;		
		END LOOP;
		CLOSE cdispositivos;
    */

		INSERT INTO log_notificaciones (contenidoNotif, idusuarioweb, sensible, interno)
			VALUES(vnotif, rusuario.idusuarioweb, vsensible, vinterno);

		respuestajson = concat('{ "enviada":', vexito::text, '}');
	ELSE
		vexito = false;		
		vmensajeResp = concat('El usuario con id', E'\'', vidusuarioweb, E'\'', ' no existe.');
		respuestajson = concat('{ "enviada":', vexito::text, ', "mensaje": "', vmensajeResp ,'"}');
	END IF;	
	
	RETURN respuestajson;
END;
$function$
