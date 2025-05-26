CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_vincularasociacion_anexo(pfiltros character varying)
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
                        SELECT DISTINCT tipounidadh1 as tipounidad, 
                               valordeunidadh1 as valordeunidad,
                               asociaciones_siges,
                               npmfechainiciovigencia,
                               array_length(string_to_array(asociaciones_siges, '@'), 1)  as canti_asociacion,
                               dequemanera
			FROM (
				SELECT DISTINCT trim(upper(tipounidadh1)) as tipounidadh1,sys_dar_numero(valordeunidadh1,'0.0') as valordeunidadh1
,m.asociaciones_siges,npmfechainiciovigencia,'contablamapeohonorario' as dequemanera
				FROM nomenclador_mapea_asociacion_para_migrar as m
			        JOIN nomenclador_para_migrar as n USING(idnomencladorparamigrar)
				WHERE tipounidadh1 <> ''  AND nullvalue(nmafechaproceso)
				
			UNION 
				
                        	SELECT trim(upper(tipounidadh1)) as tipounidadh1,sys_dar_numero(valordeunidadh1,'0.0') as valordeunidadh1
,m.asociaciones_siges,npmfechainiciovigencia,'contablamapeogasto' as dequemanera 
				FROM nomenclador_mapea_asociacion_para_migrar as m
				JOIN nomenclador_para_migrar as n ON (n.idnomencladorparamigrar = m.idnomencladorparamigrargasto)
				WHERE tipounidadh1 <> '' AND not nullvalue(idnomencladorgasto) AND nullvalue(nmafechaprocesogasto)

                                UNION
				
 		                SELECT DISTINCT trim(upper(tipounidadh1)) as tipounidadh1,sys_dar_numero(valordeunidadh1,'0.0') as valordeunidadh1
							,CASE WHEN nullvalue(n.asociaciones_siges) THEN asociaciones_sigesgastos ELSE asociaciones_siges END ,npmfechainiciovigencia,'sintablamapeo' as dequemanera		                        
				FROM nomenclador_para_migrar as n 
				WHERE (tipounidadh1 <> '' ) 
				      AND nullvalue(npmfechacargavalorunidad)
				      AND (not nullvalue(asociaciones_siges))


                                UNION
				
 			        SELECT DISTINCT trim(upper(tipounidaday1)) as tipounidaday1,sys_dar_numero(valordeunidaday1,'0.0') as valordeunidaday1
							,CASE WHEN nullvalue(n.asociaciones_siges) THEN asociaciones_sigesgastos ELSE asociaciones_siges END ,npmfechainiciovigencia,'sintablamapeo' as dequemanera		                        
				FROM nomenclador_para_migrar as n 
				WHERE (tipounidaday1 <> '' ) 
					 AND nullvalue(npmfechacargavalorunidad)
					 AND (not nullvalue(asociaciones_siges) )

                                UNION
				
 			        SELECT DISTINCT trim(upper(tipounidadgs)) as tipounidaday1,sys_dar_numero(valordeunidadgs,'0.0') as valordeunidaday1
							,CASE WHEN nullvalue(n.asociaciones_siges) THEN asociaciones_sigesgastos ELSE asociaciones_siges END ,npmfechainiciovigencia,'sintablamapeo' as dequemanera		                        
				FROM nomenclador_para_migrar as n 
				WHERE (tipounidadgs <> '' ) 
					 AND nullvalue(npmfechacargavalorunidad)
					 AND (not nullvalue(asociaciones_sigesgastos) 
                                               OR not nullvalue(asociaciones_siges) )

	) asoc_con_unidad
        WHERE asoc_con_unidad.asociaciones_siges = rfiltros.asociaciones_siges 
              AND asoc_con_unidad.dequemanera = rfiltros.dequemanera
              AND valordeunidadh1 > 0
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
		  vasocarray = string_to_array(unvalor.asociaciones_siges, '@');
		  FOR i IN 1..unvalor.canti_asociacion LOOP
                                -- MaLaPi 21/06/2023 Limpio la tabla temporal,pues se llama muchas veces a amtablavaloresv2()
                                   DELETE FROM temptablavalores;
		   
				SELECT INTO rasocconv idconvenio,acdecripcion,acfechaini,acfechafin,idasocconv	 
				FROM asocconvenio 
				NATURAL JOIN convenio 
				WHERE idasocconv = vasocarray[i]::integer AND acactivo
					AND (acfechafin >= current_date OR nullvalue(acfechafin))
					AND (cfinvigencia >= current_date OR nullvalue(cfinvigencia))
					ORDER BY idasocconv,idconvenio DESC LIMIT 1; 
					IF NOT FOUND THEN 
					  -- No existe la asociacion a la que se necesita vincular, marcamos el error pero procesamos las otras
					  UPDATE nomenclador_mapea_asociacion_para_migrar SET nmaerrordecarga = concat(nmaerrordecarga,'/','No existe la Asociacion',vasocarray[i]) 
					   WHERE asociaciones_siges = unvalor.asociaciones_siges AND unvalor.dequemanera ilike 'contablamapeo%';
					    UPDATE nomenclador_para_migrar SET errordecarga = concat(errordecarga,'/','No existe la Asociacion',vasocarray[i]) 
					   WHERE asociaciones_siges = unvalor.asociaciones_siges AND unvalor.dequemanera ilike 'sintablamapeo%';
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
							VALUES('Modificar',ranexovalor.tudescripcion,unvalor.npmfechainiciovigencia,ranexovalor.pcategoria,now(),ranexovalor.idconvenio,unvalor.valordeunidad,NULL,ranexovalor.idtablavalor,ranexovalor.tvinivigencia,ranexovalor.idtipounidad);
							RAISE NOTICE 'Voy a modificar una unidad en el Anexo (%) ',ranexovalor;
							PERFORM FROM amtablavaloresv2();
						ELSE
						    SELECT INTO rverifica * FROM tipounidad WHERE upper(trim(tudescripcion)) = unvalor.tipounidad;
							INSERT INTO temptablavalores(accion,tudescripcion,fechainiciovigencia,pcategoria,tvfechaingreso,idconvenio,valor,final,idtablavalor,tvinivigencia,idtipounidad )  
							VALUES('Agregar',rverifica.tudescripcion,unvalor.npmfechainiciovigencia,'A',now(),rasocconv.idconvenio,unvalor.valordeunidad,NULL,NULL,NULL,rverifica.idtipounidad);
							RAISE NOTICE 'Voy a Dar de alta una unidad en el Anexo (%),(en el convenio %) ',rverifica,rasocconv.idconvenio;
							PERFORM FROM amtablavaloresv2();
						END IF; --Verifica la unidad en el convenio
						RAISE NOTICE 'Ya di de alta la unidad (%) ',unvalor;
						DELETE FROM temptablavalores;
                   END IF; --Verifica la asociacion
				RAISE NOTICE 'Listo con (%) , vasocarray ',vasocarray[i];
		  END LOOP; --Para cada Asociacion
		fetch cvalores into unvalor; --Para cada Practica
		END LOOP;
		CLOSE cvalores;
     return 'Listo';
END;
$function$
