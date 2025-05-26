CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_nuevaspracticas_planes(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
      -- cvalores refcursor;
      -- unvalor record;
        rfiltros RECORD;
		--rverifica RECORD;
        --vfiltroid varchar;
		vusuario INTEGER;
		vidplancobertura VARCHAR;
		vporcentaje INTEGER;
BEGIN 
-- SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion = cargarnuevaspracticas}');
-- SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion = configurarplanes}');
-- MaLaPi Por defecto se carga en el plan de cobertura 1 - General y 29 - Reciprocidad con Coseguro y 12 - Reciprocidad .
-- MaLaPi 04/04/2023 Ahora tambien esta en los por defecto el plan 23-Reciprocidad.
--Configuro las practicas
	 vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	 
	 --Marco como procesado todo loq que esta cargado por las dudas
	 UPDATE asistencial_practicaplan SET apcprocesado = now() WHERE nullvalue(apcprocesado); 
	 
	 
     IF rfiltros.accion = 'cargarnuevaspracticas' OR rfiltros.accion = 'modificarpracticaexistente'
	 	OR rfiltros.accion = 'configurarplanes' THEN 
		RAISE NOTICE 'Entro a configurar con (%)',rfiltros.accion;
	 	vidplancobertura = 1; -- Plan General
		vporcentaje = 70;
	 INSERT INTO asistencial_practicaplan (idplancobertura,idplancoberturas,idnomenclador,idcapitulo, idsubcapitulo,idpractica
															  ,cobertura,ppcperiodo, ppcprioridad, serepite, ppcperiodoinicial, ppcperiodofinal
															  , pptexto, ppccantpracticanoauditada, ppccantpracticaauditada )
						(
	 	SELECT vidplancobertura as idplancobertura, vidplancobertura::integer as idplancoberturas, idnomenclador,idcapitulo,idsubcapitulo,idpractica
		                    ,vporcentaje as cobertura,'a' as ppcperiodo,1 as ppcprioridad, true as serepite,1 as  ppcperiodoinicial,1 as ppcperiodofinal
							,concat('Por defecto al crear una practica del nomenclador <',idnomencladorparamigrar,'>') as pptexto, 10 as ppccantpracticanoauditada,120 as ppccantpracticaauditada
  							FROM nomenclador_para_migrar 
							WHERE true --nullvalue(fechaproceso) 
							AND (incorpora ilike 'SI' OR modifica ilike 'SI' OR incorpora ilike 'NN' )
                                                        AND activo ilike 'Si' 
							AND (idnomenclador,idcapitulo,idsubcapitulo,idpractica) NOT IN (
								SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica
								FROM practicaplan
								WHERE idplancobertura = vidplancobertura
							)
							);
							
	 vidplancobertura = 29; -- Reciprocidad Con Coseguro
	 vporcentaje = 70;
	 INSERT INTO asistencial_practicaplan (idplancobertura,idplancoberturas,idnomenclador,idcapitulo, idsubcapitulo,idpractica
															  ,cobertura,ppcperiodo, ppcprioridad, serepite, ppcperiodoinicial, ppcperiodofinal
															  , pptexto, ppccantpracticanoauditada, ppccantpracticaauditada )
						(
	 	SELECT vidplancobertura as idplancobertura, vidplancobertura::integer as idplancoberturas, idnomenclador,idcapitulo,idsubcapitulo,idpractica
		                    ,vporcentaje as cobertura,'a' as ppcperiodo,1 as ppcprioridad, true as serepite,1 as  ppcperiodoinicial,1 as ppcperiodofinal
							,concat('Por defecto al crear una practica del nomenclador <',idnomencladorparamigrar,'>') as pptexto, 10 as ppccantpracticanoauditada,120 as ppccantpracticaauditada
  							FROM nomenclador_para_migrar 
							WHERE true --nullvalue(fechaproceso) 
							AND (incorpora ilike 'SI' OR modifica ilike 'SI' OR incorpora ilike 'NN' )
                                                        AND activo ilike 'Si' 
							AND (idnomenclador,idcapitulo,idsubcapitulo,idpractica) NOT IN (
								SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica
								FROM practicaplan
								WHERE idplancobertura = vidplancobertura
							) 
							);	
							
		 vidplancobertura = 12; -- Reciprocidad 
	 		vporcentaje = 100;
	 INSERT INTO asistencial_practicaplan (idplancobertura,idplancoberturas,idnomenclador,idcapitulo, idsubcapitulo,idpractica
															  ,cobertura,ppcperiodo, ppcprioridad, serepite, ppcperiodoinicial, ppcperiodofinal
															  , pptexto, ppccantpracticanoauditada, ppccantpracticaauditada )
						(
	 	SELECT vidplancobertura as idplancobertura, vidplancobertura::integer as idplancoberturas, idnomenclador,idcapitulo,idsubcapitulo,idpractica
		                    ,vporcentaje as cobertura,'a' as ppcperiodo,1 as ppcprioridad, true as serepite,1 as  ppcperiodoinicial,1 as ppcperiodofinal
							,concat('Por defecto al crear una practica del nomenclador <',idnomencladorparamigrar,'>') as pptexto, 10 as ppccantpracticanoauditada,120 as ppccantpracticaauditada
  							FROM nomenclador_para_migrar 
							WHERE true --nullvalue(fechaproceso) 
							AND (incorpora ilike 'SI' OR modifica ilike 'SI' OR incorpora ilike 'NN' )
                                                        AND activo ilike 'Si' 
							AND (idnomenclador,idcapitulo,idsubcapitulo,idpractica) NOT IN (
								SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica
								FROM practicaplan
								WHERE idplancobertura = vidplancobertura
							)
							);		
							
         vidplancobertura = 23; -- Internacion
	 vporcentaje = 100;
	 INSERT INTO asistencial_practicaplan (idplancobertura,idplancoberturas,idnomenclador,idcapitulo, idsubcapitulo,idpractica
															  ,cobertura,ppcperiodo, ppcprioridad, serepite, ppcperiodoinicial, ppcperiodofinal
															  , pptexto, ppccantpracticanoauditada, ppccantpracticaauditada )
						(
	 	SELECT vidplancobertura as idplancobertura, vidplancobertura::integer as idplancoberturas, idnomenclador,idcapitulo,idsubcapitulo,idpractica
		                    ,vporcentaje as cobertura,'a' as ppcperiodo,1 as ppcprioridad, true as serepite,1 as  ppcperiodoinicial,1 as ppcperiodofinal
							,concat('Por defecto al crear una practica del nomenclador <',idnomencladorparamigrar,'>') as pptexto, 10 as ppccantpracticanoauditada,120 as ppccantpracticaauditada
  							FROM nomenclador_para_migrar 
							WHERE true --nullvalue(fechaproceso) 
							AND (incorpora ilike 'SI' OR modifica ilike 'SI' OR incorpora ilike 'NN' )
                                                        AND activo ilike 'Si' 
							AND (idnomenclador,idcapitulo,idsubcapitulo,idpractica) NOT IN (
								SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica
								FROM practicaplan
								WHERE idplancobertura = vidplancobertura
							)
							);		

	RAISE NOTICE 'Llamo a asistencial_practicaplan_configura';
    PERFORM asistencial_practicaplan_configura();
	RAISE NOTICE 'TERMINO asistencial_practicaplan_configura';			
							
							
	  END IF;
     return 'Listo';
END;
$function$
