CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_valoresfijo(pfiltros character varying)
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
   
	 	OPEN cvalores FOR SELECT DISTINCT asociaciones_siges,fechainiciovigencia,array_length(string_to_array(asociaciones_siges, '@'), 1)  as canti_asociacion
						FROM (
							SELECT trim(asociaciones_siges) as asociaciones_siges ,fechainiciovigencia,count(*)
							--,(case when split_part(trim(replace(replace(replace(valorunidad,'$',''),'.',''),',','.')),' ',2) <> '' THEN split_part(trim(replace(replace(replace(valorunidad,'$',''),'.',''),',','.')),' ',2) ELSE trim(replace(replace(replace(valorunidad,'$',''),'.',''),',','.')) END)::float as valordeunidad
							FROM nomenclador_valorfijo_para_migrar as m
							WHERE nullvalue(nvfpmfechaproceso) AND nullvalue(nvfpmerrordecarga)
							GROUP BY asociaciones_siges,fechainiciovigencia
							) asoc_con_unidad
							WHERE fechainiciovigencia = rfiltros.fechainiciovigencia AND trim(asociaciones_siges) <> ''
--AND array_length(string_to_array(asociaciones_siges, '@'), 1) > 1
							ORDER BY array_length(string_to_array(asociaciones_siges, '@'), 1) DESC,fechainiciovigencia ASC
							LIMIT 5
;
	   FETCH cvalores INTO unvalor ;
		WHILE  found LOOP 
                     --MaLaPi 26-10-2022 Le agrego el simbolo ^ a las asociaciones para que el sys_dar_filtros me lo tome siempre como varchar
		    vparam = concat('{asociaciones_siges=^',unvalor.asociaciones_siges,' ,fechainiciovigencia=',unvalor.fechainiciovigencia,'}');
			RAISE NOTICE 'Voy a los Valores para (%) ',vparam;
		 	PERFORM convenios_migrarnomencladoryvalores_valoresfijo_configpr(vparam);
		fetch cvalores into unvalor; --Para cada grupo de asociaciones
		END LOOP;
		CLOSE cvalores;
			   
     return 'Listo';
END;
$function$
