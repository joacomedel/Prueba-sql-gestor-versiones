CREATE OR REPLACE FUNCTION public.generarpagoctactepagoprestador_ndeliminar(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
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
      /* Esto fue modificado por vas 31/08/2017*/
      -- Si no existen las temporales las creo
      IF NOT  iftableexistsparasp('tempdeuda') THEN
              CREATE TEMP TABLE tempdeuda (iddeuda  	bigint ,idcentrodeuda 	integer );
      END IF;
      IF NOT  iftableexistsparasp('temppago') THEN
	          CREATE TEMP TABLE temppago (idpago  	bigint ,idcentropago 	integer );
      END IF;

      --  Por parametro se recibe el N Informefacturacion que se esta registrando el pago
      SELECT INTO elnroinforme split_part($1, '-',1);
      SELECT INTO elidcentroinformefacturacion split_part($1, '-',2);

      -- busco la informacion neceria para almacenar el pago
      SELECT INTO rdatospago *
      FROM informefacturacion
      NATURAL JOIN informefacturacionnotadebito
      NATURAL JOIN cliente
      JOIN prestadorctacte ON (idprestador= nrocliente )
      WHERE nroinforme=elnroinforme and idcentroinformefacturacion =elidcentroinformefacturacion ;



       -- Busco la info de las  facturas compra vinculadas a la ND. Recordar que el debito puede corresponder a una factura que pertenece a un resumen
       -- Si la factura E a un resumen la deuda se busca con el nroregistro del resumen
       OPEN cfactura FOR SELECT SUM(T.importe) as importe,nroregistro, anio,iddeuda ,idcentrodeuda
                         FROM ctactedeudaprestador
                         JOIN (
                              SELECT debitofacturaprestador.importe
                                    ,CASE WHEN (nullvalue(comp.idresumen)) THEN -- no se trata de un comprobante que pertenece a un resumen
                                          comp.nroregistro
                                    ELSE   -- es un resumen
                                           comp.idresumen
                                    END  as nroregistro
                                    ,CASE WHEN (nullvalue(comp.idresumen)) THEN -- no se trata de un comprobante que pertenece a un resumen
                                          comp.anio
                                    ELSE   -- es un resumen
                                           comp.anioresumen
                                    END  as anio
                                    FROM debitofacturaprestador
                                    NATURAL JOIN informefacturacionnotadebito
                                    JOIN factura as comp  using (nroregistro,anio)
                                    WHERE  nroinforme = elnroinforme and  idcentroinformefacturacion =elidcentroinformefacturacion

                             )as T ON(ctactedeudaprestador.idcomprobante = ((T.nroregistro*10000 ) + T.anio ))
                          group by nroregistro, anio,iddeuda ,idcentrodeuda;

      FETCH cfactura into lafacturadeuda;

                      -- se registra el pago en la cuenta corriente
                     INSERT INTO ctactepagoprestador(idcomprobantetipos ,idprestadorctacte,movconcepto, nrocuentac,importe, idcomprobante, saldo )
                     VALUES ( 54,rdatospago.idprestadorctacte,  concat('Debito: ', rdatospago.tipofactura,' ',rdatospago.tipocomprobante,' ', rdatospago.nrosucursal,'-',rdatospago.nrofactura)
                       ,555,-1*lafacturadeuda.importe,(elnroinforme*10)+elidcentroinformefacturacion,-1*lafacturadeuda.importe);

                    elidpago = currval('ctactepagoprestador_idpago_seq');
                    INSERT INTO temppago (idpago ,idcentropago ) VALUES (elidpago, centro());

      WHILE FOUND LOOP

                    INSERT INTO tempdeuda(iddeuda ,idcentrodeuda ) VALUES (lafacturadeuda.iddeuda,lafacturadeuda.idcentrodeuda);
                    FETCH cfactura into lafacturadeuda;
      END LOOP;
      close cfactura;

SELECT INTO resp * FROM reimputarctacteprestador();

RETURN true;
END;
$function$
