CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_valoresunida(pfiltros character varying)
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
							SELECT asociaciones_siges,fechainiciovigencia,count(*)
							--,(case when split_part(trim(replace(replace(replace(valorunidad,'$',''),'.',''),',','.')),' ',2) <> '' THEN split_part(trim(replace(replace(replace(valorunidad,'$',''),'.',''),',','.')),' ',2) ELSE trim(replace(replace(replace(valorunidad,'$',''),'.',''),',','.')) END)::float as valordeunidad
							FROM nomenclador_tipounidad_para_migrar as m
							WHERE nullvalue(ntupmfechaproceso)
							GROUP BY asociaciones_siges,fechainiciovigencia
							) asoc_con_unidad
							WHERE fechainiciovigencia = rfiltros.fechainiciovigencia 
--AND array_length(string_to_array(asociaciones_siges, '@'), 1) = 1
							ORDER BY array_length(string_to_array(asociaciones_siges, '@'), 1) DESC,fechainiciovigencia 
							;
	   FETCH cvalores INTO unvalor ;
		WHILE  found LOOP 
                  --MaLaPi 26-10-2022 Le agrego el simbolo ^ a las asociaciones para que el sys_dar_filtros me lo tome siempre como varchar
		    vparam = concat('{asociaciones_siges=^',unvalor.asociaciones_siges,' ,fechainiciovigencia=',unvalor.fechainiciovigencia,'}');
			RAISE NOTICE 'Voy a Cargar en Anexo de Valores para (%) ',vparam;
		 	PERFORM convenios_migrarnomencladoryvalores_valoresunida_anexo(vparam);
			--RAISE NOTICE 'Voy a configurar las practicas para para (%) ',unvalor.asociaciones_siges;
			--PERFORM convenios_migrarnomencladoryvalores_vincularasociacion_configpr(concat('{asociaciones_siges=',unvalor.asociaciones_siges,'}'));
		fetch cvalores into unvalor; --Para cada grupo de asociaciones
		END LOOP;
		CLOSE cvalores;

        -- Malapi 19-07-2023 luego que se actualizan todas tablas de valores, hay que generar el nuevo historico de las configuraciones para recalcular el valor
RAISE NOTICE 'Voy a configurar las practicas en practocnva (%) ',now();
PERFORM amtablavaloresv2_practconvval(concat('{ fechainiciovigencia=',rfiltros.fechainiciovigencia,' }')); 
			   
     return 'Listo';
END;
$function$
