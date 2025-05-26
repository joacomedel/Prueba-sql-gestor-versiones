CREATE OR REPLACE FUNCTION public.w_app_obtenerbeneficio(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"accion":"obtener"}
*/
DECLARE
    --RECORD
	rrespuesta RECORD;
--VARIABLES
respuestajson jsonb;

BEGIN
--Busco los datos
SELECT INTO rrespuesta array_to_json(array_agg(row_to_json(t))) AS respuestas
FROM (
    SELECT jsonb_build_object(
        'seccion', berdescripcion,
        'idbeneficioentidadrubro', idbeneficioentidadrubro,
        'beneficios', jsonb_agg(
            jsonb_build_object(
                'idbeneficio', idbeneficio,
                'benombre', benombre,
                'idbeneficioentidad', idbeneficioentidad,
                'bedescripcion', bedescripcion,
                'btitulo', btitulo,
                'bdescripcioncorta', bdescripcioncorta,
                'bfechainivigencia', bfechainivigencia,
                'bfechafinvigencia', bfechafinvigencia,
                'localidades', (
                    SELECT jsonb_agg(jsonb_build_object('descrip', l.descrip, 'idlocalidad',l.idlocalidad))
                    FROM w_beneficiolocalidad bl
                    JOIN localidad l USING (idlocalidad)
                    WHERE bl.idbeneficio = f.idbeneficio
                ),
                'bdescripcionlarga', bdescripcionlarga,
                'bdescuento', bdescuento,
                'bimagen', w_obtener_archivo(jsonb_build_object('idarchivo', idarchivo, 'idcentroarchivo', idcentroarchivo))->>'arubicacioncompleta',
                'bterminosycondiciones', bterminosycondiciones,
                'cantidadconsumos', cantidadconsumos
            ) ORDER BY borden, bfechamodificacion DESC
        )
    ) AS benefseccion
    FROM (
        SELECT
            b.idbeneficio, berorden, borden, benombre, berdescripcion, bedescripcion, btitulo, bdescripcioncorta,
            idbeneficioentidadrubro, idbeneficioentidad, bdescripcionlarga, bdescuento, 	idarchivo, 	idcentroarchivo,
            bterminosycondiciones, COUNT(buw.idbeneficiousuarioweb) AS cantidadconsumos, bfechainivigencia, bfechafinvigencia,
            bfechamodificacion, berfechamodificacion
        FROM
            w_beneficio b
            LEFT JOIN w_beneficioestado bes USING (idbeneficio)
            LEFT JOIN w_beneficioentidad be USING (idbeneficioentidad)
            LEFT JOIN w_beneficioentidadrubro ber USING (idbeneficioentidadrubro)
            NATURAL JOIN w_beneficioestadotipo bt
            LEFT JOIN w_beneficiousuarioweb buw ON (
                buw.idbeneficio = b.idbeneficio
                AND buw.idusuarioweb = parametro ->> 'idusuarioweb'
            )
        WHERE (idbeneficioestadotipo <> 3 AND parametro->> 'accionvista' = 'obtenergestion') OR 
            (idbeneficioestadotipo <> 2
            AND nullvalue (berbaja)
            AND nullvalue (bebaja)
            AND nullvalue (befechafin)
            AND date (now()) BETWEEN bfechainivigencia AND bfechafinvigencia) 
        GROUP BY
            b.idbeneficio, bes.idbeneficioestado, be.idbeneficioentidad, ber.idbeneficioentidadrubro,
            bt.idbeneficioestadotipo
        
    ) as f
    GROUP BY
        berdescripcion, idbeneficioentidadrubro, f.berorden, f.berfechamodificacion
        ORDER BY f.berorden, f.berfechamodificacion DESC
) AS t;

respuestajson = rrespuesta.respuestas;

RETURN respuestajson;

END;
$function$
