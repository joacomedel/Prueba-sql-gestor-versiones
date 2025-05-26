CREATE OR REPLACE FUNCTION public.cambiarestadominutamarcarcomprobante()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Ya se han sincronizado las minutas cargadas en la temporal "tempminutas" con Multivac, ahora cambio el estado de cada minuta sincronizada a "sincronizada" y marco cada debito relacionado con cada minuta. 
*/
DECLARE
	cursorminuta CURSOR FOR SELECT * FROM tempminutas;
	regminuta RECORD;
        resultado BOOLEAN;


BEGIN

  --Creo la tabla donde guardo los comprobantes que debo marcar
  
CREATE TEMP TABLE comprobantedebitominuta (
             tipocomprobante INTEGER,
             nrosucursal INTEGER,
             nrofactura BIGINT,
             tipofactura VARCHAR            
 ) WITHOUT OIDS;


OPEN cursorminuta;
FETCH cursorminuta into regminuta;
     WHILE  found LOOP
/*
            INSERT INTO cambioestadoordenpago(fechacambio,nroordenpago,idtipoestadoordenpago,motivo)
            VALUES(now(),regminuta.nroordenpago,5,'Modificada al ser sincronizada con Multivac correctamente. ');
*/
            INSERT INTO cambioestadoordenpago(fechacambio,nroordenpago,idcentroordenpago,idtipoestadoordenpago,motivo)
            VALUES(now(),regminuta.nroordenpago/100,mod(regminuta.nroordenpago,100),regminuta.idtipoestadoordenpago,regminuta.observacion);

            if not nullvalue(regminuta.observacion) then
                        INSERT INTO ordenpagomultivacdatospago(fechaoperacion,observaciones,nroopsiges,nroordenpago,idcentroordenpago,nrooperacion)
                        VALUES (now(), regminuta.observacion,regminuta.nroordenpago,regminuta.nroordenpago/100,mod(regminuta.nroordenpago,100),0);
            end if;
	
--Busco los comprobantes asociados a la minuta de pago 
           INSERT INTO comprobantedebitominuta(tipocomprobante,nrofactura,nrosucursal,tipofactura)       

            (SELECT facturaventa.tipocomprobante,facturaventa.nrofactura,facturaventa.nrosucursal,facturaventa.tipofactura 
            FROM factura NATURAL JOIN debitofacturaprestador NATURAL JOIN informefacturacionnotadebito JOIN informefacturacion         
            ON(informefacturacion.nroinforme= informefacturacionnotadebito.nroinforme AND  informefacturacion.idcentroinformefacturacion=informefacturacionnotadebito.idcentroinformefacturacion) 
           JOIN informefacturacionestado ON(informefacturacion.nroinforme= informefacturacionestado.nroinforme 
           AND informefacturacion.idcentroinformefacturacion= informefacturacionestado.idcentroinformefacturacion) 
           JOIN facturaventa ON(facturaventa.nrosucursal=informefacturacion.nrosucursal AND          facturaventa.nrofactura=informefacturacion.nrofactura 
           AND facturaventa.tipocomprobante=informefacturacion.tipocomprobante AND
           facturaventa.tipofactura=informefacturacion.tipofactura)
           WHERE factura.nroordenpago=regminuta.nroordenpago/100 and factura.idcentroordenpago=mod(regminuta.nroordenpago,100) and nullvalue(facturaventa.anulada) and  informefacturacionestado.idinformefacturacionestadotipo=4 AND nullvalue(fechafin) AND factura.idtipocomprobante=1
GROUP BY facturaventa.tipocomprobante,facturaventa.nrofactura, facturaventa.nrosucursal, facturaventa.tipofactura);

     FETCH cursorminuta into regminuta;
     END LOOP;
CLOSE cursorminuta;


     --Llamo al sp que dados los debitos de la minuta correspondiente, llamara por cada debito al sp que migra
     -- Esto lo comento, porque la migración de las NDebito se ejecuta en otro proceso, anterior a la migración de las minutas
     -- Cristian, 06/12/2012
--     SELECT INTO resultado * FROM marcarDebitoMinuta();

DROP TABLE comprobantedebitominuta;
return true;
end;
$function$
