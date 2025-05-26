CREATE OR REPLACE FUNCTION public.w_app_gestionbeneficio(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* SELECT w_app_gestionbeneficio('________')
*{"accion":"obtener", "idusuarioweb": 5538}
*{"accion":"nuevo", "titulo": "prueba123", "descripcion": "loremimpsum20", "bfechainivigencia": "2024-03-20", "bfechafinvigencia": "2024-12-20", "bdescripcionlarga": "loremloremloremloremloremloremlorem", "bdescuento": "20", "bterminosycondiciones": "www.google.com", "bimagen": "IMG", "idusuarioweb": 5538, "idbeneficioentidad": 1, "arrayidbeneflocalidad": [{"idlocalidad": 1}, {"idlocalidad": 2} ]}
*{"accion":"editar", "idbeneficio": 1, "titulo": "prueba123", "descripcion": "loremimpsum20", "bfechainivigencia": "2024-03-20", "bfechafinvigencia": "2024-12-20", "bdescripcionlarga": "loremloremloremloremloremloremlorem", "bdescuento": "20", "bterminosycondiciones": "www.google.com", "bimagen": "IMG", "idusuarioweb": 5538, "idbeneficioentidad": 1, "arrayidbeneflocalidad": [{"idlocalidad": 1}, {"idlocalidad": 2} ]}
*{"accion":"baja", "idbeneficio": 1, "idusuarioweb": 5538}
*{"accion":"marcar", "idbeneficio": 1, "idusuarioweb": 5538, "nrodoc": "43947118", "tipodoc": "1"}
*{"accion":"datosgestion"}
*/
DECLARE
    --RECORD
    losarchivos varchar;
	rrespuesta RECORD;
	rbeneficio RECORD;
	rpersona RECORD;
	--VARIABLES
	paramidlocalidad jsonb;
	arrayidbenef jsonb[];
	respuestajson_ob jsonb; 
	respuestajson jsonb;
	vfechainivigencia TIMESTAMP WITHOUT TIME ZONE;
	vfechafinvigencia TIMESTAMP WITHOUT TIME ZONE;
	idbeneficioinsert integer; 
	vaccion varchar;
	vcambios integer = 0;
BEGIN
    --Obtengo los parametros
    losarchivos = parametro ->>'archivos';

	IF (parametro ->> 'accion') IS NULL THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	vaccion = parametro->>'accion';

    --RAISE EXCEPTION 'R-500, asdasdasd: %',parametro;

	CASE vaccion
		WHEN 'obtener' 
			THEN 
				IF nullvalue(parametro->>'idusuarioweb') THEN
					RAISE EXCEPTION 'R-007, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

				SELECT INTO respuestajson_ob w_app_obtenerbeneficio(parametro);
		WHEN 'nuevo'
			THEN 
				IF nullvalue(parametro->>'titulo') OR nullvalue(parametro->>'descripcion')  OR nullvalue(parametro->>'idusuarioweb') 
				 OR nullvalue(parametro->>'idbeneficioentidad')  OR nullvalue(parametro->>'bdescripcionlarga')  OR nullvalue(parametro->>'bdescuento')
				  OR nullvalue(parametro->>'bterminosycondiciones') OR nullvalue(parametro->>'arrayidbeneflocalidad')
				  OR nullvalue(parametro->>'bfechainivigencia') OR nullvalue(parametro->>'bfechafinvigencia') THEN
					RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

				--Traigo fechas
				vfechainivigencia = parametro->>'bfechainivigencia';
				vfechafinvigencia = parametro->>'bfechafinvigencia';

				--Inserto el nuevo beneficio
				INSERT INTO w_beneficio (idusuarioweb, idbeneficioentidad, btitulo, bdescripcioncorta, bdescripcionlarga, bdescuento, bfechainivigencia, bfechafinvigencia, bterminosycondiciones, idarchivo, idcentroarchivo) VALUES
				(CAST(parametro->>'idusuarioweb' AS BIGINT), CAST(parametro->>'idbeneficioentidad' AS BIGINT), parametro->>'titulo', parametro->>'descripcion', parametro->>'bdescripcionlarga', parametro->>'bdescuento', vfechainivigencia, vfechafinvigencia, parametro->>'bterminosycondiciones',  CAST(losarchivos::json->0->>'idarchivo' AS BIGINT),  CAST(losarchivos::json->0->>'idcentroarchivo' AS BIGINT));

				--Obtengo el id del insert
				SELECT INTO idbeneficioinsert currval('w_beneficio_idbeneficio_seq'::regclass);

				--Inserto el estado activo
				PERFORM w_cambiarestadobeneficio(jsonb_build_object('idbeneficio', idbeneficioinsert, 'idusuarioweb', parametro->>'idusuarioweb', 'idbeneficioestadotipo', 1));
				
				--Transformo el JSON en array para poder recorrerlo en un FOREACH
				arrayidbenef := ARRAY(SELECT jsonb_array_elements_text(parametro->'arrayidbeneflocalidad'));
				RAISE NOTICE 'arrayOrd: %', arrayidbenef;

				-- -- En caso de que se requiera insertar también una imagen
				-- IF ((parametro->>'editarFoto')::boolean AND parametro->>'arubicacion' IS NOT NULL) THEN
       	 		-- 	UPDATE w_beneficio 
        		-- 	SET bimagen = parametro->>'arubicacion'
        		-- 	WHERE idbeneficio = idbeneficioinsert;
    			-- END IF;

				-- En caso de que se requiera actualizar la imagen
				IF ((parametro->>'editarFoto')::boolean AND losarchivos IS NOT NULL) THEN
       	 			UPDATE w_beneficio 
        			SET idarchivo = CAST(losarchivos::json->0->>'idarchivo' AS BIGINT),
                    idcentroarchivo = CAST(losarchivos::json->0->>'idcentroarchivo' AS BIGINT)
        			WHERE idbeneficio = idbeneficioinsert;
    			END IF;

				--Inserto la localidad del beneficio
				FOREACH paramidlocalidad IN ARRAY arrayidbenef
				LOOP
					-- RAISE EXCEPTION 'parametro: %', paramidlocalidad;

					INSERT INTO w_beneficiolocalidad(idlocalidad, idbeneficio) VALUES 
					(CAST(paramidlocalidad->>'idlocalidad' AS INTEGER), idbeneficioinsert);
				END LOOP;		
				
				--Busco datos actualizados
				SELECT INTO respuestajson_ob w_app_obtenerbeneficio(parametro);
		WHEN 'editar'
			THEN 

				-- RAISE EXCEPTION 'R-003, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;

				IF nullvalue(parametro->>'titulo') OR nullvalue(parametro->>'descripcion')  OR nullvalue(parametro->>'idusuarioweb') 
				 OR nullvalue(parametro->>'idbeneficioentidad')  OR nullvalue(parametro->>'bdescripcionlarga')  OR nullvalue(parametro->>'bdescuento')
				--   OR nullvalue(parametro->>'bimagen') 
				   OR nullvalue(parametro->>'idbeneficio') OR nullvalue(parametro->>'bfechainivigencia') 
                  OR  nullvalue(parametro->>'bfechafinvigencia') OR  nullvalue(parametro->>'arrayidbeneflocalidad') THEN
					RAISE EXCEPTION 'R-003, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

                --Traigo fechas
				vfechainivigencia = parametro->>'bfechainivigencia';
				vfechafinvigencia = parametro->>'bfechafinvigencia';

				--Actualizo el beneficio
				UPDATE w_beneficio 
				SET idusuarioweb = CAST(parametro->>'idusuarioweb' AS BIGINT), 
					idbeneficioentidad = CAST(parametro->>'idbeneficioentidad' AS BIGINT), 
					btitulo = parametro->>'titulo', bdescripcioncorta = parametro->>'descripcion',
					bdescripcionlarga = parametro->>'bdescripcionlarga', 
					bdescuento = parametro->>'bdescuento', --bimagen = parametro->>'bimagen', 
					bfechainivigencia = vfechainivigencia, bfechafinvigencia = vfechafinvigencia, 
					bterminosycondiciones = parametro->>'bterminosycondiciones',
					bfechamodificacion = now()
				WHERE idbeneficio = parametro->>'idbeneficio';

				--Verifico si se realizo el update
				GET DIAGNOSTICS vcambios = ROW_COUNT;

				--Busco datos actualizados
				IF vcambios > 0 THEN

					-- En caso de que se requiera actualizar la imagen
				 	IF ((parametro->>'editarFoto')::boolean AND losarchivos IS NOT NULL) THEN
       	 				UPDATE w_beneficio 
        				SET idarchivo = CAST(losarchivos::json->0->>'idarchivo' AS BIGINT),
                        idcentroarchivo = CAST(losarchivos::json->0->>'idcentroarchivo' AS BIGINT)
        				WHERE idbeneficio = parametro->>'idbeneficio';
    				END IF;

					--Elimino las localidades actuales
					DELETE FROM w_beneficiolocalidad WHERE idbeneficio = parametro->>'idbeneficio';

					--Transformo el JSON en array para poder recorrerlo en un FOREACH
					arrayidbenef := ARRAY(SELECT jsonb_array_elements_text(parametro->'arrayidbeneflocalidad'));
					RAISE NOTICE 'arrayOrd: %', arrayidbenef;

					--Inserto la localidad del beneficio
					FOREACH paramidlocalidad IN ARRAY arrayidbenef
					LOOP
						-- RAISE EXCEPTION 'parametro: %', paramidlocalidad;
						INSERT INTO w_beneficiolocalidad(idlocalidad, idbeneficio) VALUES 
						(CAST(paramidlocalidad->>'idlocalidad' AS INTEGER), CAST(parametro->>'idbeneficio' AS BIGINT));
					END LOOP;		

					SELECT INTO respuestajson_ob w_app_obtenerbeneficio(parametro);
				ELSE
					RAISE EXCEPTION 'R-004, No se pudo realizar la actualización del beneficio, intente nuevamente.';
				END IF;

		WHEN 'baja'
			THEN 
				IF nullvalue(parametro->>'idbeneficio') OR nullvalue(parametro->>'idusuarioweb') THEN
					RAISE EXCEPTION 'R-005, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

				--Actualizo el beneficio
				PERFORM w_cambiarestadobeneficio(jsonb_build_object('idbeneficio', parametro->>'idbeneficio', 'idusuarioweb', parametro->>'idusuarioweb', 'idbeneficioestadotipo', 2));

				--Busco datos actualizados
				SELECT INTO respuestajson_ob w_app_obtenerbeneficio(parametro);
		WHEN 'buscar'
			THEN 
				IF nullvalue(parametro->>'idbeneficioentidad') OR nullvalue(parametro->>'idusuarioweb') THEN
					RAISE EXCEPTION 'R-008, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

                SELECT INTO rbeneficio
                    b.idbeneficio, berorden, borden, benombre, berdescripcion, bedescripcion, btitulo, bdescripcioncorta,
                    idbeneficioentidadrubro, idbeneficioentidad, bdescripcionlarga, bdescuento, w_obtener_archivo(jsonb_build_object('idarchivo', idarchivo, 'idcentroarchivo', idcentroarchivo))->>'arubicacioncompleta' as bimagen,
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
                WHERE  idbeneficioentidad = parametro->>'idbeneficioentidad'
                    AND idbeneficioestadotipo <> 2
                    AND nullvalue (berbaja)
                    AND nullvalue (bebaja)
                    AND nullvalue (befechafin)
                    AND date (now()) BETWEEN bfechainivigencia AND bfechafinvigencia 
                GROUP BY
                    b.idbeneficio, bes.idbeneficioestado, be.idbeneficioentidad, ber.idbeneficioentidadrubro,
                    bt.idbeneficioestadotipo;

                IF FOUND THEN
				    --Devuelvo el beneficio
				    SELECT INTO respuestajson_ob row_to_json(rbeneficio);
                ELSE
                    RAISE EXCEPTION 'R-010, El beneficio está fuera del periodo válido';
                END IF;
		WHEN 'marcar'
			THEN 
				IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'nrodoc') OR nullvalue(parametro->>'tipodoc') OR nullvalue(parametro->>'idbeneficio') OR nullvalue(parametro->>'codigo') THEN
					RAISE EXCEPTION 'R-006, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

                SELECT INTO rbeneficio * FROM w_beneficio 
                NATURAL JOIN  w_beneficioentidad
                WHERE idbeneficio = parametro->>'idbeneficio' AND becodigo = parametro->>'codigo';
                
                IF FOUND THEN
                    -- SELECT INTO rpersona * FROM persona
                    -- WHERE nrodoc = parametro->>'nrodoc' 
                    -- AND INTO rpersona fechafinos >= now();
                    SELECT nrodoc, false AS esEmpleado FROM persona
                    WHERE nrodoc = parametro->>'nrodoc'
                    AND fechafinos >= now()
                        UNION
                    SELECT INTO rpersona dni AS nrodoc, true AS esEmpleado FROM usuarioconfiguracion
                    WHERE dni = parametro->>'nrodoc'
                    AND ucactivo
                    LIMIT 1;

                    IF FOUND THEN
                        IF CURRENT_DATE BETWEEN rbeneficio.bfechainivigencia AND rbeneficio.bfechafinvigencia THEN
                            --Almaceno el usuario que esta utilizando el beneficio
                            INSERT INTO w_beneficiousuarioweb (idusuarioweb, idbeneficio, nrodoc, tipodoc ) VALUES
                            (CAST(parametro->>'idusuarioweb' AS BIGINT), 
                            CAST(parametro->>'idbeneficio' AS BIGINT), 
                            CASE rpersona.esEmpleado WHEN false THEN rpersona.nrodoc ELSE NULL END, 
                            CASE rpersona.esEmpleado WHEN false THEN CAST(parametro->>'tipodoc' AS SMALLINT) ELSE NULL END);
                            respuestajson_ob = json_build_object('error', false, 'mensaje', 'El beneficio fue utilizado correctamente', 'fecha', now(), 'newBenef', w_app_obtenerbeneficio(parametro));
                        ELSE
                            respuestajson_ob = json_build_object('error', true, 'mensaje', 'El beneficio está fuera del periodo válido', 'newBenef', w_app_obtenerbeneficio(parametro));
                        END IF;
                    ELSE
                        respuestajson_ob = json_build_object('error', true, 'mensaje', 'El afiliado no se encuentra activo', 'newBenef', w_app_obtenerbeneficio(parametro));
                    END IF;
                ELSE
                    respuestajson_ob = json_build_object('error', true, 'mensaje', 'El codigo del beneficio no coincide', 'newBenef', w_app_obtenerbeneficio(parametro));
                END IF;
		WHEN 'datosgestion'
			THEN 
				--Busco datos 
				SELECT INTO respuestajson_ob w_app_datosgestionbeneficio(parametro);
		ELSE 
	END CASE;
	
		--Verifico si encontre datos
	IF respuestajson_ob IS NOT NULL THEN
		respuestajson = respuestajson_ob;
	END IF;

	RETURN respuestajson;
END;
$function$
