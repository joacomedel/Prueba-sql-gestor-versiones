CREATE OR REPLACE FUNCTION public.w_darsectorhijo(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
    SP que crea una temporal "sectorhijojefe" que tiene todos los sectores que son hijos del sector en el que es jefe la persona enviada (nrodoc)
    SELECT w_darsectorhijo('{"nrodoc":"28272137"}'::JSONB);
*/
DECLARE
      respuestajson jsonb;
      respuestajson_info jsonb;
      rpesona RECORD;
      idsectorbusqueda INTEGER;

begin
    SET search_path TO 'public';

    IF nullvalue(parametro->>'nrodoc')  THEN
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;

    SELECT INTO rpesona p.idpersona, penombre, peapellido, CASE WHEN nullvalue(sej.idsector) THEN e.idsector ELSE sej.idsector END AS idsector 
    FROM ca.persona p
        NATURAL JOIN ca.empleado e
        LEFT JOIN ca.sectorempleadojefe sej ON (sej.idpersona = e.idpersona AND (sejfechahasta >= now() OR nullvalue(sejfechahasta)))
    WHERE penrodoc =  parametro->>'nrodoc';

    IF FOUND THEN 
        idsectorbusqueda = rpesona.idsector;

        --Creo la tabla temporal para almacenar los sectores hijos
        DROP TABLE IF EXISTS sectorhijojefe;
        CREATE TEMP TABLE sectorhijojefe (
                idsectorpadre INTEGER,
                idsector INTEGER,
                nivel INTEGER,
                sedescripcion varchar
        );

        -- Busco y almaceno los sectores hijos del jefe
        WITH RECURSIVE sectores_jerarquia AS (
            -- Caso base: incluir el sector inicial
            SELECT idsector, idsectorpadre, 0 AS nivel, sedescripcion
            FROM ca.sector
            WHERE idsector = idsectorbusqueda AND nullvalue(sbaja)
            
            UNION ALL
            
            -- Caso recursivo: encontrar todos los hijos del sector actual
            SELECT s.idsector, s.idsectorpadre, sj.nivel + 1, s.sedescripcion
            FROM ca.sector s
            JOIN sectores_jerarquia sj 
              ON s.idsectorpadre = sj.idsector
              AND s.idsector != s.idsectorpadre  -- Evita ciclos infinitos
        )
        -- Inserto los sectores hijos en la tabla temporal
        INSERT INTO sectorhijojefe (idsectorpadre, idsector, nivel, sedescripcion)
        SELECT idsectorpadre, idsector, nivel, sedescripcion
        FROM sectores_jerarquia;

    ELSE
        RAISE EXCEPTION 'R-002, No se encontro al empleado';
    END IF;

    respuestajson = respuestajson_info;

    return respuestajson;

    END;

$function$
