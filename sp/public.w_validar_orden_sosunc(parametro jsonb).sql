CREATE OR REPLACE FUNCTION public.w_validar_orden_sosunc(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$-- CAMBIIOS 
-- FECHA CAMBIO 25/04/2023

DECLARE

	-- refcursor
   	carticulo refcursor;
   	ccoberturas refcursor;
   	ccoberturas2 refcursor;

   	carticulo2 RECORD;
   	rcobertura RECORD;
   	elem RECORD;
    consumo RECORD;
    auditoria RECORD;
    registro RECORD;

    articulo RECORD;

    topes RECORD;

    -- GK 2023-01-10  Listado de restricciones- Limites - controles 
    limites RECORD;

    rpersona RECORD;
 
	respuestajson jsonb;
    respuestajson_info jsonb;
   	jsonafiliado jsonb;
	jsonconsumo jsonb;
	vidplancoberturas INTEGER;
	restante integer;

	topeconsumo integer;
	topevalor double precision;

	reintegrocoseguro BOOLEAN;

	cantidadTotal integer;
	alerta boolean;
	
	
BEGIN
	
	cantidadTotal=0;

	SELECT INTO jsonafiliado * FROM w_determinarelegibilidadafiliado(parametro);

	-- GK 2023-01-03 Cambio para que se manden los articulos en la cancelacion 

	--limpio LA TEMPORAL 
	DROP TABLE IF EXISTS tfar_coberturas;

	--IF NOT  iftableexists('tfar_coberturas') THEN
	CREATE TEMP TABLE 
			tfar_coberturas (
				idiva INTEGER,
				lstock INTEGER,
				precio BIGINT,
				idrubro VARCHAR,
				porccob VARCHAR,
				porciva INTEGER,
				troquel BIGINT,
				cantidadsolicitada VARCHAR,
				cantidadaprobada VARCHAR,
				astockmax VARCHAR,
				astockmin VARCHAR,
				monodroga VARCHAR,
				montofijo INTEGER,
				prioridad INTEGER,
				adescuento INTEGER,
				detallecob VARCHAR,
				idafiliado INTEGER,
				idarticulo VARCHAR,
				acomentario VARCHAR,
				idmonodroga INTEGER,
				laboratorio VARCHAR,
				acodigobarra VARCHAR,
				adescripcion VARCHAR,
				idobrasocial INTEGER,
				mnroregistro VARCHAR,
				presentacion VARCHAR,
				rdescripcion VARCHAR,
				idlaboratorio INTEGER,
				pcdescripcion VARCHAR,
				acodigointerno VARCHAR,
				articulodetalle VARCHAR,
				codautorizacion VARCHAR,
				idplancobertura INTEGER,
				idcentroarticulo INTEGER

			);

	-- Proceso articulos 
	OPEN carticulo FOR 
		SELECT * 
		FROM jsonb_to_recordset(parametro->'articulos') as x
			(
				"codbarras" text,
				"mnroregistro" VARCHAR,
				"cantidadsolicitada" int
			);

	IF NOT  iftableexists('tfar_articulo') THEN
						CREATE TEMP TABLE 
						tfar_articulo (			
							mnroregistro VARCHAR,			
							idarticulo BIGINT,			
							idcentroarticulo BIGINT,			
							convale BOOLEAN,			
							idafiliado VARCHAR,			
							acodigobarra VARCHAR,		
							idobrasocial INTEGER,			
							cantvendida INTEGER,			
							picantidadentregada INTEGER,			
							idvalidacion INTEGER,			
							idcentrovalidacion INTEGER,			
							idvalidacionitem INTEGER,
							cantidadsolicitada INTEGER,
							tipodoc INTEGER	
						);
					
				END IF;

	-- Recupero los articulos pasados por el parametro  ( codigo de barras y cantidad solicitada )
	FETCH carticulo INTO elem;
		WHILE  found LOOP
	            	
	            RAISE NOTICE 'elem (%)',elem;

	            -- Caso especial para los casos con condbarra INST 

	            SELECT  * INTO articulo FROM far_articulo WHERE  acodigobarra ilike concat('%',elem.codbarras,'%');

	            IF NOT FOUND THEN

		            SELECT INTO carticulo2 * 
		            FROM 
		              	(
		              		SELECT
								mnroregistro,
								--fm.idarticulo,
								null as idarticulo,
								--fm.idcentroarticulo,
								null as idcentroarticulo,
								parametro->>'NroDocumento'  as idafiliado,
								CASE WHEN tipodoc=null THEN 1 ELSE tipodoc end AS tipodoc,
								--acodigobarra,
								mcodbarra as acodigobarra,
								1 as idobrasocial,
								elem.cantidadsolicitada
								FROM medicamento
							--FROM far_medicamento as fm
							--NATURAL JOIN far_articulo
							LEFT JOIN far_afiliado ON ( nrodoc ilike parametro->>'NroDocumento' AND  idobrasocial=1)
							WHERE true 
								AND (mcodbarra=elem.codbarras OR mtroquel=elem.mnroregistro)  )as articulo;
		        ELSE
		        	SELECT INTO carticulo2 * 
		            FROM 
		              	(
		              		SELECT
								mnroregistro,
								fm.idarticulo,
								fm.idcentroarticulo,
								parametro->>'NroDocumento'  as idafiliado,
								CASE WHEN tipodoc=null THEN 1 ELSE tipodoc end AS tipodoc,
								acodigobarra,
								1 as idobrasocial,
								elem.cantidadsolicitada
				
							FROM far_medicamento as fm
							NATURAL JOIN medicamento
							NATURAL JOIN far_articulo
							LEFT JOIN far_afiliado ON ( nrodoc ilike parametro->>'NroDocumento' AND  idobrasocial=1)
							WHERE true 
								AND (acodigobarra ilike concat('%',elem.codbarras,'%') OR mtroquel=elem.mnroregistro)  )as articulo;

		        END IF;
	              
	            RAISE NOTICE 'Articulo (%)',carticulo2;

	            
	             INSERT INTO tfar_articulo(mnroregistro,idafiliado,tipodoc,acodigobarra, idobrasocial,cantidadsolicitada)	    
				 VALUES(
			  		carticulo2.mnroregistro,
			  		carticulo2.idafiliado ,
			  		carticulo2.tipodoc ,
			  		carticulo2.acodigobarra,
			  		carticulo2.idobrasocial ,
			  		elem.cantidadsolicitada

			  		);
				 cantidadTotal = cantidadTotal +elem.cantidadsolicitada;

			
	   	fetch carticulo into elem;
	 	END LOOP;

	 --------------------------------------------------------------------------------------------------

	-- Controlo si es autorizacion o cancelacion 
	-- 290020 AUTORIZACUON 
	-- 390020 COSEGURO
	-- 20010 CANCELACION 
	IF parametro->>'CodAccion'= '290020' OR parametro->>'CodAccion'= '390020' THEN 
		
		reintegrocoseguro = true;

	 	-- Control consumos mensual busco validaciones efectuadas en el mes en curso y su cantidad aprobada 
	 	-----------------------------------------------------------------------------------------------------  SP Consumos Mes Actual  ------------------------------------------- 
		SELECT sum(cantidadaprobada) as cantitdad INTO consumo 
		FROM 
		(
			SELECT 
				--sum(cantidadaprobada) as cantitdad INTO consumo 
				cantidadaprobada,acodigobarra,registro_coberturas_sosunc.idvalidacion,rcscrednumero
			FROM registro_coberturas_sosunc 
			LEFT JOIN item_registro_coberturas_sosunc USING(idvalidacion)
			WHERE 
			rcscrednumero ilike concat('%',parametro->>'NroDocumento','%')
			AND idvalidacionestadotipo=1
			AND rcsfechaconsumo>= concat(extract(year from  current_date),'-',RIGHT(concat('0',extract(MONTH from  current_date)),2),'-01') AND   rcsfechaconsumo <= CURRENT_DATE+1
			GROUP BY cantidadaprobada,acodigobarra,registro_coberturas_sosunc.idvalidacion,rcscrednumero
		) as agrupador
		;
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- no exiten validaciones en el mes en curso, remplazo null por cero 
		IF nullvalue(consumo.cantitdad) THEN
			consumo.cantitdad=0;
		END IF;
		----------------------------------------------------------------------------------------------------

		--Control auditoria corresponde al afiliado ingresado		
		SELECT 
			fmim.fmimcobertura  as saicobertura, 	-- porcentaje 
			fmim.idplancoberturas,
			saipresentacion,
			idsolicitudauditoria

			INTO auditoria 

		FROM solicitudauditoria
		LEFT JOIN solicitudauditoriaitem USING (idsolicitudauditoria,idcentrosolicitudauditoria)
		LEFT JOIN fichamedicainfomedicamento as fmim USING(idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento)
		LEFT JOIN monodroga as m ON (m.idmonodroga=fmim.idmonodroga)
		WHERE 
			nrodoc ilike concat('%',parametro->>'NroDocumento','%')
			AND idsolicitudauditoria=parametro->>'idsolicitudauditoria';

		

		-- Busco coberturas
		PERFORM far_traerinfocoberturas(concat('consumo=',consumo.cantitdad ,', idsolicitudauditoria=',auditoria.idsolicitudauditoria));

		-- GK 2023-01-10 

			--- Controles 
			-- Cantidad medimentos 
			-- Precio mendicamentos 
			-- Cantidad de Recetas 
			-- Control auditoria existente en caso de que ingresen un numero de auditoria

		
		
		-- si sosunc cobertura principal Obtengo topes 
		IF parametro->>'CodAccion'= '390020'  THEN 
			topevalor = null;

					-- GK 06/01/2023 Control lista negra afiliados 
	        SELECT  INTO rpersona *,cliente.barra as barracli 
	        FROM persona
	        LEFT JOIN excepciones_afiliado as ea ON (persona.nrodoc=ea.nrodoc AND  persona.tipodoc= ea.tipodoc AND idtipoexcepcionesafiliado=1)
	        LEFT JOIN benefsosunc  ON (persona.nrodoc=benefsosunc.nrodoc AND  persona.tipodoc= benefsosunc.tipodoc)
	        LEFT JOIN cliente ON cliente.nrocliente = persona.nrodoc OR cliente.nrocliente = benefsosunc.nrodoctitu
	        WHERE  persona.nrodoc = parametro->>'NroDocumento'
	        --AND tipodoc = rarticulo.tipodoc
	        AND fechafinos >=  current_date /*- 30::integer*/
	        AND ( nullvalue(eafechahasta) OR NOT current_date <= eafechahasta)
	        AND ( nullvalue(eafechadesde) OR NOT eafechadesde <= current_date);

	        IF NOT FOUND THEN
	            reintegrocoseguro = false;
	        END IF;
	        -----------------------------------------------------
		END IF;

		SELECT ftctope::double precision as tope,* INTO limites FROM far_topes_cobertura WHERE nullvalue(ftcfechahasta) AND  	 	idtipotope=2;
		topevalor = limites.tope;

		SELECT ftctope::integer as tope,* INTO limites FROM far_topes_cobertura WHERE nullvalue(ftcfechahasta) AND  	 	idtipotope=1;

		IF nullvalue(limites.tope) THEN
			topeconsumo=1000;
		ELSE 
			topeconsumo = limites.tope;
		END IF;

		-- Valores para saltear los consumos 
		IF(NOT nullvalue(auditoria.idsolicitudauditoria)) THEN 
			consumo.cantitdad=-100;
			topevalor=null;
		END IF;

			-- 1) Llamar SP obtener consumo recetas ( validaciones aprobadas sin cancelar ) mes en curso 
			-- Sp con parametro limite limites.recetas integer 
		-- IF consumo recetas no superado --

		restante =topeconsumo- consumo.cantitdad ;

		IF restante<=0 THEN
			alerta= false;
		ELSE
			alerta= true;
		END IF; 

		RAISE NOTICE 'restante  (%)',restante;
		RAISE NOTICE 'total (%)',cantidadTotal;

			--proceso coberturas 
			OPEN ccoberturas FOR SELECT *  FROM temp_control_coberturas;
			FETCH ccoberturas INTO rcobertura;
				WHILE  found LOOP

				
				
				-- Control cantidad medicamentos 
				-- control cantidad consumo 
				-- hardacorde Tope 10

				-- Si se ingreso un numero de auditoria 

				IF  reintegrocoseguro THEN
                                       RAISE NOTICE 'ENTRO 1';

					IF (NOT (parametro->>'idsolicitudauditoria')='' AND NOT nullvalue(auditoria.idsolicitudauditoria)
) 
							OR 
					
						(parametro->>'idsolicitudauditoria')=''
				
					THEN 
						RAISE NOTICE 'ENTRO 2';
						IF (rcobertura.precio< topevalor OR nullvalue(topevalor) OR rcobertura.codautorizacion<>0  )THEN  -- 020524 OR rcobertura.codautorizacion<>0 tiene cobertura especial
                                                --RAISE NOTICE 'ENTRO 3';
							IF ((restante-cantidadTotal)>=0  OR rcobertura.codautorizacion<>0 ) THEN 
                                                        --RAISE NOTICE 'ENTRO 4';
								IF  (restante>=rcobertura.cantidadvendida OR rcobertura.codautorizacion<>0) THEN
                                                                  --   RAISE NOTICE 'ENTRO 5';
										-- Cobertura total 
										restante=restante - rcobertura.cantidadvendida;
										cantidadTotal=0;
										PERFORM sp_cargartemporal(rcobertura);
										UPDATE tfar_coberturas SET cantidadaprobada= rcobertura.cantidadvendida, acomentario= ' COBERTURA APROBADA' WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;
										
										IF (restante=0) THEN
								            RAISE NOTICE 'nro doc %:',parametro->>'NroDocumento';
								            PERFORM generar_alerta_consumo_sp(concat('nrodoc=',parametro->>'NroDocumento'));
								             alerta=false;
								        END IF;

								ELSE
									/*
									IF restante> 0 THEN 

										-- QUITO COBERTURA PARCIAL -- SE RECHAZA TODO 
										-- COBERTURA PARCIAL 
										
										
										PERFORM sp_cargartemporal(rcobertura);
										UPDATE tfar_coberturas SET cantidadaprobada= restante,acomentario=' COBERTURA PARCIAL ARPOBADA ' 
										WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;
										*
										
				
										-- SIN COBERTURA 		
										--PERFORM sp_cargartemporal(rcobertura);
										--UPDATE tfar_coberturas SET cantidadaprobada= (rcobertura.cantidadvendida- restante) , porccob=0,acomentario=' TOPE MENSUAL MEDICAMENTO SUPERADO' 
										--WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;

										--NUEVO 

										PERFORM sp_cargartemporal(rcobertura);
										UPDATE tfar_coberturas SET cantidadaprobada= rcobertura.cantidadvendida,acomentario=' TOPE MENSUAL MEDICAMENTO SUPERADO PARCIALMENTE',porccob=0
										WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;
										--restante=0;
										-----------------------------

										-----------------------------

									ELSE*/
										-- ARTICULOS SIN COBERTURA 
										PERFORM sp_cargartemporal(rcobertura);
										UPDATE tfar_coberturas SET cantidadaprobada= rcobertura.cantidadvendida , porccob=0,acomentario=' TOPE MENSUAL MEDICAMENTO SUPERADO'
										WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;
										restante=0;

										 -- Disparo Alerta
								        IF (alerta) THEN
								            RAISE NOTICE 'nro doc %:',parametro->>'NroDocumento';
								            PERFORM generar_alerta_consumo_sp(concat('nrodoc=',parametro->>'NroDocumento'));
								             alerta=false;
								        END IF;
									--END IF;
									

								END IF;
							ELSE

								IF restante> 0 THEN 
									PERFORM sp_cargartemporal(rcobertura);
									UPDATE tfar_coberturas SET cantidadaprobada= rcobertura.cantidadvendida,acomentario=' TOPE MENSUAL MEDICAMENTO SUPERADO PARCIALMENTE',porccob=0
									WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;
								ELSE
									-- ARTICULOS SIN COBERTURA 
									PERFORM sp_cargartemporal(rcobertura);
									UPDATE tfar_coberturas SET cantidadaprobada= rcobertura.cantidadvendida , porccob=0,acomentario=' TOPE MENSUAL MEDICAMENTO SUPERADO'
									WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;
						

								END IF;

							END IF;
						ELSE
                                                      IF( nullvalue(auditoria.idsolicitudauditoria) AND rcobertura.codautorizacion =0 )THEN -- NO tiene cobertura especial el afiliado

							-- ARTICULOS SIN COBERTURA 
							PERFORM sp_cargartemporal(rcobertura);
							UPDATE tfar_coberturas SET cantidadaprobada= rcobertura.cantidadvendida , porccob=0, acomentario= 'SUPERA TOPE VALOR MEDICAMENTO REQUIERE AUDITORIA' WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;
                                                       END IF;

						END IF;

					ELSE
						PERFORM sp_cargartemporal(rcobertura);
						UPDATE tfar_coberturas SET cantidadaprobada= rcobertura.cantidadvendida , porccob=0, acomentario= concat('AUDITORIA NRO ',parametro->>'idsolicitudauditoria',' NO ENCONTRADA ') WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;

					END IF;
				ELSE

						PERFORM sp_cargartemporal(rcobertura);
						UPDATE tfar_coberturas SET cantidadaprobada= rcobertura.cantidadvendida , porccob=0, acomentario= (' REINTEGRO AUTOMATICO SUSPENDIDO ') WHERE cantidadaprobada=0 AND  cantidadsolicitada =rcobertura.cantidadvendida AND mnroregistro=rcobertura.mnroregistro;

				END IF;

				fetch ccoberturas into rcobertura;
			 	END LOOP;
			 	close ccoberturas;
		-------------------------------
		--- FIn control control recetas 

	 	-- paso a formato json coberturas
		SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
		FROM (SELECT * FROM tfar_coberturas) as t;
	
	ELSE
		-- CANCELACIÓN 	

		CREATE TEMP TABLE 
				rtasolicitud (estado BOOLEAN);

		-- Busco en registro_coberturas_sosunc si existe la validacion 
		SELECT * INTO registro 
		FROM registro_coberturas_sosunc 
		WHERE 
			idvalidacion=parametro->>'NroReferencia' 
			AND rcsfechareceta=parametro->>'FechaReceta' 
			AND rcscrednumero=parametro->>'NroDocumento'
			AND idvalidacionestadotipo=1
			AND nullvalue(rcsfechafin);
		-- Si exute la validacion y esta esta en estado 1
		IF FOUND THEN
			-- CANCELAR VALIDACION 
			UPDATE registro_coberturas_sosunc SET idvalidacionestadotipo=3, rcsfechafin=now() WHERE idregistocoberturas=registro.idregistocoberturas AND idvalidacion=registro.idvalidacion;

			--CARGO EXITO
			INSERT INTO rtasolicitud  (estado) VALUES (true);
			--- --proceso coberturas 
			OPEN ccoberturas FOR SELECT *  FROM tfar_articulo;
			FETCH ccoberturas INTO rcobertura;
				WHILE  found LOOP

				INSERT INTO tfar_coberturas ( 
					idiva ,
					lstock ,
					precio ,
					idrubro ,
					porccob ,
					porciva ,
					troquel ,
					cantidadsolicitada ,
					cantidadaprobada,
					astockmax ,
					astockmin ,
					monodroga ,
					montofijo ,
					prioridad ,
					adescuento ,
					detallecob ,
					--idafiliado ,
					idarticulo ,
					acomentario ,
					idmonodroga ,
					laboratorio ,
					acodigobarra ,
					adescripcion ,
					idobrasocial ,
					mnroregistro ,
					presentacion ,
					rdescripcion ,
					idlaboratorio ,
					pcdescripcion ,
					acodigointerno ,
					articulodetalle ,
					codautorizacion ,
					idplancobertura ,
					idcentroarticulo ) 
				VALUES (
					null ,
					null ,
					null ,
					null ,
					0 ,
					null,
					null ,
					0,
					0 ,
					null,
					null ,
					null ,
					null,
					99,
					1 ,
					null,
					--rcobertura.idafiliado ,
					rcobertura.idarticulo,
					'' ,
					null ,
					null ,
					rcobertura.acodigobarra ,
					'',
					1,
					rcobertura.mnroregistro ,
					null ,
					null,
					null,
					null ,
					null,
					null,
					null,
					null ,
					null);
			fetch ccoberturas into rcobertura;
		 	END LOOP;
		 	close ccoberturas;

		ELSE
			-- CARGO RECHAZO
			INSERT INTO rtasolicitud (estado) VALUES (false);
		END IF;

		SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
		FROM (SELECT * FROM tfar_coberturas) as t;

	END IF;
	

	respuestajson=respuestajson_info;

	return respuestajson;

END;
$function$
