CREATE OR REPLACE FUNCTION public.sys_cargarvalormedicamento()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       cvalormedicamento refcursor;
       unvalormed record;
       unvalormedanterior record;
      -- primero boolean;
       rtempo record;
       rmed RECORD;
      
BEGIN 
	-- UPDATE o INSERT medicamento 
     SELECT INTO rtempo * FROM sys_cargarmedicamentodesdemedicamentosys();

    -- Re ubico sp para que se proceso antes de asignarle valor a idvalor en medicamentosys
    -- 22-09-2016 Malapi: Desde hoy al procesar los medicamentos, se van a dar de alta los articulos para la farmacia.  
    SELECT INTO rtempo * FROM sys_cargarfar_articulodesdemedicamentosys();



     OPEN cvalorregistros FOR 	
  			SELECT distinct mnroregistro 
     		FROM (
				SELECT ms.mnroregistro,ms.vmfechaini,ms.vmimporte,max(ikfechainformacion) as ikfechainformacion
				FROM medicamentosys as ms
				LEFT JOIN valormedicamento USING(idvalor)
				WHERE 
					nullvalue(valormedicamento.idvalor) 
					AND ikfechainformacion >= '2024-01-01' --AND mcodbarra = '7795302180323'
				GROUP BY ms.mnroregistro,ms.vmfechaini,ms.vmimporte
				ORDER BY ms.mnroregistro    
			) as t  ;
     FETCH cvalorregistros into unvalorreg;
     WHILE FOUND LOOP

	     --primero = true;
	    OPEN cvalormedicamento FOR
		  	SELECT 
		  		ms.idmedicamentosys, 
		  		null as idvalor,
		  		ms.mnroregistro,
		  		ms.vmfechaini,
		  		null as vmfechafin,
		  		ms.vmimporte,
		  		ikfechainformacion 
			FROM medicamentosys as ms
			LEFT JOIN valormedicamento USING(idvalor)
			WHERE 
                nullvalue(valormedicamento.idvalor)  
                AND ms.mnroregistro = unvalorreg.mnroregistro
                AND ikfechainformacion >= '2024-01-01'
			ORDER BY vmfechaini;

	     FETCH cvalormedicamento into unvalormed;
	     WHILE FOUND LOOP

			SELECT INTO unvalormedanterior * 
			FROM valormedicamento 
			WHERE mnroregistro = unvalormed.mnroregistro AND nullvalue(vmfechafin);
			
			IF FOUND THEN 
				-- 
			    IF unvalormedanterior.vmfechaini <> unvalormed.vmfechaini THEN 
			        UPDATE valormedicamento SET vmfechafin = unvalormed.vmfechaini WHERE idvalor = unvalormedanterior.idvalor;

					INSERT INTO valormedicamento(mnroregistro,vmfechaini,vmfechafin,vmimporte) 
						VALUES(unvalormed.mnroregistro,unvalormed.vmfechaini,unvalormedanterior.vmfechafin,unvalormed.vmimporte);
                    UPDATE medicamentosys SET idvalor = currval(('"public"."valormedicamento_idvalor_seq"'::text)::regclass) WHERE idmedicamentosys = unvalormed.idmedicamentosys;
			    ELSE 
					
					UPDATE medicamentosys SET idvalor = unvalormedanterior.idvalor WHERE idmedicamentosys = unvalormed.idmedicamentosys;
					--GermanK 10/02/2022 Misma fecha inicio con disinto importe, guardo los datos anteriores en valormedicamentomodificado y actualizo el importe en valormedicamento
					IF (unvalormedanterior.vmimporte <> unvalormed.vmimporte) THEN
						INSERT INTO valormedicamentomodificado(idvalor,mnroregistro,vmfechaini,vmfechafin,vmimporte,nomenclado,vmfechaingreso,ikfechainformacion) 
						VALUES(	unvalormedanterior.idvalor,
								unvalormedanterior.mnroregistro,
								unvalormedanterior.vmfechaini,
								unvalormedanterior.vmfechafin,
								unvalormedanterior.vmimporte,
								unvalormedanterior.nomenclado,
								unvalormedanterior.vmfechaingreso,
								unvalormed.ikfechainformacion
							);
						UPDATE valormedicamento SET vmimporte = unvalormed.vmimporte WHERE idvalor = unvalormedanterior.idvalor;
						UPDATE medicamentosys SET idvalor = unvalormedanterior.idvalor WHERE idmedicamentosys = unvalormed.idmedicamentosys;

					END IF;
			    END IF;
			    
            ELSE 
				--No existe precio vigente
				INSERT INTO valormedicamento(mnroregistro,vmfechaini,vmfechafin,vmimporte) 
				VALUES(
						unvalormed.mnroregistro,
						unvalormed.vmfechaini,
						null,
						unvalormed.vmimporte
						);
                
                UPDATE medicamentosys SET idvalor = currval(('"public"."valormedicamento_idvalor_seq"'::text)::regclass) WHERE idmedicamentosys = unvalormed.idmedicamentosys;
			END IF;
				
			
	     FETCH cvalormedicamento into unvalormed;
	     END LOOP;
	     close cvalormedicamento;

     FETCH cvalorregistros into unvalorreg;
     END LOOP;
     close cvalorregistros;

     -- 22-09-2016 Malapi: Desde hoy al procesar los medicamentos, se van a dar de alta los articulos para la farmacia.  
     --SELECT INTO rtempo * FROM sys_cargarfar_articulodesdemedicamentosys();

    --24-09-2019 MaLaPi: Mando a generar el historico de codigo de barras para los articulos que cambiaron de valor
         SELECT INTO rtempo * FROM sys_cargarhistocodigobarraarticulodesdemedicamento();
     return 'Listo';
END;$function$
