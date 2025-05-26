CREATE OR REPLACE FUNCTION public.reimputarcuentacorriente()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

--RECORD
	regpago  RECORD;
        rusuario RECORD;
	regdeuda RECORD;
       
--CURSOR
  	ctempcomprobante refcursor;
	
--VARIABLES
        nuevosaldodeuda double precision ;
        nuevosaldopago double precision ;
	elmontoimputar double precision;
  	respuesta boolean;
        pidimputacion bigint;
  	
BEGIN
     -- Traigo la info del pago a imputar

     select into regpago * from temppago natural join cuentacorrientepagos;
     nuevosaldopago = regpago.saldo;

  /* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF NOT FOUND THEN
                     rusuario.idusuario = 25;
   
    END IF;



--     pidimputacion = nextval('ctactedeudapagocliente_idimputacion_seq'); 

     OPEN ctempcomprobante FOR
          -- Traigo la informacion de las deudas a imputar
        
          SELECT * FROM tempdeuda natural join cuentacorrientedeuda;

     FETCH ctempcomprobante into regdeuda;
     WHILE FOUND LOOP

           elmontoimputar = 0;
       
           if (abs(nuevosaldopago) >= abs(regdeuda.apagar)) then
              elmontoimputar = abs(regdeuda.apagar);
           else
               elmontoimputar = abs(nuevosaldopago);
           end if;
           nuevosaldopago =   round((nuevosaldopago + elmontoimputar)::numeric,3);
     --      nuevosaldodeuda = round((regdeuda.saldo - elmontoimputar)::numeric,3);
           nuevosaldodeuda= CASE WHEN  round(elmontoimputar::numeric,3)>=round(regdeuda.saldo::numeric,3) THEN 0 ELSE round((regdeuda.saldo - elmontoimputar)::numeric,3) end;
          

           -- vincula la deuda con el pago
           INSERT INTO cuentacorrientedeudapago(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,fechamovimientoimputacion)
           VALUES(regpago.idpago,regdeuda.iddeuda,regdeuda.idcentrodeuda,regpago.idcentropago,elmontoimputar,CURRENT_TIMESTAMP);

           -- Actualizo el saldo de la deuda
           UPDATE cuentacorrientedeuda SET saldo = round(nuevosaldodeuda::numeric, 3)
           WHERE iddeuda=regdeuda.iddeuda and idcentrodeuda =regdeuda.idcentrodeuda;

           FETCH ctempcomprobante into regdeuda;
     END LOOP;
     close ctempcomprobante;

     -- Actualizo el saldo del pago
     --round(v numeric, s int)
--KR 19-12-22 EL pago debe quedar sin saldo ya que se anulo el recibo que le da origen, por ende no hay pago
     UPDATE cuentacorrientepagos SET saldo = 0
---round(nuevosaldopago::numeric, 3)
    WHERE idpago=regpago.idpago and idcentropago =regpago.idcentropago;

     respuesta = true;

RETURN respuesta;

END;

$function$
