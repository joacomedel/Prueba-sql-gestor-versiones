CREATE OR REPLACE FUNCTION public.generarpagoctactepagonoafil_nd(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	facturas refcursor;
	unafactura RECORD;
	laordenpago bigint;
	cfactura refcursor;
	lafacturadeuda  RECORD;
	rdatospago  RECORD;
	importepagado double precision ;
	nuevosaldodeuda double precision ;
	importetotalopc double precision ;
	elidpago bigint;
	elnroinforme bigint;
	elidcentroinformefacturacion integer;
	resp boolean;
	
BEGIN
      --  Por parametro se recibe el N Informefacturacion que se esta registrando el pago
      SELECT INTO elnroinforme split_part($1, '-',1);
      SELECT INTO elidcentroinformefacturacion split_part($1, '-',2);
      
      -- busco la informacion neceria para almacenar el pago
      SELECT INTO rdatospago *
      FROM informefacturacion
      NATURAL JOIN informefacturacionnotadebito
      NATURAL JOIN cliente 
      JOIN ctacteprestador ON (idprestador= nrocliente )
      WHERE nroinforme=elnroinforme and idcentroinformefacturacion =elidcentroinformefacturacion ;

      

       -- Busco la info de las  facturas compra vinculadas a la ND
       OPEN cfactura FOR SELECT SUM(debitofacturaprestador.importe) as importe,nroregistro, anio,iddeuda ,idcentrodeuda
                     FROM debitofacturaprestador
                     NATURAL JOIN informefacturacionnotadebito
                     JOIN ctactedeudanoafil ON(ctactedeudanoafil.idcomprobante = ((debitofacturaprestador.nroregistro*10000 ) + debitofacturaprestador.anio ))
                     WHERE nroinforme = elnroinforme and  idcentroinformefacturacion =elidcentroinformefacturacion
                     group by nroregistro, anio,iddeuda ,idcentrodeuda;
     FETCH cfactura into lafacturadeuda;
     WHILE FOUND LOOP
          
            IF (lafacturadeuda.importe <>0) THEN
                      -- se registra el pago en la cuenta corriente
                      INSERT INTO ctactepagonoafil(idcomprobantetipos ,tipodoc,idctacte,movconcepto,
                             nrocuentac,importe, idcomprobante, saldo, idconcepto, nrodoc
                       )VALUES(54,600,rdatospago.idctacte,
                       'Generacion ND :'|| rdatospago.tipofactura||' '||rdatospago.tipocomprobante||' '||rdatospago.nrosucursal||'-'||rdatospago.nrofactura
                       ,555,lafacturadeuda.importe,
                       (elnroinforme*10)+elidcentroinformefacturacion,
                       lafacturadeuda.importe,555,rdatospago.idprestador);

                     elidpago = currval('ctactepagonoafil_idpago_seq');
                    SELECT INTO resp * FROM ctactenoafilimputar(lafacturadeuda.iddeuda,lafacturadeuda.idcentrodeuda,elidpago,centro());


              END IF;
              FETCH cfactura into lafacturadeuda;
      END LOOP;
      close cfactura;
RETURN true;
END;$function$
