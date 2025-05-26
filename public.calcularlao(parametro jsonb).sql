CREATE OR REPLACE FUNCTION public.calcularlao(parametro jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
/*
* Función para calcular y generar solicitudes de Licencia Anual Ordinaria (LAO)
* Recibe un objeto JSON con los parámetros necesarios y devuelve el ID de la licencia generada
* Parámetros esperados en el JSON:
*   - nrodoc: Número de documento del solicitante
*   - lifechainicio: Fecha de inicio de la licencia (formato fecha)
*   - lifechafin: Fecha de fin de la licencia (formato fecha)
*   - idlicenciatipo: ID del tipo de licencia a solicitar
*   - leobservacion: Observaciones sobre la solicitud
*/
DECLARE
    respuestajson jsonb;
    respuestajson_info jsonb;
    usuariojson jsonb;
    parametrodarusuario jsonb;
    vcantdiasapedir integer;      -- Cantidad total de días solicitados por el usuario
    vcantdiascomidos integer;     -- Contador de días consumidos durante el proceso (Caso de feriados pegados a la "fechafin")
    vidlicencia integer;          -- ID de la licencia generada
    eslaborable integer;          -- Flag para determinar si un día es laborable (1) o no (0)
    vfechainicio date;            -- Fecha de inicio de la licencia actual
    vfechafin date;               -- Fecha de fin de la licencia actual
    vfechasiguientefin date;      -- Variable auxiliar para calcular si el siguiente dia desde la fechafin es feriado
    rlicencia RECORD;             -- Registro para almacenar datos de la licencia disponible
    rpersona RECORD;              -- Registro para almacenar datos de la persona
    rlicenciagenerada RECORD;     -- Registro para almacenar datos de la licencia generada
    -- Cursor para obtener las licencias disponibles para el usuario
    cur_licencias CURSOR FOR 
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
            --Busco los días utilizados de la licencia para calcular el saldo disponible
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
        ORDER BY idlicenciatipo ASC;
BEGIN
    -- Extraigo fechas del parámetro JSON
    vfechainicio = CAST(parametro->>'lifechainicio' AS DATE);
    vfechafin = CAST(parametro->>'lifechafin' AS DATE);

    -- Obtengo datos de la persona y del usuario web
    SELECT INTO rpersona * FROM ca.persona WHERE penrodoc = parametro->>'nrodoc';
    parametrodarusuario = json_build_object('nrodoc', parametro->>'nrodoc');
    select into usuariojson * FROM sys_dar_usuario_web(parametrodarusuario);

    -- Calculo la cantidad total de días solicitados en el rango de fechas
    SELECT INTO vcantdiasapedir * FROM ca.cantidaddiassegunlicencia(vfechainicio, vfechafin, CAST(parametro->>'idlicenciatipo' AS INTEGER));

    -- Abro el cursor para recorrer las licencias disponibles
    OPEN cur_licencias;
    LOOP
        -- Obtengo la siguiente licencia
        FETCH cur_licencias INTO rlicencia;
        
        -- Salgo si no hay más licencias
        EXIT WHEN NOT FOUND;
        
        -- Salgo si ya se asignaron todos los días solicitados
        EXIT WHEN vcantdiasapedir <= 0;

        -- Salgo si la licencia actual no tiene días disponibles
        EXIT WHEN rlicencia.totlic <= 0;
       
        -- Determino cómo distribuir los días entre las licencias disponibles
        IF vcantdiasapedir >= rlicencia.totlic THEN
            -- Si necesito más días de los que tiene esta licencia, uso todos los disponibles
            vfechafin = vfechainicio + CAST((rlicencia.totlic - 1)::text || ' days' AS INTERVAL);  -- Calculo la fecha de finalizacion de la LAO utilizando los dias totales de esa licencia
            vcantdiasapedir = vcantdiasapedir - rlicencia.totlic;
            rlicencia.totlic = 0;
        ELSE 
            -- Si la licencia tiene suficientes días para cubrir lo solicitado
            vfechafin = vfechainicio + CAST((vcantdiasapedir - 1)::text || ' days' AS INTERVAL); -- Calculo la fecha de finalizacion de la LAO utilizando los dias a pedir
            vcantdiasapedir = 0;

            -- Verifico si la fecha de inicio es laborable, sino la ajusto al siguiente día laborable
            LOOP 
                SELECT INTO eslaborable * FROM ca.cantidaddiaslaborables(vfechainicio, vfechainicio);

                IF FOUND AND eslaborable = 0 AND vfechainicio < vfechafin THEN
                    vfechainicio = vfechainicio + 1;
                ELSE
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        -- Verifico que el rango de fechas sea válido después de los ajustes
        IF vfechainicio <= vfechafin THEN

            -- Verifico que el siguiente dia de la fecha fin no termine en un día no laborable y la ajusto si es necesario
            LOOP 
                vfechasiguientefin = vfechafin + 1;
                vcantdiascomidos = vcantdiasapedir;
                SELECT INTO eslaborable * FROM ca.cantidaddiaslaborables(vfechasiguientefin, vfechasiguientefin);

                IF FOUND AND eslaborable = 0 AND rlicencia.totlic > vcantdiascomidos THEN
                    vfechafin = vfechasiguientefin;
                    vcantdiascomidos = vcantdiascomidos + 1;
                ELSE
                    EXIT;
                END IF;
            END LOOP;

            -- Inserto la licencia
            INSERT INTO ca.licencia(
                idlicenciatipo,
                idpersona,
                lifechainicio,
                lifechafin,
                licantidaddias
            ) VALUES (
                rlicencia.idlicenciatipo,
                rpersona.idpersona,
                vfechainicio,
                vfechafin,
                vfechafin - vfechainicio + 1
            );
            
            vidlicencia = currval('ca.licencia_idlicencia_seq'::regclass);
            
            IF vidlicencia IS NOT NULL THEN
                -- Inserto el estado de la licencia
                INSERT INTO ca.licenciaestado (
                    idlicencia,
                    idlicenciaestadotipo,
                    leobservacion,
                    leusuario
                ) VALUES (
                    vidlicencia,
                    1,
                    parametro->>'leobservacion',
                    (usuariojson->>'idusuario')::integer
                );

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
                    'emdestino', parametro->>'peemail', 
                    'emdescripcioncorta','Solicitud de Licencia de '||COALESCE(rpersona.penombre, '') || ' ' || COALESCE(rpersona.peapellido, ''), 
                    'emremitente','no-responder@sosunc.net.ar'
                ));

            -- Actualizo la fecha de inicio para la siguiente iteración -- tendria que sumarle solo cuando la cantidad de dias a pedir sea mayor a 0
            vfechainicio = vfechafin + 1;
            ELSE
                RAISE EXCEPTION 'R-001, No se pudo generar la licencia.';
                EXIT;
            END IF;
        ELSE
            EXIT;
        END IF;
    END LOOP;

    -- Cierro el cursor
    CLOSE cur_licencias;

    return vidlicencia;
END;
$function$
