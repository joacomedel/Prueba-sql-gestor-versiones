CREATE OR REPLACE FUNCTION public.verificarsaldoafavor(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta los envios a descontar a la universidad de la deuda en ctacte
   Quedan afuera los afiliados Adherentes (35 y 36).
*/
DECLARE
--CURSOR
       cctactepagos refcursor;
       cursormovimientos refcursor;
--RECORD
       rctactepagos RECORD;
       rctactedeuda RECORD;
       runmovimiento RECORD;
--VARIABLES
       igualconcepto BOOLEAN DEFAULT false;
BEGIN
 
--VERIFICO QUE EXISTEN SALDOS A FAVOR EN EL PAGO CON EL MISMO CONCEPTO TANTO EN DEUDA COMO EN SALDO

CREATE TEMP TABLE cualeson (iddeuda bigint,idcentrodeuda integer, idconceptodeuda integer, idconceptopago integer,idpago bigint,idcentropago bigint);
 OPEN cursormovimientos FOR  SELECT *
                         FROM cuentacorrientepagos
                         JOIN persona USING(nrodoc,tipodoc)
                         WHERE saldo <> 0 
				AND ( ( $1 ilike 'sosunc' AND (persona.barra = 32))
				OR ( $1 ilike 'unc' AND (persona.barra <> 35 AND persona.barra <> 32 
                                     AND persona.barra <> 36 AND persona.barra <> 34)) )
			ORDER BY barra,cuentacorrientepagos.nrodoc,cuentacorrientepagos.tipodoc;

 FETCH cursormovimientos into runmovimiento;
 WHILE  found  and not igualconcepto LOOP

              SELECT INTO rctactedeuda * 
                   FROM cuentacorrientedeuda
                   WHERE  cuentacorrientedeuda.saldo > 0  
                     AND cuentacorrientedeuda.idctacte =runmovimiento.idctacte
                     AND (cuentacorrientedeuda.idconcepto = runmovimiento.idconcepto) ;
                   IF FOUND THEN 
                     INSERT INTO cualeson (idpago,idcentropago,idconceptopago,iddeuda,idcentrodeuda,idconceptodeuda) VALUES(runmovimiento.idpago,runmovimiento.idcentropago,runmovimiento.idconcepto,rctactedeuda.iddeuda,rctactedeuda.idcentrodeuda,rctactedeuda.idconcepto);
                     igualconcepto = true; 
                   END IF;
			
	 FETCH cursormovimientos into runmovimiento;
 END LOOP;
CLOSE cursormovimientos;






RETURN igualconcepto;
END;
$function$
