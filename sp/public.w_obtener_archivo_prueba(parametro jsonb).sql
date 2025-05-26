CREATE OR REPLACE FUNCTION public.w_obtener_archivo_prueba(parametro jsonb)
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
--    elidarchivo varchar;
   elidcentroarchivo varchar;
    mi_variable_idusuario BIGINT;
   respuestajson jsonb;
-- RECORD
    wusuario RECORD;
    elidarchivo bigint;
BEGIN
    -- elidarchivo = parametro->>'idarchivo';
    mi_variable_idusuario:= parametro->>'idusuarioweb';
    elidcentroarchivo = parametro ->> 'idcentroarchivo';

   	SELECT uwimagen, SUBSTRING(uwimagen FROM 'perfil/([^/]+)') AS uwnombreimagen
    INTO wusuario
    FROM w_usuarioweb 
    WHERE idusuarioweb = mi_variable_idusuario;

    INSERT INTO w_archivo (ardescripcion, 
    arnombre, 
    arfecha, 
    arubicacion, 
    idcentroarchivo, 
    arextension, 
    idusuarioweb, 
    armd5nombre) VALUES ('Imagen de Perfil', wusuario.uwnombreimagen, NOW(), '/var/www/html/wwwsiges/uploaded_files/perfil/', 1, 'jpg', mi_variable_idusuario, wusuario.uwnombreimagen);

    elidarchivo = currval('public.archivo_idarchivo_seq');

    INSERT INTO w_usuariowebarchivo (idusuarioweb, idarchivo, idcentroarchivo) VALUES (mi_variable_idusuario, elidarchivo, 1);


    -- Devuelve directamente el contenido de wusuario como JSON
    respuestajson = row_to_json(wusuario);

    RETURN respuestajson;

END;
$function$
