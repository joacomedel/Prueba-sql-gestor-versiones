CREATE OR REPLACE FUNCTION public.asentarreciboctacte_sindeuda()
 RETURNS SETOF recibo
 LANGUAGE plpgsql
AS $function$/* Funcion que genera un recibo y lo registra en la cta.cte . */
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
       unmovimiento  RECORD;
respuesta  RECORD;
       unpago RECORD;
       unpagofp RECORD;
       pagoctacte RECORD;
       rctactedeuda RECORD;
       unpagoctacte RECORD;
       regri RECORD;
       runadeuda RECORD;
       rdeuda RECORD;	
       rrecibopago RECORD;
       rdatoscliente RECORD;
       rorigenctacte RECORD;
       rctactedeudacliente RECORD;
       rvalorescajacomercio RECORD;
       rescliente RECORD;	
--variables
       nrorecibo bigint;
       vidpago bigint;
       vidpagocliente bigint;
       vmovpago bigint;
       vmovpagocliente bigint;
       idconceptodeuda integer;
       vimporteapagar double precision;
       vimputacionrecibo varchar;
       --movimientoconcepto varchar;
	   vnrocuentac varchar;
	   vidconcepto integer;
       --vorigen varchar;
       vtipodoc INTEGER;
       vtotaldeuda DOUBLE PRECISION DEFAULT 0.0;

BEGIN

SELECT INTO vimporteapagar sum(monto) FROM tempfacturaventacupon 
									   NATURAL JOIN valorescaja;
									   


--MaLaPi 27-04-2022 La tabla de deuda viene con el nrodoc, tipodoc 
SELECT INTO rdeuda * FROM temppagodeuda LIMIT 1;
--997 Caja - puente cobranzas
vidconcepto = 997 ;
vimputacionrecibo = 'Recibo s/Deuda.';
--MaLaPi 19/03/2021 Si el proceso se llama desde Java en barra se pone la barra del afiliado, con lo que verifica_origen_ctacte() falla al buscar el origen, pues necesita el tipoddoc
SELECT INTO rescliente * FROM cliente WHERE nrocliente = rdeuda.nrodoc AND cliente.barra < 99 AND rdeuda.tipodoc > 29;
IF FOUND THEN 
vtipodoc = rescliente.barra;
vimputacionrecibo = concat(vimputacionrecibo,' ',rescliente.denominacion,' ');
ELSE

SELECT INTO rescliente * FROM cliente WHERE nrocliente = rdeuda.nrodoc;
vimputacionrecibo = concat(vimputacionrecibo,' ',rescliente.denominacion,' ');
vtipodoc = rdeuda.tipodoc;
END IF;
	--MaLaPi 12-12-2017 Verifico en que tabla deberian estar las deudas y pagos. 
	CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
	INSERT INTO tempcliente(nrocliente,barra) VALUES(rdeuda.nrodoc,vtipodoc);
	SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5) as clavecentropersonactacte 
		FROM (
		SELECT verifica_origen_ctacte() as origen 
		) as t;
	DROP TABLE tempcliente;

vimputacionrecibo = concat(vimputacionrecibo,' Origen:',rorigenctacte.origentabla,' ');
  --MaLapi 27-04-2022 Le coloco la nrocuentac 10201- Caja Puente Cobranda
 --KR 29-05-2022 Le coloco la nrocuentac 10202- Caja Puente Cobranza Cliente
vnrocuentac = 10202;

     SELECT INTO nrorecibo * FROM getidrecibocaja();
     INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,importeenletras)
     VALUES (nrorecibo,vimporteapagar,now(),vimputacionrecibo,centro(),convertinumeroalenguajenatural(vimporteapagar::numeric));

	 SELECT INTO rrecibo * FROM recibo WHERE idrecibo = nrorecibo AND centro = centro();

