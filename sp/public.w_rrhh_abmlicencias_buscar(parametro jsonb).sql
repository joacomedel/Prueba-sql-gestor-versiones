CREATE OR REPLACE FUNCTION public.w_rrhh_abmlicencias_buscar(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
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
      respuestalistas jsonb;
      rpersona RECORD;
	  rsector RECORD;

      vidlicencia bigint;
      vidlicenciaestadotipo bigint;
      rlicencia  record;
      vaccion varchar;
      vnrodoc varchar;
        numpage INTEGER := (parametro->>'page')::INTEGER;
        pagesize INTEGER := (parametro->>'pageSize')::INTEGER;
        buscar TEXT := parametro->>'search';
---idturno
begin
    SET search_path TO 'public';

    vidlicencia = (parametro->>'idlicencia')::bigint;
    vaccion = parametro->>'accion';

    select into usuariojson * FROM sys_dar_usuario_web(parametro);

    IF (not nullvalue(parametro->>'idlicenciaestadotipo') AND parametro->>'idlicenciaestadotipo' = '1') OR
    (NOT nullvalue(parametro->>'origen') AND parametro->>'origen' = 'app') THEN
	    --Se estan buscando las licencias para ser autorizadas, en ese caso busco el sector al que pertenece
	    --la persona que esta logueada
		SELECT INTO rsector penrodoc,idtipodocumento,idsector, idpersona
		from ca.persona
		natural join ca.empleado
		natural join ca.sector
		JOIN usuario ON penrodoc = dni
		WHERE penrodoc = parametro->>'nrodoc' ;

        PERFORM w_darsectorhijo(parametro);
	END IF;

	IF parametro->>'accion' = 'w_licencia_accion' OR parametro->>'accion' = 'w_licencia_accion_nuevo' OR parametro->>'accion' = 'w_licencia_accion_modificar' OR parametro->>'accion' = 'cambio_estado_empleado' THEN
             IF nullvalue(parametro->>'nrodoc') AND nullvalue(parametro->>'idlicenciaestadotipo')   THEN
                RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
             END IF;

             IF (parametro->>'nrodoc' = 'null' AND nullvalue(parametro->>'idlicenciaestadotipo'))   THEN
                 vnrodoc = parametro->>'usunrodoc';
             ELSE
                 vnrodoc = parametro->>'nrodoc';
             END IF;

            -- SL 30/07/24 - Agrego condicion para entrar en busqueda cuando cambio el estado
            IF parametro->>'accion' = 'cambio_estado_empleado'  THEN
                vidlicenciaestadotipo = '1';
            ELSE
                vidlicenciaestadotipo = parametro->>'idlicenciaestadotipo';
            END IF;
            IF (not nullvalue(vidlicenciaestadotipo) AND vidlicenciaestadotipo = '1') THEN
                --Se quiere buscar licencias para autorizar
                select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                from (
                    SELECT  ca.licenciatipo.*,ca.licenciaestadotipo.*,ca.persona.*
                            ,idlicenciaestado,idlicenciaestadotipo,leobservacion,to_char(lefechainicio, 'DD/MM/YYYY HH:mm') as lefechainicio,lefechafin,leusuario,idlicenciaestadotipo
                            ,to_char(lifechainicio, 'DD/MM/YYYY') as lifechainicio,to_char(lifechafin, 'DD/MM/YYYY') as lifechafin ,concat(penombre,' ',peapellido) as pnombreapellido,idlicencia, linotificado,idlicenciatipo,idpersona,licantidaddias
                        FROM ca.persona
                            LEFT JOIN ca.licencia USING(idpersona)
                            LEFT JOIN ca.licenciatipo USING(idlicenciatipo)
                            LEFT JOIN ca.licenciaestado USING(idlicencia)
                            LEFT JOIN ca.licenciaestadotipo	USING(idlicenciaestadotipo)
                        WHERE ((not nullvalue(vnrodoc) AND penrodoc = vnrodoc )
                            OR (not nullvalue(parametro->>'idlicenciaestadotipo')
                                        AND idlicenciaestadotipo = vidlicenciaestadotipo
                                        AND vnrodoc = 0 AND penrodoc IN (
                                            SELECT penrodoc
                                                FROM sectorhijojefe shj
                                                JOIN ca.sector s ON (s.idsector = shj.idsector)
                                                JOIN ca.empleado e ON (s.idsector = e.idsector)
                                                JOIN ca.persona p ON (p.idpersona = e.idpersona)
                                                JOIN ca.afip_situacionrevistaempleado asre ON (asre.idpersona = p.idpersona)
                                                WHERE (asrefechahasta >= now() OR nullvalue(asrefechahasta))  AND penrodoc <> parametro->>'nrodoc'
                                            )
                                )
                        )
                AND nullvalue(lefechafin)
                ORDER BY licencia.idlicencia DESC
                ) as t;
            ELSE
                select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                from (
                SELECT  to_char(lifechainicio, 'DD/MM/YYYY') as lifechainicio,to_char(lifechafin, 'DD/MM/YYYY') as lifechafin ,concat(penombre,' ',peapellido) as pnombreapellido,idlicencia, linotificado,idlicenciatipo,idpersona,licantidaddias,ca.licenciatipo.*
                    ,idlicenciaestado,idlicenciaestadotipo,leobservacion,to_char(lefechainicio, 'DD/MM/YYYY HH:mm') as lefechainicio,lefechafin,leusuario,idlicenciaestadotipo
                    ,ca.licenciaestadotipo.*,ca.persona.*
                            FROM ca.persona
                             JOIN ca.licencia USING(idpersona)
                             JOIN ca.licenciatipo USING(idlicenciatipo)
                             JOIN ca.licenciaestado USING(idlicencia)
                             JOIN ca.licenciaestadotipo	USING(idlicenciaestadotipo)
                WHERE ((not nullvalue(vnrodoc) AND penrodoc = vnrodoc ) OR (not nullvalue(parametro->>'idlicenciaestadotipo') AND idlicenciaestadotipo = parametro->>'idlicenciaestadotipo') )
                            AND nullvalue(lefechafin)
                            ORDER BY licencia.idlicencia DESC
                ) as t;
            END IF;
    END IF;
    -- SL 29/07/24 - Agrego condicion para traer licencias con estado en la app
    IF NOT nullvalue(parametro->>'origen') AND parametro->>'origen' = 'app' AND
    (parametro->>'accion' = 'w_app_licencia_accion_buscarpendientes' OR parametro->>'accion' = 'w_licencia_accion_estado') THEN
        IF nullvalue(parametro->>'nrodoc') THEN
            RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
        END IF;

        SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT  to_char(lifechainicio, 'DD/MM/YYYY') as lifechainicio,to_char(lifechafin, 'DD/MM/YYYY') as lifechafin ,concat(penombre,' ',peapellido) as pnombreapellido,idlicencia, linotificado,idlicenciatipo,p.idpersona,licantidaddias,ca.licenciatipo.*
                ,idlicenciaestado,idlicenciaestadotipo,leobservacion,to_char(lefechainicio, 'DD/MM/YYYY HH:mm') as lefechainicio,lefechafin,leusuario,idlicenciaestadotipo
                ,ca.licenciaestadotipo.*,p.*
            FROM ca.persona p
                LEFT JOIN ca.licencia USING(idpersona)
                LEFT JOIN ca.licenciatipo USING(idlicenciatipo)
                LEFT JOIN ca.licenciaestado USING(idlicencia)
                LEFT JOIN ca.licenciaestadotipo	USING(idlicenciaestadotipo)
                LEFT JOIN ca.sectorempleadojefe sej on (sej.idpersona = rsector.idpersona AND (sejfechahasta IS NULL OR sejfechahasta >= now()))
                --JOIN ca.licenciatipoonline USING (idlicenciatipo)
			WHERE -- idlicenciaestadotipo = 1 AND
                -- (nullvalue(ltofechahasta) OR ltofechahasta >= now())
                --AND (ltofechadesde <= lefechainicio) AND
                EXTRACT(YEAR FROM lefechainicio) = EXTRACT(YEAR FROM CURRENT_DATE)
                AND nullvalue(lefechafin)
                AND (lefechainicio >= sejfechadesde)
                AND (penrodoc IN (
                    SELECT penrodoc
                        FROM sectorhijojefe shj
                        JOIN ca.sector s ON (s.idsector = shj.idsector)
                        JOIN ca.empleado e ON (s.idsector = e.idsector)
                        JOIN ca.persona p ON (p.idpersona = e.idpersona)
                        JOIN ca.afip_situacionrevistaempleado asre ON (asre.idpersona = p.idpersona)
                        WHERE (asrefechahasta >= now() OR nullvalue(asrefechahasta))  AND penrodoc <> parametro->>'nrodoc'
                ))
            ORDER BY licencia.idlicencia DESC
        ) as t;
    END IF;
    -- SL 29/07/24 - Agrego condicion para devolver todas las licencias aprobadas
    IF NOT nullvalue(parametro->>'origen') AND parametro->>'origen' = 'app' AND (parametro->>'accion' = 'w_app_licencia_accion_buscartodas' OR parametro->>'accion' = 'w_licencia_accion_estadotodas') THEN

        IF nullvalue(parametro->>'nrodoc') THEN
            RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
        END IF;

        SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT  to_char(lifechainicio, 'DD/MM/YYYY') as lifechainicio,to_char(lifechafin, 'DD/MM/YYYY') as lifechafin ,concat(penombre,' ',peapellido) as pnombreapellido,idlicencia, linotificado,idlicenciatipo,idpersona,licantidaddias,ca.licenciatipo.*
                ,idlicenciaestado,idlicenciaestadotipo,leobservacion,to_char(lefechainicio, 'DD/MM/YYYY HH:mm') as lefechainicio,lefechafin,leusuario,idlicenciaestadotipo
                ,ca.licenciaestadotipo.*,ca.persona.*, COUNT(*) OVER() AS totalCount
            FROM ca.persona
                LEFT JOIN ca.licencia USING(idpersona)
                LEFT JOIN ca.licenciatipo USING(idlicenciatipo)
                LEFT JOIN ca.licenciaestado USING(idlicencia)
                LEFT JOIN ca.licenciaestadotipo	USING(idlicenciaestadotipo)
			WHERE nullvalue(lefechafin)
                AND penrodoc IN (
                    select penrodoc
                    from ca.persona
                        natural join ca.empleado
                        natural join ca.sector
                        natural join ca.afip_situacionrevistaempleado
                        JOIN usuario ON penrodoc = dni
                    WHERE lefechainicio	>= '2024-01-01' AND (asrefechahasta >= now() OR nullvalue(asrefechahasta)) AND penrodoc <> parametro->>'nrodoc'
                        AND (parametro->>'idlicenciaestadotipo' = '0' OR idlicenciaestadotipo = parametro->>'idlicenciaestadotipo')
                            AND  (nullvalue(buscar) OR buscar = '' OR penombre ILIKE '%' || buscar || '%' 
                                OR peapellido ILIKE '%' || buscar || '%' 
                                OR leobservacion ILIKE '%' || buscar || '%'
                                OR letdescripcion ILIKE '%' || buscar || '%'
                                OR ltdescripcion ILIKE '%' || buscar || '%'
                                OR TO_CHAR(lifechainicio, 'DD/MM/YYYY') ILIKE '%' || buscar || '%'
                                OR TO_CHAR(lifechafin, 'DD/MM/YYYY') ILIKE '%' || buscar || '%'
                                OR idlicencia ILIKE '%' || buscar || '%'
                                )
                )
                 ORDER BY 
                CASE 
                    WHEN parametro->>'orderBy' = 'ltdescripcion' THEN ltdescripcion::text
                    WHEN parametro->>'orderBy' = 'idlicencia' THEN idlicencia::text
                    WHEN parametro->>'orderBy' = 'leobservacion' THEN leobservacion::text
                    WHEN parametro->>'orderBy' = 'pnombreapellido' THEN penombre
                    WHEN parametro->>'orderBy' = 'letdescripcion' THEN letdescripcion::text
                    WHEN parametro->>'orderBy' = 'lifechainicio' THEN to_char(lifechainicio, 'DD/MM/YYYY')
                    WHEN parametro->>'orderBy' = 'lifechafin' THEN to_char(lifechafin, 'DD/MM/YYYY')
                    WHEN parametro->>'orderBy' = 'lefechainicio' THEN to_char(lefechainicio, 'DD/MM/YYYY')
                    --ELSE licencia.idlicencia::text -- Default si el campo no es válido
                END  || CASE WHEN parametro->>'orderDirection' = 'desc' THEN ' DESC' ELSE ' ASC' END
                LIMIT pagesize OFFSET (numpage - 1) * pagesize
        ) as t;

        SELECT INTO respuestalistas array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT  *
            FROM ca.licenciaestadotipo
			WHERE letactivo
        ) as t;

        respuestajson_info = json_build_object('licencias', respuestajson_info, 'licenciaestados',respuestalistas);
    END IF;
    IF respuestajson_info IS NOT NULL THEN
        respuestajson_info = concat('{ "w_licencia_accion":' , respuestajson_info , '}');
    ELSE
        respuestajson_info = concat('{ "w_licencia_accion":[] }');
    END IF;
    respuestajson = respuestajson_info;

    return respuestajson;

    END;

$function$
