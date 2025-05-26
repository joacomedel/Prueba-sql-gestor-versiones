CREATE OR REPLACE FUNCTION public.w_vinculararchivoorden(parametro jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
* Vincula la orden con un archivo de la tabla w_archivo
* {"nroorden": 5538, "centro": 1, "archivos": [{"tipo": url, "valor": "www.hola_que_tal.com"} ...}]}
*/
DECLARE
    respuesta boolean;
    arrayArch jsonb[];
    paramArch jsonb;
begin

    IF nullvalue(parametro->>'nroorden') OR nullvalue(parametro->>'centro') OR nullvalue(parametro->>'archivos') THEN 
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;
        respuesta = false;
        --Transformo el JSON en array para poder recorrerlo en un FOREACH
        arrayArch := ARRAY(SELECT jsonb_array_elements_text(parametro->'archivos'));
        RAISE NOTICE 'arrayOrd: %', arrayArch;

        FOREACH paramArch IN ARRAY arrayArch

        LOOP
            INSERT INTO w_ordenarchivo(idarchivo, idcentroarchivo, nroorden, centro) VALUES 
                (CAST(paramArch->>'idarchivo' AS BIGINT), CAST(paramArch->>'idcentroarchivo' AS BIGINT), CAST(parametro->>'nroorden' AS BIGINT), CAST(parametro->>'centro' AS BIGINT));

            respuesta = true;
        END LOOP;

    return respuesta;
end;
$function$
