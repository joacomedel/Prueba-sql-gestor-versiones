CREATE OR REPLACE FUNCTION public.anularmovimientoctacteafiliado(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


--REGISTROS 
rmovasi RECORD;
rmovctacte RECORD;

--VARIABLES 
elidpago  bigint;

BEGIN
 SELECT INTO rmovasi * FROM consumoasiv2 WHERE caconcepto  ILIKE  concat('%', $1, '%') AND idcomprobantetipos =12;
   

/* KR 18-01-19 Si la minuta generó un movimiento en la cta cte del afiliado lo cancelo, verifico que sea un movimiento en la deuda, que es el uso que hoy se le está dando. Faltaría implementar la cancelación si el movimiento es en el pago - idcomprobantetipos=12 es migración ASI*/
 IF FOUND THEN 
     SELECT INTO rmovctacte * FROM cuentacorrientedeuda WHERE idcomprobante=rmovasi.idconsumoasi AND idcomprobantetipos =12;
     IF FOUND THEN 
        INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
	VALUES (rmovctacte.idcomprobantetipos,rmovctacte.tipodoc,rmovctacte.idctacte,now(),concat('Se genera un pago por la anulacion de MP que generó un movimiento en la deuda. Datos de la deuda: ', rmovctacte.movconcepto),rmovctacte.nrocuentac,rmovctacte.importe,rmovctacte.idcomprobante,0,rmovctacte.idconcepto,rmovctacte.nrodoc);

        elidpago = currval('cuentacorrientepagos_idpago_seq');
             
	INSERT INTO cuentacorrientedeudapago(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,fechamovimientoimputacion)
         VALUES(elidpago,rmovctacte.iddeuda,rmovctacte.idcentrodeuda,centro(),rmovctacte.importe,now());

           -- Actualizo el saldo de la deuda
        UPDATE cuentacorrientedeuda SET saldo = 0
        WHERE iddeuda=rmovctacte.iddeuda and idcentrodeuda =rmovctacte.idcentrodeuda;
     END IF; 
END IF; 
   





RETURN TRUE;


END;
    $function$
