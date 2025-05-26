CREATE OR REPLACE FUNCTION public.ctactenoafilimputarnotadebito(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE


    regnotadebito record;
	elnroinforme integer;
	elidcentroinformefacturacion  integer;

  	regdeuda  RECORD;
	elidpago bigint;
	unafactura RECORD;
	importepago double precision ;
	cfactura refcursor;
	elidcentropago integer;
  	respuesta boolean;
	
	
BEGIN
     -- $1 elnroinforme  $2 elidcentroinformefacturacion
     elnroinforme = $1;  elidcentroinformefacturacion =$2;

     SELECT INTO regnotadebito
             DISTINCT nroregistro, anio,nrofactura,nrosucursal,desccomprobanteventa,tipofactura,importectacte as importe, idctacte,
              nrocliente , informefacturacion.barra
     FROM informefacturacion
     JOIN facturaventa USING(nrofactura,nrosucursal,tipocomprobante,tipofactura)
     JOIN ctacteprestador ON (facturaventa.nrodoc =ctacteprestador.idprestador  )
     JOIN tipocomprobanteventa ON (facturaventa.tipocomprobante = tipocomprobanteventa.idtipo)
     JOIN informefacturacionnotadebito USING (nroinforme,idcentroinformefacturacion)
     JOIN debitofacturaprestador USING (idcentrodebitofacturaprestador ,iddebitofacturaprestador)
     WHERE nroinforme = elnroinforme and idcentroinformefacturacion =elidcentroinformefacturacion;

    -- buscar la deuda que se genero en el ingreso de la factura con el nroregistro, anio,

     SELECT INTO regdeuda * FROM ctactedeudanoafil  WHERE idcomprobante = (regnotadebito.nroregistro*10000)+regnotadebito.anio and idcomprobantetipos = 49;
     IF FOUND THEN
              -- Ingreso el pago
              INSERT INTO ctactepagonoafil(idcomprobantetipos,idctacte,movconcepto,
                             nrocuentac,importe, idcomprobante, saldo, idconcepto, nrodoc ,tipodoc
                     )VALUES(49,regnotadebito.idctacte,concat('Generacion ND ',regnotadebito.desccomprobanteventa,' ',regnotadebito.nrofactura,'-',regnotadebito.nrosucursal),
                     555,regnotadebito.importe,
                     (elnroinforme*10)+elidcentroinformefacturacion,regnotadebito.importe,555,regnotadebito.nrocliente,regnotadebito.barra);

              elidpago = currval('ctactepagonoafil_idpago_seq');

              -- Imputo el pago a la deuda
              SELECT INTO respuesta * FROM ctactenoafilimputar(regdeuda.iddeuda,regdeuda.idcentrodeuda,elidpago,centro());
    END IF;

RETURN respuesta;
END;
$function$
