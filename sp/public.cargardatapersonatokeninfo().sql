CREATE OR REPLACE FUNCTION public.cargardatapersonatokeninfo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$ /*
    Este sp carga datos antiguos en la tabla "w_persona_token_info" sacando la informacion del "log_mensajes"
	SELECT cargardatapersonatokeninfo();
*/
DECLARE
	respuesta BOOLEAN;
    json_salida jsonb;
    json_entrada jsonb;
    rdata RECORD;
    rprestador RECORD;
    rtokenuser RECORD;
    rdocumento RECORD;
    rexisteregistro RECORD;
    rusuariowebvalidador RECORD;
    cdata refcursor;

BEGIN

    respuesta = false;
    -- Abrir un cursor para iterar sobre los registros de la tabla w_log_mensajes
    OPEN cdata FOR
        SELECT * FROM w_log_mensajes 
        WHERE lmfechaingreso >= '2024-07-01' 
        AND lmsalida NOT ILIKE '%ERROR:%'
        AND lmoperacion ILIKE '%emitir%'
        ORDER BY lmfechaingreso DESC;

    -- Iterar sobre cada registro encontrado
    LOOP
        FETCH cdata INTO rdata;
        EXIT WHEN NOT FOUND; -- Salir del loop cuando no se encuentren más registros

        json_entrada := rdata.lmentrada::jsonb;
        json_salida := rdata.lmsalida::jsonb;


        SELECT INTO rdocumento
                    CASE WHEN not nullvalue(b.nrodoctitu)   THEN  b.nrodoctitu  
                        WHEN not nullvalue(br.nrodoctitu)   THEN  br.nrodoctitu  
                        WHEN (nullvalue(b.nrodoctitu) AND nullvalue(br.nrodoctitu)) THEN  p.nrodoc END as titu
            FROM persona p 
            LEFT JOIN benefsosunc b USING (nrodoc,tipodoc)
            LEFT JOIN benefreci br USING (nrodoc,tipodoc)
            WHERE nrodoc = json_entrada->>'NroDocumento' OR nrodoc = json_entrada->>'NroAfiliado';

        SELECT INTO rtokenuser * FROM persona_token WHERE pttoken = json_entrada->>'token' AND nrodoc = rdocumento.titu;
        
        SELECT INTO rexisteregistro * 
        FROM w_persona_token_info
        WHERE (nroorden = json_salida->'resultado'->0->>'nroorden' AND centro = json_salida->'resultado'->0->>'centro') 
        OR idpersonatoken = rtokenuser.idpersonatoken;

        -- raise EXCEPTIOn 'DATOS: %', rtokenuser;

        IF NOT FOUND THEN
            -- raise EXCEPTIOn 'DATOS: %', json_entrada->>'CuilEfector';

            select INTO rprestador * from prestador WHERE replace(pcuit,'-','') ilike json_entrada->>'CuilEfector';
            SELECT INTO rusuariowebvalidador * FROM w_usuarioweb WHERE uwnombre = trim(json_entrada->>'uwnombre');


            IF ((json_entrada->>'token' = 'suap1234'  OR  json_entrada->>'token' = 'suap279' OR json_entrada->>'token' = substr(json_entrada->>'NroAfiliado',5) )
                    OR (json_entrada->>'token' = 'evweb3412' OR json_entrada->>'token' = 'evweb5553' OR json_entrada->>'token' = 'exp_sc' OR json_entrada->>'token' = substr(json_entrada->>'NroAfiliado',6) )) THEN
            
                -- raise EXCEPTIOn 'Código de Convenio: %', json_salida->'resultado'->0->>'nroorden';

                INSERT INTO w_persona_token_info (ptidescripcion,	nroorden, centro,	idprestador,	idusuariowebvalidador) 
                VALUES(CONCAT('Validacion Online Comodin',' - ', json_entrada->>'token'), CAST(json_salida->'resultado'->0->>'nroorden' AS BIGINT), CAST(json_salida->'resultado'->0->>'centro' AS BIGINT), rprestador.idprestador, rusuariowebvalidador.idusuarioweb);
            
            END IF;
        
        respuesta = true;
        
        END IF;

    END LOOP;

    -- Cerrar el cursor
    CLOSE cdata;
    

	RETURN respuesta;
END
$function$
