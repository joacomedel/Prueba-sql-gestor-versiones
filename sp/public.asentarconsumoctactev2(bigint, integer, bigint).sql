CREATE OR REPLACE FUNCTION public.asentarconsumoctactev2(bigint, integer, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
--	respuesta = boolean;
   nrocomprobante alias for $1;
   lugarcomprobante alias for $2;
   pnroorden alias for $3;

    cursorconsumo refcursor;
   

   nrocuentacontable VARCHAR;
   idcuentacorriente VARCHAR;
   nrodocumento VARCHAR;
   movimientoconcepto VARCHAR;

   fechamov  TIMESTAMP;
   signomovimiento INTEGER;
   idtipocuentacorriente INTEGER;
   comprobantemovimiento BIGINT;

--RECORD 
  relreintegro RECORD;
  recctacte RECORD;
  unconsumo RECORD;
  datoscuentacorriente RECORD;
  titureci RECORD;
  ordenanulada RECORD;
  movimietocancelar RECORD;
  reccancelado RECORD;
  recdeuda RECORD;
  recpago RECORD;
  recdeudapago RECORD;

BEGIN
/* cambio VAS 09-03-15 VAS para guardar quien realizo el conusmo en el movconcepto de la cta cte */
/* KR 9-11-15 se cambio para registrar en caso de anulacion de orden expendida, un movimiento a favor en la cta cte del afiliado, a traves de una NC Interna.
	Es decir, SIEMPRE se deja un saldo a favor. */
OPEN cursorconsumo FOR SELECT quienconsumio , unionrdenes.nroorden, unionrdenes.centro, unionrdenes.fechaemision, unionrdenes.tipo,
comprobantestipos.expendio,
				CASE
				    WHEN unionrdenes.oetdescripcion is null THEN importesorden.importe * 1::double precision
				    ELSE importesorden.importe * (- 1::double precision)
				END AS importe, importesorden.idformapagotipos, concat(to_char(formapagotipos.idformapagotipos, '99'::text) , ' - ' , formapagotipos.fpabreviatura::text)AS tformapago
, recibo.idrecibo, unionrdenes.oetdescripcion
				,persona.barra,consumo.nrodoc,consumo.tipodoc
			 FROM ( SELECT  1 as prioridad, orden.nroorden, orden.centro, orden.fechaemision, orden.tipo,orden.asi, NULL::"unknown" AS oetdescripcion
				   FROM orden
			UNION
				 SELECT  2 as prioridad, orden.nroorden, orden.centro, ordenestados.fechacambio AS fechaemision, orden.tipo, orden.asi, ordenestadotipos.oetdescripcion
				   FROM orden
			   NATURAL JOIN ordenestados
			  NATURAL JOIN ordenestadotipos
			) unionrdenes 
			NATURAL JOIN consumo
			NATURAL JOIN (SELECT persona.nrodoc,persona.tipodoc,persona.barra , concat(persona.apellido ,',' , persona.nombres) as quienconsumio FROM persona) as persona
			NATURAL JOIN ordenrecibo
			NATURAL JOIN recibo
			NATURAL JOIN importesorden
			NATURAL JOIN formapagotipos
                        JOIN comprobantestipos ON (unionrdenes.tipo= idcomprobantetipos)
		WHERE importesorden.idformapagotipos = 3  /*Forma de Pago cta cte*/
		AND recibo.idrecibo = nrocomprobante
		AND recibo.centro = lugarcomprobante
		AND (pnroorden is null OR importesorden.nroorden = pnroorden)
		AND NOT unionrdenes.asi
		ORDER BY  unionrdenes.fechaemision, prioridad;

	FETCH cursorconsumo into unconsumo;
	WHILE found LOOP
	IF unconsumo.expendio THEN
--KR 14-10-21 HOY la cuenta que se utiliza para asistencial es la 10321
       nrocuentacontable = '10321'; --Cta Cte Asistencial NQN
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
                   --idcuentacorriente = datoscuentacorriente.idctacte;
                   --idtipocuentacorriente = datoscuentacorriente.tipodoctitu;
                 /*   idcuentacorriente = to_number(datoscuentacorriente.nrodoctitu,'99999999')*10+datoscuentacorriente.tipodoctitu;*/
                   idcuentacorriente = concat(datoscuentacorriente.nrodoctitu,datoscuentacorriente.tipodoctitu);
                   idtipocuentacorriente = datoscuentacorriente.tipodoctitu;
                   nrodocumento = datoscuentacorriente.nrodoctitu;
                END IF;
            ELSE --Es un titular
            SELECT INTO datoscuentacorriente * FROM afilsosunc
                                               WHERE afilsosunc.barra = unconsumo.barra
                                                      AND afilsosunc.nrodoc =  unconsumo.nrodoc;
                IF FOUND THEN
                   --idcuentacorriente = datoscuentacorriente.idctacte;
                   --idtipocuentacorriente = datoscuentacorriente.tipodoc;
             /*      idcuentacorriente = to_number(datoscuentacorriente.nrodoc,'99999999')*10+datoscuentacorriente.tipodoc;*/
 idcuentacorriente = concat(datoscuentacorriente.nrodoc,datoscuentacorriente.tipodoc);
                
                   idtipocuentacorriente = datoscuentacorriente.tipodoc;
                 	nrodocumento = datoscuentacorriente.nrodoc;
                END IF;
            END IF; --titu.barra < 30
            END IF; --unconsumo.barra > 100
       END IF;

     IF unconsumo.oetdescripcion = 'Anulada' THEN
 --KR 09-04-19 MODIFICO, si es una orden de reintegro es un pago, por ende guardo en cuentacorrientepagos
        IF (unconsumo.tipo=55) THEN --es una orden de reintegro
          SELECT INTO recctacte ccp.*, ccdp.iddeuda, ccdp.idcentrodeuda FROM cuentacorrientepagos ccp LEFT JOIN cuentacorrientedeudapago ccdp USING(idpago, idcentropago)  
          WHERE ccp.idcomprobantetipos = unconsumo.tipo AND ccp.idcomprobante = comprobantemovimiento;
          IF (recctacte.iddeuda is null) THEN  --el pago no se imputo entonces puedo liberarlo (sigo mismo modelo de deudas)

             SELECT INTO relreintegro * FROM reintegroorden WHERE nroorden = unconsumo.nroorden AND centro = unconsumo.centro; 
          
             movimientoconcepto = concat('Cancelacion pago por Anulacion de Orden ' , to_char(unconsumo.nroorden,'00000000') , '-' , to_char(unconsumo.centro,'000'), ' correspondiente al reintegro ' ,relreintegro.nroreintegro,'-',relreintegro.anio,'-',
relreintegro.idcentroregional);
		
-- KR 05-06-19 al anularse un reintegro en cta cte no debe generar contabilidad, el tipo comprobante 61 (Anular orden reintegro) esta de esta manera configurado
               INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
			VALUES (61,idtipocuentacorriente,idcuentacorriente,current_date,movimientoconcepto,nrocuentacontable,unconsumo.importe,comprobantemovimiento,0,387,nrodocumento);

               INSERT INTO cuentacorrientedeudapago (idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp) 
                                                       VALUES(recctacte.idpago,currval('cuentacorrientedeuda_iddeuda_seq'::regclass),current_date,centro(),recctacte.idcentropago,abs(unconsumo.importe));
               UPDATE cuentacorrientepagos SET saldo = 0 WHERE idpago = recctacte.idpago AND idcentropago = recctacte.idcentropago;
            
          END IF;	
 
        ELSE 
         


        --Verifico que si ya existe un pago para esa deuda
		SELECT INTO reccancelado * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.idcomprobante = comprobantemovimiento
                                   AND cuentacorrientedeuda.idcomprobantetipos = unconsumo.tipo;
		IF FOUND THEN 		
	       -- Se verifica que no exista un movimiento de pago ya registrado
	          SELECT INTO recpago cuentacorrientepagos.* FROM cuentacorrientepagos                                        
                                         WHERE cuentacorrientepagos.idcomprobante = comprobantemovimiento
--KR 14-10-21 pongo 1 en idcomprobantetipos ya que cuando inserta lo hace con ese idcomprobantetipos 
                                         AND cuentacorrientepagos.idcomprobantetipos = 1;
	          IF NOT FOUND THEN
	             --Si el movimiento a favor no se genero en la cuenta corriente...lo registro
			-- El idcomprobantetipos = 1 Nota de Credito INTERNA
			               movimientoconcepto = concat('Nota Credito por Anulacion de Orden ' , to_char(unconsumo.nroorden,'00000000') , '-' , to_char(unconsumo.centro,'000'));
			               fechamov = CURRENT_TIMESTAMP;
			               INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
                           VALUES (1,idtipocuentacorriente,idcuentacorriente,fechamov,movimientoconcepto,nrocuentacontable,abs(unconsumo.importe)*-1,comprobantemovimiento,abs(unconsumo.importe)*-1,387,nrodocumento);
                          --Malapi 21/03/2016 Si la anulación se hace el mismo dia que la emision de la orden, genero el movimiento de imputacion
--KR 31-01-18 Solo libero el pago si la deuda tiene saldo
--MaLaPi 20-01-2020 Si la deuda que voy a anular se trata de una orden de tipo= 56 (On line) siempre imputo
                            IF  (fechamov::date = reccancelado.fechamovimiento :: date OR reccancelado.idcomprobantetipos = 56 ) AND (reccancelado.saldo >0) THEN
                                INSERT INTO cuentacorrientedeudapago (idpago,iddeuda,fechamovimientoimputacion,idcentrodeuda,idcentropago,importeimp) 
                                                       VALUES(currval('cuentacorrientepagos_idpago_seq'::regclass),reccancelado.iddeuda,current_date,reccancelado.idcentrodeuda,centro(),abs(unconsumo.importe));
                                UPDATE cuentacorrientedeuda SET saldo = 0 WHERE iddeuda = reccancelado.iddeuda AND idcentrodeuda = reccancelado.idcentrodeuda;
                                UPDATE cuentacorrientepagos SET saldo = 0 WHERE idpago = currval('cuentacorrientepagos_idpago_seq'::regclass) AND idcentropago = centro();
                            END IF;
		  END IF; 
		END IF;-- No esta resgistrada la deuda
      END IF;
     ELSE -- Hay que registra un expendio de orden no su anulacion

   --KR 09-04-19 MODIFICO, si es una orden de reintegro es un pago, por ende guardo en cuentacorrientepagos
      IF (unconsumo.tipo=55) THEN --es una orden de reintegro
          SELECT INTO relreintegro * FROM reintegroorden WHERE nroorden = unconsumo.nroorden AND centro = unconsumo.centro; 
          SELECT INTO recctacte * FROM cuentacorrientepagos WHERE cuentacorrientepagos.idcomprobantetipos = unconsumo.tipo
	   							AND cuentacorrientepagos.idcomprobante = comprobantemovimiento;
		IF NOT FOUND THEN
		   movimientoconcepto = concat('Reintegro: ' ,relreintegro.nroreintegro,'-',relreintegro.anio,'-',
relreintegro.idcentroregional, ' de orden: ',to_char(unconsumo.nroorden,'00000000') , '-' , to_char(unconsumo.centro,'000'),'. DNI: ', unconsumo.nrodoc,': ' , unconsumo.quienconsumio);
        	   INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte
,fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo,nrodoc)
	VALUES(unconsumo.tipo,idtipocuentacorriente,idcuentacorriente,unconsumo.fechaemision, movimientoconcepto, nrocuentacontable, 387,unconsumo.importe*-1,comprobantemovimiento, unconsumo.importe*-1,nrodocumento);

			
		END IF; --Ya esta registrado el pago para esa orden 

      ELSE 

	   SELECT INTO recdeuda * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.idcomprobantetipos = unconsumo.tipo
	   							AND cuentacorrientedeuda.idcomprobante = comprobantemovimiento;
		IF NOT FOUND THEN
			movimientoconcepto = concat('Pago Coseguro de Orden ' , to_char(unconsumo.nroorden,'00000000') , '-' , to_char(unconsumo.centro,'000'),'. DNI: ', unconsumo.nrodoc,': ' , unconsumo.quienconsumio);
			fechamov = unconsumo.fechaemision;
			INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
			VALUES (unconsumo.tipo,idtipocuentacorriente,idcuentacorriente,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.importe,comprobantemovimiento,unconsumo.importe,387,nrodocumento);
		END IF; --Ya esta registrada la deuda
      END IF;
     END IF;

--KR 13-03-19 MODIFICO PARA GUARDAR AHORA EN LA CABECERA DEL RECIBO EL NRODOC/BARRA
        UPDATE recibo SET renrocliente = unconsumo.nrodoc, rebarra = unconsumo.barra WHERE idrecibo = nrocomprobante AND centro = lugarcomprobante;
	FETCH cursorconsumo into unconsumo;
	END LOOP;
	close cursorconsumo;	

--respuesta = 'false';

return 'true';
END;
$function$
