CREATE OR REPLACE FUNCTION public.w_notificarturnodemorado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$ /*
	SELECT FROM public.w_notificarturnodemorado();
*/
DECLARE
	respuesta BOOLEAN;
	respuestaenviomensaje jsonb;
	plataforma text;
    eslaborable integer;
	remaildestino RECORD;
    cdata refcursor;
    rdata RECORD;
BEGIN

    respuesta = FALSE;

    OPEN cdata FOR
         SELECT *
            FROM w_turno t
            NATURAL JOIN w_turnoestado te
            NATURAL JOIN w_turnotipo tt
            LEFT JOIN w_turnoestadotipopermisorolweb tetp USING(idturnoestadotipo)
            LEFT JOIN w_enviomensajeturno USING (idturno)
            WHERE (idturnoestadotipo = 38 OR idturnoestadotipo = 35 OR idturnoestadotipo = 37 OR idturnoestadotipo = 42) 
            AND nullvalue(tefechafin) 
            AND nullvalue(idenviomensajeturno)
            AND tefechaini > CURRENT_DATE - INTERVAL '30 days'
            AND tefechaini < CURRENT_DATE - INTERVAL '4 days';
	
    SELECT INTO eslaborable * FROM ca.cantidaddiaslaborables(CURRENT_DATE, CURRENT_DATE);

    IF FOUND AND eslaborable = 1 THEN
        LOOP
            FETCH cdata INTO rdata;
            EXIT WHEN NOT FOUND; -- Salir del loop cuando no se encuentren más registros

                
                -- UPDATE w_turnoestado 
                --     SET tefechafin = CURRENT_DATE
                -- WHERE idturno = rdata.idturno 
                -- AND idcentroturnoestado = rdata.idcentroturnoestado 
                -- AND nullvalue(tefechafin);
                
                -- INSERT INTO w_turnoestado (idcentroturnoestado,	idturno,	idusuarioweb,	idcentroturno,	idturnoestadotipo,	tefechainidesc,	tefechafin,	tecomentarioexterno,	tecomentariointerno)
                -- VALUES(rdata.idcentroturnoestado, rdata.idturno, 5538, rdata.idcentroturno, 39, CURRENT_DATE, NULL, 'Reintegro inactivo por mas de 90 dias', 'Reintegro inactivo por mas de 90 dias');

                IF rdata.idturnoestadotipo = 38 THEN
                    --Si es 38 (Esperando respuesta afiliado) busco el email del afiliado
                    SELECT INTO remaildestino CONCAT('["',uwmail,'"]') AS email FROM persona 
                        NATURAL JOIN public.w_usuarioafiliado
                        NATURAL JOIN public.w_usuarioweb
                    WHERE nrodoc = rdata.nrodoc;
                    plataforma = '<a href="https://www.sosunc.org.ar/sosuncmovil/">SOSUNC.MOVIL</a> ';
                ELSE 
                    --Si es otro idturnoestadotipo busco los emails de los auditores correspondientes
                    -- SELECT * FROM w_usuariorolwebsiges 
                    --     NATURAL JOIN w_usuarioweb
                    --     JOIN ca.persona ON (penrodoc = dni)
                    --     NATURAL JOIN ca.empleado
                    --     LEFT JOIN ca.emailsector USING (idsector)
                    -- WHERE idrolweb = rdata.idrolweb

                    --!SL 27/02/25 - LO HARCODEO YA QUE NO TENGO LOS EMAILS, CUANO ESTEN HACELO BIEN! 
                    IF rdata.idturnoestadotipo = 42 THEN    -- Auditoria Psiclologica
                        SELECT INTO remaildestino '["auditoria.psicologica@sosunc.org.ar"]' AS email;
                    END IF;

                    IF rdata.idturnoestadotipo = 35 THEN -- Auditoria odontologica
                        SELECT INTO remaildestino '["auditoria.odontologica@sosunc.org.ar"]' AS email;
                    END IF;

                    IF rdata.idturnoestadotipo = 37 THEN -- Auditoria Medica
                        SELECT INTO remaildestino '["auditoria.medica@sosunc.org.ar"]' AS email;
                    END IF;
                    plataforma = '<a href="https://www.sosunc.org.ar/sigesweb/vista/login/login.php">SIGESWEB</a> ';
                END IF;

                --  Inserto en la tabla de mensaje
                SELECT INTO respuestaenviomensaje * FROM public.w_abmenviomensaje(jsonb_build_object('emcontenido',
                    '<div style="margin-left: 50px;">' ||
                    '<p style="font-size: 15px;">Estimado/a,</p>' ||
                    '<p>Le recordamos que tiene una solicitud de '|| COALESCE(rdata.ttnombre, '') ||' Nº'|| COALESCE(rdata.idturno::TEXT, '') ||' pendiente de gestión en la plataforma.</p>' ||
                    '<p>Por favor, ingrese a ' ||
                    plataforma||
                    'para revisar y completar el proceso.</p>' ||
                    '<p>Si ya ha gestionado la solicitud, puede ignorar este mensaje.</p>' ||
                    '<p>Saludos cordiales.</p>' ||
                    '</div>',
                    'accion', 'nuevo',
                    'idenviomensajetipo', 1,
                    'emdestino', remaildestino.email, 
                    'emdescripcioncorta','Recordatorio de '||  COALESCE(rdata.ttnombre, '') || ' - Nº'|| COALESCE(rdata.idturno::TEXT, '') ||' demorado', 
                    'emremitente','no-responder@sosunc.net.ar'
                ));

                INSERT INTO w_enviomensajeturno (idenviomensaje, idcentroturno, idturno)
                VALUES (CAST(respuestaenviomensaje->>'idenviomensaje' AS BIGINT), rdata.idcentroturno, rdata.idturno);


                respuesta = TRUE;

        END LOOP;

        -- Cerrar el cursor
        CLOSE cdata;
    END IF;

	RETURN respuesta;
END
$function$
