CREATE OR REPLACE FUNCTION public.w_obtener_archivo(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
*{"idusuarioweb":5538,
	"idarchivo":"200",
	"idcentroarchivo": "1" }
*/
DECLARE
-- VARIABLES 
   elidarchivo varchar;
   elidcentroarchivo varchar;
   respuestajson jsonb;
-- RECORD
    warchivo RECORD;
BEGIN
    elidarchivo = parametro->>'idarchivo';
    elidcentroarchivo = parametro ->> 'idcentroarchivo';

   	SELECT idarchivo, idcentroarchivo, arfecha, arnombre, arextension, armd5nombre, arhabilitado,
        idusuarioweb, ardescripcion, REGEXP_REPLACE(arubicacion, '^.*?/uploaded_files/', 'uploaded_files/') || armd5nombre AS arubicacioncompleta
    INTO warchivo
    FROM w_archivo 
    WHERE idarchivo = elidarchivo AND idcentroarchivo = elidcentroarchivo;

    -- Devuelve directamente el contenido de warchivo como JSON
    respuestajson = row_to_json(warchivo);

    RETURN respuestajson;

END;
$function$
