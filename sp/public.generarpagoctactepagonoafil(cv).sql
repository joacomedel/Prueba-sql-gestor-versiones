CREATE OR REPLACE FUNCTION public.generarpagoctactepagonoafil(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	facturas refcursor;
	unafactura RECORD;
	
	laordenpago bigint;
	cfactura refcursor;
	lafacturadeuda  RECORD;
	rlaordenpagocontable  RECORD;
        rctacte RECORD;
	importepagado double precision ;
	nuevosaldodeuda double precision ;
	importetotalopc double precision ;
	elidpago bigint;
	elidordenpagocontable bigint;
	elidcentroordenpagocontable integer;
	resp boolean;
        fidctacte bigint;
        fidprestador bigint;
rta boolean;
	
BEGIN

rta = false;
      --  Por parametro se recibe el N OPC que se esta registrando el pago
      SELECT INTO elidordenpagocontable split_part($1, '-',1);
      SELECT INTO elidcentroordenpagocontable split_part($1, '-',2);
  

     -- Busco info de la orden de pago contable
     SELECT INTO rlaordenpagocontable * FROM ordenpagocontable WHERE idordenpagocontable = elidordenpagocontable and idcentroordenpagocontable = elidcentroordenpagocontable;
    
     importetotalopc = rlaordenpagocontable.opcmontototal;

     -- Busco la info de la CtaCte del prestador
     select into rctacte idctacte,idprestador
     from ctacteprestador
     natural join ordenpagocontable
     WHERE idordenpagocontable = elidordenpagocontable and idcentroordenpagocontable = elidcentroordenpagocontable;
     -- guardo los datos del pago en la cuenta corriente
     IF FOUND THEN
        fidctacte = rctacte.idctacte;
        fidprestador = rctacte.idprestador;
        INSERT INTO ctactepagonoafil(idcomprobantetipos ,tipodoc,idctacte,movconcepto,
                             nrocuentac,importe, idcomprobante, saldo, idconcepto, nrodoc
                      )VALUES(49,600,fidctacte,concat('Generacion OPC:',elidordenpagocontable,'-',elidcentroordenpagocontable),
                              555,(abs(importetotalopc)*-1),
                              (elidordenpagocontable*10)+elidcentroordenpagocontable,(-1 * abs(importetotalopc)),555,fidprestador);

          elidpago = currval('ctactepagonoafil_idpago_seq');
    END IF;
    IF(rlaordenpagocontable.idordenpagocontabletipo=0) THEN -- Se trata de una OPC de orden pago
                  -- Busco la info de las  facturas vinculadas a una OP
                  OPEN cfactura FOR SELECT *
                       FROM ordenpagocontable
                       NATURAL JOIN ordenpagocontableordenpago
                       JOIN factura USING (nroordenpago , idcentroordenpago)
                       JOIN ctactedeudanoafil ON(ctactedeudanoafil.idcomprobante = ((factura.nroregistro*10000 ) + factura.anio ))
                       JOIN ctacteprestador ON (ctacteprestador.idprestador = factura.idprestador)

                       WHERE idordenpagocontable = elidordenpagocontable
                             and idcentroordenpagocontable = elidcentroordenpagocontable
                             and idcomprobantetipos =49;
                       FETCH cfactura into lafacturadeuda;
     END IF;
     IF(rlaordenpagocontable.idordenpagocontabletipo=1) THEN -- Se trata de una OPC de facturas
                  -- Busco la info de las  facturas vinculadas a una OP
                  OPEN cfactura FOR SELECT *
                   FROM factura
                   JOIN ctactedeudanoafil ON(ctactedeudanoafil.idcomprobante = ((factura.nroregistro*10000 ) + factura.anio ))
                   JOIN ctacteprestador ON (ctacteprestador.idprestador = factura.idprestador)
                   JOIN ordenpagocontablereclibrofact on(factura.nroregistro=ordenpagocontablereclibrofact.numeroregistro)
                   WHERE ordenpagocontablereclibrofact.idordenpagocontable = elidordenpagocontable
                         and ordenpagocontablereclibrofact.idcentroordenpagocontable = elidcentroordenpagocontable
                         and idcomprobantetipos =49;
                   FETCH cfactura into lafacturadeuda;
                   if not found then
                     CLOSE cfactura;
                     OPEN cfactura FOR SELECT montopagado as fimportepagar,*
                     FROM reclibrofact
                     JOIN ctactedeudanoafil ON(ctactedeudanoafil.idcomprobante = ((reclibrofact.numeroregistro*10000 ) + reclibrofact.anio ))
                     JOIN ctacteprestador ON (ctacteprestador.idprestador = reclibrofact.idprestador)
                     JOIN ordenpagocontablereclibrofact on(reclibrofact.numeroregistro=ordenpagocontablereclibrofact.numeroregistro)
                     WHERE ordenpagocontablereclibrofact.idordenpagocontable = elidordenpagocontable
                         and ordenpagocontablereclibrofact.idcentroordenpagocontable = elidcentroordenpagocontable
                         and idcomprobantetipos =49;
                     FETCH cfactura into lafacturadeuda;
                   end if;
     END IF;
     WHILE FOUND LOOP
              -- actualizo el importe de la opc
             --importetotalopc = importetotalopc - lafacturadeuda.fimportepagar;

             -- Se paga de la factura el importe: fimportepagar obtenido en la auditoria
             importepagado = lafacturadeuda.fimportepagar;

             --IF (importepagado <>0) THEN
                      -- se registra el pago en la cuenta corriente


                     
                     SELECT INTO resp * FROM ctactenoafilimputarmanual(lafacturadeuda.iddeuda,lafacturadeuda.idcentrodeuda,elidpago,centro(),importepagado);
                     rta=true;
              --END IF;
              FETCH cfactura into lafacturadeuda;
      END LOOP;
      close cfactura;
RETURN rta;
END;
$function$
