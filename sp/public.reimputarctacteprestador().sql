CREATE OR REPLACE FUNCTION public.reimputarctacteprestador()
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
	elmontoimputar double precision;
  	respuesta boolean;
  	uncomprobante record;
  	ctempcomprobante refcursor;
	pidimputacion bigint;
	xnroregistro bigint;
	xanio integer;
	xidopc bigint;
	xidcopc integer;
        elidusuario integer;
	
BEGIN
	xnroregistro=0;
	xidopc=0;

     pidimputacion = nextval('ctactedeudapagoprestador_idimputacion_seq');

     -- Traigo la info del pago a imputar
     select into regpago * from temppago natural join ctactepagoprestador;
     nuevosaldopago = regpago.saldo;

     --KR 2019-08-03 GUARDO el usuario en ctactedeudapago 
        SELECT INTO elidusuario * FROM sys_dar_usuarioactual();


     OPEN ctempcomprobante FOR
          -- Traigo la informacion de las deudas a imputar
          SELECT * FROM tempdeuda natural join ctactedeudaprestador;

     FETCH ctempcomprobante into regdeuda;
     WHILE FOUND LOOP   

           elmontoimputar = 0;
           if (abs(nuevosaldopago) >= abs(regdeuda.saldo)) then
              elmontoimputar = abs(regdeuda.saldo);
           else
               elmontoimputar = abs(nuevosaldopago);
           end if;

           nuevosaldopago =  nuevosaldopago + elmontoimputar;
           nuevosaldodeuda = regdeuda.saldo - elmontoimputar;

           -- vincula la deuda con el pago
           INSERT INTO ctactedeudapagoprestador(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idimputacion, idusuario)
           VALUES(regpago.idpago,regdeuda.iddeuda,regdeuda.idcentrodeuda,regpago.idcentropago,elmontoimputar,pidimputacion,elidusuario);

-- CS 2018-11-13 Vincula la OPC con Reclibrofact
		if regpago.idcomprobantetipos=40 then
		   	xidopc = regpago.idcomprobante/10;
		   	xidcopc = regpago.idcomprobante%10;
     		end if;
		if regdeuda.idcomprobantetipos=49 then
		   	xnroregistro = regdeuda.idcomprobante/10000;
		   	xanio = regdeuda.idcomprobante%10000;
	   	end if;
		-- vincula la opc con reclibrofact
		if xidopc>0 and xnroregistro>0 then
			INSERT INTO ordenpagocontablereclibrofact(numeroregistro,anio,idordenpagocontable,idcentroordenpagocontable,montopagado)
			VALUES(xnroregistro,xanio,xidopc,xidcopc,elmontoimputar);
		end if;
------------------------------------------------

           -- Actualizo el saldo de la deuda
           UPDATE ctactedeudaprestador SET saldo = nuevosaldodeuda
           WHERE iddeuda=regdeuda.iddeuda and idcentrodeuda =regdeuda.idcentrodeuda;

           FETCH ctempcomprobante into regdeuda;
     END LOOP;
     close ctempcomprobante;

     -- Actualizo el saldo del pago
     UPDATE ctactepagoprestador SET saldo =nuevosaldopago
     WHERE idpago=regpago.idpago and idcentropago =regpago.idcentropago;
     --SELECT INTO respuesta * FROM imputarpagoctacteprestadorconcomprobantes(regpago.idpago,regpago.idcentropago);
     respuesta =true;

RETURN respuesta;

END;
$function$
