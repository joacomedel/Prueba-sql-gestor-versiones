CREATE OR REPLACE FUNCTION public.generarimporteaportes_masivo(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD       
	runac RECORD;
	runaci RECORD;
	ridiva RECORD;
	rfiltros RECORD;
	rdatosbase RECORD;

--CURSOR 
	c_adherente REFCURSOR;


--VARIABLES
	vbrutoaumento DOUBLE PRECISION;
	vbrutoaportar DOUBLE PRECISION;
	vbrutoimporte DOUBLE PRECISION;
	vusuario INTEGER; 
	vimporteiva DOUBLE PRECISION;
	vimportetotal DOUBLE PRECISION;

	vincremento  DOUBLE PRECISION;
	nuevo_bruto_incremento DOUBLE PRECISION;

	v_imp_titular  DOUBLE PRECISION;
	v_porc_incremento_titu DOUBLE PRECISION;  -- lo usamos para titular

	v_imp_conyuge DOUBLE PRECISION;
	v_porc_incremento_conyuge DOUBLE PRECISION;  -- vas 030123

	v_imp_hijos DOUBLE PRECISION;
	v_porc_incremento_hijo DOUBLE PRECISION; -- vas 030123
 

	v_aciimporte_siniva_nuevo  DOUBLE PRECISION;  
	v_aciimporte_con_iva_nuevo DOUBLE PRECISION;
	v_aciimporte_total_nuevo DOUBLE PRECISION;


	vimp_minimo DOUBLE PRECISION;   -- VAS se incorpora un monto minimo al calculo

	r_adherente record; 
	v_aciimportesinivanuevo numeric;
	vtodook varchar;
	encabezadlo_xls varchar;
BEGIN

vtodook = 'TodoOK';




EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF rfiltros.accion = 'simulaincremento' THEN 
        --- Inicializo los parametros seteados en la interfaz
		vincremento = 1 + (rfiltros.incremento / 100);
		vimp_minimo = rfiltros.imp_minimo;  -- Este es el valor al dia de hoy ** poner en la interfaz
		v_porc_incremento_titu = rfiltros.porc_incremento_titu; 
		v_porc_incremento_conyuge = rfiltros.porc_incremento_conyuge; 
		v_porc_incremento_hijo = rfiltros.porc_incremento_hijo; 
		
 		RAISE NOTICE 'vincremento (%)   ',vincremento;

 		-- BelenA agrego para que se vayan actualizando los valores si se tocaron los base:
 		SELECT INTO rdatosbase * 
 		FROM datosbaseincrementomasivo 
 		WHERE dbimincrementoporc = rfiltros.incremento 
 			AND dbimmontominimo = rfiltros.imp_minimo
 			AND dbimtituporc = rfiltros.porc_incremento_titu
 			AND dbimconyporc = rfiltros.porc_incremento_conyuge
 			AND dbimbenefporc =  rfiltros.porc_incremento_hijo
 			AND nullvalue(dbimfechafin);

 		IF NOT FOUND THEN
 			UPDATE datosbaseincrementomasivo set dbimfechafin = now() WHERE nullvalue(dbimfechafin);

 			INSERT INTO datosbaseincrementomasivo(dbimincrementoporc, dbimmontominimo, dbimtituporc, dbimconyporc, dbimbenefporc) 
 			VALUES (rfiltros.incremento, rfiltros.imp_minimo, rfiltros.porc_incremento_titu, rfiltros.porc_incremento_conyuge, rfiltros.porc_incremento_hijo);
 		END IF;

		
		 IF iftableexists_fisica('temp_aporteconfiguracion_masivo') THEN
   				DROP TABLE temp_aporteconfiguracion_masivo;
		 END IF;
      --encabezadlo_xls = '1-nrodoc#nrodoc@2-apellido#apellido@3-nombres#nombres@4-barra#barra@5-incremento#incremento@6-aciporcentaje#aciporcentaje@7-nrodoc_conyuge#nrodoc_conyuge@8-cant_conyuge#cant_conyuge@9-cant_benef#cant_benef@10-aciimportebrutohoy#aciimportebrutohoy@11-aciimportebrutonuevo#aciimportebrutonuevo@12-aciimportesinivahoy#aciimportesinivahoy@13-aciimporteivahoy#aciimporteivahoy@14-aciimportetotalhoy#aciimportetotalhoy@15-aciimportesinivanuevo#aciimportesinivanuevo@16-aciimporteivanuevo#aciimporteivanuevo@17-aciimportetotalnuevo#aciimportetotalnuevo@18-aciaumentomasivo#aciaumentomasivo@19-idaporteconfiguracionmasivo#idaporteconfiguracionmasivo@20-tacmmodificado#tacmmodificado@21-acifechainicio#acifechainicio';
		encabezadlo_xls = '1-nrodoc#nrodoc@2-apellido#apellido@3-nombres#nombres@4-barra#barra@5-nrodoc_conyuge#nrodoc_conyuge@6-cant_conyuge#cant_conyuge@7-cant_benef#cant_benef@8-incremento#incremento@9-aciporcentaje#aciporcentaje@10-aciimportebrutohoy#aciimportebrutohoy@11-aciimportesinivahoy#aciimportesinivahoy@12-aciimporteivahoy#aciimporteivahoy@13-aciimportetotalhoy#aciimportetotalhoy@14-aciimportebrutonuevo#aciimportebrutonuevo@15-aciimportesinivanuevo#aciimportesinivanuevo@16-aciimporteivanuevo#aciimporteivanuevo@17-aciimportetotalnuevo#aciimportetotalnuevo@18-aciaumentomasivo#aciaumentomasivo@19-idaporteconfiguracionmasivo#idaporteconfiguracionmasivo@20-tacmmodificado#tacmmodificado@21-acifechainicio#acifechainicio';
		CREATE TABLE temp_aporteconfiguracion_masivo (
 				idaporteconfiguracionmasivo serial PRIMARY KEY,
				tacmmodificado timestamp,
				aciaumentomasivo boolean,
				nombres varchar,
				apellido varchar,
				nrodoc varchar,
				barra integer,
				aciimportesinivahoy float,
				aciimporteivahoy float,
				aciimportetotalhoy float,
				aciporcentaje float,
			        nrodoc_conyuge varchar, --- se agrega 0923 por nuevo requerimiento en el calculo de importe jub
			        cant_conyuge integer, -- se agrega 0124   
			        cant_benef integer,  -- se agrega 0124  
				aciimportebrutohoy float,
				acifechainicio timestamp,
				aciimportebrutonuevo float,
				aciimportesinivanuevo float,
				aciimporteivanuevo float,
				aciimportetotalnuevo float,
				incremento float,
				usugenero integer DEFAULT sys_dar_usuarioactual(),
				usuingreso integer,
			   mapeocampocolumna varchar
		);

		--- 1 recuperar a los adherentes para calcular el valor de su cuota	
		OPEN c_adherente FOR SELECT *
		                      FROM aporteconfiguracion 
				      NATURAL JOIN  persona
				      NATURAL JOIN  aporteconfiguracionimportes 
				      LEFT JOIN ( SELECT nrodoctitu, tipodoctitu, text_concatenar(concat(conyug.nrodoc,'  ')) as  nrodoc_conyuge ,  count(*)   as cant_conyug
					          FROM benefsosunc 
					          JOIN persona as conyug USING (nrodoc,tipodoc)
					          JOIN persona as titu ON ( nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc )	
						  WHERE conyug.barra = 1 
						         --- ANTES SE FIJABA QUE ESTE ACTIVO AND fechafinos >=NOW()
						         AND conyug.fechafinos = titu.fechafinos
						  GROUP BY  nrodoctitu, tipodoctitu --- por si hay algun 35 con mas de un conyuge
				      ) AS el_conyuge ON (nrodoctitu=nrodoc AND tipodoctitu = tipodoc) 	 	
				      LEFT JOIN ( SELECT nrodoctitu, tipodoctitu, count(*)   as cant_benef
					          FROM benefsosunc 
					          JOIN persona as hijo USING (nrodoc,tipodoc)
						  JOIN persona as titu ON ( nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc )	
					          WHERE hijo.barra <> 1 
						        AND hijo.fechafinos = titu.fechafinos
						  GROUP BY  nrodoctitu, tipodoctitu --- 
				     ) AS los_benef ON (los_benef.nrodoctitu=nrodoc AND los_benef.tipodoctitu = tipodoc) 	
				     WHERE nullvalue(acfechafin) and nullvalue(acifechafin)  and fechafinos >=current_date - 180::integer
						    ---   AND nrodoc = '10951507'
					            -- AND nrodoc = '05757450' solo titu
						    -- AND nrodoc = '13090854'  -- con conyuge y benef
				     ORDER BY apellido,nombres,nrodoc,barra;
			
   		FETCH c_adherente INTO r_adherente;
   		WHILE FOUND LOOP	
				-- 2 calculo cada uno de los valores
			/*	now() as tacmmodificado
				,r_adherente.aciaumentomasivo,r_adherente.nombres,r_adherente.apellido,r_adherente.nrodoc,r_adherente.barra 
			   ,round(r_adherente.aciimportesiniva::numeric,2) as aciimportesinivahoy
			   ,round(r_adherente.aciimporteiva::numeric,2) as aciimporteivahoy
			   ,round((r_adherente.aciimportesiniva + r_adherente.aciimporteiva )::numeric,2) as aciimportetotalhoy
			   ,case when nullvalue(aciporcentaje) then round((round(aciimportesiniva::numeric,2)/ round(aciimportebruto::numeric,2) * 100)::numeric,0) 
			         ELSE round(aciporcentaje::numeric,2) end  as aciporcentaje
			   ,CASE WHEN nullvalue(nrodoc_conyuge) THEN '' 
			         ELSE nrodoc_conyuge END 
			   ,round(aciimportebruto::numeric,2) as aciimportebrutohoy
			   ,acifechainicio
			 
			   ,round((aciimportebruto*vincremento)::numeric,2) as aciimportebrutonuevo
			   --- aciimportesinivanuevo se debe calcular como el % incremento  y si es menor al minimo llevar al minimo 
			   ,round(aciimportesiniva::numeric,2) as aciimportesinivanuevo
			   
			
			   ,round(aciimporteiva::numeric,2) as aciimporteivanuevo
			   ,round((aciimportesiniva+aciimporteiva)::numeric,2) as aciimportetotalnuevo
			   ,vincremento as incremento
			   */
			    -- % de descuentos:     v_incremento_titu   V_incremento_conyuge v_incremento_hijo
				
				-- calculo el monto del titular = aciimportebruto*v_incremento_titu  SI es mayor al vimp_minimo. CASO CONTRARIO el valor es vimp_minimo.
			--	v_porc_incremento_titu = 0.04; --- ** poner en la interfaz
				nuevo_bruto_incremento = round((r_adherente.aciimportebruto*vincremento)::numeric,2) ;
				v_imp_titular = CASE WHEN (round((nuevo_bruto_incremento * v_porc_incremento_titu)::numeric,2) > vimp_minimo ) 
				                          THEN round((nuevo_bruto_incremento * v_porc_incremento_titu)::numeric,2)
				                ELSE vimp_minimo END ;
				
				-- calculo el monto del conyuge = aciimportebruto*V_incremento_conyuge  SI es mayor al vimp_minimo. CASO CONTRARIO el valor es vimp_minimo.
			
			---	v_porc_incremento_conyuge = 0.02; --- ** poner en la interfaz
				v_imp_conyuge = 0;
				
				IF (NOT nullvalue(r_adherente.cant_conyug ) AND r_adherente.cant_conyug >0 ) THEN
						  v_imp_conyuge = CASE WHEN (round((nuevo_bruto_incremento * v_porc_incremento_conyuge)::numeric,2) > vimp_minimo ) 
				                    	      THEN round((nuevo_bruto_incremento * v_porc_incremento_conyuge)::numeric,2)
				          			      ELSE vimp_minimo END ;
				END IF;
				 
				-- calculo el monto del hijo = aciimportebruto*V_incremento_conyuge  SI es mayor al vimp_minimo. CASO CONTRARIO el valor es vimp_minimo.
				 
			--	v_porc_incremento_hijo = 0.02; ---** poner en la interfaz
				v_imp_hijos = 0;
				IF (NOT nullvalue(r_adherente.cant_benef ) AND r_adherente.cant_benef >0 ) THEN
						v_imp_hijos = r_adherente.cant_benef *  round((nuevo_bruto_incremento * v_porc_incremento_hijo)::numeric,2);  
				END IF;
				-- el importe total se calcula como la suma de los importes calculados  
				v_aciimporte_siniva_nuevo  = v_imp_titular + v_imp_conyuge + v_imp_hijos;
			/*
				RAISE NOTICE 'nrodoc (%) nurvo bruto incremento  (%) ', r_adherente.nrodoc, nuevo_bruto_incremento ;
				RAISE NOTICE 'nrodoc (%) v_imp_titular  (%) ', r_adherente.nrodoc, v_imp_titular ;
				RAISE NOTICE 'nrodoc (%)  cant cony (%) v_imp_conyuge  (%) ', r_adherente.nrodoc ,r_adherente.cant_conyug, v_imp_conyuge ;
				RAISE NOTICE 'nrodoc (%) cant hijo (%)  v_imp_hijos  (%) ', r_adherente.nrodoc ,r_adherente.cant_benef  ,v_imp_hijos ;
				RAISE NOTICE 'nrodoc (%) v_aciimporte_siniva_nuevo  (%) ', r_adherente.nrodoc ,v_aciimporte_siniva_nuevo ;
			*/
				v_aciimporte_con_iva_nuevo  = round(( (v_aciimporte_siniva_nuevo  * 10.5) / 100)::numeric,2);
				v_aciimporte_total_nuevo = v_aciimporte_siniva_nuevo + v_aciimporte_con_iva_nuevo;
				
				-- 3  inserto la info
				INSERT INTO  temp_aporteconfiguracion_masivo (tacmmodificado,aciaumentomasivo,nombres,apellido,nrodoc,barra
															  ,aciimportesinivahoy
															  ,aciimporteivahoy
															  ,aciimportetotalhoy
															  ,aciporcentaje
															  ,nrodoc_conyuge
															  ,cant_conyuge
															  ,cant_benef
															  ,aciimportebrutohoy
															  ,acifechainicio
															  ,aciimportebrutonuevo
															  ,aciimportesinivanuevo
															  ,aciimporteivanuevo
															  ,aciimportetotalnuevo
															  ,incremento
															  , mapeocampocolumna) VALUES
				 (	 now(),r_adherente.aciaumentomasivo,r_adherente.nombres,r_adherente.apellido,r_adherente.nrodoc,r_adherente.barra
				 	,round(r_adherente.aciimportesiniva::numeric,2)
				    ,round(r_adherente.aciimporteiva::numeric,2)
				 	,round((r_adherente.aciimportesiniva + r_adherente.aciimporteiva )::numeric,2)	   
				 	,case WHEN nullvalue(r_adherente.aciporcentaje) then round((round(r_adherente.aciimportesiniva::numeric,2)/ round(r_adherente.aciimportebruto::numeric,2) * 100)::numeric,0) 
			         		ELSE round(r_adherente.aciporcentaje::numeric,2) END
			    	,CASE WHEN nullvalue(r_adherente.nrodoc_conyuge) THEN '' 
			         		ELSE r_adherente.nrodoc_conyuge END 
				    ,CASE WHEN nullvalue(r_adherente.cant_conyug ) THEN 0 ELSE r_adherente.cant_conyug END 
				    ,CASE WHEN nullvalue(r_adherente.cant_benef) THEN 0 ELSE r_adherente.cant_benef END 
				  	,round(r_adherente.aciimportebruto::numeric,2)
			   	  	,r_adherente.acifechainicio
			      	,round((r_adherente.aciimportebruto*vincremento)::numeric,2)
				    --- calculos de los importes sin_iva
				 	,round(v_aciimporte_siniva_nuevo::numeric,2)
				 	,v_aciimporte_con_iva_nuevo
			    	,v_aciimporte_total_nuevo
				  
			      	,vincremento  
				    ,encabezadlo_xls
				);
		    /*   
		        UPDATE temp_aporteconfiguracion_masivo SET aciimportesinivanuevo = round(( (aciimportebrutonuevo * aciporcentaje) / 100)::numeric,2) ;
				UPDATE temp_aporteconfiguracion_masivo SET aciimporteivanuevo= round(( (aciimportesinivanuevo  * 10.5) / 100)::numeric,2) ;
		        UPDATE temp_aporteconfiguracion_masivo SET aciimportetotalnuevo= round((aciimportesinivanuevo  + aciimporteivanuevo)::numeric,2) ;
			*/
				
			
				FETCH c_adherente INTO r_adherente;
		END LOOP;
		
		
END IF;

IF rfiltros.accion = 'procesaincremento' THEN 

		INSERT INTO temporal_jubilados (nombres, nroafiliado, tarea, periodo, importeaporte, iva, total, nrodoc, barra, importebruto, porcentaje, mesaporte, anioaporte, importeconiva,  incrementomasivo) (

		SELECT concat(nombres,' ',apellido) as nombres,concat(nrodoc,'-',barra) as nroafiliado,'corregirimportefacturar' as tarea,to_char(current_timestamp + interval '10' day , 'Mon-YYYY') as periodo,aciimportesinivanuevo as importeaporte,aciimporteivanuevo as iva,aciimportetotalnuevo as total,nrodoc,barra,aciimportebrutonuevo as importebruto,aciporcentaje as porcentaje,to_char(current_timestamp + interval '10' day , 'MM')::integer as mesaporte,to_char(current_timestamp + interval '10' day , 'YYYY')::integer as anioaporte,aciimportetotalnuevo  as importeconiva , CASE WHEN aciaumentomasivo THEN 'true' ELSE 'false' END as incrementomasivo 
		FROM temp_aporteconfiguracion_masivo);

 		SELECT INTO vtodook * FROM generarimporteaportes('');   

END IF;

IF rfiltros.accion = 'ingresararchivoincrementos' THEN 

	       UPDATE temp_aporteconfiguracion_masivo 
               SET tacmmodificado = now(), 
                   aciimportesinivanuevo = t.aciimportesinivanuevo ,
                   aciimporteivanuevo = t.aciimporteivanuevo ,
                   aciimportetotalnuevo = t.aciimportetotalnuevo , 
                   aciporcentaje = t.aciporcentaje ,
                   aciimportebrutonuevo = t.aciimportebrutonuevo, 
                   usuingreso= sys_dar_usuarioactual()
		FROM  temp_aporteconfiguracion_masivo_vuelta as t
		WHERE temp_aporteconfiguracion_masivo.nrodoc = t.nrodoc 
                      AND temp_aporteconfiguracion_masivo.aciimportesinivahoy = t.aciimportesinivahoy 
                      AND temp_aporteconfiguracion_masivo.aciimporteivahoy = t.aciimporteivahoy 
                      AND temp_aporteconfiguracion_masivo.aciimportetotalhoy = t.aciimportetotalhoy
		      AND temp_aporteconfiguracion_masivo.aciimportebrutohoy = t.aciimportebrutohoy 
                      AND temp_aporteconfiguracion_masivo.acifechainicio = t.acifechainicio;

		DELETE FROM temp_aporteconfiguracion_masivo WHERE tacmmodificado <> now();

END IF;

return '';
END;$function$
