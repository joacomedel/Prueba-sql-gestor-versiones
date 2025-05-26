CREATE OR REPLACE FUNCTION public.asentarcompensacionctacte()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
    cractacte refcursor;
    cursorpagoctacte refcursor;

--RECORD
    rractacte RECORD;
    rusuario RECORD;
    regctactepago RECORD;
    rpagoctacte  RECORD;

--VARIABLES
    nrorecibo bigint;
    elidorigen bigint;
    ridpago bigint;
    codpago bigint;
    coddeuda bigint;    
    movconceptodeuda varchar;

BEGIN

/*Busco todas las deudas que estan en la tabla temporal reciboautomaticoctacte y genero un recibo para más de una deuda del mismo concepto por afiliado*/

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;




 OPEN cractacte FOR 


   SELECT racc.idpago,racc.idcentropago,ccd.idctacte,ccd.nrodoc, ccd.tipodoc, ccd.idconcepto, round(sum(importeimp)::numeric,2) as importerecibo, 
	text_concatenarsinrepetir(ccd.movconcepto) as imprecibo
       ,idformapagotipos ,racc.idvalorescaja, min(ccd.nrocuentac::integer) as nrocuentac,
       CASE WHEN nullvalue(racc.fechaemision) THEN NOW() ELSE racc.fechaemision END AS fechaemision
   FROM reciboautomaticoctacte as racc 
   NATURAL JOIN valorescaja
   JOIN cuentacorrientedeuda AS ccd USING(iddeuda, idcentrodeuda)
   GROUP BY racc.idpago,racc.idcentropago,ccd.idctacte,ccd.nrodoc, ccd.tipodoc, ccd.idconcepto,idformapagotipos,racc.idvalorescaja
   ,racc.fechaemision;


FETCH cractacte INTO rractacte;
WHILE FOUND LOOP
SELECT INTO regctactepago * FROM  cuentacorrientepagos WHERE idpago = rractacte.idpago AND idcentropago = rractacte.idcentropago;
IF FOUND THEN 
   movconceptodeuda = concat('Asiento de compensacion deuda: Deudas: ', rractacte.imprecibo,' Pagos: ',regctactepago.movconcepto);
   rractacte.imprecibo = concat('Asiento de compensacion pago: Deudas: ', rractacte.imprecibo,' Pagos: ',regctactepago.movconcepto);
   
   
   SELECT INTO nrorecibo * FROM getidrecibocaja();

   INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro) 
          VALUES (nrorecibo,rractacte.importerecibo,rractacte.fechaemision, rractacte.imprecibo, centro());

   --idorigenrecibo =4 es Compensacion
   SELECT INTO elidorigen idorigenrecibo FROM origenrecibo WHERE ordescripcion ILIKE '%Compensacion%';
   INSERT INTO reciboautomatico(idrecibo,centro,idorigenrecibo) VALUES (nrorecibo,centro(),elidorigen);

  
     INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
     VALUES (nrorecibo,rractacte.idformapagotipos,rractacte.importerecibo,centro());
 
      INSERT INTO recibocupon(idvalorescaja,  monto, cuotas, idrecibo,centro,nrotarjeta,nrocupon,autorizacion)
            VALUES(rractacte.idvalorescaja, rractacte.importerecibo, 1, nrorecibo,centro(),'','','');

      INSERT INTO recibousuario(idrecibo,idusuario,centro)
      VALUES (nrorecibo,rusuario.idusuario,centro());

        INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,idpagostipos,idlocalidad,idprovincia,nrocuentac)
	VALUES(nextval('pagos_idpagos_seq'),centro(),nrorecibo,rractacte.idformapagotipos,
       rractacte.imprecibo,rractacte.fechaemision,rractacte.idformapagotipos,6,2,rractacte.nrocuentac);
  
    ridpago =currval('pagos_idpagos_seq');

    INSERT INTO pagosafiliado (idpagos,nrodoc,tipodoc) VALUES(ridpago,rractacte.nrodoc,rractacte.tipodoc);

    UPDATE reciboautomaticoctacte SET idrecibo = nrorecibo, idcentrorecibo=centro()  
	WHERE reciboautomaticoctacte.idpago = rractacte.idpago 	AND reciboautomaticoctacte.idcentropago = rractacte.idcentropago;

 --  PERFORM generarmovimientocompensacionctacte(nrorecibo,centro());
   --- Generar Movimiento en la Cuenta Corriente
  
   INSERT INTO cuentacorrientepagos(idcentropago,idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
   VALUES(centro(),0,rractacte.tipodoc,rractacte.idctacte,rractacte.fechaemision,rractacte.imprecibo,rractacte.nrocuentac,rractacte.importerecibo*-1,nrorecibo,0,rractacte.idconcepto,rractacte.nrodoc);
   codpago = currval('cuentacorrientepagos_idpago_seq');

   INSERT INTO cuentacorrientedeuda(idcentrodeuda,idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
   VALUES(centro(),0,rractacte.tipodoc,rractacte.idctacte,rractacte.fechaemision,movconceptodeuda,rractacte.nrocuentac,rractacte.importerecibo,nrorecibo,0,regctactepago.idconcepto,rractacte.nrodoc);
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
		INSERT INTO cuentacorrientedeudapagocompensacion (idcentrodeudaoriginal,
								idcentropagooriginal,
								iddeudaoriginal,
								idpagooriginal,
								idcentrodeudagenerada,
								idcentropagogenerada,
								iddeudagenerada,
							        idpagogenerada)
	        VALUES(rpagoctacte.idcentrodeuda, rpagoctacte.idcentropago, rpagoctacte.iddeuda, rpagoctacte.idpago, centro(), centro(),coddeuda,codpago );


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
