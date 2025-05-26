CREATE OR REPLACE FUNCTION public.generarreciboautomaticodesdectactedeuda()
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
    rplanpago RECORD;
    rdatosdeudapago  RECORD;
--VARIABLES
    nrorecibo bigint;
    elidorigen bigint;
    ridpago bigint;
    codpago bigint;

BEGIN

/*Busco todas las deudas que estan en la tabla temporal reciboautomaticoctacte y genero un recibo para más de una deuda del mismo concepto por afiliado*/

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;



IF existecolumtemp('reciboautomaticoctacte','idprestamo') THEN

 OPEN cractacte FOR 


   SELECT ccd.idctacte,ccd.nrodoc, ccd.tipodoc, ccd.idconcepto, round(sum(importeimp)::numeric,2) as importerecibo, 
	text_concatenarsinrepetir(ccd.movconcepto) as imprecibo
       ,idformapagotipos ,racc.idvalorescaja, racc.idprestamo, racc.idcentroprestamo, min(ccd.nrocuentac::integer) as nrocuentac,
       CASE WHEN nullvalue(racc.fechaemision) THEN NOW() ELSE racc.fechaemision END AS fechaemision
   FROM reciboautomaticoctacte as racc 
   NATURAL JOIN valorescaja
   LEFT JOIN cuentacorrientedeuda AS ccd USING(iddeuda, idcentrodeuda)
   GROUP BY ccd.idctacte,ccd.nrodoc, ccd.tipodoc, ccd.idconcepto,idformapagotipos,racc.idvalorescaja, racc.idprestamo, 
               racc.idcentroprestamo, racc.fechaemision;


FETCH cractacte INTO rractacte;
WHILE FOUND LOOP

   rractacte.imprecibo = concat('Recibo automatico por generacion de plan de pago Nro. ', rractacte.idprestamo, '-', rractacte.idcentroprestamo,' ', rractacte.imprecibo);

   SELECT INTO nrorecibo * FROM getidrecibocaja();

   INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro) 
          VALUES (nrorecibo,rractacte.importerecibo,rractacte.fechaemision, rractacte.imprecibo, centro());

   --idorigenrecibo =3 es plan de pago
   SELECT INTO elidorigen idorigenrecibo FROM origenrecibo WHERE ordescripcion ILIKE '%prestamo%';
   INSERT INTO reciboautomatico(idrecibo,centro,idorigenrecibo) VALUES (nrorecibo,centro(),elidorigen);

  
     INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
     VALUES (nrorecibo,rractacte.idformapagotipos,rractacte.importerecibo,centro());
 
      
    INSERT INTO recibocupon(idvalorescaja,  monto, cuotas, idrecibo,centro,nrotarjeta,nrocupon,autorizacion)
            VALUES(rractacte.idvalorescaja, rractacte.importerecibo, 1, nrorecibo,centro(),'','','');

        INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,idpagostipos,idlocalidad,idprovincia,nrocuentac)
	VALUES(nextval('pagos_idpagos_seq'),centro(),nrorecibo,rractacte.idformapagotipos,
       rractacte.imprecibo,rractacte.fechaemision,rractacte.idformapagotipos,6,2,rractacte.nrocuentac);
  
    ridpago =currval('pagos_idpagos_seq');

    INSERT INTO pagosafiliado (idpagos,nrodoc,tipodoc) VALUES(ridpago,rractacte.nrodoc,rractacte.tipodoc);
   

   INSERT INTO cuentacorrientepagos(idcentropago,idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
   VALUES(centro(),0,rractacte.tipodoc,rractacte.idctacte,rractacte.fechaemision,rractacte.imprecibo,rractacte.nrocuentac,rractacte.importerecibo*-1,nrorecibo,0,rractacte.idconcepto,rractacte.nrodoc);
   codpago = currval('cuentacorrientepagos_idpago_seq');

  --KR 09-09-21 SE pone aqui para que se dispare el asientogenerico_crear_8
   INSERT INTO recibousuario(idrecibo,idusuario,centro) VALUES (nrorecibo,rusuario.idusuario,centro());



	 OPEN cursorpagoctacte FOR SELECT *
			FROM reciboautomaticoctacte
			JOIN cuentacorrientedeuda ccd USING(iddeuda,idcentrodeuda)
			WHERE  ccd.idconcepto = rractacte.idconcepto
				AND ccd.tipodoc = rractacte.tipodoc
				AND ccd.nrodoc = rractacte.nrodoc
				AND reciboautomaticoctacte.idprestamo = rractacte.idprestamo
				AND reciboautomaticoctacte.idcentroprestamo = rractacte.idcentroprestamo
                                 ORDER BY ccd.iddeuda;

         FETCH cursorpagoctacte INTO rpagoctacte;
          WHILE  found LOOP
                 UPDATE reciboautomaticoctacte SET idrecibo = nrorecibo, idcentrorecibo=centro()  
		 WHERE idprestamo = rractacte.idprestamo AND idcentroprestamo=rractacte.idcentroprestamo;

                   UPDATE prestamoplandepago SET idpago = codpago ,idcentropago = centro()
				WHERE iddeuda = rpagoctacte.iddeuda AND idcentrodeuda = rpagoctacte.idcentrodeuda 
				AND idprestamo = rpagoctacte.idprestamo 
				AND idcentroprestamo=rpagoctacte.idcentroprestamo;
		/*   UPDATE cuentacorrientedeudapago SET idpago = codpago,idcentropago = centro()
						WHERE iddeuda = rpagoctacte.iddeuda 
						AND idcentrodeuda = rpagoctacte.idcentrodeuda
						AND idpago = rpagoctacte.idpago 
                                                AND idcentropago = rpagoctacte.idcentropago;*/

--KR 09-09-21 Se realiza esta modificacion para que se pueda generar la contabilidad de la imputacion. SP asientogenerico_crear_9

                   SELECT INTO rdatosdeudapago * FROM cuentacorrientedeudapago WHERE iddeuda = rpagoctacte.iddeuda 
						AND idcentrodeuda = rpagoctacte.idcentrodeuda
						AND idpago = rpagoctacte.idpago 
                                                AND idcentropago = rpagoctacte.idcentropago;

                   INSERT INTO cuentacorrientedeudapago (idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
                   VALUES (codpago,centro(),rdatosdeudapago.iddeuda, rdatosdeudapago.idcentrodeuda,NOW(),rdatosdeudapago.importeimp);

                   DELETE FROM cuentacorrientedeudapago WHERE iddeuda = rpagoctacte.iddeuda 
						AND idcentrodeuda = rpagoctacte.idcentrodeuda
						AND idpago = rpagoctacte.idpago 
                                                AND idcentropago = rpagoctacte.idcentropago AND importeimp= rdatosdeudapago.importeimp;

                  
               
           FETCH cursorpagoctacte INTO rpagoctacte;
           END LOOP;
           CLOSE cursorpagoctacte;
     -- Fin de Eliminar Luego

     
  

FETCH cractacte INTO rractacte;
END LOOP;
CLOSE cractacte;

DELETE FROM cuentacorrientepagos WHERE (idpago,idcentropago) IN (SELECT idpago,idcentropago FROM reciboautomaticoctacte GROUP BY idpago,idcentropago);

END IF; 

RETURN TRUE;


END;
    $function$
