CREATE OR REPLACE FUNCTION public.w_obtenerempleadojefe(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"nrodoc": 43947118}
*/
DECLARE
    respuestajson jsonb;
    rdatosjefe RECORD;
    rdatos RECORD;
begin
    IF nullvalue(parametro->>'nrodoc') THEN 
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;

    -- --SL 24/10/24 - Verifico si la persona es jefe
    -- SELECT INTO rdatosjefe * FROM ca.persona p
    --     NATURAL JOIN ca.empleado es
    --     LEFT JOIN ca.sectorempleadojefe sej ON (sej.idsector = es.idsector)
    -- WHERE p.penrodoc =  parametro->>'nrodoc' AND sej.idpersona = p.idpersona AND (sej.sejfechadesde <= NOW()) AND (sejfechahasta >= now() OR nullvalue(sejfechahasta));
    
    -- SL 11/12/24 Busco al jefe del empleado
    SELECT INTO rdatos sej.idsector, pj.penrodoc, pj.penombre, pj.peapellido, ar.arubicacion, 
    ARRAY(
        SELECT DISTINCT email
        FROM (
            VALUES (pj.peemail), (ej.ememail), (s.seemail)
        ) AS email_table(email)
        WHERE email IS NOT NULL
    ) AS peemail
    FROM ca.persona p
        NATURAL JOIN ca.empleado es
        NATURAL JOIN ca.sector s
        LEFT JOIN ca.sectorempleadojefe sej ON (sej.idsector = es.idsector)
        LEFT JOIN ca.sectorempleadojefe esjefe ON (p.idpersona = esjefe.idpersona AND (esjefe.sejfechahasta >= now() OR esjefe.sejfechahasta IS NULL))
        JOIN ca.persona pj ON (sej.idpersona = pj.idpersona)        --Busco datos personales
        JOIN ca.empleado ej ON (ej.idpersona = pj.idpersona)        --Busco datos institucionales
        LEFT JOIN ca.archivopersona ap ON (ap.idpersona = pj.idpersona AND idtipoarchivo = 1)
        LEFT JOIN public.w_archivo ar USING (idarchivo, idcentroarchivo)
    WHERE p.penrodoc = parametro->>'nrodoc' 
    AND pj.penrodoc <> parametro->>'nrodoc' 
    AND (nullvalue(esjefe.idpersona) OR esjefe.sejfechahasta <= now())
    AND (sej.sejfechadesde <= NOW()) 
    AND (sej.sejfechahasta >= now() OR sej.sejfechahasta IS NULL)
    ORDER BY sej.sejfechadesde DESC;

    IF NOT FOUND THEN
        --SL 11/12/24 - Si no lo encuentro busco al encargado del sector
        SELECT INTO rdatos sej.idsector, pj.penrodoc, pj.penombre, pj.peapellido, ar.arubicacion, 
        ARRAY(
            SELECT DISTINCT email
            FROM (
                VALUES (pj.peemail), (ej.ememail), (s.seemail)
            ) AS email_table(email)
            WHERE email IS NOT NULL
        ) AS peemail
        FROM ca.persona p
            NATURAL JOIN ca.empleado es
            NATURAL JOIN ca.sector s
            JOIN ca.sector sp ON (s.idsectorpadre = sp.idsector)                --Busco al sector padre
            LEFT JOIN ca.sectorempleadojefe sej ON (sej.idsector = sp.idsector)
            JOIN ca.persona pj ON (sej.idpersona = pj.idpersona)
            JOIN ca.empleado ej ON (ej.idpersona = pj.idpersona)
			LEFT JOIN ca.archivopersona ap ON (ap.idpersona = pj.idpersona AND idtipoarchivo = 1)
			LEFT JOIN public.w_archivo ar USING (idarchivo, idcentroarchivo)
        WHERE p.penrodoc = parametro->>'nrodoc' AND pj.penrodoc <> parametro->>'nrodoc' AND (sej.sejfechadesde <= NOW()) AND (sejfechahasta >= now() OR nullvalue(sejfechahasta))
            ORDER BY sejfechadesde DESC;
    END IF;

    IF NOT FOUND THEN
    -- SL 11/12/24 - Si no encuentro jefe devuelvo siempre RRHH
       SELECT INTO rdatos  s.idsector, p.penrodoc, p.penombre, p.peapellido, ar.arubicacion, 
        ARRAY[
            'recursoshumanos@sosunc.org.ar', 
            'rrhh.auxiliar@sosunc.net.ar'
        ] AS peemail
        FROM ca.sector s 
            NATURAL JOIN ca.empleado e
            NATURAL JOIN ca.persona p
            LEFT JOIN ca.sectorempleadojefe sej ON (sej.idsector = s.idsector)
        LEFT JOIN ca.archivopersona ap ON (ap.idpersona = p.idpersona AND idtipoarchivo = 1)
        LEFT JOIN public.w_archivo ar USING (idarchivo, idcentroarchivo)
        WHERE s.idsector = 60;
    END IF;

    respuestajson = row_to_json(rdatos);
    return respuestajson;

end;
$function$
