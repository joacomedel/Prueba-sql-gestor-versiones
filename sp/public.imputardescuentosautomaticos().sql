CREATE OR REPLACE FUNCTION public.imputardescuentosautomaticos()
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
                              informedescuentoplanillav2.idpago, informedescuentoplanillav2.idcentropago, idctacte
                              ,CASE WHEN barra=32 THEN concat(barra, trim(to_char(current_date-30, 'YYYYMM')))
                              ELSE trim(to_char(current_date-30, 'YYYYMM'))   END as elid
                              , barra
                              FROM informedescuentoplanillav2  JOIN persona USING(nrodoc, tipodoc)
                               JOIN cuentacorrientepagos USING(idpago, idcentropago)
                               WHERE informedescuentoplanillav2.mes= date_part('month', current_date -30) 
--                               WHERE informedescuentoplanillav2.mes= 5 
					AND informedescuentoplanillav2.anio = date_part('year', current_date -30)
					--AND informedescuentoplanillav2.anio = 2018
                             
                                --AND informedescuentoplanillav2.informedescuentoplanillatipo = 2
                               AND cuentacorrientepagos.saldo < 0  
                               ORDER BY idctacte, idconcepto;
      FETCH cdtoautomatico into rdtoautomatico;
	
      WHILE FOUND LOOP
	--me quedo con aquellos pagos donde el saldo >0

			INSERT INTO tempimputacion(idcentrodeuda,idcentropago,idenviodescontarctacte,iddeuda,idpago,automatica)
	           SELECT cuentacorrientedeuda.idcentrodeuda,rdtoautomatico.idcentropago,rdtoautomatico.elid,cuentacorrientedeuda.iddeuda,rdtoautomatico.idpago,TRUE
                   FROM cuentacorrientedeuda
                   WHERE  cuentacorrientedeuda.saldo > 0  AND (cuentacorrientedeuda.idctacte =rdtoautomatico.idctacte OR cuentacorrientedeuda.idctacte ilike concat('%',rdtoautomatico.idctacte)) --MaLaPi 12-06-2018 Coloco un ilike para el caso de los dni que tienen menos de 8 caracteres
                   AND   fechaenvio=date_trunc('MONTH', current_date-30)::date + 21::integer
                   AND (cuentacorrientedeuda.idconcepto = rdtoautomatico.idconcepto OR 
                       (cuentacorrientedeuda.idconcepto<>360 AND (rdtoautomatico.idconcepto=387  AND rdtoautomatico.barra<>32))

                             ) ;
                     	
			
	FETCH cdtoautomatico into rdtoautomatico;
	END LOOP;
	CLOSE cdtoautomatico;

PERFORM asentarimputaciondescuentoctacte();

--borro los datos de la temporal tempimputacion
  DELETE FROM tempimputacion;
 
--KAR 13-12-22 genero tbn la imputacion automatica de los descuentos de empleados de farmacia

  OPEN cdtoautomatico FOR SELECT ccpc.nrocuentac, informedescuentoplanillav2.idpago, informedescuentoplanillav2.idcentropago 
                              ,CASE WHEN barra=32 THEN concat(barra, trim(to_char(current_date-30, 'YYYYMM')))
                              ELSE trim(to_char(current_date-30, 'YYYYMM'))   END as elid, barra, idclientectacte, idcentroclientectacte
                              FROM informedescuentoplanillav2 JOIN ctactepagocliente ccpc  USING(idpago, idcentropago) JOIN mapeocuentascontablesconcepto mcc ON (ccpc.nrocuentac=mcc.nrocuentac) JOIN persona USING(nrodoc, tipodoc) 
                               WHERE informedescuentoplanillav2.mes= date_part('month', current_date -30) 
					AND informedescuentoplanillav2.anio = date_part('year', current_date -30)	 
                               AND ccpc.saldo < 0  
                               ORDER BY idclientectacte, ccpc.nrocuentac;

   FETCH cdtoautomatico into rdtoautomatico;
	
   WHILE FOUND LOOP
	INSERT INTO tempimputacion(idcentrodeuda,idcentropago,idenviodescontarctacte,iddeuda,idpago,automatica)
	SELECT  idcentrodeuda,rdtoautomatico.idcentropago,rdtoautomatico.elid,ctactedeudacliente.iddeuda,rdtoautomatico.idpago,TRUE
        FROM ctactedeudacliente 
        WHERE  ctactedeudacliente.saldo > 0 AND ctactedeudacliente.idclientectacte =rdtoautomatico.idclientectacte  AND  ctactedeudacliente.idcentroclientectacte =rdtoautomatico.idcentroclientectacte 
                   AND   ccdcfechaenvio	=date_trunc('MONTH', current_date-30)::date + 21::integer
--KAR ahora el pago tiene la cta contable 10202 segun lo hablado con silvia, pero la deuda no tiene dicha cuenta ni corresponde el concepto con lo cual lo comento, hoy se aplica el pago no importa la cuenta.
          --        AND  ctactedeudacliente.nrocuentac= rdtoautomatico.nrocuentac 
              ;
                     	
			
	FETCH cdtoautomatico into rdtoautomatico;
	END LOOP;
	CLOSE cdtoautomatico;

PERFORM tesoreria_adherente_asentarimputaciondescuentoctacte('');
 
return 'true';
END;
$function$
