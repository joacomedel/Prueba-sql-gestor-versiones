CREATE OR REPLACE FUNCTION public.recibircobroacuenta()
 RETURNS SETOF recibo
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta los pagos que se realizan por caja
de los pagos de la cuenta corriente. */
DECLARE
rusuario record;

       rrecibo public.recibo%rowtype;
--cursores
       cursormovimientos refcursor;
       --Las formas de pago del recibo, para insertarlos en importes recibos y recibocupon
       cursorpagos CURSOR FOR SELECT * FROM tempfacturaventacupon NATURAL JOIN valorescaja;

       cursorpagosformapago CURSOR FOR SELECT idformapagotipos,sum(monto) as importefpt
                            FROM tempfacturaventacupon
                            NATURAL JOIN valorescaja
                            GROUP BY idformapagotipos;
--registros
       unpagofp RECORD;
       runcobro RECORD;
       rrecibopago RECORD;
       rdatoscliente RECORD;
       rorigenctacte RECORD;
--variables
       nrorecibo bigint;
       vidpago bigint;
       vmovpago bigint;
       vimporteacobrar double precision;
       vimputacionrecibo varchar;
       movimientoconcepto varchar;

BEGIN

SELECT INTO vimporteacobrar sum(importeacobrar) FROM tempcobroacuenta;

SELECT INTO runcobro *,nroconcepto as idconcepto FROM tempcobroacuenta 
                       LEFT JOIN mapeocuentascontablesconcepto USING(nrocuentac);

--KR 31-10-22 tkt 5457
SELECT INTO vimputacionrecibo text_concatenar(concat('Ctas. involucradas ' , concepto))
                                   FROM tempcobroacuenta ;

--Se asienta la cabecera del recibo     

     SELECT INTO nrorecibo * FROM getidrecibocaja();
     INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,importeenletras,renrocliente,rebarra)
     VALUES (nrorecibo,vimporteacobrar,
      CASE WHEN nullvalue(runcobro.fecharecibo) THEN now() ELSE runcobro.fecharecibo::date END 
        ,vimputacionrecibo,centro(),convertinumeroalenguajenatural(vimporteacobrar::numeric),runcobro.nrodoc,runcobro.tipodoc);

   
     SELECT INTO rrecibo * FROM recibo WHERE idrecibo = nrorecibo AND centro = centro();

--inserto en importesrecibo tantas tupla como formas de pago existan, agrupadas x idformapagotipos
   movimientoconcepto = concat('Cobro a cuenta. ',vimputacionrecibo );
   
     OPEN cursorpagosformapago;
     FETCH cursorpagosformapago into unpagofp;
     WHILE  found LOOP
          INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
          VALUES (nrorecibo,unpagofp.idformapagotipos,unpagofp.importefpt,centro());
           -- Se asienta en pagos Dejo por defecto tipopago = 4, que es efectivo y creo que no se usa
           --Le coloco la nrocuentac de la deuda.
           INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,pfechaemision,idpagostipos,idbanco,idlocalidad,idprovincia,nrooperacion,nrocuentabanco,nrocuentac)
           VALUES(nextval('pagos_idpagos_seq'),centro(),nrorecibo,unpagofp.idformapagotipos,vimputacionrecibo,
   CASE WHEN nullvalue(runcobro.fecharecibo) THEN now() ELSE runcobro.fecharecibo::date END,
   CASE WHEN nullvalue(runcobro.fecharecibo) THEN now() ELSE runcobro.fecharecibo::date END,4,0,6,2,0,0,runcobro.nrocuentac);
           vidpago =currval('pagos_idpagos_seq');

          
	  
     FETCH cursorpagosformapago into unpagofp;
     END LOOP;
     close cursorpagosformapago;

