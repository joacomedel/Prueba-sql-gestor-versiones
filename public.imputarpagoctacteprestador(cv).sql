CREATE OR REPLACE FUNCTION public.imputarpagoctacteprestador(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	regpago  RECORD;
	regdeuda RECORD;
	nuevosaldodeuda double precision ;
	nuevosaldopago double precision ;
	importeimput double precision ;
	difdeudapago double precision ;
	eliddeuda bigint;
	elidcentrodeuda  integer;
	elidpago bigint;
	elidcentropago integer;
	elmontopagado double precision;
	respuesta boolean;
	uncomprobante record;
	ctempcomprobante refcursor;
	ncreditos refcursor;
	unancredito record;
        opagoacuentas refcursor;
	unaopagoacuenta record;
	pidimputacion bigint;
	montopagadototal double precision;
	montoimputar double precision;
        elidusuario integer;
	
BEGIN
	pidimputacion = nextval('ctactedeudapagoprestador_idimputacion_seq');

	SELECT INTO elidpago split_part($1, '-',1);
	SELECT INTO elidcentropago split_part($1, '-',2);

--KR 2019-08-03 GUARDO el usuario en ctactedeudapago 
        SELECT INTO elidusuario * FROM sys_dar_usuarioactual();

-- CS 2018-06-01 //---------------------------------------------------
-- Para que tome el monto total de los valores y de esta forma se incluyan las OP a Cuenta parciales
--	SELECT into montopagadototal sum(ordenpagocontablereclibrofact.montopagado) FROM ctactepagoprestador as pago
--	join ordenpagocontable as opc on (pago.idcomprobante=opc.idordenpagocontable*10+opc.idcentroordenpagocontable and pago.idcomprobantetipos=40)
--	join ordenpagocontablereclibrofact using (idordenpagocontable,idcentroordenpagocontable)
--	join ctactedeudaprestador as ccdp on (ordenpagocontablereclibrofact.numeroregistro*10000+ordenpagocontablereclibrofact.anio=ccdp.idcomprobante)
--	where pago.idpago=elidpago and pago.idcentropago=elidcentropago;

SELECT into montopagadototal sum(popmonto) 
FROM ctactepagoprestador as pago
	join ordenpagocontable as opc on (pago.idcomprobante=opc.idordenpagocontable*10+opc.idcentroordenpagocontable and pago.idcomprobantetipos=40)
	join pagoordenpagocontable using (idordenpagocontable,idcentroordenpagocontable)
        where pago.idpago=elidpago and pago.idcentropago=elidcentropago;
------------------------------------------------------------------------

	select into regpago * from ctactepagoprestador where idpago=elidpago and idcentropago=elidcentropago;
	nuevosaldopago = regpago.saldo;     

	OPEN ctempcomprobante FOR
	-- Traigo la informacion de las facturas pagadas en la OPContable
	SELECT * FROM ctactepagoprestador as pago
	join ordenpagocontable as opc on (pago.idcomprobante=opc.idordenpagocontable*10+opc.idcentroordenpagocontable and pago.idcomprobantetipos=40)
	join ordenpagocontablereclibrofact using (idordenpagocontable,idcentroordenpagocontable)
	join ctactedeudaprestador as ccdp on (ordenpagocontablereclibrofact.numeroregistro*10000+ordenpagocontablereclibrofact.anio=ccdp.idcomprobante)

	/*               left join ctactepagoprestador as ccpp on (ordenpagocontablereclibrofact.numeroregistro*10000+ordenpagocontablereclibrofact.anio=ccdp.idcomprobante)*/
	where pago.idpago=elidpago and pago.idcentropago=elidcentropago;

	FETCH ctempcomprobante into uncomprobante;
	WHILE FOUND LOOP
		eliddeuda = uncomprobante.iddeuda;
		elidcentrodeuda = uncomprobante.idcentrodeuda;

		select into regdeuda * from ctactedeudaprestador where iddeuda = uncomprobante.iddeuda and idcentrodeuda=uncomprobante.idcentrodeuda;
		montoimputar = (uncomprobante.montopagado/montopagadototal)* regpago.importe;
		nuevosaldopago =  nuevosaldopago - montoimputar;
		nuevosaldodeuda = regdeuda.saldo + montoimputar;

		-- vincula la deuda con el pago
		INSERT INTO ctactedeudapagoprestador(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idimputacion,idusuario)
		VALUES(elidpago,eliddeuda,elidcentrodeuda,elidcentropago,abs(round(montoimputar::numeric,2)),pidimputacion,elidusuario);

		-- Actualizo el saldo de la deuda
		UPDATE ctactedeudaprestador SET saldo = round(nuevosaldodeuda::numeric,2)
		WHERE iddeuda=eliddeuda and idcentrodeuda =elidcentrodeuda;

		OPEN ncreditos FOR
		-- Traigo la informacion de las Notas de credito de la OPContable
		SELECT *,ccpp.idpago as idpagonc FROM ctactepagoprestador as pago
		join ordenpagocontable as opc on (pago.idcomprobante=opc.idordenpagocontable*10+opc.idcentroordenpagocontable and pago.idcomprobantetipos=40)
		join ordenpagocontablereclibrofact using (idordenpagocontable,idcentroordenpagocontable)
		join ctactepagoprestador as ccpp on (ordenpagocontablereclibrofact.numeroregistro*10000+ordenpagocontablereclibrofact.anio=ccpp.idcomprobante)
		where pago.idpago=elidpago and pago.idcentropago=elidcentropago;

		FETCH ncreditos into unancredito;
		WHILE FOUND LOOP
			montoimputar = (uncomprobante.montopagado/montopagadototal)* unancredito.montopagado;
			nuevosaldodeuda = nuevosaldodeuda + montoimputar;

			-- vincula la deuda con el pago
			INSERT INTO ctactedeudapagoprestador(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idimputacion, idusuario)           VALUES(unancredito.idpagonc,eliddeuda,elidcentrodeuda,unancredito.idcentropago,abs(round(montoimputar::numeric,2)),pidimputacion, elidusuario);

			-- Actualizo el saldo del pago (de la ncredito)
			UPDATE ctactepagoprestador SET saldo = round((saldo - montoimputar)::numeric,2)
			WHERE idpago=unancredito.idpagonc and idcentropago =unancredito.idcentropago;
		FETCH ncreditos into unancredito;
		END LOOP;
		close ncreditos;



                OPEN opagoacuentas FOR
		-- Traigo la informacion de las Ordenes de Pago a Cuenta de la OPContable
/*
		SELECT *,ccpp.idpago as idpagonc FROM ctactepagoprestador as pago
		join ordenpagocontable as opc on (pago.idcomprobante=opc.idordenpagocontable*10+opc.idcentroordenpagocontable and pago.idcomprobantetipos=40)
		join ordenpagocontablereclibrofact using (idordenpagocontable,idcentroordenpagocontable)
		join ctactepagoprestador as ccpp on (ordenpagocontablereclibrofact.numeroregistro*10+ordenpagocontablereclibrofact.anio=ccpp.idcomprobante)
		where pago.idpago=elidpago and pago.idcentropago=elidcentropago;
*/
--CS 2017-03-30

        SELECT ordenpagocontableacuenta.montopagado,ccpp.idpago as idpagonc,ccpp.idcentropago
        FROM ctactepagoprestador as pago
		join ordenpagocontable as opc on (pago.idcomprobante=opc.idordenpagocontable*10+opc.idcentroordenpagocontable and pago.idcomprobantetipos=40)
		join ordenpagocontableacuenta using (idordenpagocontable,idcentroordenpagocontable)
		join ctactepagoprestador as ccpp on (ordenpagocontableacuenta.idordenpagocontableacuenta*10+ordenpagocontableacuenta.idcentroordenpagocontableacuenta=ccpp.idcomprobante)
        where pago.idpago=elidpago and pago.idcentropago=elidcentropago;

		FETCH opagoacuentas into unaopagoacuenta;
		WHILE FOUND LOOP
			montoimputar = (uncomprobante.montopagado/montopagadototal)* unaopagoacuenta.montopagado;
		    nuevosaldodeuda = nuevosaldodeuda + montoimputar;
            IF (montoimputar > 1 ) THEN
	     		-- vincula la deuda con el pago
      			INSERT INTO ctactedeudapagoprestador(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idimputacion,idusuario)           VALUES(unaopagoacuenta.idpagonc,eliddeuda,elidcentrodeuda,unaopagoacuenta.idcentropago,abs(round((montoimputar)::numeric,2)),pidimputacion,elidusuario);

         		-- Actualizo el saldo del pago (de la ncredito)
		     	UPDATE ctactepagoprestador SET saldo = round((saldo - montoimputar)::numeric,2)
			    WHERE idpago=unaopagoacuenta.idpagonc and idcentropago =unaopagoacuenta.idcentropago;
             END IF;
		FETCH opagoacuentas into unaopagoacuenta;
		END LOOP;
		close opagoacuentas;
		-- Actualizo el saldo de la deuda
		UPDATE ctactedeudaprestador SET saldo = round((nuevosaldodeuda)::numeric,2)
		WHERE iddeuda=eliddeuda and idcentrodeuda =elidcentrodeuda;
	FETCH ctempcomprobante into uncomprobante;
	END LOOP;
	close ctempcomprobante;

	-- Actualizo el saldo del pago
	UPDATE ctactepagoprestador SET saldo =round((nuevosaldopago)::numeric,2)
	WHERE idpago=elidpago and idcentropago =elidcentropago;
	respuesta =true;

RETURN respuesta;
END;
$function$
