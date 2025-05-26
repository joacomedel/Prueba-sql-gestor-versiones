CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_confiltro(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
        
        rfiltros RECORD;
        
        vfiltroid varchar;
        
      
BEGIN 

PERFORM convenios_migrarnomencladoryvalores_arregla('{ accion = desactivar}');
--sys_dar_usuarioactual();

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
     IF rfiltros.accion = 'meaperpracticas'  THEN 
      --MaLaPi 04-10-2022 Por el momento el mapea practicas no hace nada... luego se va a usar para mostrar alertas de re asignacion en el expendio           

     END IF;

     IF rfiltros.accion = 'desactivarpracticas'  THEN 
	    --SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion =desactivar, cuales = 'sinmapear'}');
		--SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion =desactivar, cuales = 'luegomapear'}');
	 	PERFORM convenios_migrarnomencladoryvalores_desactivar(pfiltros);
	  
     END IF;
     IF rfiltros.accion = 'cargarnuevaspracticas'  THEN
	    --SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion =cargarnuevaspracticas}');
	  	PERFORM convenios_migrarnomencladoryvalores_nuevaspracticas(pfiltros);

     END IF;
     
	--MaLaPi 26-07-2024 Comento este if, pues creo esta repetido con el de abajo
	 --IF rfiltros.accion = 'modificarpracticaexistente'  THEN
	    --SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion =modificarpracticas}');
	  	--PERFORM convenios_migrarnomencladoryvalores_nuevaspracticas(pfiltros);
     --END IF;

       IF rfiltros.accion = 'modificarpracticaexistente'  THEN
	    --SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion =modificarpracticas}');
	  	PERFORM convenios_migrarnomencladoryvalores_nuevaspracticas(pfiltros);
      END IF;


      IF rfiltros.accion = 'altamodificaasociacion'  THEN
	    --SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion =altamodificaasociacion}');
	      PERFORM convenios_migrarnomencladoryvalores_cargaasociacion(pfiltros);
     END IF;
	 
     IF rfiltros.accion = 'configurarplanes'  THEN
	    --SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion =altamodificaasociacion}');
	      PERFORM convenios_migrarnomencladoryvalores_nuevaspracticas_planes(pfiltros);
     END IF;

     IF rfiltros.accion = 'vincularconasociacion_conunidad'   THEN 
	  --SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion=vincularconasociacion_conunidad}');
      PERFORM convenios_migrarnomencladoryvalores_vincularasociacion(pfiltros);
     END IF;
	 
	 IF rfiltros.accion = 'cargavalorfijo'   THEN 
       PERFORM convenios_migrarnomencladoryvalores_cargarvalores('{ accion=cargavalorfijo}');
     END IF;
	
     IF rfiltros.accion = 'cargavalorunidad'   THEN 
       PERFORM convenios_migrarnomencladoryvalores_valoresunida(pfiltros);
     END IF;

      IF rfiltros.accion = 'actualizavalorfijo'   THEN 
        RAISE NOTICE 'Llamo a convenios_migrarnomencladoryvalores_valoresfijo'; 
       PERFORM convenios_migrarnomencladoryvalores_valoresfijo(pfiltros);
     END IF;

    IF rfiltros.accion = 'calcularvalorespractica'   THEN 
       PERFORM calcularvalorespractica_masivo_completo(concat('{ fechadesde=',current_date,' }'));
     END IF;

  IF rfiltros.accion = 'actualizarasoccoseguros'  THEN 
          RAISE NOTICE 'Voy a configurar las practicas en Coseguros';
          PERFORM sys_asistencial_ampractconvval_coseguro('');
          RAISE NOTICE 'Voy a calcular los valores';
          PERFORM calcularvalorespractica_masivo_completo(concat('{ fechadesde=',current_date,' }'));
          RAISE NOTICE 'Termine de Calcularlos... Coseguros esta lista';
  END IF;

  IF rfiltros.accion = 'generarPlantilla' THEN
     PERFORM convenios_migrarnomencladoryvalores_generaplanilla(pfiltros);
     --select * from temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal
     RAISE NOTICE 'Hacer el select de la tabla (%)','temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal';
  END IF;

   IF rfiltros.accion = 'arreglaasocvinculada' THEN
      --SELECT convenios_migrarnomencladoryvalores_asoc_desv('{tabla=nomenclador_valorfijo_para_migrar,hoja=KINESIO,fechainiciovigencia=2023-03-01}');
     --Filtros debe tener '{tabla=nomenclador_valorfijo_para_migrar,hoja=KINESIO,fechainiciovigencia=2023-03-01}'
     --Si la tabla es nomenclador_valorfijo_para_migrar se debe enviar la hoja a verificar
     --'{tabla=nomenclador_para_migrar,idnomenclador=12,idcapitulo=34,idsubcapitulo=**,idpractica=**,hoja=lala,fechainiciovigencia=2023-03-01}'
     --Si la tabla es nomenclador_para_migrar se debe enviar el nomenclador y capitulo
     --PERFORM convenios_migrarnomencladoryvalores_asoc_desv(pfiltros);
     --Si la tabla es nomenclador_tipounidad_para_migrar se debe enviar el nomenclador y capitulo
     --'{tabla=nomenclador_tipounidad_para_migrar,idnomenclador=07,idcapitulo=66,idsubcapitulo=**,idpractica=**,hoja=lala,fechainiciovigencia=2023-04-01}'
     PERFORM convenios_migrarnomencladoryvalores_asoc_desv(pfiltros);
     --select * from temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal
     RAISE NOTICE 'Hacer el select de la tabla (%)','temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal';
  END IF;
--
	
     --IF rfiltros.accion = 'vincularconplanescobertura'  THEN 
        

     -- END IF;

     
     return 'Listo';
END;
$function$
