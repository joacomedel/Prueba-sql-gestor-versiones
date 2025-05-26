CREATE OR REPLACE FUNCTION public.w_app_buscarprestadoresgestor(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$

	-- SELECT w_app_buscarprestadoresgestor('{idusuarioweb: '33493'}')

DECLARE 
	rdatos RECORD;
	rdatospres RECORD;
	respuestajson jsonb;
BEGIN

	--Verifico que lleguen los datos necesarios para operar
	IF (parametro ->> 'idusuarioweb' IS NULL) THEN
		RAISE EXCEPTION 'R-001 WS_Login, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	--Busco el gestor y verifico si tiene el rol
	SELECT INTO rdatos * FROM w_usuarioweb 
	NATURAL JOIN w_usuariorolweb
	WHERE idusuarioweb = parametro ->> 'idusuarioweb'
	AND idrolweb = 28;		-- Rol gestor de prestadores

	IF FOUND THEN
		--Busco los prestadores asociado al gestor
		SELECT INTO rdatospres  array_to_json(array_agg(row_to_json(t))) AS prestadores
            FROM (	
				SELECT p.*, up.idusuarioweb FROM w_usuariowebgestorprestador AS gup
				NATURAL JOIN prestador AS p
				LEFT JOIN w_usuarioprestador AS up USING (idprestador)
				WHERE gup.idusuarioweb = rdatos.idusuarioweb
				AND nullvalue(gupeliminado)
			) as t;

		-- Verificar si rdatospres es NULL y asignar un array vacío si es el caso
		IF rdatospres IS NULL THEN
			respuestajson = '[]'::json;  -- '[]' representa un array JSON vacío en PostgreSQL
		ELSE
			respuestajson = rdatospres.prestadores;
		END IF;
	ELSE
		--Notifico el error
		RAISE EXCEPTION 'R-002 WS_Login, El usuario no es un gestor de prestadores. %',parametro;
	END IF;

	RETURN respuestajson;
END;
$function$
