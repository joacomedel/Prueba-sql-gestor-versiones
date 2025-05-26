CREATE OR REPLACE FUNCTION public.reimputarctactecliente()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
	regpago  RECORD;
        rusuario RECORD;
	regdeuda RECORD;
        rpagocancelado RECORD;
       
--CURSOR
  	ctempcomprobante refcursor;
	
--VARIABLES
        nuevosaldodeuda double precision ;
        nuevosaldopago double precision ;
	elmontoimputar double precision;
  	respuesta boolean;
        pidimputacion bigint;
resp_modaporte character varying;
  	
BEGIN
     -- Traigo la info del pago a imputar

     select into regpago * from temppago natural join ctactepagocliente ORDER BY idpago;
     nuevosaldopago = regpago.saldo;

  /* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF NOT FOUND THEN
                     rusuario.idusuario = 25;
   
    END IF;



     pidimputacion = nextval('ctactedeudapagocliente_idimputacion_seq'); 

     OPEN ctempcomprobante FOR
          -- Traigo la informacion de las deudas a imputar
        
          SELECT * FROM tempdeuda natural join ctactedeudacliente order by iddeuda;

     FETCH ctempcomprobante into regdeuda;
     WHILE FOUND LOOP

           elmontoimputar = 0;
        /*   if (abs(nuevosaldopago) >= abs(regdeuda.saldo)) then
              elmontoimputar = abs(regdeuda.saldo);
           else
               elmontoimputar = abs(nuevosaldopago);
           end if;
*/
           if (abs(nuevosaldopago) >= abs(regdeuda.apagar)) then
              elmontoimputar =  round(abs(regdeuda.apagar)::numeric,3);  
           else
               elmontoimputar =  round(abs(nuevosaldopago)::numeric,3);  
           end if;
           nuevosaldopago =   round((nuevosaldopago + elmontoimputar)::numeric,3);
 
--KR 19-01-22 EL nuevo saldo de la deuda es siempre el saldo menos el importe que se imputa. 
   /*        nuevosaldodeuda = case when elmontoimputar=0.000 then elmontoimputar else round((regdeuda.saldo - regdeuda.apagar)::numeric,3) end ;
*/         nuevosaldodeuda= CASE WHEN elmontoimputar>regdeuda.saldo THEN 0 ELSE round((regdeuda.saldo - elmontoimputar)::numeric,3) end;
           -- vincula la deuda con el pago
           INSERT INTO ctactedeudapagocliente(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idimputacion,idusuario)
           VALUES(regpago.idpago,regdeuda.iddeuda,regdeuda.idcentrodeuda,regpago.idcentropago,elmontoimputar,pidimputacion,rusuario.idusuario);

           -- Actualizo el saldo de la deuda
           UPDATE ctactedeudacliente SET saldo = round(nuevosaldodeuda::numeric, 3)
           WHERE iddeuda=regdeuda.iddeuda and idcentrodeuda =regdeuda.idcentrodeuda;

---- VAS270923 corroboro si se trata de una deuda correspondiente a un pago de aporte
           IF(regdeuda.idcomprobantetipos=21) THEN
                 SELECT INTO resp_modaporte modificarestadoaporte(concat('{iddeuda=',regdeuda.iddeuda, ' , idcentrodeuda=',regdeuda.idcentrodeuda,'} '));

---- VAS270923 corroboro si se trata de una deuda correspondiente a un pago de aporte
           END IF; 

           FETCH ctempcomprobante into regdeuda;
     END LOOP;
     close ctempcomprobante;

     -- Actualizo el saldo del pago
--Verifico si el pago se trata de un recibo anulado, si es asi el saldo del pago es 0
     SELECT INTO rpagocancelado * FROM ctactepagocliente  JOIN recibo ON idcomprobante = idpago AND idcentropago = centro 
             WHERE idpago=regpago.idpago and idcentropago =regpago.idcentropago;
     IF (rpagocancelado.reanulado IS not null) THEN 
         UPDATE ctactepagocliente SET saldo = 0
        ---round(nuevosaldopago::numeric, 3)
           WHERE idpago=regpago.idpago and idcentropago =regpago.idcentropago;
     ELSE 
          UPDATE ctactepagocliente SET saldo = round(nuevosaldopago::numeric, 3)
           WHERE idpago=regpago.idpago and idcentropago =regpago.idcentropago;
     END IF; 

     respuesta =true;

RETURN respuesta;

END;$function$
