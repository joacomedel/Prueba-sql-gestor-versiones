CREATE OR REPLACE FUNCTION public.tesoreria_adherente_imputarpagosconsaldopendiente(character varying)
 RETURNS character varying
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
      OPEN cdtoautomatico FOR SELECT CASE WHEN nroconcepto = 372 THEN 360        
		              ELSE nroconcepto END as nroconcepto, idpago, idcentropago, idclientectacte,idcentroclientectacte, saldo,importe, ccpc.nrocuentac,fechamovimiento 
                              FROM ctactepagocliente ccpc JOIN mapeocuentascontablesconcepto mcc ON (ccpc.nrocuentac=mcc.nrocuentac)
                              NATURAL JOIN clientectacte ccc  
                              WHERE abs(round(saldo::numeric, 2)) > 0.01  and fechamovimiento>='2020-01-01'
                              ORDER BY idclientectacte, nroconcepto,fechamovimiento 
                               --LIMIT 30
                               ;
      FETCH cdtoautomatico into rdtoautomatico;
	
      WHILE FOUND LOOP
	--me quedo con aquellos pagos donde el saldo >0
		
		   INSERT INTO tempimputacion(idcentrodeuda,idcentropago,iddeuda,idpago,automatica)
	           SELECT ctactedeudacliente.idcentrodeuda,rdtoautomatico.idcentropago,ctactedeudacliente.iddeuda,rdtoautomatico.idpago,TRUE
                   FROM ctactedeudacliente
                   WHERE ctactedeudacliente.importe = abs(rdtoautomatico.importe) 
                           AND ctactedeudacliente.saldo > 0  
                           AND (ctactedeudacliente.idclientectacte=rdtoautomatico.idclientectacte AND ctactedeudacliente.idcentroclientectacte=rdtoautomatico.idcentroclientectacte) 
                   AND (ctactedeudacliente.nrocuentac= rdtoautomatico.nrocuentac)
		ORDER BY idclientectacte, fechamovimiento;
		IF NOT FOUND THEN
			INSERT INTO tempimputacion(idcentrodeuda,idcentropago,iddeuda,idpago,automatica)
			   SELECT ccdc.idcentrodeuda,rdtoautomatico.idcentropago,ccdc.iddeuda,rdtoautomatico.idpago,TRUE
			   FROM ctactedeudacliente ccdc JOIN mapeocuentascontablesconcepto mcc ON (ccdc.nrocuentac=mcc.nrocuentac)
			   WHERE ccdc.saldo > 0  
				   AND (ccdc.idclientectacte=rdtoautomatico.idclientectacte AND ccdc.idcentroclientectacte=rdtoautomatico.idcentroclientectacte)  
 --KR 31-03-23 SI el concepto del pago es 997, nrocuentac=10202 imputo con cualquier concepto de la deuda
			   AND (mcc.nroconcepto= rdtoautomatico.nroconcepto OR rdtoautomatico.nroconcepto = 997)
			   ORDER BY idclientectacte, fechamovimiento;
			 IF FOUND THEN 
				--RAISE NOTICE 'Se procesan pagos idctacte de (%) <> Importe ',rdtoautomatico.idctacte;
                                PERFORM tesoreria_adherente_asentarimputaciondescuentoctacte('');
                                DELETE FROM tempimputacion;
			 ELSE 
				--RAISE NOTICE ' No tiene deuda (%)',rdtoautomatico.idctacte;
			 END IF;
		ELSE
			--RAISE NOTICE 'Se procesan pagos idctacte de (%) = Importe ',rdtoautomatico.idctacte;
                        PERFORM tesoreria_adherente_asentarimputaciondescuentoctacte(' '); 
                        DELETE FROM tempimputacion;

		END IF;
                     	
			
	FETCH cdtoautomatico into rdtoautomatico;
	END LOOP;
	CLOSE cdtoautomatico;
 
return ' ';
END;$function$
