CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_desactivar(pfiltros character varying)
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
-- SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion = desactivarpracticas}');
     vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
     IF rfiltros.accion = 'desactivarpracticas'  THEN 
	 	OPEN cvalores FOR SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,codigocorto
		                     ,pdescripcion,activo
                                                         --,hon,ayud_1,ayud_2,gastos
                                                         --,tipounidad,valordeunidad,modifica
							 ,incorpora,mapea,idnomencladorparamigrar,fechaproceso
                                                          --,errordecarga,errordedecargaacumulado
							 ,true as procesar
  							FROM nomenclador_para_migrar 
							WHERE nullvalue(fechaproceso) 
								AND nullvalue(errordecarga) 
								AND trim(activo) ilike 'NO' 
								--MaLaPi ya no se tiene en cuenta, pues solo se usa si la practica fue consumida, para saber a donde redirigir el consumo
								--AND CASE WHEN rfiltros.cuales = 'sinmapear' THEN mapea = '' 
								--         WHEN rfiltros.cuales = 'luegomapear' THEN mapea <> '' 
								--		 ELSE FALSE END
								;
				FETCH cvalores INTO unvalor ;
				WHILE  found LOOP 
				    --Verifico que exista la practica actualmente en el nomenclador
					SELECT INTO rverifica * FROM practica WHERE (idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
						IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
					IF FOUND THEN
					    --Verifico que no este desactivada
						IF NOT rverifica.activo THEN
							unvalor.procesar = false;
							UPDATE nomenclador_para_migrar SET fechaproceso = now(),errordecarga = concat(errordecarga,'-','Ya estaba desactivada') WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
						END IF;
					ELSE
					--La practica no exuste en el nomenclador...
					    unvalor.procesar = false;
						UPDATE nomenclador_para_migrar SET fechaproceso = now(),errordecarga = concat(errordecarga,'-','La practica no existe ') WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
					END IF;
					
					--Verifico que la practica no se uso en el ultimo año
					select INTO rverifica count(*) as cantidad  from orden NATURAL JOIN consumo natural join ordvalorizada  natural join itemvalorizada  natural join item 
						where not anulado AND fechaemision >= current_date - 365::integer AND (idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
											IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);

                                         --UPDATE nomenclador_para_migrar SET errordecarga = concat(errordecarga,'-','Se uso en el ultimo año ',rverifica.cantidad) WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;       
					IF rverifica.cantidad > 10 THEN
						UPDATE nomenclador_para_migrar SET errordecarga = concat(errordecarga,'-','Se uso en el ultimo año ',rverifica.cantidad) WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;  
						--MaLapi si tiene marcado el remapeo debo desactivarla igual y luego modificar los consumo
						--IF unvalor.mapea <> '' THEN
						--ELSE
						    --unvalor.procesar = false;
							--UPDATE nomenclador_para_migrar SET errordecarga = concat(errordecarga,'-','Se uso en el ultimo año ',rverifica.cantidad) WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
							--RAISE NOTICE 'Esta no se va a procesar (%) ',concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
						--END IF;
					END IF;
						
					
					IF unvalor.procesar THEN 
						--Desactivo la practica
						UPDATE practica SET activo = false WHERE (idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
															IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
						--La saco de los planes de cobertura
						INSERT INTO practicaplanborradas (idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas, ppccantpractica, ppcperiodo
														  , ppccantperiodos, ppclongperiodo, ppcprioridad, idconfiguracion, serepite, ppcperiodoinicial, ppcperiodofinal, ppbporque
														 ,ppcoberturaamuc, ppcoberturasosunc, idplancoberturaamuctipos)
														  (
						SELECT idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas, ppccantpractica
							, ppcperiodo, ppccantperiodos, ppclongperiodo, ppcprioridad, idconfiguracion
							, serepite, ppcperiodoinicial, ppcperiodofinal,  'Se desactiva la practica' as ppbporque 
							,ppcoberturaamuc, ppcoberturasosunc, idplancoberturaamuctipos
							FROM practicaplan
							WHERE (idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
															IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica) 
						);
						
						DELETE FROM practicaplan WHERE (idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
												 IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica); 
												 
						--La saco practica valores para expendio
						INSERT INTO practicavaloresborrados (idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, importe, internacion, idasocconv, pvidusuario
															 , pvfechainivigencia, pvfechafinvigencia,  pvbidusuario, pvbporque) 
						( SELECT idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, importe, internacion, idasocconv, pvidusuario
															 , pvfechainivigencia, pvfechafinvigencia, vusuario as pvbidusuario, 'Se desactiva la practica' as pvbporque
						 FROM practicavalores
						 WHERE (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica) 
												 IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica) 
						);
						
						DELETE FROM practicavalores WHERE (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica) 
												 IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica); 
						
						--La desactivo como vigente el ultimo valor configurado en practconvval
						UPDATE practconvval SET pcvfechaingreso = now(), pcvsis = now() , tvvigente = false WHERE tvvigente AND (idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
															IN (SELECT unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
						--Marco como procesado los datos
						UPDATE nomenclador_para_migrar SET fechaproceso = now() WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
						RAISE NOTICE 'Listo con (%) ',concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
					END IF;
					
				fetch cvalores into unvalor;
				END LOOP;
				CLOSE cvalores;
     END IF;
     return 'Listo';
END;
$function$
