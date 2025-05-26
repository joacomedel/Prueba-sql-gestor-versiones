CREATE OR REPLACE FUNCTION public.w_app_obtenerinfosector(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idusuarioweb": 5538, "nrodoc": "43947118" "accion": "obtener", "idsector": null}
*/
DECLARE
    respuestajson_info jsonb;
    respuestajson_secciones jsonb;
    respuestajson_seccionesjefe jsonb;
    respuestajson jsonb;
    respuestajsonjefe jsonb;
begin
    PERFORM w_darsectorhijo(parametro);

    SELECT INTO respuestajson_seccionesjefe array_to_json(array_agg(row_to_json(t)))
    FROM (
        SELECT *
            FROM ca.sectorempleadojefe
            NATURAL JOIN ca.sector
            NATURAL JOIN ca.persona
        WHERE ((sejfechahasta >= now() OR nullvalue(sejfechahasta)) AND nullvalue(sbaja))
        AND CASE WHEN NOT nullvalue(parametro->>'idsector') THEN idsector = parametro->>'idsector' ELSE TRUE END
        AND penrodoc <> parametro->>'nrodoc'
		AND (NOT nullvalue(sejfechahasta) OR parametro->>'rolvista' = 'rrhh')
        ORDER BY idsector DESC
    ) as t;
    SELECT INTO respuestajson_secciones array_to_json(array_agg(row_to_json(t)))
    FROM (
        SELECT *
            FROM sectorhijojefe
            JOIN ca.sector USING (idsector)
        WHERE nullvalue(sbaja) 
        ORDER BY idsector ASC
    ) as t;
    respuestajson_info = json_build_object('sectores', respuestajson_secciones, 'sectoresjefe', respuestajson_seccionesjefe);
    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
