CREATE OR REPLACE FUNCTION public.w_app_abmsectorempleado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idusuarioweb": 5538, "accion": "obtener"}
* {"idusuarioweb": 5538, "idsector": 77, "idpersona": 530, fechadesde: "2024-04-01", "fechahasta": "2024-04-20", "accion": "modificar"}
*/
DECLARE
    respuestajson_info jsonb;
    respuestajson jsonb;
    parametrobusqueda jsonb;
    datosempleado record;
    vaccion character varying;
    rdatosjefe RECORD;
    rdatosempleado RECORD;
    rdatosrol RECORD;
begin
    IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'nrodoc') OR nullvalue(parametro->>'accion') THEN
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    vaccion = parametro->>'accion';
    CASE vaccion
        WHEN 'obtener'
            THEN
                --SL 23/10/24 - Busco los datos del sector y jefe
                SELECT INTO datosempleado sef.idsector
                from ca.persona
                natural join ca.empleado
                natural join ca.sector
                join ca.sectorempleadojefe sef USING (idpersona)
                JOIN usuario ON penrodoc = dni
                WHERE penrodoc = parametro->>'nrodoc'
                AND (sejfechahasta >= now() OR nullvalue(sejfechahasta))
                AND nullvalue(sbaja);
                
                IF FOUND THEN
                    parametro = parametro || jsonb_build_object('idsector', datosempleado.idsector);
                    SELECT INTO respuestajson_info w_app_obtenerinfosector(parametro);
                END IF;
        WHEN 'obtenertodo'
            THEN
                SELECT INTO respuestajson_info w_app_obtenerinfosector(parametro);
        WHEN 'modificar'
            THEN
                IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'idpersona') OR
                nullvalue(parametro->>'sejfechadesde') OR nullvalue(parametro->>'idsectorempleadojefe') THEN
                    RAISE EXCEPTION 'R-003, Todos los parametros deben estar completos.  %',parametro;
                END IF;
                SELECT INTO rdatosempleado *
                FROM ca.persona
                    NATURAL JOIN ca.empleado
                    JOIN w_usuariorolwebsiges ON (dni = penrodoc)
                WHERE idpersona = parametro->>'idpersona'
                LIMIT 1;
                --Actualizo el registro anterior
                UPDATE ca.sectorempleadojefe
                SET sejfechadesde = CAST(parametro->>'sejfechadesde' AS DATE),
                    sejfechahasta = CAST(parametro->>'sejfechahasta' AS DATE)
                WHERE idsectorempleadojefe = parametro->>'idsectorempleadojefe';
                UPDATE w_usuariorolweb
                SET urwfechadesde = CAST(parametro->>'sejfechadesde' AS TIMESTAMP),
                    urwfechahasta = CAST(parametro->>'sejfechahasta' AS TIMESTAMP)
                WHERE idusuarioweb = rdatosempleado.idusuarioweb AND idrolweb = 42;
                UPDATE w_usuariorolwebsiges
                SET urwsfechadesde = CAST(parametro->>'sejfechadesde' AS TIMESTAMP),
                    urwsfechahasta = CAST(parametro->>'sejfechahasta' AS TIMESTAMP)
                WHERE dni = rdatosempleado.penrodoc AND idusuarioweb = rdatosempleado.idusuarioweb AND idrolweb = 42;
                SELECT INTO respuestajson_info w_app_obtenerinfosector(parametro);
        WHEN 'nuevo'
            THEN
                IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'idpersona') OR nullvalue(parametro->>'sejfechadesde') THEN
                    RAISE EXCEPTION 'R-003, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                --Busco del jefe
                SELECT INTO rdatosjefe *
                FROM ca.persona
                NATURAL JOIN ca.empleado
                WHERE penrodoc = parametro->>'nrodoc';

                SELECT INTO rdatosempleado *
                FROM ca.persona
                    NATURAL JOIN ca.empleado
                    JOIN w_usuariorolwebsiges ON (dni = penrodoc)
                WHERE idpersona = parametro->>'idpersona'
                LIMIT 1;

                IF FOUND THEN
                    --Inserto el nuevo registro
                    INSERT INTO ca.sectorempleadojefe (idusuarioweb,idsector,idpersona,sejfechadesde,sejfechahasta) VALUES
                    (CAST(parametro->>'idusuarioweb' AS BIGINT),
                    rdatosjefe.idsector,
                    CAST(parametro->>'idpersona' AS BIGINT),
                    CAST(parametro->>'sejfechadesde' AS DATE),
                    CAST(parametro->>'sejfechahasta' AS DATE));

                    INSERT INTO w_usuariorolweb (idusuarioweb, idrolweb, urwfechadesde, urwfechahasta) VALUES
                    (rdatosempleado.idusuarioweb, 42, CAST(parametro->>'sejfechadesde' AS TIMESTAMP), CAST(parametro->>'sejfechahasta' AS TIMESTAMP));

                    INSERT INTO w_usuariorolwebsiges (dni, idusuarioweb, idrolweb, urwsfechadesde, urwsfechahasta) VALUES
                    (rdatosempleado.penrodoc, rdatosempleado.idusuarioweb, 42, CAST(parametro->>'sejfechadesde' AS TIMESTAMP), CAST(parametro->>'sejfechahasta' AS TIMESTAMP));
                    parametrobusqueda = json_build_object('idpersona', parametro->>'idpersona', 'nrodoc', parametro->>'nrodoc', 'idusuarioweb', parametro->>'idusuarioweb', 'rolvista', parametro->>'rolvista');
                    IF parametro->>'rolvista' <> 'rrhh' THEN
                        parametrobusqueda = jsonb_set(
                            parametrobusqueda::jsonb,
                            '{idsector}',
                            to_jsonb(CAST(parametro->>'idsector' AS BIGINT))::jsonb
                        );
                    END IF;
                    SELECT INTO respuestajson_info w_app_obtenerinfosector(parametrobusqueda);
                ELSE
                    RAISE EXCEPTION 'R-006, El empleado no cuenta con usuario web.';
                END IF;
        WHEN 'obtenerempleados'
            THEN
                 IF nullvalue(parametro->>'idsector') THEN
                    RAISE EXCEPTION 'R-002, Todos los parametros deben estar completos.  %',parametro;
                END IF;
                SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT penombre, peapellido, idpersona, ememail, seemail, s.idsector
                        FROM ca.empleado e
                        NATURAL JOIN ca.sector s
                        NATURAL JOIN ca.persona p
                        NATURAL JOIN ca.afip_situacionrevistaempleado
                        LEFT JOIN ca.sectorempleadojefe sef USING (idpersona)
                    WHERE (e.idsector = parametro->>'idsector')
                    AND nullvalue(sbaja)
                    AND (asrefechahasta >= now() OR nullvalue(asrefechahasta))
                    AND (nullvalue(sef.idsector) OR sef.sejfechahasta = current_date OR to_char(now(), 'YYYY-MM-DD')::date NOT BETWEEN sef.sejfechadesde AND sef.sejfechahasta)
                    AND p.penrodoc <> parametro->>'nrodoc'
                    GROUP BY penombre, peapellido, idpersona, s.idsector
                ) as t;

        ELSE
	END CASE;
    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
