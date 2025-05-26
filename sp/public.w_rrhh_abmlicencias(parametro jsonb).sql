CREATE OR REPLACE FUNCTION public.w_rrhh_abmlicencias(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"nrodoc":"28272137","idlicenciatipo":1,"lifechainicio":"2020-01-01","w_licencia_accion":"nuevo","lifechafin":"2020-01-01","leobservacion":"2020-01-01","idlicencia":0}
* 13-07-2021 MaLaPi Agrego los datos del usuario
  {"accion":"w_licencia_accion","idpersona":"0","nrodoc":"28272137","pnombreapellido":"null","ejecutar":"rrhh_abmlicencias","w_idusuario":4874,"w_nrodoc":"28272137","w_idrol":3,"w_Nombre":"Pino, Maria Laura ","uwnombre":"usucbrn"}
*/
DECLARE
--VARIABLES
   vmontoctacte DOUBLE PRECISION;
--RECORD
      respuestajson jsonb;
      usuariojson jsonb;
      respuestajson_info jsonb;
      parametrodarusuario jsonb;
      listado JSONB := '[]'::JSONB;
      respuestaempleadojefe jsonb;
    --   parametronotificacion jsonb;
      vidlicencia bigint;
      rpersona RECORD;
      rlicencia  RECORD;
      rsector  RECORD;
      rlicenciamensual  RECORD;
      rlicenciaconfig  RECORD;
      sectoresjefes  RECORD;
      rlicenciagenerada RECORD;
      vdisponibleanual integer = 0;
      vdisponiblemensual integer = 0;
      vcantusuado integer = 0;
      vaccion varchar;
      vnrodoc varchar;
      vorigen varchar;