--KR 23-08-22 verifico el origen del pago 
     CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
     INSERT INTO tempcliente(nrocliente,barra) VALUES(runcobro.nrodoc,runcobro.tipodoc);
     SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5) as clavecentropersonactacte 
		FROM (
		SELECT verifica_origen_ctacte() as origen 
		) as t;
	DROP TABLE tempcliente;

   INSERT INTO recibocobroacuenta(idrecibo,centro,idorigenrecibo)
     VALUES (nrorecibo,centro(),case when rorigenctacte.origentabla= 'clientectacte' then 2 else 1 end);


 
   -- Ingreso el pago en la cuenta corriente, el Idcomprobante = nrorecibo

   IF rorigenctacte.origentabla = 'clientectacte' THEN 
      vmovpago= nextval('ctactepagonoafil_idpago_seq');
    
      UPDATE pagos SET pconcepto = movimientoconcepto WHERE idpagos = vidpago AND centro = centro();
      UPDATE recibo SET imputacionrecibo = movimientoconcepto WHERE idrecibo = nrorecibo AND centro = centro();
   
     INSERT INTO ctactepagonoafil(idpago,idcentropago,idcomprobantetipos,tipodoc,idctacte
   ,fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo,nrodoc)
      VALUES(vmovpago,centro(),0,runcobro.tipodoc,concat(runcobro.nrodoc,runcobro.tipodoc),
   CASE WHEN nullvalue(runcobro.fecharecibo) THEN now() ELSE runcobro.fecharecibo::date END
  ,movimientoconcepto,runcobro.nrocuentac,runcobro.idconcepto,vimporteacobrar*-1,nrorecibo,vimporteacobrar*-1,runcobro.nrodoc);

     --KR 17-06-15 GUARDO los datos en las tablas de ctacte cliente
       SELECT INTO rdatoscliente *,concat(cuitini,cuitmedio,cuitfin) as elidctacte
       FROM cliente NATURAL JOIN clientectacte
       WHERE cliente.nrocliente=runcobro.nrodoc AND cliente.barra=runcobro.tipodoc;

       INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,
                   nrocuentac,importe,idcomprobante,saldo)
       VALUES(0,rdatoscliente.idclientectacte,rdatoscliente.idcentroclientectacte,now(),movimientoconcepto ,runcobro.nrocuentac
                     , vimporteacobrar*-1,nrorecibo, vimporteacobrar*-1);


    END IF;

    IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
        vmovpago = nextval('cuentacorrientepagos_idpago_seq');
	movimientoconcepto = vimputacionrecibo;
	INSERT INTO cuentacorrientepagos(idpago,idcentropago,idcomprobantetipos,tipodoc,idctacte
,fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo,nrodoc)
	VALUES(vmovpago,centro(),0,runcobro.tipodoc,concat(runcobro.nrodoc,runcobro.tipodoc),
   CASE WHEN nullvalue(runcobro.fecharecibo) THEN now() ELSE runcobro.fecharecibo::date END
  ,movimientoconcepto,runcobro.nrocuentac,runcobro.idconcepto,vimporteacobrar*-1,nrorecibo,vimporteacobrar*-1,runcobro.nrodoc);

    END IF;

/*Dani comento el 24112023 ya que no se deben generar recibos para prestadores, con lo cual no debe afectar la ctacte del prestador*/
 /*IF rorigenctacte.origentabla = 'prestadorctacte' THEN 
        vmovpago = nextval('ctactepagoprestador_idpago_seq');
	movimientoconcepto = vimputacionrecibo;
	INSERT INTO ctactepagoprestador(idpago,idcentropago,idcomprobantetipos,idprestadorctacte
,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo)
	VALUES(vmovpago,centro(),0,rorigenctacte.clavepersonactacte,
   CASE WHEN nullvalue(runcobro.fecharecibo) THEN now() ELSE runcobro.fecharecibo::date END
  ,movimientoconcepto,runcobro.nrocuentac,vimporteacobrar*-1,nrorecibo,vimporteacobrar*-1);

END IF;
*/

-- Ingreso los datos en recibocupon
   open cursorpagos;
   FETCH cursorpagos into rrecibopago;
      WHILE FOUND LOOP
            INSERT INTO recibocupon(idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon,idrecibo,centro)
            VALUES(rrecibopago.idvalorescaja, rrecibopago.autorizacion, rrecibopago.nrotarjeta,rrecibopago.monto,
             rrecibopago.cuotas, rrecibopago.nrocupon, nrorecibo, centro());


     FETCH cursorpagos into rrecibopago;
     END LOOP;
     close cursorpagos;

--CS 2018-12-27 esto se ejecutaba mas arriba
/* Se guarda la informacion del usuario que genero el comprobante */
  SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
  IF NOT FOUND THEN 
     rusuario.idusuario = 25;
  END IF;
    INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (nrorecibo,centro(),rusuario.idusuario) ;
-- --------------------------------------------------------------------------------------------------------

RETURN NEXT rrecibo;
END;$function$
