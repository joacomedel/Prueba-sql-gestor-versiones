CREATE OR REPLACE FUNCTION public.generarmovimientoenctacteconfacturaventa(pnrofactura integer, pnrosucursal integer, ptipofactura character varying, ptipocomprobante integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES    
montocuentacorriente Double precision;
idinformefacturacion  integer;
eltipoinfo INTEGER; 

--REGISTROS
elcomprobante RECORD;
elmovimiento RECORD;
rdatosnoafil RECORD;
rdatoscliente RECORD;
rdeuda RECORD;


BEGIN


     SELECT INTO elcomprobante * FROM  facturaventa
				NATURAL JOIN facturaventausuario
				WHERE nrofactura = pnrofactura 
					AND tipofactura = ptipofactura AND nrosucursal = pnrosucursal 
					AND tipocomprobante = ptipocomprobante;
     
     IF FOUND THEN
     --  1 - creo el informe de facturacion
     -- 2 registro la deuda
     -- Creo el informe de facturacion
       

       SELECT INTO elmovimiento *, CASE WHEN tipomovimiento ILIKE '%Pago%' THEN -1 ELSE 1 END AS elsigno
                   FROM tipofacturatipomovimiento WHERE tipofactura= elcomprobante.tipofactura;
       IF FOUND  THEN --se encontro el movimiento 

         IF elmovimiento.tipomovimiento ILIKE '%Deuda%' THEN 

             SELECT INTO montocuentacorriente  sum(monto) * elmovimiento.elsigno
          FROM facturaventacupon NATURAL JOIN valorescaja 
          WHERE   idformapagotipos = 3 AND
                     nrofactura = elcomprobante.nrofactura AND 
                 tipocomprobante = elcomprobante.tipocomprobante AND 
                 nrosucursal = elcomprobante.nrosucursal AND
                 tipofactura = elcomprobante.tipofactura;

          SELECT INTO idinformefacturacion * FROM  crearinformefacturacion(elcomprobante.nrodoc,elcomprobante.barra,11);
        
          INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
        (SELECT elcomprobante.centro, idinformefacturacion, idconcepto, cantidad, SUM(importe) as importe,  descripcion
              FROM itemfacturaventa
                WHERE  nrofactura = elcomprobante.nrofactura AND 
                 tipocomprobante = elcomprobante.tipocomprobante AND 
                 nrosucursal = elcomprobante.nrosucursal AND
                 tipofactura = elcomprobante.tipofactura
              GROUP BY centro(), idinformefacturacion,idconcepto,cantidad,descripcion

                        );
    UPDATE informefacturacion  SET
                 nrofactura = elcomprobante.nrofactura ,
                 tipocomprobante = elcomprobante.tipocomprobante ,
                 nrosucursal = elcomprobante.nrosucursal ,
                 tipofactura = elcomprobante.tipofactura,
                 idtipofactura = elcomprobante.tipofactura,
                 idformapagotipos = 3,
                 fechainforme = elcomprobante.fechaemision
          WHERE idcentroinformefacturacion = elcomprobante.centro and  nroinforme = idinformefacturacion;
      

          IF (elcomprobante.barra < 100) THEN 
              INSERT INTO cuentacorrientedeuda (
                idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
                (21,elcomprobante.barra,concat(elcomprobante.nrodoc,elcomprobante.barra::varchar), elcomprobante.fechacreacion,
                concat('Emision Factura ',elcomprobante.tipocomprobante , elcomprobante.nrosucursal::varchar
                ,elcomprobante.nrofactura::varchar),
                10311,montocuentacorriente, (idinformefacturacion*100)+elcomprobante.centro,
                 montocuentacorriente,387,elcomprobante.nrodoc,elcomprobante.centro);
         ELSE 
        	SELECT INTO eltipoinfo dartipoinformecliente(elcomprobante.nrodoc,elcomprobante.barra,elcomprobante.tipofactura);
                IF (eltipoinfo <>11) THEN
			UPDATE informefacturacion SET idinformefacturaciontipo=eltipoinfo
				WHERE nroinforme=idinformefacturacion AND idcentroinformefacturacion=elcomprobante.centro;
		END IF;

               PERFORM generardeudaordenesinstitucion(idinformefacturacion); 

                PERFORM  cambiarestadoinformefacturacion(idinformefacturacion,elcomprobante.centro,4,
                              'Generado desde asentarcomprobantefacturaciongenerico x deuda cliente' );
             
		--Cambio la fecha para que me quede en la deuda y el informe la fecha de creacion de la factura
--		select INTO rdeuda * from ctactedeudanoafil where idcomprobantestipos = 21 AND idcomprobante = idinformefacturacion * 100 + elcomprobante.centro	AND nrodoc=elcomprobante.nrodoc LIMIT 1;
--                IF FOUND THEN 
--			UPDATE ctactedeudanoafil SET fechamovimiento = elcomprobante.fechacreacion WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;			
--                END IF;

		select INTO rdeuda * from ctactedeudacliente where idcomprobantetipos = 21 AND idcomprobante = idinformefacturacion * 100 + elcomprobante.centro LIMIT 1;
                IF FOUND THEN 
			UPDATE ctactedeudacliente SET fechamovimiento = elcomprobante.fechacreacion WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;
                END IF;
          END IF;
      
       ELSE -- ES un pago
                   SELECT INTO montocuentacorriente  sum(monto) * elmovimiento.elsigno
                      FROM facturaventacupon 
			NATURAL JOIN valorescaja 
                         WHERE  nrofactura = elcomprobante.nrofactura AND 
				tipocomprobante = elcomprobante.tipocomprobante AND 
				nrosucursal = elcomprobante.nrosucursal AND
				tipofactura = elcomprobante.tipofactura;
			IF (elcomprobante.barra <100) THEN 

                   INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,
                      movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc)
                   VALUES(51,elcomprobante.barra,concat(elcomprobante.nrodoc,elcomprobante.barra::varchar),elcomprobante.fechacreacion,
                     concat('Nota Credito ',elcomprobante.tipocomprobante , elcomprobante.nrosucursal::varchar
                    ,elcomprobante.nrofactura::varchar),10311,
                      montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                      montocuentacorriente,elcomprobante.nrodoc);

                ELSE 
                  
                 SELECT INTO rdatoscliente *,concat(cuitini,cuitmedio,cuitfin) as elidctacte
                           FROM cliente NATURAL JOIN clientectacte
                           WHERE cliente.nrocliente=elcomprobante.nrodoc AND cliente.barra=elcomprobante.barra;
                  IF FOUND THEN
                    INSERT INTO ctactepagonoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                    nrocuentac,importe,idcomprobante,saldo,nrodoc)
                      VALUES(51,elcomprobante.barra,rdatoscliente.elidctacte::varchar,elcomprobante.fechacreacion,
                     concat('Nota Credito ', to_char(elcomprobante.nrosucursal, '0000')
                         , '-' ,  to_char(elcomprobante.nrofactura, '00000000')) ,
                     10311, montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                            montocuentacorriente,elcomprobante.nrodoc);

                
                  INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,fechamovimiento,movconcepto,
                    nrocuentac,importe,idcomprobante,saldo)
                      VALUES(51,rdatoscliente.idclientectacte,elcomprobante.fechacreacion,
                     concat('Nota Credito ', to_char(elcomprobante.nrosucursal, '0000')
                         , '-' ,  to_char(elcomprobante.nrofactura, '00000000')) ,
                     10311, montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                            montocuentacorriente);

                 END IF; 

               END IF; 
     
            END IF; --DE SI ES DEUDA O PAGO EL MOVIMIENTO
         END IF; -- HAY Un tipo movimiento en la tabla
       END IF;

-- CS 2018-04-26
-- Para crear los asientos de las facturas
/*   
   -- formato: 'FA|1|20|1894'
   PERFORM asientogenericofacturaventa_crear(concat(elcomprobante.tipofactura,'|',elcomprobante.tipocomprobante,'|',elcomprobante.nrosucursal,'|',elcomprobante.nrofactura));
*/

    RETURN true;
END;
$function$
