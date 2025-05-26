CREATE OR REPLACE FUNCTION public.buscarreciboscobranza(character varying, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
--VARIABLES
  buscardeuda CHARACTER VARYING; 
--CURSORES
    cursorrecibo refcursor;
--REGISTROS
    regreccob RECORD;	
BEGIN

--CREATE TEMP TABLE temprecibocobranza (   idrecibo INTEGER NOT NULL,  centro INTEGER NOT NULL,  monto FLOAT  ) WITHOUT OIDS;

IF ($4 ILIKE 'asistencial') THEN 
    buscardeuda = '
                (SELECT facturaorden.nroorden*100+facturaorden.centro as idcomprobante,facturaorden.idcomprobantetipos as idcomprobantetipos
                FROM facturaorden 
                UNION
                SELECT (idfacturareciprocidadinfo *100 + idcentrofacturareciprocidadinfo)as idcomprobante, 31 as idcomprobantetipos
                FROM facturareciprocidadinfo
               ) as facturacion' ;

ELSE 
    buscardeuda = '(SELECT
                   CASE WHEN  idinformefacturaciontipo=3 THEN pc.idprestamocuotas*10+pc.idcentroprestamo
                   ELSE informefacturacion.nroinforme * 100 +informefacturacion.idcentroinformefacturacion
                   END  as idcomprobante, 
                   CASE WHEN  idinformefacturaciontipo=2 THEN 21
                   ELSE CASE WHEN  idinformefacturaciontipo=3 THEN 7
                   ELSE CASE WHEN  idinformefacturaciontipo=11 THEN 21 END END END as idcomprobantetipos
                   FROM informefacturacion
                   LEFT JOIN (SELECT pc.*, informefacturacionturismo.* FROM informefacturacionturismo NATURAL JOIN consumoturismo  
                             NATURAL JOIN  prestamo JOIN prestamocuotas as pc USING(idprestamo,idcentroprestamo)
                             ) AS pc USING (nroinforme, idcentroinformefacturacion)
                   WHERE not nullvalue(informefacturacion.nrofactura) 
                   ) as facturacion ';

END IF; 

for regreccob IN EXECUTE concat('SELECT DISTINCT recibo.idrecibo, recibo.centro, recibo.importerecibo
           FROM ', buscardeuda , '
           
           JOIN cuentacorrientedeuda as ccd  USING(idcomprobante,  idcomprobantetipos  )
           JOIN cuentacorrientedeudapago  USING (iddeuda, idcentrodeuda)
           JOIN cuentacorrientepagos as ccp USING (idpago, idcentropago)
           JOIN  recibo ON(ccp.idcomprobante= recibo.idrecibo AND ccp.idcentropago=recibo.centro)
           JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
           LEFT JOIN (SELECT * FROM recibocupon
                               NATURAL JOIN valorescaja
                     ) as temppagorecibo    ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
           LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)

           WHERE nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago) AND 
                recibo.fecharecibo::date >=',$1,'
                 AND recibo.fecharecibo::date <=',$2,'
                 AND ccp.idcentropago=',$3,'
           ') LOOP
       INSERT INTO temprecibocobranza (idrecibo, centro, monto,seleccionado) VALUES
              (regreccob.idrecibo, regreccob.centro, regreccob.importerecibo, false);
    


 END LOOP;

return true;
END;
$function$
