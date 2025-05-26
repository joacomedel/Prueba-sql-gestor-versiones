CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_info(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
        rfiltros RECORD;
        vfiltroid varchar;
		vtexto varchar;
        
      
BEGIN 
--sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	 
	  IF rfiltros.accion = 'traer_fechas_valores'  THEN 
	  CREATE TEMP TABLE temp_convenios_migrarnomencladoryvalores_info as (
     	
		SELECT text_concatenar(concat('#',fechainiciovigencia,'@',proceso))::text as fechas
			FROM (
		select DISTINCT fechainiciovigencia, 'valorfijo' as proceso from nomenclador_valorfijo_para_migrar WHERE nullvalue(nvfpmfechaproceso) AND trim(asociaciones_siges) <> ''
		UNION
		select DISTINCT fechainiciovigencia, 'unidad' as proceso from nomenclador_tipounidad_para_migrar where nullvalue(ntupmfechaproceso) AND trim(asociaciones_siges) <> ''
		) as t 
    	
		  );
     END IF;
	 
     IF rfiltros.accion = 'meaperpracticas'  THEN 
     
     END IF;

     IF rfiltros.accion = 'desactivarpracticas'  THEN 
	  	--PERFORM convenios_migrarnomencladoryvalores_desactivar(pfiltros);
	  
     END IF;
     IF rfiltros.accion = 'cargarnuevaspracticas'  THEN
	    
	  	--PERFORM convenios_migrarnomencladoryvalores_nuevaspracticas(pfiltros);

     END IF;
     
	 IF rfiltros.accion = 'modificarpracticaexistente'  THEN
	   
	  --	PERFORM convenios_migrarnomencladoryvalores_nuevaspracticas(pfiltros);
     END IF;

       IF rfiltros.accion = 'modificarpracticaexistente'  THEN
	    
	  	--PERFORM convenios_migrarnomencladoryvalores_nuevaspracticas(pfiltros);
      END IF;

      IF rfiltros.accion = 'altamodificaasociacion'  THEN
	    
	    --  PERFORM convenios_migrarnomencladoryvalores_cargaasociacion(pfiltros);
     END IF;
	 
     IF rfiltros.accion = 'configurarplanes'  THEN
	    
	     -- PERFORM convenios_migrarnomencladoryvalores_nuevaspracticas_planes(pfiltros);
     END IF;

     IF rfiltros.accion = 'vincularconasociacion_conunidad'   THEN 
	 
      --PERFORM convenios_migrarnomencladoryvalores_vincularasociacion(pfiltros);
     END IF;
	 
	 IF rfiltros.accion = 'cargavalorfijo'   THEN 
      -- PERFORM convenios_migrarnomencladoryvalores_cargarvalores('{ accion=cargavalorfijo}');
     END IF;
	
     IF rfiltros.accion = 'cargavalorunidad'   THEN 
      -- PERFORM convenios_migrarnomencladoryvalores_valoresunida(pfiltros);
     END IF;

      IF rfiltros.accion = 'actualizavalorfijo' AND rfiltros.quecosa = 'resultado'   THEN 
       --PERFORM convenios_migrarnomencladoryvalores_valoresfijo(pfiltros);
     END IF;
	 
	  IF rfiltros.accion = 'actualizavalorfijo' AND rfiltros.quecosa = 'ayuda'   THEN 
       --PERFORM convenios_migrarnomencladoryvalores_valoresfijo(pfiltros);
     END IF;

    IF rfiltros.accion = 'calcularvalorespractica'   THEN 
       --PERFORM calcularvalorespractica_masivo_completo(concat('{ fechadesde=',current_date,' }'));
     END IF;

  IF rfiltros.accion = 'actualizarasoccoseguros'  THEN 
         -- RAISE NOTICE 'Voy a configurar las practicas en Coseguros';
         -- PERFORM sys_asistencial_ampractconvval_coseguro('');
         -- RAISE NOTICE 'Voy a calcular los valores';
         -- PERFORM calcularvalorespractica_masivo_completo(concat('{ fechadesde=',current_date,' }'));
         -- RAISE NOTICE 'Termine de Calcularlos... Coseguros esta lista';
  END IF;
	
     --IF rfiltros.accion = 'vincularconplanescobertura'  THEN 
        

     -- END IF;

     
     return 'Listo';
END;
$function$
