CREATE OR REPLACE FUNCTION public.w_obtenerturnoestado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"NroDocumento":"08216252","TipoDocumento":1}
*/
DECLARE
    elidcentroturno TEXT := parametro->>'idcentroturno';
    resturnoestado JSON;
    respuestajson TEXT;
    estadosiguiente JSON;
    turnosestado JSON;
    plantillasmensaje JSON;
    numpage INTEGER := (parametro->>'page')::INTEGER;
    pagesize INTEGER :=  COALESCE((parametro->>'pageSize')::INTEGER, 10);
    buscar TEXT := parametro->>'search';
BEGIN

    IF (parametro->>'accion' <> 'historial' OR parametro->>'accion' IS NULL) THEN 
        -- Devuelve los turnos en estado actual dependiendo del permiso y del idrolweb pasados por parámetro
        SELECT json_agg(t) INTO resturnoestado
        FROM (
            SELECT 
                w_turno.*, ttnombre,
                TO_CHAR(tufecha, 'dd-mm-yyyy HH24:MI:SS') AS tufecha, 
                COALESCE(persona.nrodoc, personacentroregional.nrodoc) AS nrodoc,   COUNT(*) OVER() AS totalCount, 
                CONCAT(apellido, ', ', nombres) AS nombreafiliado, crdescripcion, tetnombre, idturnoestado, idcentroturnoestado, tet.idturnoestadotipo, tetpr.tetpreditableexterno,tetpr.tetprespectador,
                -- Subconsulta para obtener todos los archivos externos relacionados con el turno
                (
                    SELECT json_agg(archivo.archivodetalle)
                    FROM (
                        SELECT w_obtener_archivo(jsonb_build_object('idarchivo', ta.idarchivo, 'idcentroarchivo', ta.idcentroarchivo)) AS archivodetalle
                        FROM w_turnoarchivo ta
                        WHERE ta.idturno = w_turno.idturno AND ta.	idturnoarchivotipo = 2
                        
                    ) archivo
                ) AS archivos,
                    -- Subconsulta para obtener todos los archivos internos relacionados con el turno
                (
                    SELECT json_agg(archivo.archivodetalle)
                    FROM (
                        SELECT w_obtener_archivo(jsonb_build_object('idarchivo', ta.idarchivo, 'idcentroarchivo', ta.idcentroarchivo)) AS archivodetalle
                        FROM w_turnoarchivo ta
                        WHERE ta.idturno = w_turno.idturno AND ta.	idturnoarchivotipo = 1
                    ) archivo
                ) AS archivosinternos,
                -- Subconsulta para obtener todos los archivos relacionados con el turno
                ( SELECT te.idturnoestadotipo	AS turnoestadosiguiente
                        FROM w_turnoestadotipopermisorolweb as tetpr
                        JOIN w_turnoestado as te on (te.idturno = w_turno.idturno)
                        WHERE 
                            te.tefechafin IS NOT NULL AND tetpr.tetpreditableexterno = FALSE AND tet.idturnoestadotipo <> te.idturnoestadotipo
                            AND (tetpr.idpermiso = parametro->>'idpermiso' AND tetpr.idrolweb = parametro->>'idrolweb')
                        ORDER BY te.tefechafin DESC LIMIT 1  
                ) AS estadosiguiente,
                CASE 
                    WHEN (tet.teteditable) THEN ( 
                        SELECT COUNT(*) + 1 
                        FROM w_turnoestado 
                        NATURAL JOIN w_turnoestadotipo 
                        WHERE tefechafin IS NULL 
                            AND teteditable 
                            AND idrolweb = parametro->>'idrolweb' 
                            AND w_turno.idturno > w_turnoestado.idturno 
                    ) 
                    ELSE 0 END AS cantespera 
            FROM w_turno 
            NATURAL JOIN persona 
            LEFT JOIN personacentroregional ON (personacentroregional.nrodoc = w_turno.nrodoc AND personacentroregional.tipodoc = w_turno.tipodoc) 
            LEFT JOIN centroregional ON (personacentroregional.idcentropersonacentroregional = centroregional.idcentroregional) 
            NATURAL JOIN w_turnotipo AS tt
            JOIN w_turnoestado USING(idturno) 
            JOIN w_turnoestadotipo AS tet USING(idturnoestadotipo) 
            LEFT JOIN w_turnoestadotipopermisorolweb AS tetpr ON ((tet.idturnoestadotipo = tetpr.idturnoestadotipo OR tetpr.idturnoestadotipo IS NULL) AND tt.idturnotipo = tetpr.idturnotipo)
            WHERE 
                tefechafin IS NULL AND
                tetpr.idpermiso = parametro->>'idpermiso' AND
                tetpr.idrolweb = parametro->>'idrolweb' 
                AND  (buscar IS NULL OR buscar = '' OR apellido ILIKE '%' || buscar || '%' 
                                OR crdescripcion ILIKE '%' || buscar || '%' 
                                OR nombres ILIKE '%' || buscar || '%'
                                OR w_turno.idturno::TEXT ILIKE '%' || buscar || '%'
                                OR TO_CHAR(tufecha, 'YYYY-MM-DD') ILIKE '%' || buscar || '%'
                                OR tetnombre ILIKE '%' || buscar || '%'
                                )
            GROUP BY w_turno.idturno, tufecha, persona.nrodoc, 
                    apellido, nombres, 
                    tt.idturnotipo, 
                    tet.idturnoestadotipo, 
                    idturnoestado, w_turno.idcentroturno, 
                    personacentroregional.nrodoc, crdescripcion, idcentroturnoestado, tetpr.tetpreditableexterno, tetpr.tetprespectador
            ORDER BY 
                CASE WHEN parametro->>'orden_direccion' = 'DESC' 
                    THEN w_turno.idturno END DESC,
                CASE WHEN parametro->>'orden_direccion' != 'DESC' OR parametro->>'orden_direccion' IS NULL
                    THEN w_turno.idturno END ASC
            LIMIT pagesize OFFSET (numpage - 1) * pagesize
        ) t;
    END IF;
   
    -- Devuelve los estados siguientes
    SELECT jsonb_agg(jsonb_build_object('idturnoestadotiposiguiente', tetpr.idturnoestadotiposiguiente, 'tetnombre', tet.tetnombre))
        INTO estadosiguiente
            FROM w_turnoestadotipopermisorolweb AS tetpr
            --LEFT JOIN w_turnotipo AS tt ON tt.idturnotipo = tetpr.idturnotipo
            LEFT JOIN w_turnoestadotipo AS tet ON (tetpr.idturnoestadotiposiguiente = tet.idturnoestadotipo)
        WHERE tetpr.idrolweb = parametro->>'idrolweb'
            AND tetpr.idpermiso = parametro->>'idpermiso' 
            AND NOT tetpr.idturnoestadotiposiguiente IS NULL;

    IF (parametro->>'accion' IS NOT NULL AND (parametro->>'accion' = 'gestion' OR parametro->>'accion' = 'todo' OR parametro->>'accion' = 'historial')) THEN
        -- Devuelve los estados correspondiente para el usuario
        -- SELECT jsonb_agg(jsonb_build_object('idturnoestadotipo', tet.idturnoestadotipo, 'tetdescripcion', tet.tetdescripcion, 'tetnombre', tet.tetnombre, 'teticono', tet.teticono))
        --     INTO turnosestado
        --         FROM w_turnoestadotipopermisorolweb AS tetpr
        --         LEFT JOIN w_turnoestadotipo AS tet ON (tet.idturnotipo = tetpr.idturnotipo )
        --     WHERE tetpr.idrolweb = parametro->>'idrolweb' AND tetpr.idpermiso = parametro->>'idpermiso' AND nullvalue(tetpr.idturnoestadotiposiguiente);

        
        SELECT jsonb_agg(jsonb_build_object('idturnoestadotipo', t.idturnoestadotipo, 'tetdescripcion', t.tetdescripcion, 'tetnombre', t.tetnombre, 'teticono', t.teticono
                )) INTO turnosestado FROM (SELECT tet.*
                                                FROM w_turnoestadotipo AS tet
                                                JOIN w_turnoestadotipopermisorolweb AS tetpr ON tet.idturnotipo = tetpr.idturnotipo
                                                LEFT JOIN w_turnoestadotipopermisorolweb AS excluidos
                                                ON tet.idturnoestadotipo = excluidos.idturnoestadotipo
                                                AND excluidos.idturnoestadotiposiguiente IS NOT NULL
                                                WHERE tetpr.idrolweb = parametro->>'idrolweb'
                                                AND tetpr.idpermiso = parametro->>'idpermiso'
                                                AND excluidos.idturnoestadotipo IS NULL
                                                AND tet.tetactivo IS NULL
                                                ORDER BY tet.tetorden) t; -- Excluye los que tienen un idturnoestadotiposiguiente definido -- Excluye los que tienen un idturnoestadotiposiguiente definido

        SELECT jsonb_agg(jsonb_build_object('pmdescripcion', pm.pmdescripcion, 'idplantillamensaje', pm.idplantillamensaje))
            INTO plantillasmensaje FROM w_plantillamensaje AS pm
                NATURAL JOIN w_plantillamensajerolweb AS pmr
                WHERE pmr.idrolweb = parametro->>'idrolweb' ; -- Excluye los que tienen un idturnoestadotiposiguiente definido

    END IF;

    	-- ds agrego accion historial para que devuelva los turno por usuario y sin fecha fin  
	IF (parametro->>'accion' = 'historial') THEN
		SELECT jsonb_agg(resultado) INTO resturnoestado FROM (
			SELECT DISTINCT ON (w_turno.idturno) w_turno.idturno, COUNT(*) OVER() AS totalCount, TO_CHAR(tufecha, 'dd-mm-yyyy HH24:MI:SS') AS tufecha,  COALESCE(persona.nrodoc, personacentroregional.nrodoc) AS nrodoc, 
				CONCAT(apellido, ', ', nombres) AS nombreafiliado, crdescripcion, tetnombre, w_turno.idcentroturno,
				CASE WHEN (w_turnoestadotipo.teteditable) THEN 
						(SELECT COUNT(*) + 1  FROM w_turnoestado 
						NATURAL JOIN w_turnoestadotipo 
						WHERE tefechafin IS NULL  AND teteditable AND idrolweb = 34  AND w_turno.idturno > w_turnoestado.idturno) ELSE 0 
				END AS cantespera 
			FROM w_turno 
			NATURAL JOIN persona LEFT JOIN personacentroregional  ON (personacentroregional.nrodoc = w_turno.nrodoc AND personacentroregional.tipodoc = w_turno.tipodoc) 
			LEFT JOIN centroregional  ON (personacentroregional.idcentropersonacentroregional = centroregional.idcentroregional) 
			NATURAL JOIN w_turnotipo JOIN w_turnoestado USING(idturno) JOIN w_turnoestadotipo USING(idturnoestadotipo) 
			WHERE tefechafin ILIKE '%%'  AND  idusuarioweb = parametro->>'idusuarioweb' AND w_turnotipo.idturnotipo = '11' 
            AND (buscar IS NULL OR buscar = '' OR apellido ILIKE '%' || buscar || '%' 
                            OR crdescripcion ILIKE '%' || buscar || '%' 
                            OR nombres ILIKE '%' || buscar || '%'
                            OR w_turno.idturno::TEXT ILIKE '%' || buscar || '%'
                            OR TO_CHAR(tufecha, 'YYYY-MM-DD') ILIKE '%' || buscar || '%'
                            OR tetnombre ILIKE '%' || buscar || '%'
                            )
            ORDER BY idturno DESC
            LIMIT pagesize OFFSET (numpage - 1) * pagesize
    	) AS resultado;
	END IF;
    

    respuestajson := concat('{"turnosestado":', COALESCE(resturnoestado, '[]'), ', 
                              "acciones":', COALESCE(estadosiguiente, '[]'), ',
                              "plantillasmensaje":', COALESCE(plantillasmensaje, '[]'), ',
                              "estadostipo":', COALESCE(turnosestado, '[]'), 
                             '}');
    
    RETURN respuestajson;
END;

$function$
