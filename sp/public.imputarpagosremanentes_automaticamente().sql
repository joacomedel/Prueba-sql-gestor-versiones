CREATE OR REPLACE FUNCTION public.imputarpagosremanentes_automaticamente()
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
                              cuentacorrientepagos.idpago, cuentacorrientepagos.idcentropago, idctacte
                              , barra,saldo
                              FROM cuentacorrientepagos  
                              JOIN persona USING(nrodoc, tipodoc)
                               WHERE abs(cuentacorrientepagos.saldo) > 0  
                               ORDER BY idctacte, idconcepto;
      FETCH cdtoautomatico into rdtoautomatico;
	
      WHILE FOUND LOOP
	--me quedo con aquellos pagos donde el saldo >0

		  INSERT INTO tempimputacion(idcentrodeuda,idcentropago,idenviodescontarctacte,iddeuda,idpago,automatica)
	           SELECT cuentacorrientedeuda.idcentrodeuda,rdtoautomatico.idcentropago,null,cuentacorrientedeuda.iddeuda,rdtoautomatico.idpago,TRUE
                   FROM cuentacorrientedeuda
                   WHERE  cuentacorrientedeuda.saldo > 0  AND (cuentacorrientedeuda.idctacte =rdtoautomatico.idctacte OR cuentacorrientedeuda.idctacte ilike concat('%',rdtoautomatico.idctacte)) --MaLaPi 12-06-2018 Coloco un ilike para el caso de los dni que tienen menos de 8 caracteres
                   AND (cuentacorrientedeuda.idconcepto = rdtoautomatico.idconcepto OR 
                       (cuentacorrientedeuda.idconcepto<>360 AND (rdtoautomatico.idconcepto=387  AND rdtoautomatico.barra<>32))
                             ) ;
                     	
			
	FETCH cdtoautomatico into rdtoautomatico;
	END LOOP;
	CLOSE cdtoautomatico;

PERFORM asentarimputaciondescuentoctacte();
return 'true';
END;
$function$
