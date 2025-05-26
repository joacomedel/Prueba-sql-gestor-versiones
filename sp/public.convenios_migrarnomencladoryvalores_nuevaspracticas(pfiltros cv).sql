CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_nuevaspracticas(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalores refcursor;
       unvalor record;
        rfiltros RECORD;
		rverifica RECORD;
        vfiltroid varchar;
		vusuario INTEGER;
BEGIN 
-- SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion = cargarnuevaspracticas}');
     vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	 RAISE NOTICE 'se va a ejecutar la accion (%) ', rfiltros.accion ;
     IF rfiltros.accion = 'cargarnuevaspracticas'  THEN 
	 	OPEN cvalores FOR SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,codigocorto
		                     ,pdescripcion,activo,hon,ayud_1,ayud_2,gastos,tipounidadh1,valordeunidadh1,tipounidaday1,valordeunidaday1,modifica
							 ,incorpora,mapea,idnomencladorparamigrar,fechaproceso,errordecarga,errordedecargaacumulado
							 ,true as procesar
  				  FROM nomenclador_para_migrar 
				  WHERE nullvalue(fechaproceso) 
                                  AND sys_dar_boolean(aplicanomenclador,true)-- VAS 19-11-2024 Para que solo las tome cuando la configuracion aplica al nomenclador
					AND nullvalue(errordecarga) 
					AND incorpora ilike 'SI' ;
      END IF;
      IF rfiltros.accion = 'modificarpracticaexistente'  THEN 
	        RAISE NOTICE 'ENTRE A (%) ', rfiltros.accion ;
	   	OPEN cvalores FOR SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,codigocorto
		                     ,pdescripcion,activo,hon,ayud_1,ayud_2,gastos,tipounidadh1,valordeunidadh1,tipounidaday1,valordeunidaday1,modifica
							 ,incorpora,mapea,idnomencladorparamigrar,fechaproceso,errordecarga,errordedecargaacumulado
							 ,true as procesar
  		FROM nomenclador_para_migrar 
		WHERE nullvalue(fechaproceso) 
                      AND sys_dar_boolean(aplicanomenclador,true)-- VAS 19-11-2024 Para que solo las tome cuando la configuracion aplica al nomenclador
		        AND nullvalue(errordecarga) 
			AND modifica ilike 'SI'
								;
      END IF;
      --Marco como procesado todo lo cargado y que no se proceso anteriormente
      UPDATE asistencial_nomenclador 
      SET anprocesado =  now() ,anerror = 'Los doy de baja para cargar nuevas' 
      WHERE nullvalue(anprocesado);
      
      --Marco como procesado todo lo cargado y que no se proceso anteriormente
      UPDATE asistencial_practicaplan 
      SET apcprocesado = now() 
      WHERE nullvalue(apcprocesado);
      
      FETCH cvalores INTO unvalor ;
      WHILE  found LOOP 
      RAISE NOTICE 'voy a procesar el idnomencladorparamigrar %',unvalor.idnomencladorparamigrar ;

                IF unvalor.idnomenclador = '' OR  unvalor.idcapitulo = '' OR unvalor.idsubcapitulo = '' OR unvalor.idpractica = '' THEN
                            unvalor.procesar = false;
                            UPDATE nomenclador_para_migrar 
			    SET fechaproceso = now(),errordecarga = concat(errordecarga,'-','Algunas de sus partes esta vacio',unvalor.idnomenclador,'_',unvalor.idcapitulo,'_',unvalor.idsubcapitulo,'_',unvalor.idpractica) 
			    WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
										
			    RAISE NOTICE 'Esta no se va a procesar (%) ',concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
                 END IF;
		 IF rfiltros.accion = 'cargarnuevaspracticas'  THEN 
			--Verifico que la practica no exista actualmente en el nomenclador
                        SELECT INTO rverifica * 
                        FROM practica
                        WHERE (idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
				IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
			IF FOUND THEN
				unvalor.procesar = false; -- Volver a false
				UPDATE nomenclador_para_migrar 
				SET fechaproceso = now(),errordecarga = concat(errordecarga,'-','La practica ya existe') 
				WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
				RAISE NOTICE 'Esta no se va a procesar (%) ',concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
			END IF;
		 END IF;
					
		 IF rfiltros.accion = 'modificarpracticaexistente'  THEN 
			--Verifico que la practica exista actualmente en el nomenclador
			SELECT INTO rverifica * 
			FROM practica 
			WHERE (idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
										IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
			IF NOT FOUND THEN
				unvalor.procesar = false;
				UPDATE nomenclador_para_migrar 
				SET fechaproceso = now(),errordecarga = concat(errordecarga,'-','La practica NO existe') 
				WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
				RAISE NOTICE 'Esta no se va a procesar (%) ',concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
			END IF;
		END IF;
					
		IF unvalor.procesar THEN 
				--Cargar la practica
				-- Si el cambpo tipounidad <> '' entonces el valor es por unidad, es decir lo que esta en hon. ayud y ayud2 son cantidad de unidades
				-- Si el cambpo tipounidad = '' entonces hon. ayud y ayud2 son con valores fijos...
				-- Si el campo hon = '' entonces no se paga, por lo que debe quedar con honorario y cantidad en 0, idem para ayud_1y ayud_2
				-- Si el campo hon <> '' entonces se paga, por lo que debe quedar con honorario (depende del campo tipounidad) y cantidad en 1
				INSERT INTO asistencial_nomenclador(					 			idnomenclador, idcapitulo, idsubcapitulo, idpractica, andescripcionpractica
									, anhonorario1, anhonorario2, anhonorario3, ancantidad1, ancantidad2, ancantidad3,angastos, ancantgastos
									,  angastos2, ancantgastos2, angastos3, ancantgastos3, angastos4, ancantgastos4, angastos5, ancantgastos5
									, idnomencladorparamigrar
				) (
                                    SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,andescripcionpractica,
                                    CASE WHEN array_length(string_to_array(anhonorario1, ','), 1)  > 1
			                      AND array_length(string_to_array(anhonorario1, '.'), 1)  > 1  
	                                      THEN trim(replace(replace(anhonorario1,'.',''),',','.')) 
	                                 WHEN array_length(string_to_array(anhonorario1, ','), 1)  > 1
			                      AND array_length(string_to_array(anhonorario1, '.'), 1)  = 1  
	                                     THEN trim(replace(anhonorario1,',','.')) 
	                                 ELSE anhonorario1 END as anhonorario1,
                                    CASE WHEN array_length(string_to_array(anhonorario2, ','), 1)  > 1
			                    AND array_length(string_to_array(anhonorario2, '.'), 1)  > 1  
			                    THEN trim(replace(replace(anhonorario2,'.',''),',','.')) 
			                 WHEN array_length(string_to_array(anhonorario2, ','), 1)  > 1
					    AND array_length(string_to_array(anhonorario2, '.'), 1)  = 1  
					    THEN trim(replace(anhonorario2,',','.')) 
	                                 ELSE anhonorario2 END as anhonorario2,
	                           CASE WHEN array_length(string_to_array(anhonorario3, ','), 1)  > 1
			                     AND array_length(string_to_array(anhonorario3, '.'), 1)  > 1  
	                                     THEN trim(replace(replace(anhonorario3,'.',''),',','.')) 
	                                WHEN array_length(string_to_array(anhonorario3, ','), 1)  > 1
		                              AND array_length(string_to_array(anhonorario3, '.'), 1)  = 1  
	                                     THEN trim(replace(anhonorario3,',','.')) 
	                                ELSE anhonorario3 END as anhonorario3
                                        ,ancantidad1,ancantidad2,ancantidad3,
                                  CASE WHEN array_length(string_to_array(angastos, ','), 1)  > 1
		                            AND array_length(string_to_array(angastos, '.'), 1)  > 1  
	                                    THEN trim(replace(replace(angastos,'.',''),',','.')) 
		                       WHEN array_length(string_to_array(angastos, ','), 1)  > 1
			                    AND array_length(string_to_array(angastos, '.'), 1)  = 1  
	                                    THEN trim(replace(angastos,',','.')) 
	                               ELSE angastos END as angastos
        
                                ,ancantgastos,angastos2,ancantgastos2
                                ,asangastos3,ancantgastos3
                                ,asangastos4,ancantgastos4
                                ,angastos5,ancantgastos5
                                ,idnomencladorparamigrar
                      FROM (

	                         SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica
		                     ,pdescripcion as andescripcionpractica
--MaLaPi 26-07-2024 Cambio para soportar el null en las columnas
							--,CASE WHEN hon = ''  THEN '0' WHEN tipounidadh1 <> '' THEN trim(replace(hon,'$','')) ELSE '1' END as anhonorario1 
							--,CASE WHEN ayud_1 = ''  THEN '0' WHEN tipounidaday1 <> '' THEN trim(replace(ayud_1,'$','')) ELSE '1' END as anhonorario2 
							--,CASE WHEN ayud_2 = ''  THEN '0' WHEN tipounidaday1 <> '' THEN trim(replace(ayud_2,'$','')) ELSE '1' END as anhonorario3
							--,CASE WHEN hon = ''  THEN '0' ELSE  '1' END as ancantidad1 
							--,CASE WHEN ayud_1 = ''  THEN '0' ELSE  '1' END as ancantidad2 
							--,CASE WHEN ayud_2 = ''  THEN '0' ELSE  '1' END as ancantidad3
							--,CASE WHEN gastos = ''  THEN '0' WHEN tipounidadgs <> '' THEN trim(replace(gastos,'$','')) ELSE '1' END as angastos 
							--,CASE WHEN gastos = ''  THEN '0' ELSE '1' END as ancantgastos
                                                        ,CASE WHEN (hon = '' or hon is null)  THEN '0' WHEN tipounidadh1 <> '' THEN trim(replace(hon,'$','')) ELSE '1' END as anhonorario1 
							,CASE WHEN (ayud_1 = '' or ayud_1 is null)  THEN '0' WHEN tipounidaday1 <> '' THEN trim(replace(ayud_1,'$','')) ELSE '1' END as anhonorario2 
							,CASE WHEN (ayud_1 = '' or ayud_1 is null) THEN '0' ELSE  '1' END as ancantidad2 
                                                        ,CASE WHEN (ayud_2 = '' or ayud_2 is null)   THEN '0' WHEN tipounidaday1 <> '' THEN trim(replace(ayud_2,'$','')) ELSE '1' END as anhonorario3
							,CASE WHEN (hon = '' or hon is null)  THEN '0' ELSE  '1' END as ancantidad1 
							,CASE WHEN (ayud_2 = '' or ayud_2 is null) THEN '0' ELSE  '1' END as ancantidad3
							,CASE WHEN (gastos = '' OR gastos is null)  THEN '0' WHEN tipounidadgs <> '' THEN trim(replace(gastos,'$','')) ELSE '1' END as angastos 
							,CASE WHEN (gastos = '' OR gastos is null)  THEN '0' ELSE '1' END as ancantgastos
							, '0' as angastos2, '0' as ancantgastos2, '0' as  asangastos3, '0' as ancantgastos3, '0' as asangastos4, '0' as ancantgastos4, '0' as angastos5, '0' as ancantgastos5
							,idnomencladorparamigrar
  			FROM nomenclador_para_migrar 
			WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar
) as t

							
						);
		 RAISE NOTICE 'inserto en asistencial_nomenclador %',unvalor.idnomencladorparamigrar ;

						
		IF rfiltros.accion = 'cargarnuevaspracticas'  THEN 
			-- MaLaPi Por defecto se carga en el plan de cobertura 1 - General y 29 - Reciprocidad con Coseguro y 12 - Reciprocidad .
			--Configuro las practicas
						 
			INSERT INTO asistencial_practicaplan (idplancobertura,idplancoberturas,idnomenclador,idcapitulo, idsubcapitulo,idpractica
															  ,cobertura,ppcperiodo, ppcprioridad, serepite, ppcperiodoinicial, ppcperiodofinal
															  , pptexto, ppccantpracticanoauditada, ppccantpracticaauditada )
			(SELECT '1' as idplancobertura, 1 as idplancoberturas, idnomenclador,idcapitulo,idsubcapitulo,idpractica
		                    ,70 as cobertura,'a' as ppcperiodo,1 as ppcprioridad, true as serepite,1 as  ppcperiodoinicial,1 as ppcperiodofinal
							,concat('Por defecto al crear una practica del nomenclador <',idnomencladorparamigrar,'>') as pptexto, 10 as ppccantpracticanoauditada,120 as ppccantpracticaauditada
			  FROM nomenclador_para_migrar 
			  WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar 
			  UNION 
			  SELECT '29' as idplancobertura, 29 as idplancoberturas, idnomenclador,idcapitulo,idsubcapitulo,idpractica
		                    ,70 as cobertura,'a' as ppcperiodo,1 as ppcprioridad, true as serepite,1 as  ppcperiodoinicial,1 as ppcperiodofinal
							,concat('Por defecto al crear una practica del nomenclador <',idnomencladorparamigrar,'>') as pptexto, 10 as ppccantpracticanoauditada,120 as ppccantpracticaauditada
							FROM nomenclador_para_migrar 
							WHERE  idnomencladorparamigrar = unvalor.idnomencladorparamigrar 
			  UNION 
			  --Reciprocidad va siempre con Auditoria
			  SELECT '12' as idplancobertura, 12 as idplancoberturas, idnomenclador,idcapitulo,idsubcapitulo,idpractica
		                    ,100 as cobertura,'a' as ppcperiodo,1 as ppcprioridad, true as serepite,1 as  ppcperiodoinicial,1 as ppcperiodofinal
							,concat('Por defecto al crear una practica del nomenclador <',idnomencladorparamigrar,'>') as pptexto, 0 as ppccantpracticanoauditada,10 as ppccantpracticaauditada
			  FROM nomenclador_para_migrar 
			  WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar 
		 );
						
	 END IF; --rfiltros.accion = 'cargarnuevaspracticas'
	 -- Se les debe dar valores... para que asociaciones? 
	 --Marco como procesado los datos
	 UPDATE nomenclador_para_migrar 
	 SET fechaproceso = now() 
	 WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
	 RAISE NOTICE 'Listo con (%) ',concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
 END IF; --unvalor.procesar
					
 fetch cvalores into unvalor;
 END LOOP;
 CLOSE cvalores;
				
    RAISE NOTICE 'Llamo a asistencial_nomenclador_verifica';
    --Verifica los datos cargados en asistencial_nomenclador
    PERFORM asistencial_nomenclador_verifica();
    RAISE NOTICE 'TERMINO asistencial_nomenclador_verifica';
						
    RAISE NOTICE 'Llamo a asistencial_nomenclador_configura';
    --configura los datos datos cargados en asistencial_nomenclador
    PERFORM asistencial_nomenclador_configura();
    RAISE NOTICE 'TERMINO asistencial_nomenclador_configura';
    RAISE NOTICE 'Llamo a asistencial_practicaplan_configura';
    PERFORM asistencial_practicaplan_configura();
    RAISE NOTICE 'TERMINO asistencial_practicaplan_configura';
    return 'Listo';
END;
$function$