--inserto en importesrecibo tantas tupla como formas de pago existan, agrupadas x idformapagotipos

     OPEN cursorpagosformapago;
     FETCH cursorpagosformapago into unpagofp;
     WHILE  found LOOP
          INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
          VALUES (nrorecibo,unpagofp.idformapagotipos,unpagofp.importefpt,centro());
           -- Se asienta en pagos Dejo por defecto tipopago = 4, que es efectivo y creo que no se usa
         
           INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,pfechaemision,idpagostipos,idbanco,idlocalidad,idprovincia,nrooperacion,nrocuentabanco,nrocuentac)
           VALUES(nextval('pagos_idpagos_seq'),centro(),nrorecibo,unpagofp.idformapagotipos,vimputacionrecibo,now(),now(),4,0,6,2,0,0,vnrocuentac);
           vidpago =currval('pagos_idpagos_seq');

           IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
				INSERT INTO pagosafiliado(idpagos,nrodoc,tipodoc) 
                VALUES(vidpago,rdeuda.nrodoc,rdeuda.tipodoc);
	   	  END IF;
	  
     FETCH cursorpagosformapago into unpagofp;
     END LOOP;
     close cursorpagosformapago;

		IF rorigenctacte.origentabla = 'clientectacte' THEN 
				INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo) 
				VALUES(0,rorigenctacte.clavepersonactacte,rorigenctacte.clavecentropersonactacte::integer,now(),vimputacionrecibo,vnrocuentac,vimporteapagar*-1,nrorecibo,vimporteapagar*-1);
				vidpagocliente = currval('ctactepagocliente_idpago_seq'::regclass);
			ELSE
			    vmovpago= nextval('ctactepagonoafil_idpago_seq');
				INSERT INTO ctactepagonoafil(idpago,idcentropago,idcomprobantetipos,tipodoc,idctacte
				,fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo,nrodoc)
				VALUES(vmovpago,centro(),0,rdeuda.tipodoc,concat(rdeuda.nrodoc,rdeuda.tipodoc),now()
				,vimputacionrecibo,vnrocuentac,vidconcepto,vimporteapagar*-1,nrorecibo,vimporteapagar*-1,rdeuda.nrodoc);

			END IF;
      
IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
        vmovpago = nextval('cuentacorrientepagos_idpago_seq');
		--movimientoconcepto = vimputacionrecibo;
		INSERT INTO cuentacorrientepagos(idpago,idcentropago,idcomprobantetipos,tipodoc,idctacte
			,fechamovimiento,movconcepto,nrocuentac,idconcepto,importe,idcomprobante,saldo,nrodoc)
		VALUES(vmovpago,centro(),0,rdeuda.tipodoc,concat(rdeuda.nrodoc,rdeuda.tipodoc),now(),vimputacionrecibo
     	,vnrocuentac,vidconcepto,round((vimporteapagar*-1)::numeric,2),nrorecibo,round((vimporteapagar*-1)::numeric,2),rdeuda.nrodoc);
END IF;
-- Ingreso los datos en recibocupon
   open cursorpagos;
   FETCH cursorpagos into rrecibopago;
      WHILE FOUND LOOP
            INSERT INTO recibocupon(idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon,idrecibo,centro)
            VALUES(rrecibopago.idvalorescaja, rrecibopago.autorizacion, rrecibopago.nrotarjeta,rrecibopago.monto,
             rrecibopago.cuotas, rrecibopago.nrocupon, nrorecibo, centro());
             SELECT INTO rvalorescajacomercio * FROM valorescajacomercio 
                     WHERE valorescajacomercio.idvalorescaja = rrecibopago.idvalorescaja 
                       AND valorescajacomercio.idvalorescaja = 959 
                       LIMIT 1;
             IF FOUND THEN 
                    INSERT INTO recibocuponlote (idrecibocupon,idcentrorecibocupon,idposnet,nrocomercio,nrolote)
                    VALUES(CURRVAL('recibocupon_idrecibocupon_seq'::regclass),centro(),rvalorescajacomercio.idposnet,rvalorescajacomercio.nrocomercio,CURRVAL('recibocupon_idrecibocupon_seq'::regclass));
             END IF;

     FETCH cursorpagos into rrecibopago;
     END LOOP;
     close cursorpagos;

-- Esto estaba mas arriba, lo pongo acá porque hay un trigger que registra en asientogenerico
    INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (nrorecibo,centro(),sys_dar_usuarioactual());

RETURN NEXT rrecibo;
END;
$function$
