CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_valoresunida_anexo(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalores refcursor;
       unvalor record;
        rfiltros RECORD;
		rasocconv RECORD;
		rverifica RECORD;
		ranexovalor RECORD;  
        vusuario INTEGER;
		--vidprestador BIGINT;
		--vidasocconv INTEGER;
		--vidconvenio INTEGER;
		vasocarray VARCHAR[];
BEGIN 
-- Este proceso no carga anexo de valores para la asociacion
IF iftableexists('TEMPTABLAVALORES') THEN 
	DELETE FROM TEMPTABLAVALORES;
ELSE 
	CREATE TEMP TABLE TEMPTABLAVALORES (  ACCION VARCHAR,  TUDESCRIPCION VARCHAR,  FECHAINICIOVIGENCIA VARCHAR,  PCATEGORIA VARCHAR,  TVFECHAINGRESO TIMESTAMP,  IDCONVENIO BIGINT,  VALOR VARCHAR,  IDTABLAVALOR BIGINT,  TVINIVIGENCIA TIMESTAMP,  IDTIPOUNIDAD BIGINT,  FINAL INTEGER  ); 
END IF;

     vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
	 	OPEN cvalores FOR
SELECT asoc_con_unidad.*,array_length(string_to_array(asociaciones_siges, '@'), 1)  as canti_asociacion
							FROM (
						SELECT trim(upper(tipounidad)) as tipounidad
							,sys_dar_numero(valorunidad,0.0) as valorunidad
							,asociaciones_siges
							,fechainiciovigencia
							,idnomencladortipounidadparamigrar
							FROM nomenclador_tipounidad_para_migrar as m
							WHERE nullvalue(ntupmfechaproceso)
							) asoc_con_unidad
WHERE asoc_con_unidad.asociaciones_siges = rfiltros.asociaciones_siges
AND fechainiciovigencia = rfiltros.fechainiciovigencia
ORDER BY asociaciones_siges
;
	    FETCH cvalores INTO unvalor ;
		WHILE  found LOOP 
		  -- Me aseguro que existe el tipo de unidad en el catalogo de Siges
		  SELECT INTO rverifica * FROM tipounidad WHERE upper(trim(tudescripcion)) = unvalor.tipounidad;
		  IF NOT FOUND THEN
		  	INSERT INTO tipounidad(tudescripcion) VALUES(unvalor.tipounidad);
		  END IF;
		  --Tengo que recorrrer las asociaciones
		  IF unvalor.valorunidad > 0 THEN 
		  vasocarray = string_to_array(unvalor.asociaciones_siges, '@');
		  FOR i IN 1..unvalor.canti_asociacion LOOP
				SELECT INTO rasocconv idconvenio,acdecripcion,acfechaini,acfechafin,idasocconv	 
				FROM asocconvenio 
				NATURAL JOIN convenio 
				WHERE idasocconv = vasocarray[i]::integer AND acactivo
					AND (acfechafin >= current_date OR nullvalue(acfechafin))
					AND (cfinvigencia >= current_date OR nullvalue(cfinvigencia))
					ORDER BY idasocconv,idconvenio DESC LIMIT 1; 
					IF NOT FOUND THEN 
					  -- No existe la asociacion a la que se necesita vincular, marcamos el error pero procesamos las otras
--Dani reemplazo porq daba error					 
 UPDATE nomenclador_tipounidad_para_migrar SET /*nmaerrordecarga*/ntupmerrordecarga = concat(ntupmerrordecarga,'/','Valoresunida_anexo::No existe la Asociacion',vasocarray[i]) 
						  												WHERE idnomencladortipounidadparamigrar = unvalor.idnomencladortipounidadparamigrar;
					  RAISE NOTICE 'No existe la Asociacion (%) ',vasocarray[i];
					ELSE
					 -- Verifico si la unidad ya esta vinculada al Convenio, si no es asi, la vinculo
					 SELECT INTO ranexovalor tablavalores.idtablavalor,tablavalores.idconvenio,tablavalores.idtipounidad,tipounidad.tudescripcion
					 ,CASE WHEN nullvalue(tablavaloresxcategoria.idtipovalor) THEN tablavalores.idtipovalor ELSE tablavaloresxcategoria.idtipovalor END  as valor
					 ,tablavalores.tvinivigencia,tablavalores.tvfechaingreso,pcategoria        
					 FROM tablavalores        
					 LEFT JOIN tablavaloresxcategoria  USING (idconvenio,idtablavalor,idtipounidad)       
					 NATURAL JOIN convenio        
					 NATURAL JOIN tipounidad        
					 WHERE convenio.idconvenio = rasocconv.idconvenio AND (nullvalue(convenio.cfinvigencia) OR (convenio.cfinvigencia > CURRENT_DATE))             
					 AND (nullvalue(tablavalores.tvfinvigencia)  OR (tablavalores.tvfinvigencia > CURRENT_DATE))
					AND tudescripcion ilike unvalor.tipounidad;
						IF FOUND THEN
						    INSERT INTO temptablavalores (accion,tudescripcion,fechainiciovigencia,pcategoria,tvfechaingreso,idconvenio,valor,final,idtablavalor,tvinivigencia,idtipounidad )  
							VALUES('Modificar',ranexovalor.tudescripcion,unvalor.fechainiciovigencia,ranexovalor.pcategoria,now(),ranexovalor.idconvenio,unvalor.valorunidad,NULL,ranexovalor.idtablavalor,ranexovalor.tvinivigencia,ranexovalor.idtipounidad);
							RAISE NOTICE 'Voy a modificar una unidad en el Anexo (%) ',ranexovalor;
							PERFORM FROM amtablavaloresv2();
						ELSE
						    SELECT INTO rverifica * FROM tipounidad WHERE upper(trim(tudescripcion)) = unvalor.tipounidad;
							INSERT INTO temptablavalores(accion,tudescripcion,fechainiciovigencia,pcategoria,tvfechaingreso,idconvenio,valor,final,idtablavalor,tvinivigencia,idtipounidad )  
							VALUES('Agregar',rverifica.tudescripcion,unvalor.fechainiciovigencia,'A',now(),rasocconv.idconvenio,unvalor.valorunidad,NULL,NULL,NULL,rverifica.idtipounidad);
							RAISE NOTICE 'Voy a Dar de alta una unidad en el Anexo (%),(en el convenio %) ',rverifica,rasocconv.idconvenio;
							PERFORM FROM amtablavaloresv2();
						END IF; --Verifica la unidad en el convenio
						RAISE NOTICE 'Ya di de alta la unidad (%) ',unvalor;
						DELETE FROM temptablavalores;
                   END IF; --Verifica la asociacion
				RAISE NOTICE 'Listo con (%) , vasocarray ',vasocarray[i];
		  END LOOP; --Para cada Asociacion
		  END IF;
		  UPDATE nomenclador_tipounidad_para_migrar SET ntupmfechaproceso = now() 
		  WHERE idnomencladortipounidadparamigrar = unvalor.idnomencladortipounidadparamigrar;
		fetch cvalores into unvalor; --Para cada Practica
		END LOOP;
		CLOSE cvalores;
     return 'Listo';
END;
$function$
