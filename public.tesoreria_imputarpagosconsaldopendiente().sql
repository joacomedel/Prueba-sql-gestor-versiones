CREATE OR REPLACE FUNCTION public.tesoreria_imputarpagosconsaldopendiente()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSOR
       cdtoautomatico refcursor;
--REGISTROS
       rdtoautomatico RECORD;

BEGIN
      
      CREATE TEMP TABLE tempimputacion ( 
				  idenviodescontarctacte VARCHAR,
				  iddeuda BIGINT NOT NULL,
				  idpago BIGINT NOT NULL, 
				  importeimputado DOUBLE PRECISION,
				  importedeuda DOUBLE PRECISION,
				  automatica BOOLEAN,
				  idcentrodeuda INTEGER,
				  idcentropago INTEGER
				) WITHOUT OIDS;

--me quedo con aquellos datos donde impenvio = impdescontado
      OPEN cdtoautomatico FOR SELECT CASE WHEN cuentacorrientepagos.idconcepto = 372 THEN 360        
		              ELSE cuentacorrientepagos.idconcepto END as idconcepto,
                              cuentacorrientepagos.idpago, cuentacorrientepagos.idcentropago, idctacte,barra, cuentacorrientepagos.saldo,cuentacorrientepagos.importe
                              FROM cuentacorrientepagos
                              JOIN persona USING(nrodoc, tipodoc)
                              WHERE abs(cuentacorrientepagos.saldo) > 0 
                                --     AND (nrodoc = '26331252') --33291948-32	BERZANO,ROMINA	2913.24	-1539.28	-22412564-32	AGOSTA,GABRIELA ROSANA	9530.46	-317.93
                               ORDER BY idctacte, idconcepto,fechamovimiento
                               --LIMIT 30
                               ;
      FETCH cdtoautomatico into rdtoautomatico;
	
      WHILE FOUND LOOP
	--me quedo con aquellos pagos donde el saldo >0
		
		   INSERT INTO tempimputacion(idcentrodeuda,idcentropago,iddeuda,idpago,automatica)
	           SELECT cuentacorrientedeuda.idcentrodeuda,rdtoautomatico.idcentropago,cuentacorrientedeuda.iddeuda,rdtoautomatico.idpago,TRUE
                   FROM cuentacorrientedeuda
                   WHERE cuentacorrientedeuda.importe = abs(rdtoautomatico.importe) -- 19-06-2019 Malapi Primero busco si existe una deuda con igual importe, para el caso de las notas de credito por anulacion de orden
                           AND cuentacorrientedeuda.saldo > 0  
                           AND (cuentacorrientedeuda.idctacte =rdtoautomatico.idctacte 
                                 OR cuentacorrientedeuda.idctacte ilike concat('%',rdtoautomatico.idctacte)) 
                                  --MaLaPi 12-06-2018 Coloco un ilike para el caso de los dni que tienen menos de 8 caracteres
                   AND (cuentacorrientedeuda.idconcepto = rdtoautomatico.idconcepto OR 
                       (cuentacorrientedeuda.idconcepto<>360 AND (rdtoautomatico.idconcepto=387  AND rdtoautomatico.barra<>32))
		) ORDER BY idctacte, fechamovimiento;
		IF NOT FOUND THEN
			INSERT INTO tempimputacion(idcentrodeuda,idcentropago,iddeuda,idpago,automatica)
			   SELECT cuentacorrientedeuda.idcentrodeuda,rdtoautomatico.idcentropago,cuentacorrientedeuda.iddeuda,rdtoautomatico.idpago,TRUE
			   FROM cuentacorrientedeuda
			   WHERE cuentacorrientedeuda.saldo > 0  
				   AND (cuentacorrientedeuda.idctacte =rdtoautomatico.idctacte 
					 OR cuentacorrientedeuda.idctacte ilike concat('%',rdtoautomatico.idctacte)) 
					  --MaLaPi 12-06-2018 Coloco un ilike para el caso de los dni que tienen menos de 8 caracteres
			   AND (cuentacorrientedeuda.idconcepto = rdtoautomatico.idconcepto OR 
			       (cuentacorrientedeuda.idconcepto<>360 AND (rdtoautomatico.idconcepto=387  AND rdtoautomatico.barra<>32)
--KR 31-03-23 SI el concepto del pago es 997, imputo con cualquier concepto de la deuda
                               OR (rdtoautomatico.idconcepto = 997)
)
			) ORDER BY idctacte, fechamovimiento;
			IF FOUND THEN 
				RAISE NOTICE 'Se procesan pagos idctacte de (%) <> Importe ',rdtoautomatico.idctacte;
                                PERFORM asentarimputaciondescuentoctacte();
                                DELETE FROM tempimputacion;
			ELSE 
				RAISE NOTICE ' No tiene deuda (%)',rdtoautomatico.idctacte;
			END IF;
		ELSE
			RAISE NOTICE 'Se procesan pagos idctacte de (%) = Importe ',rdtoautomatico.idctacte;
                        PERFORM asentarimputaciondescuentoctacte(); 
                        DELETE FROM tempimputacion;

		END IF;
                     	
			
	FETCH cdtoautomatico into rdtoautomatico;
	END LOOP;
	CLOSE cdtoautomatico;

--PERFORM asentarimputaciondescuentoctacte();
return 'true';
END;
$function$
