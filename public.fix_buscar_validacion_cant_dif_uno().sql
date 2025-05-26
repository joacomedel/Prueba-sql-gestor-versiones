CREATE OR REPLACE FUNCTION public.fix_buscar_validacion_cant_dif_uno()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	una_validacion RECORD;
	consumo_web JSONB;
	cursor_validacion refcursor;
	json_entrada JSONB;
    cant INTEGER;
BEGIN
       cant = 0;
	OPEN cursor_validacion FOR SELECT * 
	                       FROM w_log_mensajes
							WHERE true
							      --     AND (lmsalida ilike '%1554086%' or lmentrada ilike '%1554086%')
								  AND lmfechaingreso >='2025-01-01' AND lmfechaingreso <='2025-03-28'
								  AND lmoperacion ilike '%emitirconsumo%';

	 FETCH cursor_validacion into una_validacion;
     WHILE  found LOOP
        		-- EXECUTE sys_dar_filtros(una_validacion.lmentrada)  INTO rfiltros;
        		json_entrada = una_validacion.lmentrada::JSONB;
        
        		-- Iterar sobre cada elemento en ConsumosWeb
        		FOR consumo_web IN 
            		SELECT jsonb_array_elements(json_entrada->'ConsumosWeb')
        		LOOP
						-- Muesto valores
						-- RAISE EXCEPTION 'Cantidad: %, Código Convenio: %, Descripción: %', 
						-- consumo_web->>'Cantidad', consumo_web->>'CodigoConvenio', consumo_web->>'DescripcionCodigoConvenio';
						IF (consumo_web->>'Cantidad'>1)  THEN
							cant = cant+1;
						END IF;          
        		END LOOP;

            	FETCH cursor_validacion INTO una_validacion;
        END LOOP;
        RAISE EXCEPTION 'Cantidad>>>>>: %', cant;
            --            consumo_web->>'Cantidad', consumo_web->>'CodigoConvenio', consumo_web->>'DescripcionCodigoConvenio';

     	CLOSE cursor_validacion;

return 'true';
END;
$function$
