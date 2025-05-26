CREATE OR REPLACE FUNCTION public.generarmovimientocompensacionctacte(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
    cractacte refcursor;
    cursorpagoctacte refcursor;

--RECORD
    rractacte RECORD;
    regctactepago RECORD;
    rpagoctacte  RECORD;

--VARIABLES
   
    codpago bigint;
    coddeuda bigint;    
    movconceptodeuda varchar;

BEGIN

/*Busco todas las deudas que estan en la tabla temporal reciboautomaticoctacte y genero un recibo para más de una deuda del mismo concepto por afiliado*/


 OPEN cractacte FOR 
   SELECT *
   FROM reciboautomaticoctacte as racc  NATURAL JOIN recibo
   WHERE idrecibo= $1 AND idcentrorecibo=$2;


FETCH cractacte INTO rractacte;
WHILE FOUND LOOP
SELECT INTO regctactepago * FROM  cuentacorrientepagos WHERE idpago = rractacte.idpago AND idcentropago = rractacte.idcentropago;
IF FOUND THEN 
   movconceptodeuda = concat('Asiento de compensacion: Deudas: ', rractacte.imprecibo,' Pagos: ',regctactepago.movconcepto);
      
   --- Generar Movimiento en la Cuenta Corriente
   INSERT INTO cuentacorrientepagos(idcentropago,idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
   VALUES(centro(),0,rractacte.tipodoc,rractacte.idctacte,rractacte.fechaemision,rractacte.imputacionrecibo,rractacte.nrocuentac,rractacte.importerecibo*-1,$1,0,rractacte.idconcepto,rractacte.nrodoc);
   codpago = currval('cuentacorrientepagos_idpago_seq');

   INSERT INTO cuentacorrientedeuda(idcentrodeuda,idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
   VALUES(centro(),0,rractacte.tipodoc,rractacte.idctacte,rractacte.fechaemision,movconceptodeuda,rractacte.nrocuentac,rractacte.importerecibo,nrorecibo,0,rractacte.idconcepto,rractacte.nrodoc);
   coddeuda = currval('cuentacorrientedeuda_iddeuda_seq');

    INSERT INTO cuentacorrientedeudapago(idpago,iddeuda,idcentrodeuda,idcentropago)
    VALUES(codpago,coddeuda,centro(),centro());

	 OPEN cursorpagoctacte FOR SELECT *
			FROM reciboautomaticoctacte
			JOIN cuentacorrientedeuda ccd USING(iddeuda,idcentrodeuda)
			WHERE  ccd.idconcepto = rractacte.idconcepto
				AND ccd.tipodoc = rractacte.tipodoc
				AND ccd.nrodoc = rractacte.nrodoc
				AND reciboautomaticoctacte.idpago = rractacte.idpago
				AND reciboautomaticoctacte.idcentropago = rractacte.idcentropago
                                ORDER BY ccd.iddeuda;

         FETCH cursorpagoctacte INTO rpagoctacte;
          WHILE  found LOOP
                
		 INSERT INTO cuentacorrientedeudapagocompensacion (idcentrodeudaoriginal,idcentropagooriginal,iddeudaoriginal,
		 idpagooriginal,idcentrodeudagenerada,idcentropagogenerada,iddeudagenerada,idpagogenerada)
	         VALUES(rractacte.idcentrodeuda, rractacte.idcentropago, rractacte.iddeuda, rractacte.idpago, centro(), centro(),coddeuda,codpago );


           FETCH cursorpagoctacte INTO rpagoctacte;
           END LOOP;
           CLOSE cursorpagoctacte;
     -- Fin de Eliminar Luego

     
  
END IF; --IF FOUND THEN del Existe el pago
FETCH cractacte INTO rractacte;
END LOOP;
CLOSE cractacte;

RETURN TRUE;


END;
    $function$
