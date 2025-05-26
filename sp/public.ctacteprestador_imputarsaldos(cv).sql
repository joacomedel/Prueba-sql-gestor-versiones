CREATE OR REPLACE FUNCTION public.ctacteprestador_imputarsaldos(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Este SP se utiliza para crear movimientos manuales en la cuenta correiente de los prestadores.
   La finalidad es compensar las deudas y los pagos que se encuentren con saldo a una determinada fecha
 */
DECLARE
       rfiltros record;
       elidprestadorctacte bigint;
       
       cdeudaprestador refcursor;
       rdeuda record;
       eliddeuda bigint;
       
       elidimputacion  bigint;
       
       cpagoprestador refcursor;
       rpago record;
       elidpago bigint;
       elidusuario integer;
BEGIN
      
    --  RAISE NOTICE 'En el sp ctacteprestador_imputarsaldos(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;
    
  
--KR 2019-08-03 GUARDO el usuario en ctactedeudapago 
        SELECT INTO elidusuario * FROM sys_dar_usuarioactual();

      -- 1 Busco el idctacte del prestador
      SELECT INTO elidprestadorctacte idprestadorctacte FROM prestadorctacte WHERE idprestador = rfiltros.idprestador;
  

      -- 2 Busco Informacion de las deudas de los prestadore y genero el pago que los compensa
      OPEN cdeudaprestador FOR SELECT *
      FROM ctactedeudaprestador
      WHERE idprestadorctacte = elidprestadorctacte
            and abs(saldo) > 0
            and fechamovimiento <= rfiltros.fechamovimiento;
      FETCH cdeudaprestador INTO rdeuda;
      IF FOUND THEN
            INSERT INTO ctactepagoprestador (
                   idprestadorctacte,idcomprobantetipos,idcomprobante,fechamovimiento,movconcepto,nrocuentac,importe,saldo,fechacomprobante
            )VALUES(rdeuda.idprestadorctacte,12,0619,rdeuda.fechamovimiento,'Movimiento compensacion deuda',rdeuda.nrocuentac,0,0,now());
            elidpago = currval('ctactepagoprestador_idpago_seq');
      END IF;
      WHILE FOUND LOOP
            -- actualizo el importe del pago generado
            UPDATE ctactepagoprestador SET importe = importe - rdeuda.saldo WHERE idcentropago = centro()  and  idpago = elidpago;
            
            elidimputacion  = nextval('ctactedeudapagoprestador_idimputacion_seq');
            INSERT INTO ctactedeudapagoprestador  (idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idusuario,idimputacion)
            VALUES (elidpago,rdeuda.iddeuda,rdeuda.idcentrodeuda,centro(),rdeuda.saldo,25,elidimputacion);

           -- actualizo el saldo de la deuda
            UPDATE ctactedeudaprestador SET saldo = saldo - rdeuda.saldo WHERE iddeuda = rdeuda.iddeuda and idcentrodeuda = rdeuda.idcentrodeuda;
           
            FETCH cdeudaprestador INTO rdeuda;
      END LOOP;

     -- 3 Busco Informacion de los pagos de los prestadore y genero la deuda que los compensa
      OPEN cpagoprestador FOR SELECT *
      FROM ctactepagoprestador
      WHERE idprestadorctacte = elidprestadorctacte
            and abs(saldo) > 0
            and fechamovimiento <= rfiltros.fechamovimiento;
      FETCH cpagoprestador INTO rpago;
      IF FOUND THEN
            INSERT INTO ctactedeudaprestador (idprestadorctacte,idcomprobantetipos,idcomprobante,fechamovimiento,movconcepto,nrocuentac,importe,saldo)
            VALUES(rpago.idprestadorctacte,12,0619,now(),'Movimiento compensacion pago',rpago.nrocuentac,0,0);
            eliddeuda = currval('ctactedeudaprestador_iddeuda_seq');
      END IF;
      WHILE FOUND LOOP
            -- actualizo el importe de la deuda generado
            UPDATE ctactedeudaprestador SET importe = importe + abs( rpago.saldo) WHERE idcentrodeuda = centro()  and  iddeuda = eliddeuda;

            elidimputacion  = nextval('ctactedeudapagoprestador_idimputacion_seq');
            INSERT INTO ctactedeudapagoprestador  (idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idusuario,idimputacion)
            VALUES (rpago.idpago,eliddeuda,centro(),centro(),rpago.saldo,elidusuario,elidimputacion);
            
            -- actualizo el saldo del pago 
            UPDATE ctactepagoprestador SET saldo = saldo - rpago.saldo WHERE idpago=rpago.idpago and idcentropago=rpago.idcentropago;
            FETCH cpagoprestador INTO rpago;
      END LOOP;


RETURN TRUE;
END;
$function$
