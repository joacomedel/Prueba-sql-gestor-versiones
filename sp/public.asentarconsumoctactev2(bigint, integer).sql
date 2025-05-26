CREATE OR REPLACE FUNCTION public.asentarconsumoctactev2(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
--	respuesta = boolean;
    cursorconsumo refcursor;
    unconsumo RECORD;
   datoscuentacorriente RECORD;
   titureci RECORD;
   ordenanulada RECORD;
   movimietocancelar RECORD;
   reccancelado RECORD;
   nrocomprobante alias for $1;
   lugarcomprobante alias for $2;
   nrocuentacontable VARCHAR;
   idcuentacorriente VARCHAR;
   nrodocumento VARCHAR;
   movimientoconcepto VARCHAR;

   fechamov  TIMESTAMP;
   signomovimiento INTEGER;
   idtipocuentacorriente INTEGER;
   comprobantemovimiento BIGINT;
BEGIN
OPEN cursorconsumo FOR SELECT DISTINCT ordenesdos.nroorden
                      , ordenesdos.centro
                      ,ordenesdos.importe
                      ,ordenesdos.nrodoc
                      ,ordenesdos.barra
                      ,ordenesdos.tipo
                      ,ordenesdos.idformapagotipos
                      ,ordenesdos.tformapago
                      ,ordenesdos.fechaemision
                      ,ordenesdos.oetdescripcion
                      FROM ordenesdos
                            WHERE idrecibo = $1
                            AND ordenesdos.centro = $2
                            AND idformapagotipos = 3
                      ORDER BY ordenesdos.fechaemision; /*Forma de Pago cta cte*/
	FETCH cursorconsumo into unconsumo;
	WHILE found LOOP
	
	IF (unconsumo.tipo = 2) -- Se trata de una orden valorizada
       OR (unconsumo.tipo = 3) -- Se trata de una orden de Internacion
       OR (unconsumo.tipo = 4) -- Se trata de una orden de Consulta
       THEN
       nrocuentacontable = '10311'; --Cta Cte Asistencial NQN
       IF unconsumo.importe >= 0 THEN signomovimiento = 1;
       ELSE signomovimiento = -1; END IF;
       comprobantemovimiento = unconsumo.nroorden * 100 + unconsumo.centro;
       IF unconsumo.barra >= 100 THEN --Corresponde a un afiliado por reciprocidad, corresponde que se imputa a la cta cte de la Obra social por reciprocidad
          IF  unconsumo.barra < 130 THEN --Corresponde a un afiliado de reciprocidad del benef, hay que buscar la barra del titu
             SELECT INTO titureci * FROM benefreci NATURAL JOIN persona WHERE benefreci.nrodoc = unconsumo.nrodoc AND persona.barra = unconsumo.barra;
             SELECT INTO datoscuentacorriente * FROM osreci WHERE osreci.barra = titureci.barratitu;
             IF FOUND THEN
                  idcuentacorriente = datoscuentacorriente.abreviatura;
                  idtipocuentacorriente = datoscuentacorriente.barra;
  	              nrodocumento = null;
             END IF;
          ELSE --Corresponde a un afiliado de reciprocidad titular
             SELECT INTO datoscuentacorriente * FROM osreci WHERE osreci.barra = unconsumo.barra;
             IF FOUND THEN
                  idcuentacorriente = datoscuentacorriente.abreviatura;
                  idtipocuentacorriente = datoscuentacorriente.barra;
	               nrodocumento = null;
             END IF;
          END IF;

       ELSE --Corresponde a un afiliado de Sosunc, corresponde que se imputa a la cta cte del afiliado
           IF unconsumo.barra < 30 THEN --Se trata de un Benef, la cta cte es del titular
               SELECT INTO datoscuentacorriente * FROM benefsosunc
                   JOIN afilsosunc ON (afilsosunc.nrodoc = benefsosunc.nrodoctitu
                                   AND afilsosunc.tipodoc = benefsosunc.tipodoctitu)
                   WHERE --benefsosunc.barra = unconsumo.barra AND
                   benefsosunc.nrodoc =  unconsumo.nrodoc;
                IF FOUND THEN
                   /*idcuentacorriente = datoscuentacorriente.idctacte;
                   idtipocuentacorriente = datoscuentacorriente.tipodoctitu;*/
                    idcuentacorriente = to_number(datoscuentacorriente.nrodoctitu,'99999999')*10+datoscuentacorriente.tipodoctitu;
                   idtipocuentacorriente = datoscuentacorriente.tipodoc;
                   nrodocumento = datoscuentacorriente.nrodoctitu;
                END IF;
            ELSE --Es un titular
            SELECT INTO datoscuentacorriente * FROM afilsosunc
                                               WHERE afilsosunc.barra = unconsumo.barra
                                                      AND afilsosunc.nrodoc =  unconsumo.nrodoc;
                IF FOUND THEN
                   /*idcuentacorriente = datoscuentacorriente.idctacte;
                   idtipocuentacorriente = datoscuentacorriente.tipodoc;*/
                   idcuentacorriente = to_number(datoscuentacorriente.nrodoc,'99999999')*10+datoscuentacorriente.tipodoc;
                   idtipocuentacorriente = datoscuentacorriente.tipodoc;
                 	nrodocumento = datoscuentacorriente.nrodoc;
                END IF;
            END IF; --titu.barra < 30
            END IF; --unconsumo.barra > 100
       END IF;

     IF unconsumo.oetdescripcion = 'Anulada' THEN

           movimientoconcepto = concat('Anulacion de Orden ' , to_char(unconsumo.nroorden,'00000000') , '-' , to_char(unconsumo.centro,'000'));
           fechamov = unconsumo.fechaemision;
           -- La anulacion es como ingresar un pago para la orden
           INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
           VALUES (unconsumo.tipo,idtipocuentacorriente,idcuentacorriente,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.importe,comprobantemovimiento,0,387,nrodocumento);
                  /*Si se trata de una anulacion, se debe registrar el movimiento que se esta cancelando*/
             SELECT INTO reccancelado * FROM cuentacorrientedeuda
                                      WHERE cuentacorrientedeuda.idcomprobante = comprobantemovimiento
                                      AND cuentacorrientedeuda.idcomprobantetipos = unconsumo.tipo;
            INSERT INTO cuentacorrientedeudapago(iddeuda,idcentrodeuda,idpago,idcentropago,fechamovimientoimputacion)
                   VALUES (reccancelado.iddeuda,reccancelado.idcentrodeuda,currval('cuentacorrientepagos_idpago_seq'),centro(),fechamov);
           UPDATE cuentacorrientedeuda SET saldo = 0 WHERE cuentacorrientedeuda.iddeuda = reccancelado.iddeuda
                                                     AND cuentacorrientedeuda.idcentrodeuda = reccancelado.idcentrodeuda;
       ELSE
           movimientoconcepto = concat('Pago Coseguro de Orden ' , to_char(unconsumo.nroorden,'00000000') , '-' , to_char(unconsumo.centro,'000'));
           fechamov = unconsumo.fechaemision;
           INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
           VALUES (unconsumo.tipo,idtipocuentacorriente,idcuentacorriente,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.importe,comprobantemovimiento,unconsumo.importe,387,nrodocumento);

     END IF;
    fetch cursorconsumo into unconsumo;
	
	END LOOP;
close cursorconsumo;	
--respuesta = 'false';

return 'true';
END;
$function$
