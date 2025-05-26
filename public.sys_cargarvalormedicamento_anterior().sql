CREATE OR REPLACE FUNCTION public.sys_cargarvalormedicamento_anterior()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       cvalormedicamento refcursor;
       unvalormed record;
       unvalormedanterior record;
       primero boolean;
       rtempo record;
       rmed RECORD;
      
BEGIN 

     SELECT INTO rtempo * FROM sys_cargarmedicamentodesdemedicamentosys();

     OPEN cvalorregistros FOR 	SELECT distinct mnroregistro FROM (
					SELECT ms.mnroregistro,ms.vmfechaini,ms.vmimporte,max(ikfechainformacion) as ikfechainformacion
					FROM medicamentosys as ms
					LEFT JOIN valormedicamento USING(idvalor)
					WHERE nullvalue(valormedicamento.idvalor) 
					AND ikfechainformacion >= '2016-01-01' --AND mcodbarra = '7795302180323'
					GROUP BY ms.mnroregistro,ms.vmfechaini,ms.vmimporte
					ORDER BY ms.mnroregistro
				) as t;

                                

     FETCH cvalorregistros into unvalorreg;
     WHILE FOUND LOOP

	     primero = true;
	     OPEN cvalormedicamento FOR
		  SELECT * FROM (
			select null as idmedicamentosys,idvalor,mnroregistro,vmfechaini,vmfechafin,vmimporte from valormedicamento where mnroregistro = unvalorreg.mnroregistro
			UNION 
			SELECT 
                        ms.idmedicamentosys, null as idvalor,ms.mnroregistro,ms.vmfechaini,null as vmfechafin,ms.vmimporte 
			FROM medicamentosys as ms
			LEFT JOIN valormedicamento USING(idvalor)
			WHERE nullvalue(valormedicamento.idvalor)  AND ms.mnroregistro = unvalorreg.mnroregistro
			) as t
		ORDER BY vmfechaini;

	     FETCH cvalormedicamento into unvalormed;
	     WHILE FOUND LOOP
		IF primero THEN
			IF (unvalormed.idvalor is null) THEN
				INSERT INTO valormedicamento(mnroregistro,vmfechaini,vmfechafin,vmimporte) 
				VALUES(unvalormed.mnroregistro,unvalormed.vmfechaini,null,unvalormed.vmimporte);
				SELECT INTO unvalormedanterior idvalor,mnroregistro,vmfechaini,vmfechafin,vmimporte FROM valormedicamento
				WHERE idvalor = currval(('"public"."valormedicamento_idvalor_seq"'::text)::regclass);
                                UPDATE medicamentosys SET idvalor = currval(('"public"."valormedicamento_idvalor_seq"'::text)::regclass) 
                                WHERE idmedicamentosys = unvalormed.idmedicamentosys;
			ELSE
				unvalormedanterior=unvalormed;
			END IF;
			primero = false;
		ELSE 
			IF (unvalormed.idvalor is null) THEN
				--IF(unvalormed.vmimporte <> unvalormedanterior.vmimporte) THEN
					UPDATE valormedicamento SET vmfechafin = unvalormed.vmfechaini WHERE idvalor = unvalormedanterior.idvalor;
					INSERT INTO valormedicamento(mnroregistro,vmfechaini,vmfechafin,vmimporte) 
					VALUES(unvalormed.mnroregistro,unvalormed.vmfechaini,unvalormedanterior.vmfechafin,unvalormed.vmimporte);

					SELECT INTO unvalormedanterior idvalor,mnroregistro,vmfechaini,vmfechafin,vmimporte FROM valormedicamento
					WHERE idvalor = currval(('"public"."valormedicamento_idvalor_seq"'::text)::regclass);
                       
                                        UPDATE medicamentosys SET idvalor = currval(('"public"."valormedicamento_idvalor_seq"'::text)::regclass) 
                                        WHERE idmedicamentosys = unvalormed.idmedicamentosys;

				--END IF;
			ELSE 
				unvalormedanterior=unvalormed;
			END IF;
		END IF;
	       
	     FETCH cvalormedicamento into unvalormed;
	     END LOOP;
	     close cvalormedicamento;

     FETCH cvalorregistros into unvalorreg;
     END LOOP;
     close cvalorregistros;

     -- 22-09-2016 Malapi: Desde hoy al procesar los medicamentos, se van a dar de alta los articulos para la farmacia.  
      SELECT INTO rtempo * FROM sys_cargarfar_articulodesdemedicamentosys();
     return 'Listo';
END;
$function$
