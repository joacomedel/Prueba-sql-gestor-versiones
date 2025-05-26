CREATE OR REPLACE FUNCTION public.w_coberturamedicamento(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*select from w_coberturamedicamento('{"codigobarra":"7793640002093","medicamento":"actron", "monodroga": "ibuprofeno"}'::jsonb);*/
/*ds 12/12/24 - creo funcion para gestionar los datos del perfil del empleado*/
DECLARE
    vaccion TEXT := parametro->>'accion';
    datosmedicamento JSONB; -- Cambiado de JSON a JSONB
    respuestajson JSONB;
    rpersona bigint; 
BEGIN

	CASE
      WHEN vaccion = 'filtrar' THEN 
        SELECT INTO datosmedicamento array_to_json(array_agg(row_to_json(t)))
        FROM (
          SELECT mtroquel as Troquel,mcodbarra as CodigoBarra,mnombre as    Medicamento, mpresentacion as    Presentacion,monnombre as    Monodroga,(multiplicador * 100) as    Cobertura
            FROM manextra 
                    NATURAL JOIN medicamento
                    NATURAL JOIN vias
                    NATURAL JOIN formas
                    NATURAL JOIN monodroga
                    JOIN plancoberturafarmacia USING(idmonodroga)
            WHERE nullvalue(fechafinvigencia)
                AND not nullvalue( mcodbarra) ---AND multiplicador<>0
                AND idfarmtipoventa <> 1  -- venta libre
                AND idfarmtipoventa <> 7 --- No clasificado
                AND idfarmtipoventa <> 5 -- Pendiente
                AND (
                        (
                            parametro->>'codigobarra' IS NULL 
                            OR parametro->>'codigobarra' = '' 
                            OR mcodbarra ilike CONCAT('%', parametro->>'codigobarra', '%') 
                        ) AND (
                            parametro->>'medicamento' IS NULL 
                            OR parametro->>'medicamento' = '' 
                            OR concat(mnombre, monnombre) ilike CONCAT('%', parametro->>'medicamento', '%') 
                        ) 
                        --AND (
                        --    parametro->>'monodroga' IS NULL 
                        --    OR parametro->>'monodroga' = '' 
                        --    OR monnombre ilike CONCAT('%', parametro->>'monodroga', '%') 
                        --)
                )
            ORDER BY mnombre,monnombre 
        ) t;
	ELSE 
        RAISE EXCEPTION 'El valor de acción no es válido. %', parametro;
	END CASE;

    respuestajson := jsonb_build_object(
    'datosmedicamento', COALESCE(datosmedicamento, '{}'::jsonb)
);

    RETURN respuestajson;
END;

$function$
