CREATE OR REPLACE FUNCTION public.w_app_gestionperfilempleado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*select from w_app_gestionperfilempleado('{"nrodoc":"96023820","accion":"obtenerempleado"}'::jsonb);*/
/*ds 12/12/24 - creo funcion para gestionar los datos del perfil del empleado*/
DECLARE
    vaccion TEXT := parametro->>'accion';
    datosempleado JSONB; -- Cambiado de JSON a JSONB
    respuestajson JSONB;
    rpersona bigint; 
BEGIN

	CASE
      WHEN vaccion = 'obtenerempleado' THEN 

        SELECT INTO datosempleado array_to_json(array_agg(row_to_json(t)))
        FROM (
          SELECT p.idpersona, p.peapellido, p.penombre, p.penrodoc, ct.ctdescripcion, s.sedescripcion
            FROM ca.persona p
              JOIN usuarioconfiguracion ON (penrodoc = dni)
              LEFT JOIN ca.empleado e USING (idpersona)
              LEFT JOIN ca.sector s USING (idsector)
              LEFT JOIN ca.empleadosector es ON (es.idpersona = p.idpersona)
              LEFT JOIN ca.contratotipo ct ON (ct.idcontratotipo = e.idcontratotipo)

          WHERE ucactivo AND nullvalue(esfechafin) AND (dni = parametro->>'nrodoc'  
            OR (
                parametro->>'penombre' IS NOT NULL 
                AND parametro->>'penombre' != '' 
                AND penombre ilike CONCAT('%', parametro->>'penombre', '%')
            ) OR (
                parametro->>'peapellido' IS NOT NULL 
                AND parametro->>'peapellido' != ''
                AND peapellido ilike CONCAT('%', parametro->>'peapellido', '%')
            ))
          LIMIT 50
        ) t;
        
	ELSE 
        RAISE EXCEPTION 'El valor de acción no es válido. %', parametro;
	END CASE;

    respuestajson := jsonb_build_object(
    'datosempleado', COALESCE(datosempleado, '{}'::jsonb)
);

    RETURN respuestajson;
END;

$function$
