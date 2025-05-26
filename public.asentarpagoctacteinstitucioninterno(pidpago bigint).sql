CREATE OR REPLACE FUNCTION public.asentarpagoctacteinstitucioninterno(pidpago bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--parametros
       --pidpago alias for $1;
--Cursores
       cursorfacturas CURSOR FOR SELECT *
                                 FROM informefacturacion
                                 NATURAL JOIN (
                                     SELECT DISTINCT idcomprobante/100 as nroinforme,idcomprobante%100 as idcentroinformefacturacion,sum(importeapagar) as importeapagar
                                      FROM temppagodeuda
                                      NATURAL JOIN ctactedeudanoafil
                                      WHERE   temppagodeuda.origendeuda = 'noafiliado'
                                      GROUP BY idcomprobantetipos,idcomprobante
UNION   
SELECT DISTINCT idcomprobante/100 as nroinforme,idcomprobante%100 as idcentroinformefacturacion,sum(importeapagar) as importeapagar
                                      FROM temppagodeuda
                                      NATURAL JOIN ctactedeudacliente
                                      WHERE   temppagodeuda.origendeuda = 'noafiliado' and idcomprobantetipos=21
                                      GROUP BY idcomprobantetipos,idcomprobante

                                      UNION    
SELECT DISTINCT idcomprobante/100 as nroinforme,idcomprobante%100 as idcentroinformefacturacion,sum(importeapagar) as importeapagar
                                      FROM temppagodeuda
                                      JOIN cuentacorrientedeuda USING(iddeuda,idcentrodeuda)
                                      WHERE   temppagodeuda.origendeuda = 'afiliado'
                                      GROUP BY idcomprobantetipos,idcomprobante
                                      ) as informes;


--registros
       unafactura RECORD;
       pagofact RECORD;
       regmesinfo RECORD;
       recdeuda RECORD;
       rpagosinstitucion RECORD;
-- variables
       imptotal DOUBLE PRECISION;
       imppagado REAL;
       movimientoconcepto varchar;
       comprobantemovimiento BIGINT;


BEGIN

  movimientoconcepto = 'Pago del Informe de Facturacion: ';

 OPEN cursorfacturas;
     FETCH cursorfacturas into unafactura;
     WHILE  found LOOP

	SELECT INTO pagofact * FROM pagosfacturaventa
  	                      WHERE nroinforme=unafactura.nroinforme
                            AND idcentroinformefacturacion=unafactura.idcentroinformefacturacion
	                        AND nrofactura= unafactura.nrofactura AND tipocomprobante = unafactura.tipocomprobante
                            AND nrosucursal=unafactura.nrosucursal AND tipofactura=unafactura.tipofactura;

	IF FOUND THEN
		
	    UPDATE pagosfacturaventa SET importepagado=(unafactura.importeapagar + pagosfacturaventa.importepagado)
	    WHERE nroinforme=unafactura.nroinforme
              AND idcentroinformefacturacion=unafactura.idcentroinformefacturacion
              AND nrofactura= unafactura.nrofactura AND tipocomprobante = unafactura.tipocomprobante
              AND nrosucursal=unafactura.nrosucursal AND tipofactura=unafactura.tipofactura;

	ELSE
	      INSERT INTO pagosfacturaventa (idpagos,nrofactura,tipocomprobante,nrosucursal,tipofactura,importepagado,nroinforme,idcentroinformefacturacion)
          VALUES (pidpago,unafactura.nrofactura,unafactura.tipocomprobante,unafactura.nrosucursal,unafactura.tipofactura,unafactura.importeapagar,unafactura.nroinforme,unafactura.idcentroinformefacturacion);

	END IF;
	
	  SELECT INTO imptotal SUM(informefacturacionitem.importe)
                           FROM informefacturacionitem
                           NATURAL JOIN informefacturacion
                           WHERE nroinforme=unafactura.nroinforme
                                 AND idcentroinformefacturacion=unafactura.idcentroinformefacturacion
	                             AND nrofactura= unafactura.nrofactura
                                 AND tipocomprobante = unafactura.tipocomprobante
                                 AND nrosucursal=unafactura.nrosucursal
                                 AND tipofactura=unafactura.tipofactura;

	  SELECT INTO imppagado SUM(pagosfacturaventa.importepagado)
                            FROM pagosfacturaventa
	  	                    WHERE nroinforme=unafactura.nroinforme
                              AND idcentroinformefacturacion=unafactura.idcentroinformefacturacion
	                          AND nrofactura= unafactura.nrofactura
                              AND tipocomprobante = unafactura.tipocomprobante
                              AND nrosucursal=unafactura.nrosucursal
                              AND tipofactura=unafactura.tipofactura;
	
      IF float84le(float8abs(float84mi(imptotal,imppagado)),0.03) THEN
	   --SI EL INFORME FUE COMPLETAMENTE PAGADO ENTONCES LE CAMBIO EL ESTADO A PAGADO, SINO A PARCIALMENTE PAGADO
		PERFORM  cambiarestadoinformefacturacion(unafactura.nroinforme::integer,unafactura.idcentroinformefacturacion::integer,6,'GENERADO AUTOMATICAMENTE DESDE SP:asentarpagoctacteinstitucioninterno'::varchar);
	  ELSE
		PERFORM  cambiarestadoinformefacturacion(unafactura.nroinforme::integer,unafactura.idcentroinformefacturacion::integer,7,'GENERADO AUTOMATICAMENTE DESDE CAJA, PAGO A UNA INSTITUCION, SP:asentarpagoctacteinstitucioninterno'::varchar);
	  END IF;

         IF (unafactura.idinformefacturaciontipo = 8) THEN --si el informe es de aportes y contribuciones

            SELECT INTO regmesinfo mesingreso, anioingreso
                   FROM informefacturacionaportescontribuciones
                   WHERE nroinforme=unafactura.nroinforme
                         AND idcentroinformefacturacion=unafactura.idcentroinformefacturacion
                   GROUP BY mesingreso, anioingreso;
            movimientoconcepto =concat( movimientoconcepto , ' y ' , unafactura.nroinforme , ' - ' , unafactura.idcentroinformefacturacion , 'del mes ' , regmesinfo.mesingreso , ' - ' ,regmesinfo.anioingreso);
        ELSE
            movimientoconcepto = concat(movimientoconcepto , '  ' , unafactura.nroinforme , ' - ' , unafactura.idcentroinformefacturacion);
        END IF;

     SELECT INTO rpagosinstitucion * FROM pagosinstitucion
                      WHERE idpagos=pidpago
                      AND  nrofactura = unafactura.nrofactura
                      AND tipocomprobante=unafactura.tipocomprobante
                      AND nrosucursal= unafactura.nrosucursal
                      AND tipofactura=unafactura.tipofactura;
     IF NOT FOUND THEN

        INSERT INTO pagosinstitucion (idpagos,idprestador,fechaenviofactura,nrofactura,tipocomprobante,nrosucursal,tipofactura)
        VALUES(pidpago,unafactura.barra,null,unafactura.nrofactura,unafactura.tipocomprobante,unafactura.nrosucursal,unafactura.tipofactura);

     END IF;
     FETCH cursorfacturas into unafactura;
     END LOOP;
     close cursorfacturas;


RETURN movimientoconcepto;
END;
$function$