---idturno
begin
    vidlicencia = (parametro->>'idlicencia')::bigint;
    vaccion = parametro->>'accion';
    vorigen = parametro->>'origen';
    IF vorigen = 'app' THEN
        parametrodarusuario = json_build_object('nrodoc', parametro->>'nrodoc');
        select into usuariojson * FROM sys_dar_usuario_web(parametrodarusuario);
        respuestaempleadojefe = w_obtenerempleadojefe(parametrodarusuario);
    ELSE
        select into usuariojson * FROM sys_dar_usuario_web(parametro);
    END IF;
    -- raise exception 'prueba,%',usuariojson;
        --------------- w_licencia_accion_nuevo ---------------
    IF (vaccion = 'w_licencia_accion_nuevo') THEN
        IF vorigen is not null and vorigen ilike '%ofa%' THEN
            SELECT INTO rpersona  p.* FROM ofa_agentes a  JOIN ca.empleado e ON a.legajo = e.emlegajo JOIN ca.persona p ON e.idpersona = p.idpersona
            WHERE a.legajo  = parametro->>'idpersona';
        ELSE
            SELECT INTO rpersona * FROM ca.persona WHERE penrodoc = parametro->>'nrodoc' OR idpersona = parametro->>'idpersona';
        END IF;
        RAISE NOTICE 'rpersona (%)',rpersona;
            IF FOUND THEN
            --SL 30/01/25 - Verifico si es una LAO (69 = LAO y 89 = LAO FARMA) y viene desde la app
            IF vorigen is not null and vorigen ilike '%app%' AND (parametro->>'idlicenciatipo' = 69 OR parametro->>'idlicenciatipo' = 89) THEN
                parametro = parametro || respuestaempleadojefe;
                SELECT INTO vidlicencia * FROM calcularlao(parametro);
            ELSE
                INSERT INTO ca.licencia(idlicenciatipo,idpersona,lifechainicio,lifechafin,licantidaddias)
                VALUES((parametro->>'idlicenciatipo')::integer,rpersona.idpersona,TO_DATE(parametro->>'lifechainicio','YYYY-MM-DD'),TO_DATE(parametro->>'lifechafin','YYYY-MM-DD'),TO_DATE(parametro->>'lifechafin','YYYY-MM-DD') - TO_DATE(parametro->>'lifechainicio','YYYY-MM-DD') + 1);
                            INSERT INTO ca.licenciaestado (idlicencia,idlicenciaestadotipo,leobservacion,leusuario)
                            VALUES(currval('ca.licencia_idlicencia_seq'::regclass),1,parametro->>'leobservacion',(usuariojson->>'idusuario')::integer);
                vidlicencia = currval('ca.licencia_idlicencia_seq'::regclass);

                IF vorigen is not null and vorigen ilike '%ofa%' THEN
                    IF not nullvalue(parametro->>'idcertificado') THEN
                    UPDATE ofa_permisopersonallicencia SET idlicencia = currval('ca.licencia_idlicencia_seq'::regclass) WHERE idcertificado = parametro->>'idcertificado';
                    ELSE --es una licencia de LAO
                        UPDATE ofa_permisopersonallicencia SET idlicencia = currval('ca.licencia_idlicencia_seq'::regclass) WHERE idsolicitud = parametro->>'idsolicitud';
                    END IF;
                END IF;

                IF vidlicencia IS NOT NULL OR vidlicencia <> 0 THEN
                    --Busco la licencia generada
                    SELECT INTO rlicenciagenerada * FROM ca.licencia 
                    NATURAL JOIN ca.licenciatipo
                    NATURAL JOIN ca.licenciaestado
                    WHERE idlicencia = vidlicencia AND nullvalue(lefechafin); 

                    --Inserto en la tabla de mensaje
                    PERFORM public.w_abmenviomensaje(jsonb_build_object('emcontenido',
                            '<div style="margin-left: 50px;">' ||
                            '<p style="font-size: 15px;">' ||
                            COALESCE(rpersona.penombre, '') || ' ' || COALESCE(rpersona.peapellido, '') || 
                            ' ha solicitado la licencia Nº ' || COALESCE(rlicenciagenerada.idlicencia::text, '') || 
                            ' - ' || COALESCE(rlicenciagenerada.ltdescripcion, '') || 
                            '. La misma se encuentra en espera.</p>' ||
                            '<ul>' ||
                            '<li><b>Fecha de inicio:</b> ' || TO_CHAR(rlicenciagenerada.lifechainicio, 'DD/MM/YYYY') || ' </li>' ||
                            '<li><b>Fecha de fin:</b> ' || TO_CHAR(rlicenciagenerada.lifechafin, 'DD/MM/YYYY') || '</li>' ||
                            '<li><b>Motivo:</b> ' || COALESCE(rlicenciagenerada.leobservacion, '') || ' </li>' ||
                            '</ul>' ||
                            '<p>' ||
                            'Por favor, revise la solicitud en la plataforma ' ||
                            '<a href="https://www.sosunc.org.ar/sosuncmovil/autorizar_licencias?redirect=true&titulo=ver_la_licencia&idlicencia=' || COALESCE(rlicenciagenerada.idlicencia::text, '') || '">' ||
                            'Sosunc.movil' ||
                            '</a>' ||
                            '</p>' ||
                            '<img ' ||
                            'src="https://www.sosunc.org.ar/sigesweb/uploaded_files/licencias/solicitada.jpg" ' ||
                            'alt="Estado de la licencia" ' ||
                            'style="width: 350px; display: block;" ' ||
                            '/>' ||
                            '</div>',
                            'accion', 'nuevo',
                            'idenviomensajetipo', 1,
                            'emdestino', respuestaempleadojefe->>'peemail', 
                            'emdescripcioncorta','Solicitud de Licencia de '||COALESCE(rpersona.penombre, '') || ' ' || COALESCE(rpersona.peapellido, ''), 
                            'emremitente','no-responder@sosunc.net.ar'
                        ));
                ELSE
                    RAISE EXCEPTION 'R-010, Error al generar la licencia.';
                END IF;
            END IF;
        ELSE
            RAISE EXCEPTION 'R-001, No se encuentra la persona.  %',parametro;
        END IF;
    END IF;
    --------------- w_licencia_accion_cantidad ---------------
    IF (vaccion = 'w_licencia_accion_cantidad') THEN

        --Verifico si la licencia es LAO (69 es la LAO generica que ve en la plataforma se puede ver en "licenciatipo", 89 = LAO (farmacia))
        IF (parametro->>'idlicenciatipo' = 69 OR parametro->>'idlicenciatipo' = 89) THEN
            -- SELECT INTO respuestajson array_to_json(array_agg(row_to_json(t)))
            -- FROM (
            --     SELECT ltccontidaddias, 
            --             COALESCE(SUM(ca.cantidaddiassegunlicencia(lifechainicio, lifechafin, l.idlicenciatipo::integer)), 0) AS cantlic, , 
            --             ltccontidaddias - COALESCE(SUM(ca.cantidaddiassegunlicencia(lifechainicio, lifechafin, l.idlicenciatipo::integer)), 0) AS totlic, 
            --             idpersona, 
            --             ltc.idlicenciatipo, 
            --             ltdescripcion
            --     FROM ca.licenciatipoconfiguracion ltc
            --             NATURAL JOIN ca.persona
            --             NATURAL JOIN ca.licenciatipo
            --             LEFT JOIN ca.licencia l USING (idpersona, idlicenciatipo)
            --             LEFT JOIN ca.licenciaestado USING (idlicencia)
            --     WHERE ltdescripcion ilike '%LICENCIA ANUAL ORDINARIA%'
            --         AND (nullvalue(lefechafin) AND (idlicenciaestadotipo = 2 OR nullvalue(idlicenciaestadotipo)))
            --         AND penrodoc = parametro->>'nrodoc'
            --         AND CASE WHEN nullvalue(ltcfechavigencia) THEN ltfechafinvigencia >= now() ELSE ltcfechavigencia >= now() END
            --     GROUP BY idpersona, ltc.idlicenciatipo, l.idlicenciatipo, ltdescripcion , ltccontidaddias
            -- ) as t;

            -- respuestajson_info = json_build_object('disponibleanual', vdisponibleanual, 'disponiblemensual', vdisponiblemensual, 'cantusuado', rlicencia.cantlic, 'lttopediario', rlicenciaconfig.lttopediario, 'lttopemensual', rlicenciaconfig.lttopemensual, 'lttopeanual', rlicenciaconfig.lttopeanual, 'ltfechafinvigencia', rlicenciaconfig.ltfechafinvigencia, 'ltccontidaddias', rlicenciaconfig.ltccontidaddias);

             -- Consulta que obtiene los registros
            FOR rlicencia IN 
                    SELECT ltccontidaddias, 
                            CASE WHEN nullvalue(du.dias_utilizados) THEN 0 ELSE du.dias_utilizados END as cantlic, 
                            ltccontidaddias - CASE WHEN nullvalue(du.dias_utilizados) THEN 0 ELSE du.dias_utilizados END as totlic, 
                            p.idpersona, 
                            ltc.idlicenciatipo, 
                            ltdescripcion,
                            CASE WHEN nullvalue(ltcfechavigencia) THEN ltfechafinvigencia ELSE ltcfechavigencia END AS fechavigencia
                    FROM 
                        ca.licenciatipoconfiguracion ltc
                        NATURAL JOIN ca.persona p
                        NATURAL JOIN ca.licenciatipo lt
                        --Busco los dias utilizados de la licencia
                        LEFT JOIN (
                                SELECT 
                                    lh.idlicenciatipo, 
                                    lh.idpersona,
                                    SUM(ca.cantidaddiassegunlicencia(lh.lifechainicio, lh.lifechafin, lh.idlicenciatipo::integer)) AS dias_utilizados
                                FROM ca.licencia lh
                                LEFT JOIN ca.licenciaestado le ON le.idlicencia = lh.idlicencia
                                WHERE (nullvalue(le.lefechafin) AND (le.idlicenciaestadotipo = 2 OR le.idlicenciaestadotipo = 1 OR nullvalue(le.idlicenciaestadotipo)))
                                AND nullvalue(le.lefechafin)
                                GROUP BY lh.idlicenciatipo, lh.idpersona
                            ) du ON (du.idlicenciatipo = lt.idlicenciatipo AND du.idpersona = p.idpersona)
                    WHERE 
                        ltdescripcion ILIKE '%LICENCIA ANUAL ORDINARIA%'
                        AND penrodoc = parametro->>'nrodoc'
                        AND (ltccontidaddias - CASE WHEN nullvalue(du.dias_utilizados) THEN 0 ELSE du.dias_utilizados END) > 0
                        AND CASE WHEN nullvalue(ltcfechavigencia) THEN ltfechafinvigencia >= NOW() ELSE ltcfechavigencia >= NOW() END
                    ORDER BY idlicenciatipo ASC
                LOOP
                    -- Acumulación de datos
                    vdisponibleanual := vdisponibleanual + rlicencia.totlic;
                    vdisponiblemensual := vdisponiblemensual + rlicencia.totlic;
                    vcantusuado := vcantusuado + rlicencia.cantlic;

                    -- Construcción del listado JSON
                    listado := listado || jsonb_build_object(
                        'ltdescripcion', rlicencia.ltdescripcion,
                        'cantlic', rlicencia.cantlic,
                        'totlic', rlicencia.totlic,
                        'ltccontidaddias', rlicencia.ltccontidaddias
                    );
                END LOOP;

                -- Construcción del objeto JSON final
                respuestajson_info := json_build_object(
                    'disponibleanual', vdisponibleanual,
                    'disponiblemensual', vdisponiblemensual,
                    'cantusuado', vcantusuado,
                    'listado', listado
                );

        ELSE 
            -- Licencias tomadas anual 
            SELECT INTO rlicencia SUM(ca.cantidaddiassegunlicencia (lifechainicio, lifechafin, idlicenciatipo::integer) ) as cantlic, idpersona
                FROM ca.licencia
                NATURAL JOIN ca.persona
                NATURAL JOIN ca.licenciatipo
                LEFT JOIN ca.licenciaestado USING (idlicencia)
            WHERE idlicenciatipo = parametro->>'idlicenciatipo'
            AND (nullvalue(lefechafin) AND (idlicenciaestadotipo = 2 OR nullvalue(idlicenciaestadotipo)))
            AND penrodoc = parametro->>'nrodoc'
            AND (EXTRACT(YEAR FROM lifechainicio) = EXTRACT(YEAR FROM CAST(parametro->>'fechapedido' AS DATE)))
            -- Va a faltar filtrar las LAOS por ltfechafinvigencia
            GROUP BY idpersona;

            -- Licencias tomadas mensualmente
            SELECT INTO rlicenciamensual SUM(ca.cantidaddiassegunlicencia (lifechainicio, lifechafin, idlicenciatipo::integer) ) as cantlic, idpersona
                FROM ca.licencia
                NATURAL JOIN ca.persona
                NATURAL JOIN ca.licenciatipo
                LEFT JOIN ca.licenciaestado USING (idlicencia)
            WHERE idlicenciatipo = parametro->>'idlicenciatipo'
            AND (nullvalue(lefechafin) AND (idlicenciaestadotipo = 2 OR nullvalue(idlicenciaestadotipo)))
            AND penrodoc = parametro->>'nrodoc'
            AND (EXTRACT(MONTH FROM lifechainicio) = EXTRACT(MONTH FROM CAST(parametro->>'fechapedido' AS DATE)))
            AND (EXTRACT(YEAR FROM lifechainicio) = EXTRACT(YEAR FROM CAST(parametro->>'fechapedido' AS DATE)))
            GROUP BY idpersona;
            
            --Configuracion de la licencia
            SELECT INTO rlicenciaconfig lttopemensual, lttopeanual, ltfechafinvigencia, lttopediario
                FROM ca.licenciatipo lt
            WHERE lt.idlicenciatipo = parametro->>'idlicenciatipo';

            -- TOPE ANUAL DISPONIBLE CUANDO 'ltccontidaddias' NO ESTÁ DEFINIDO
            vdisponibleanual = COALESCE(rlicenciaconfig.lttopeanual - rlicencia.cantlic, rlicenciaconfig.lttopeanual);
            vdisponiblemensual = vdisponibleanual; -- Inicialmente igual al disponible anual
            
            -- SI EXISTE UN TOPE MENSUAL, AJUSTAR EL DISPONIBLE MENSUAL
            IF rlicenciaconfig.lttopemensual IS NOT NULL THEN
                vdisponiblemensual = COALESCE(rlicenciaconfig.lttopemensual - rlicenciamensual.cantlic, rlicenciaconfig.lttopemensual);
            END IF;
            respuestajson_info = json_build_object('disponibleanual', vdisponibleanual, 'disponiblemensual', vdisponiblemensual, 'cantusuado', rlicencia.cantlic, 'lttopediario', rlicenciaconfig.lttopediario, 'lttopemensual', rlicenciaconfig.lttopemensual, 'lttopeanual', rlicenciaconfig.lttopeanual, 'ltfechafinvigencia', rlicenciaconfig.ltfechafinvigencia);
        END IF;
        
        respuestajson = respuestajson_info;
    END IF;
    --------------- w_licencia_accion_modificar ---------------
	 IF (vaccion = 'w_licencia_accion_modificar') THEN
        SELECT INTO rpersona * FROM ca.persona NATURAL JOIN ca.licencia LEFT JOIN  ca.licenciaestado USING(idlicencia)
            WHERE idlicencia = parametro->>'idlicencia' AND nullvalue(lefechafin);
        IF FOUND THEN
            UPDATE ca.licencia SET idlicenciatipo= (parametro->>'idlicenciatipo')::integer,lifechainicio = TO_DATE(parametro->>'lifechainicio','DD-MM-YYYY'), lifechafin = TO_DATE(parametro->>'lifechafin','DD-MM-YYYY'), licantidaddias = TO_DATE(parametro->>'lifechafin','DD-MM-YYYY') - TO_DATE(parametro->>'lifechainicio','DD-MM-YYYY') + 1
            WHERE idlicencia = parametro->>'idlicencia' and idpersona =  parametro->>'idpersona';
            IF nullvalue(rpersona.idlicenciaestadotipo) THEN
                INSERT INTO ca.licenciaestado (idlicencia,idlicenciaestadotipo,leobservacion,leusuario)
                VALUES((parametro->>'idlicencia')::integer,1,parametro->>'leobservacion',(usuariojson->>'idusuario')::integer);
            ELSE
                UPDATE ca.licenciaestado SET leobservacion = parametro->>'leobservacion' WHERE idlicencia = parametro->>'idlicencia' AND nullvalue(lefechafin);
            END IF;
        ELSE
            RAISE EXCEPTION 'R-001, No se encuentra la Licencia.  %',parametro;
        END IF;
       END IF;
   RAISE NOTICE 'parametro (%)',parametro;
    --KAR 02-05-23 En ofa updatea el estado, no genera una nueva tupla, por lo que mando el estado si quiero un nuevo estado
    IF not nullvalue(parametro->>'idlicenciaestadotipo') AND vorigen <> 'app' THEN
            vaccion = 'w_licencia_accion_estado';
    END IF;
    --------------- w_licencia_accion_sectores ---------------
	IF (vaccion = 'w_licencia_accion_sectores') THEN
        WITH jefes AS (
            SELECT idsector, idpersona, sejfechadesde FROM ca.sectorempleadojefe sej
                LEFT JOIN ca.persona p USING (idpersona)
                WHERE CURRENT_DATE BETWEEN sej.sejfechadesde AND COALESCE(sej.sejfechahasta, CURRENT_DATE)
                    AND sej.idpersona IS NOT NULL AND NOT EXISTS (
                    SELECT 1 FROM ca.licencia l
                        LEFT JOIN ca.licenciaestado le USING (idlicencia)
                        LEFT JOIN ca.licenciaestadotipo USING (idlicenciaestadotipo) WHERE l.idpersona = sej.idpersona
                            AND lifechainicio <= CURRENT_DATE AND lifechafin >= CURRENT_DATE
                            AND (idlicenciaestadotipo <> 4 AND lefechainicio <= CURRENT_DATE AND lefechafin >= CURRENT_DATE OR nullvalue(lefechafin) OR nullvalue(idlicenciaestado))))

        SELECT INTO sectoresjefes json_agg(result) FROM (
            SELECT s.*, s.idsector, s.sedescripcion, s.idsectorpadre, p.idpersona as jefeactual,
                CASE WHEN p.idpersona IS NULL THEN 'RRHH' 
                ELSE CONCAT(p.penombre, ' ', p.peapellido) 
                END AS jefenombre
            FROM ca.sector AS s 
            LEFT JOIN ca.persona p ON (p.idpersona = COALESCE(
                    (SELECT idpersona FROM jefes WHERE idsector = s.idsector ORDER BY sejfechadesde DESC LIMIT 1), -- jefe actual
                    (SELECT idpersona FROM jefes WHERE idsector = s.idsectorpadre ORDER BY sejfechadesde DESC LIMIT 1) )) -- jefe del sector padre
            WHERE nullvalue(sbaja) ORDER BY s.sedescripcion DESC
        ) AS result;

        respuestajson = concat('{  "sectoresjefes": ', sectoresjefes.json_agg, '}');
        -- respuestajson =  row_to_json(sectoresjefes.json_agg) ;
    END IF;
    
    RAISE NOTICE 'parametro (%)',parametro;

    --KAR 02-05-23 En ofa updatea el estado, no genera una nueva tupla, por lo que mando el estado si quiero un nuevo estado
    IF not nullvalue(parametro->>'idlicenciaestadotipo') AND vorigen <> 'app' THEN
            vaccion = 'w_licencia_accion_estado';
    END IF;
    --------------- w_licencia_accion_estado ---------------
    IF (vaccion = 'w_licencia_accion_estado') OR parametro->>'accion' = 'w_licencia_accion_estadotodas' OR (vaccion = 'cambio_estado_empleado') THEN
                SELECT INTO rlicencia * FROM ca.licencia
                    NATURAL JOIN  ca.licenciaestado
                    NATURAL JOIN ca.licenciatipo
                    NATURAL JOIN ca.persona
                    JOIN w_usuariorolwebsiges ON (dni = penrodoc)
                    WHERE idlicencia = vidlicencia AND nullvalue(lefechafin)
                    LIMIT 1;
                IF FOUND THEN
                        IF  nullvalue(parametro->>'idlicenciaestadotipo')    THEN
                                    RAISE EXCEPTION 'R-001, No se envia el estado al que se quiere enviar.  %',parametro;
                        END IF;
                    UPDATE ca.licenciaestado SET lefechafin = now() WHERE idlicencia = parametro->>'idlicencia' AND nullvalue(lefechafin);
                    INSERT INTO ca.licenciaestado (idlicencia,idlicenciaestadotipo,leobservacion,leusuario)
                    VALUES(vidlicencia,trim(parametro->>'idlicenciaestadotipo')::integer,parametro->>'leobservacion',(usuariojson->>'idusuario')::integer);
					-- SL 14/11/24 - Agrego marca de notificacion
					 UPDATE ca.licencia SET linotificado = now() WHERE idlicencia = vidlicencia;

                    -- SELECT INTO rpersona * FROM ca.persona
                    -- WHERE penrodoc = parametro->>'nrodoc';
                    -- parametronotificacion = json_build_object(
                    --     'idusuarioweb', rlicencia.idusuarioweb,
                    --     'tag', 'tag',
                    --     'mensaje', 'La licencia ' || vidlicencia::TEXT || ' ha sido actualizada por '|| rpersona.penombre || ' ' || rpersona.peapellido ||', Haga clic para ver más información.',
                    --     'link', 'licencias',
                    --     'sensible', false,
                    --     'interno', true
                    -- );
                    -- PERFORM w_enviarNotificacionPush(parametronotificacion);
            ELSE
                            RAISE EXCEPTION 'R-002, La licencia no Existe.  %',parametro;
                END IF;
    END IF;
    /* SL 18/02/25 - No se utiliza mas ya que antes se enviaba manualmente los emails y ahora lo realiza el worker 
    --------------- w_licencia_accion_nuevo ---------------
    IF parametro->>'accion' = 'w_licencia_accion_nuevo' OR
    (parametro->>'accion' = 'w_licencia_accion_modificar'  AND vorigen <> 'app' ) THEN
        SELECT INTO rlicencia *, to_char(lifechainicio, 'DD/MM/YYYY') as lifechainicio,to_char(lifechafin, 'DD/MM/YYYY') as lifechafin, ltdescripcion
        FROM ca.licencia
                NATURAL JOIN  ca.licenciaestado
                LEFT JOIN ca.licenciatipo USING(idlicenciatipo)
                LEFT JOIN ca.licenciaestadotipo	USING(idlicenciaestadotipo)
                WHERE idlicencia = vidlicencia AND nullvalue(lefechafin);
        respuestajson_info = concat('{ "', vaccion  , '":' , row_to_json(rlicencia) , ', "destino": ', respuestaempleadojefe->>'peemail', '}');
        respuestajson = respuestajson_info ;
    END IF;
    */
    -- SL 29/07/24 - Agrego condicion para traer pendientes para autorizar segun el sector
    IF parametro->>'accion' = 'w_licencia_accion' OR parametro->>'accion' = 'w_licencia_accion_nuevo' OR parametro->>'accion' = 'w_app_licencia_accion_buscarpendientes' OR parametro->>'accion' = 'w_app_licencia_accion_buscartodas' OR
    ((parametro->>'accion' = 'w_licencia_accion_modificar' OR parametro->>'accion' = 'cambio_estado_empleado' OR parametro->>'accion' = 'w_licencia_accion_estado' OR parametro->>'accion' = 'w_licencia_accion_estadotodas')  AND vorigen = 'app' ) THEN
        SELECT INTO respuestajson public.w_rrhh_abmlicencias_buscar(parametro);
    END IF;
    --------------- w_licencia_accion_buscar_licenciatipos ---------------
    IF parametro->>'accion' = 'w_licencia_accion_buscar_licenciatipos' OR
    (parametro->>'accion' = 'w_licencia_accion' AND vorigen = 'app')  THEN
        IF vorigen = 'app' THEN
            select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
            from (
                SELECT *
                FROM ca.licenciatipo lt
                NATURAL JOIN ca.licenciatipoonline lto
                NATURAL JOIN ca.persona p
                NATURAL JOIN ca.empleado e
                WHERE penrodoc = parametro->>'nrodoc' AND e.idconvenio = lt.idconveniolic /*AND (nullvalue(ltfechafinvigencia) OR ltfechafinvigencia >= now()) */AND (nullvalue(ltofechahasta) OR ltofechahasta >= now())
            ) as t;
        ELSE
            select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
            from (
                SELECT * FROM ca.licenciatipo
            ) as t;
        END IF;
        IF respuestajson IS NULL THEN
            respuestajson_info = json_build_object('licenciatipos', respuestajson_info);
        ELSE
            --SL 02/08/24 - Devuelvo
            respuestajson_info = json_build_object('licenciatipos', respuestajson_info, 'licencias',respuestajson->'w_licencia_accion');
        END IF;
        respuestajson = respuestajson_info;
    END IF;
    return respuestajson;
end;
$function$
