CREATE OR REPLACE FUNCTION public.asentarpagoctacte()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta los pagos que se realizan por mesa de entreada
de los pagos de la cuenta corriente.
*/
DECLARE
--cursores
       cursormovimientos CURSOR FOR SELECT * FROM pagocuentacorriente WHERE not nullvalue(pagocuentacorriente.idmovimiento);
       cursorpagos CURSOR FOR SELECT * FROM temppagodeuda;
       cursorri refcursor; 
--registros
       unmovimiento RECORD;
       unpago RECORD;
       pagoctacte RECORD;
       rctactedeuda RECORD;
       unpagoctacte RECORD;
       regri RECORD;
--variables
       nrorecibo bigint;
       ridpago bigint;
       movpago bigint;
       idconceptodeuda integer;

BEGIN
    
     SELECT INTO unpago * FROM temppagoctacte;
     --Se asienta el recibo
     SELECT INTO nrorecibo * FROM getidrecibocaja();
     INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,importeenletras)
     VALUES (nrorecibo,unpago.importeapagar,unpago.fechaingreso,unpago.conceptoPago,unpago.centro,unpago.importeenletras);

   
     UPDATE temppagoctacte SET idrecibo = nrorecibo;

    SELECT INTO pagoctacte * FROM pagocuentacorriente WHERE nullvalue(pagocuentacorriente.idmovimiento);


      /*Ingreso el pago en la cuenta corriente, el Idcomprobante = nrorecibo*/
    movpago = nextval('cuentacorrientepagos_idpago_seq');
   
     INSERT INTO cuentacorrientepagos(idpago,idcentropago,idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc)
     VALUES(movpago,centro(),pagoctacte.idcomprobantetipos,unpago.tipodoc,pagoctacte.nrodoc,pagoctacte.fechamovimiento,pagoctacte.movconcepto,pagoctacte.nrocuentac,
(case when pagoctacte.importe >0 then (pagoctacte.importe* (- 1::double precision)) else (pagoctacte.importe) end)
,nrorecibo,0,unpago.nrodoc);

     
      OPEN cursorri FOR SELECT sum(monto) AS monto,idformapagotipos
                            FROM temppagodeuda
                            GROUP BY idformapagotipos;
     FETCH cursorri INTO regri;
   
     WHILE FOUND LOOP
          INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
          VALUES (nrorecibo,regri.idformapagotipos,regri.monto,centro());
   
       FETCH cursorri INTO regri;
     END LOOP;
     close cursorri;

 /*inserto en importesrecibo tantas tupla como formas de pago existan, agrupadas x idformapagotipos*/
     OPEN cursorpagos;
     FETCH cursorpagos into unpagoctacte;
     WHILE  found LOOP
         
     /*    INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
         VALUES (nrorecibo,unpagoctacte.idformapagotipos,unpagoctacte.monto,centro());
   */


     -- Se asienta en pagos
    INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,pfechaemision,idpagostipos,idbanco,idlocalidad,idprovincia,nrooperacion,nrocuentabanco)
    VALUES(nextval('pagos_idpagos_seq'),unpago.centro,nrorecibo,unpagoctacte.idformapagotipos,unpago.conceptoPago,unpago.fechaingreso,unpago.fechaemision,unpago.idpagotipo,unpagoctacte.idbanco,unpago.idlocalidad,unpago.idprovincia,unpagoctacte.nrooperacion,unpagoctacte.nrocuentabanco);
    ridpago =currval('pagos_idpagos_seq');
    INSERT INTO pagosafiliado (idpagos,nrodoc,tipodoc) VALUES(ridpago,unpago.nrodoc,unpago.tipodoc);


     FETCH cursorpagos into unpagoctacte;
     END LOOP;
     close cursorpagos;


     /*Modifico los movimentos para que figuren como cancelados*/
     OPEN cursormovimientos;
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
            SELECT INTO rctactedeuda * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.iddeuda = unmovimiento.idmovimiento
                                                                 AND cuentacorrientedeuda.idcentrodeuda = unmovimiento.idcentro;

            idconceptodeuda = rctactedeuda.idconcepto;
             INSERT INTO cuentacorrientedeudapago (idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
            VALUES (movpago,centro(),unmovimiento.idmovimiento,unmovimiento.idcentro,CURRENT_TIMESTAMP, unmovimiento.importe);



            UPDATE cuentacorrientedeuda SET saldo =   round(CAST (rctactedeuda.saldo-  unmovimiento.importe AS numeric), 2)
WHERE cuentacorrientedeuda.iddeuda = unmovimiento.idmovimiento AND cuentacorrientedeuda.idcentrodeuda = unmovimiento.idcentro;
            /*Si se trata de un prestamo, asigno el idrecibo con que se pago la cuota - Si idcomprobantetipos = 7 se trata de una cuota de prestamo*/
            IF FOUND AND rctactedeuda.idcomprobantetipos = 7 THEN
                  UPDATE prestamocuotas SET idrecibo = nrorecibo
                                           , idcentrorecibo = unpago.centro
                                WHERE prestamocuotas.idprestamocuotas *10 + prestamocuotas.idcentroprestamocuota = rctactedeuda.idcomprobante;
            END IF;
           
            INSERT INTO pagoscuentacorriente (idmovimiento,idcentrodeuda,idcentropago,idpagos)
            VALUES (unmovimiento.idmovimiento,unmovimiento.idcentro,centro(),ridpago);
     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;

     UPDATE cuentacorrientepagos SET idconcepto = idconceptodeuda 
            WHERE idpago= movpago AND idcentropago=centro();
  


RETURN FALSE;
END;$function$
