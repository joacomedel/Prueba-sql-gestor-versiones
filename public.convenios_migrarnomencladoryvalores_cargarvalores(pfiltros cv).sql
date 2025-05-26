CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_cargarvalores(pfiltros character varying)
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
	 
    IF rfiltros.accion = 'cargavalorfijo'  THEN 
	
	 	OPEN cvalores FOR SELECT DISTINCT asociaciones_siges::varchar,array_length(string_to_array(asociaciones_siges, '@'), 1)  as canti_asociacion
FROM 
(                                                        
/*SELECT DISTINCT 
							trim(m.asociaciones_siges) as asociaciones_siges
							FROM nomenclador_mapea_asociacion_para_migrar as m
							JOIN nomenclador_para_migrar as n USING(idnomencladorparamigrar)
							WHERE tipounidadh1 = ''  AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'
							UNION
							SELECT DISTINCT 
							trim(m.asociaciones_siges) as asociaciones_siges	
							FROM nomenclador_mapea_asociacion_para_migrar as m
							JOIN nomenclador_para_migrar as n ON (n.idnomencladorparamigrar = m.idnomencladorparamigrargasto)
							WHERE tipounidadh1 = ''  AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'
                                                        UNION */
                                                        SELECT DISTINCT 
							trim(m.asociaciones_siges) as asociaciones_siges	
							FROM nomenclador_para_migrar as m
							WHERE (tipounidadh1 = ''  OR nullvalue(tipounidadh1) AND (tipounidadgs = '' OR nullvalue(tipounidadgs)) )  AND not nullvalue(asociaciones_siges) AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'

) as t
--WHERE  asociaciones_siges = '126 @ 1000 @ 1001 @ 103 @ 108 @ 102 @ 1004 @ 101 @ 135 @ 111 @ 114 @ 146 @ 123 @ 128 @ 132 @ 113 @ 109 @ 121'
ORDER BY canti_asociacion DESC
							
							--LIMIT 4
							;
	   FETCH cvalores INTO unvalor ;
		WHILE  found LOOP 
		    RAISE NOTICE 'Voy a configurar las practicas para para (%) ',unvalor.asociaciones_siges;
			PERFORM convenios_migrarnomencladoryvalores_cargarvalores_configpr(concat('{asociaciones_siges=^',unvalor.asociaciones_siges,'}'));
		fetch cvalores into unvalor; --Para cada grupo de asociaciones
		END LOOP;
		CLOSE cvalores;
	END IF;
     return 'Listo';
END;
$function$
