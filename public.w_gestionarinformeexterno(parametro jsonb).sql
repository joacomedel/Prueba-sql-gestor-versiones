CREATE OR REPLACE FUNCTION public.w_gestionarinformeexterno(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
 SELECT w_gestionarinformeexterno('{"idprestador": "20287189517", "accion":""}')   -- BUSCA X PRESTADOR
 SELECT w_gestionarinformeexterno('{"idprestador": "20287189517", "accion":"crearInforme"}') -- CREA UN INFORME 
 SELECT w_gestionarinformeexterno('{"arrayOrd": [{"nroorden": "1435355",  "centro": "1"}, {"nroorden": "1435353",  "centro": "1"}, {"nroorden": "1435351",  "centro": "1"}], "nrodoc": "20287189517", "idinforme":"1", "accion":"agregar"}') -- AGREGO ORDENES A INFORME
 SELECT w_gestionarinformeexterno('{"arrayOrd": [{"nroorden": "1435353",  "centro": "1"}, {"nroorden": "1435351",  "centro": "1"}], "nrodoc": "20287189517", "idinforme":"1", "accion":"eliminar"}') -- ELIMINA ORDENES DE INFORM
 SELECT w_gestionarinformeexterno('{"idinforme": "4", "nroestado":"10", "accion":"cambiarestado"}') -- CAMBIAR ESTADO ORDEN
 SELECT w_gestionarinformeexterno('{"idprestador": "20287189517", "accion":"filtrarord", "todo":true}')   -- TRAE TODAS LAS ORDENES DISPONIBLES
 SELECT w_gestionarinformeexterno('{"idprestador": "20287189517", "accion":"filtrarord", "todo":false, "fechaini": "23-11-10", "fechafin": "23-11-30"}')   -- FILTRA ORDENES
*/
	respuestajson jsonb;

	vidprestador BIGINT;
	rdatos RECORD;
	rdatosord RECORD;
    vaccion varchar(50);
    numpage INTEGER := (parametro->>'page')::INTEGER;
    pagesize INTEGER :=  COALESCE((parametro->>'pageSize')::INTEGER, 10);
    buscar TEXT := parametro->>'search';
begin
	-- Verifico parametros
	IF (parametro->>'accion' IS NULL OR parametro->>'idusuariowebgestor' IS NULL) THEN
		RAISE EXCEPTION 'R-007, Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;

	vaccion = parametro->>'accion';

	IF (parametro->>'pcuit' IS NOT NULL) THEN
		SELECT INTO vidprestador w_app_buscaridprestador(parametro);
	END IF;

	-- Agrego vidprestador al objeto parametro
	parametro = parametro || jsonb_build_object('idprestador', vidprestador);

	CASE vaccion
		WHEN 'crear'
			THEN 
				-- LLamo SP que crea el informe
				PERFORM w_crearinformeexterno(parametro);
		WHEN 'buscarInforme'
			THEN 
				-- LLamo SP que busca el informe
				SELECT INTO respuestajson w_buscarinformeexterno(parametro);
		WHEN 'agregar'
			THEN
				-- LLamo SP que agrega ordenes al informe
				PERFORM w_agregarinformeexterno(parametro);
		WHEN 'enviar'
			THEN 
				-- LLamo SP que envia el informe
				PERFORM w_enviarinformeexterno(parametro);
		WHEN 'buscar'
			THEN 
				-- LLamo SP que busca todos los datos del informe
				SELECT INTO respuestajson w_obtenerdatosinformeexterno(parametro);
		WHEN 'buscarPorEstado'
			THEN 
                -- Verifico parametros
                IF (parametro->>'idinformefacturacionestadotipo' IS NULL) THEN
                    RAISE EXCEPTION 'R-010, Al Menos uno de los parametros deben estar completos.  %',parametro;
                END IF;

				SELECT INTO respuestajson informes.arrayinforme 
                    FROM (
                        SELECT array_to_json(array_agg(row_to_json(t))) as arrayinforme
                        FROM (
                            SELECT *,
                            COUNT(*) OVER() AS totalCount
                            FROM w_informefacturacionexterno
                                NATURAL JOIN w_informefacturacionexternoestado
                                NATURAL JOIN informefacturacionestadotipo
                            WHERE  nullvalue(ifeefechafin)
                            AND idinformefacturacionestadotipo = parametro->>'idinformefacturacionestadotipo'
                            AND (
                                nullvalue(buscar) OR buscar = '' 
                                OR idinformefacturacionexterno ILIKE '%' || buscar || '%'
                                OR ifefechaini ILIKE '%' || buscar || '%'
                                OR ifefechafin ILIKE '%' || buscar || '%'
                            )
                            ORDER BY idinformefacturacionexterno DESC
                            LIMIT pagesize OFFSET (numpage - 1) * pagesize
                        ) AS t
                    ) AS informes;
			ELSE
	END CASE;

	-- Verifico si tengo alguna respuesta
	IF(respuestajson IS NULL) THEN
		--Traigo todos los informes asociados al prestador
		SELECT INTO respuestajson ordenesinforme.arrayordinforme 
		FROM (
			SELECT array_to_json(array_agg(row_to_json(t))) as arrayordinforme
			FROM (
				SELECT *,
                COUNT(*) OVER() AS totalCount
				FROM w_informefacturacionexterno
					NATURAL JOIN w_informefacturacionexternoestado
					NATURAL JOIN informefacturacionestadotipo
				WHERE idusuariowebgestor = parametro->>'idusuariowebgestor'
				AND nullvalue(ifeefechafin)
				AND idinformefacturacionestadotipo <> 5       -- SL 06/03/24 - Verifico que no este en estado "Cancelado"
                AND (
                    nullvalue(buscar) OR buscar = '' 
                    OR idinformefacturacionexterno ILIKE '%' || buscar || '%'
                    OR ifefechaini ILIKE '%' || buscar || '%'
                    OR ifefechafin ILIKE '%' || buscar || '%'
                )
                ORDER BY idinformefacturacionexterno DESC
                LIMIT pagesize OFFSET (numpage - 1) * pagesize
			) AS t
		) AS  ordenesinforme;
	END IF;

	return respuestajson;
end;
$function$
