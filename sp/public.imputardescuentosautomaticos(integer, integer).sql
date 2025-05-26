CREATE OR REPLACE FUNCTION public.imputardescuentosautomaticos(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSOR
       cdtoautomatico refcursor;
--REGISTROS
       rdtoautomatico RECORD;
  
BEGIN
      
      CREATE  TABLE tempimputacion ( 
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
                              informedescuentoplanillav2.idpago, informedescuentoplanillav2.idcentropago, idctacte
                              FROM informedescuentoplanillav2  JOIN cuentacorrientepagos USING(idpago, idcentropago)
                               WHERE informedescuentoplanillav2.mes=$1 AND informedescuentoplanillav2.anio = $2
                               AND (informedescuentoplanillav2.nrodoc= '27349352' 
                             or informedescuentoplanillav2.nrodoc='17733470')
                               AND cuentacorrientepagos.saldo < 0  
                               ORDER BY idctacte, idconcepto;
      FETCH cdtoautomatico into rdtoautomatico;
	
      WHILE FOUND LOOP
	--me quedo con aquellos pagos donde el saldo >0

			INSERT INTO tempimputacion(idcentrodeuda,idcentropago,idenviodescontarctacte,iddeuda,idpago,automatica)
	           SELECT cuentacorrientedeuda.idcentrodeuda,rdtoautomatico.idcentropago,idctacte,cuentacorrientedeuda.iddeuda,rdtoautomatico.idpago,TRUE
                   FROM cuentacorrientedeuda
                   WHERE  cuentacorrientedeuda.saldo > 0  AND cuentacorrientedeuda.idctacte =rdtoautomatico.idctacte
                             AND (cuentacorrientedeuda.idconcepto = rdtoautomatico.idconcepto OR (cuentacorrientedeuda.idconcepto<>360 AND rdtoautomatico.idconcepto=387 )) ;
                     	
			
	FETCH cdtoautomatico into rdtoautomatico;
	END LOOP;
	CLOSE cdtoautomatico;

 PERFORM asentarimputaciondescuentoctacte();
return 'true';
END;$function$
