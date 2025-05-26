CREATE OR REPLACE FUNCTION public.eliminarrecibo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       ptipocomprobante integer;
       pnrosucursal integer;
       pnrofactura bigint;
       ptipofactura varchar ;

       cur_recibo refcursor;
       cursordeudas REFCURSOR; --BelenA 10-04-24 agrego
       rec_recibo record;
       desimputar boolean; --BelenA 10-04-24 agrego

       elidajuste integer;
       ritemfacturaventa record;
    
       xpago record;
       xiddcd bigint;
       xiddeuda bigint;
       xidcentrodeuda integer;
       xctacte varchar;
       rusuario RECORD;
       resprecibo RECORD;
       rdeuda RECORD;   --BelenA 10-04-24 agrego
BEGIN
---cfar_ordenventaorden cur_recibo
--- rfar_ordenventaorden rec_recibo

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

CREATE TEMP TABLE tempconsumoasi (ctacte integer,idclientectacte bigint,idcentroclientectacte integer,    idconsumoasi  BIGINT, cafechamigracion TIMESTAMP, nrodoc VARCHAR(8), tipodoc INTEGER,  caimporte DOUBLE PRECISION,  signo INTEGER,  idcomprobantetipos INTEGER, caconcepto VARCHAR, idconcepto INTEGER, error BOOLEAN) ;

CREATE TEMP TABLE temppago(idpago bigint,idcentropago integer);
CREATE TEMP TABLE tempdeuda(iddeuda bigint,idcentrodeuda integer,apagar double precision);

-- BelenA 10-04-24 agrego para llamar al desimputar 
CREATE TEMP TABLE cuentacorrientedeudapagodesimputar (ccdpdobservacion varchar , iddeuda    bigint ,idcentrodeuda   integer, idpago bigint,idcentropago integer,                origenctacte varchar);

