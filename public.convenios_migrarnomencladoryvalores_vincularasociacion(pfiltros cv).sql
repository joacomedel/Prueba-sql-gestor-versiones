CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_vincularasociacion(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalores refcursor;
       unvalor record;
        rfiltros RECORD;
		vparam VARCHAR;
        vusuario INTEGER;
		
		
BEGIN 

     vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
     OPEN cvalores FOR SELECT DISTINCT asociaciones_siges,dequemanera
	   	       FROM (
				SELECT DISTINCT m.asociaciones_siges,'contablamapeohonorario' as dequemanera		                
                                FROM nomenclador_mapea_asociacion_para_migrar as m
			        JOIN nomenclador_para_migrar as n USING(idnomencladorparamigrar)
				WHERE tipounidadh1 <> ''  AND nullvalue(nmafechaproceso)
				
                                UNION 
				
                        	SELECT DISTINCT m.asociaciones_siges,'contablamapeogasto' as dequemanera 		                        
                                FROM nomenclador_mapea_asociacion_para_migrar as m
			        JOIN nomenclador_para_migrar as n ON (n.idnomencladorparamigrar = m.idnomencladorparamigrargasto)
				WHERE tipounidadh1 <> '' 
                                      AND not nullvalue(idnomencladorgasto) 
                                      AND nullvalue(nmafechaprocesogasto)
                                      
                                UNION 
				
                                SELECT DISTINCT CASE WHEN nullvalue(n.asociaciones_siges) THEN asociaciones_sigesgastos ELSE asociaciones_siges END ,'sintablamapeo' as dequemanera		                        
				FROM nomenclador_para_migrar as n 
				WHERE (tipounidadh1 <> '' OR tipounidaday1 <> '' OR tipounidadgs <> '') 
				       AND nullvalue(npmfechacargavalorunidad)
				       AND (not nullvalue(asociaciones_siges)
                                             OR not nullvalue(asociaciones_sigesgastos))

 	
	       ) asoc_con_unidad

               WHERE true
                      --dequemanera = 'contablamapeohonorario'
               ORDER BY asociaciones_siges
					
		--LIMIT 1
	    ;
	   FETCH cvalores INTO unvalor ;
	   WHILE  found LOOP 
		    
			vparam = concat('{asociaciones_siges=',unvalor.asociaciones_siges,', dequemanera=',unvalor.dequemanera,' }');
			RAISE NOTICE 'Voy a Cargar en Anexo de Valores para (%) ',vparam;
		 	PERFORM convenios_migrarnomencladoryvalores_vincularasociacion_anexo(vparam);
			RAISE NOTICE 'Voy a configurar las practicas para para (%) ',unvalor.asociaciones_siges;
			PERFORM convenios_migrarnomencladoryvalores_vincularasociacion_configpr(vparam);
		fetch cvalores into unvalor; --Para cada grupo de asociaciones
		END LOOP;
		CLOSE cvalores;
			   
     return 'Listo';
END;
$function$