OPEN cur_recibo FOR
    SELECT * FROM temprecibo;
     FETCH cur_recibo into rec_recibo;
     WHILE FOUND LOOP

     ------ BelenA  verifico si puedo modificar el Recibo o si está dentro de una liquidacion de tarjeta.

    SELECT INTO resprecibo * FROM recibo_esposiblemodificarcomprobante(concat('{idrecibo=',rec_recibo.idrecibo,', centro=',rec_recibo.centro,'}')) as semodifica;

    IF( not nullvalue(resprecibo.semodifica) )THEN
                        --BelenA: El mensaje del RAISE ahora sera dependiendo del mensaje que te devuelve en el respiva. TK 6093
                        RAISE EXCEPTION '%',resprecibo.semodifica;
    ELSE
        -- Esto es para saber si tiene deuda imputada o no
        desimputar = false;
        
        -- BelenA 10-04-24 modifico toda la forma de desimputar si tiene deuda y ya no crea el movimiento nuevo en la ctacte del
        -- "Genera deuda por anulacion de recibo..."

        xctacte = 'afiliadoctacte';
        -- Busco si es un pago de un afiliado
        SELECT into xpago 1 as ctacte,* 
        FROM cuentacorrientepagos 
        WHERE idcomprobante=rec_recibo.idrecibo and idcentropago=rec_recibo.centro;

        IF FOUND THEN
            -- Busco si esta imputado a una deuda en la cuenta del afiliado
            open cursordeudas FOR
                SELECT iddeuda, idcentrodeuda, SUM(importeimp) AS importeimp
                FROM cuentacorrientepagos 
                NATURAL JOIN cuentacorrientedeudapago 
                WHERE idcomprobante=rec_recibo.idrecibo and idcentropago=rec_recibo.centro 
                GROUP BY iddeuda, idcentrodeuda ;

            fetch cursordeudas into rdeuda;
            WHILE FOUND LOOP
                   INSERT INTO cuentacorrientedeudapagodesimputar(ccdpdobservacion, iddeuda ,idcentrodeuda, origenctacte, idpago, idcentropago ) 
                   VALUES ( concat('Anulacion de Recibo ', xpago.movconcepto) ,rdeuda.iddeuda,rdeuda.idcentrodeuda,xctacte, xpago.idpago ,xpago.idcentropago);

                desimputar = true;
            fetch cursordeudas into rdeuda;
            END LOOP;
            close cursordeudas; 

        ELSE
            -- Si no es pago de afiliado, es de cliente/adherente
            xctacte = 'clientectacte';

            SELECT into xpago 2 as ctacte,* 
            FROM ctactepagocliente 
            WHERE idcomprobante=rec_recibo.idrecibo and idcentropago=rec_recibo.centro;

            -- Busco si esta imputado a una deuda en la cuenta del cliente
            open cursordeudas FOR
                SELECT  iddeuda, idcentrodeuda, SUM(importeimp) AS importeimp
                FROM ctactepagocliente 
                NATURAL JOIN ctactedeudapagocliente 
                WHERE idcomprobante=rec_recibo.idrecibo and idcentropago=rec_recibo.centro 
                GROUP BY iddeuda, idcentrodeuda ;

            fetch cursordeudas into rdeuda;
            WHILE FOUND LOOP
                   INSERT INTO cuentacorrientedeudapagodesimputar(ccdpdobservacion, iddeuda ,idcentrodeuda, origenctacte, idpago, idcentropago ) 
                   VALUES ( concat('Anulacion de Recibo ', xpago.movconcepto) ,rdeuda.iddeuda,rdeuda.idcentrodeuda,xctacte, xpago.idpago ,xpago.idcentropago);

                desimputar = true;
            fetch cursordeudas into rdeuda;
            END LOOP;
            close cursordeudas; 
        END IF;

            IF (desimputar) THEN
                -- Llamo al SP que va a desimputar los movimientos
                PERFORM tesoreria_desimputar_cuentascorrientes();
            END IF;

            INSERT INTO temppago(idpago,idcentropago) values(xpago.idpago,xpago.idcentropago);
            
            -- VAS 180823 SELECT into xiddcd eliminarrecibo_crearconsumoasi();
            DELETE FROM tempconsumoasi;

            xiddeuda = xiddcd/100;
            xidcentrodeuda= xiddcd%100;    

            INSERT INTO tempdeuda(iddeuda,idcentrodeuda,apagar) values(xiddeuda,xidcentrodeuda,abs(xpago.importe));

            --Marco como ANULADO el Recibo
            UPDATE recibo set reanulado=now(),idusuarioreanulado=rusuario.idusuario WHERE idrecibo=rec_recibo.idrecibo and centro=rec_recibo.centro;    

            -- Pongo el pago en 0 tanto importe como saldo y le concateno la anulacion
            IF ( xpago.ctacte = 1) THEN
            -- 1  xctacte = 'afiliadoctacte';
                UPDATE cuentacorrientepagos
                SET importe=0 , saldo=0, movconcepto=concat('Anulacion de Recibo - ', xpago.movconcepto)
                WHERE idpago=xpago.idpago AND idcentropago=xpago.idcentropago;

            ELSE
            -- 2  xctacte = 'clientectacte';
                UPDATE ctactepagocliente
                SET importe=0 , saldo=0, movconcepto=concat('Anulacion de Recibo - ', xpago.movconcepto)
                WHERE idpago=xpago.idpago AND idcentropago=xpago.idcentropago;

            END IF;

            -- Revierto el asientogenerico de la cobranza
            perform asientogenerico_revertir(idasientogenerico*100+idcentroasientogenerico) FROM asientogenerico WHERE idcomprobantesiges=concat(rec_recibo.idrecibo,'|',rec_recibo.centro) and idasientogenericocomprobtipo=8;

            -- Revierto los asientosgenericos de las imputaciones
            /*** -- VAS 110822 : esto se revierte en el triger que se dispara en cuentacorrientedeudpago 
            -- perform asientogenerico_revertir(idasientogenerico*100+idcentroasientogenerico) FROM asientogenerico WHERE idcomprobantesiges ilike concat('%|',xpago.idpago,'|',xpago.idcentropago) and idasientogenericocomprobtipo=9;
           *******/
    -- KR 24-11-21
    -- tkt 4661 si dicen ok a eliminar un recibo de una caja que ya fue controlada, entonces descomentar
            DELETE FROM controlcajarecibo WHERE idrecibo= rec_recibo.idrecibo and centro =rec_recibo.centro;

    END IF;

    FETCH cur_recibo into rec_recibo;

    END LOOP;

   
return 'true';
END;

$function$
