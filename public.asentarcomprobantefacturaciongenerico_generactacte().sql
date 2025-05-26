CREATE OR REPLACE FUNCTION public.asentarcomprobantefacturaciongenerico_generactacte()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES    
montocuentacorriente Double precision;
idinformefacturacion  integer;
eltipoinfo INTEGER;
--REGISTROS
rfactventa RECORD;
elmovimiento RECORD;
rorigenctacte RECORD;

vconceptousuario varchar;
vmovconcepto varchar;
vidcomprobante bigint;
BEGIN

	SELECT INTO rfactventa * FROM tempfacturaventa;
	SELECT INTO vconceptousuario nrocupon FROM tempfacturaventacupon LIMIT 1;
--	SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacion() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
     	IF (rfactventa.ctacte ) THEN
           --  1 - creo el informe de facturacion
	   -- 2 registro la deuda
 	   -- Creo el informe de facturacion
			   --MaLaPi 12-12-2017 Verifico en que tabla deberian estar las deudas y pagos. 
			CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
			INSERT INTO tempcliente(nrocliente,barra) VALUES(rfactventa.nrodoc,rfactventa.barra);
			SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
				FROM (
				SELECT verifica_origen_ctacte() as origen 
				) as t;
			DROP TABLE tempcliente;
		-- Genero el Informe de Facturacion, el tipo de informe es 14 - Generico pues se usa para deuda o pago
				SELECT INTO idinformefacturacion * FROM  crearinformefacturacion(rfactventa.nrodoc,rfactventa.barra,14);
				INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
					(SELECT centro(), idinformefacturacion, idconcepto, cantidad, SUM(importe) as importe,  descripcion
					FROM itemfacturaventa
					WHERE  nrofactura = rfactventa.nrofactura AND 
					 tipocomprobante = rfactventa.tipocomprobante AND 
					 nrosucursal = rfactventa.nrosucursal AND
					 tipofactura = rfactventa.tipofactura
					 GROUP BY centro(), idinformefacturacion,idconcepto,cantidad,descripcion
					);
				  UPDATE informefacturacion  SET
					 nrofactura = rfactventa.nrofactura ,
					 tipocomprobante = rfactventa.tipocomprobante ,
					 nrosucursal = rfactventa.nrosucursal ,
					 tipofactura = rfactventa.tipofactura,
					 idtipofactura = rfactventa.tipofactura,
					 idformapagotipos = 3
				  WHERE idcentroinformefacturacion = centro() and  nroinforme = idinformefacturacion;


		           	SELECT INTO eltipoinfo dartipoinformecliente(rfactventa.nrodoc,rfactventa.barra,rfactventa.tipofactura);
				IF (eltipoinfo <>11) THEN
				UPDATE informefacturacion SET idinformefacturaciontipo=eltipoinfo
					WHERE nroinforme=idinformefacturacion AND idcentroinformefacturacion=centro();
				END IF;


				   -- Dejo el Informe en estado 4 - Facturado
				   PERFORM  cambiarestadoinformefacturacion(idinformefacturacion,centro(),4,
						      'Generado desde asentarcomprobantefacturaciongenerico x Mov en Cta.Cte' );
			-- Fin de Generar el Informe
			vidcomprobante = (idinformefacturacion*100)+centro();
			vmovconcepto = concat('Emision de ',rfactventa.tipofactura ,' ', rfactventa.nrosucursal::varchar
					,' ',rfactventa.nrofactura::varchar,' Con el Informe ',idinformefacturacion,'-',centro());
			
			IF vconceptousuario <> '0' THEN
				vmovconcepto = concat(vmovconcepto,' ',vconceptousuario);
			END IF;
				vmovconcepto = concat(vmovconcepto,'|',rfactventa::text);
			

		       SELECT INTO elmovimiento *, CASE WHEN tipomovimiento ILIKE '%Pago%' THEN -1 ELSE 1 END AS elsigno
				   FROM tipofacturatipomovimiento WHERE tipofactura= rfactventa.tipofactura;
		       IF FOUND  THEN --se encontro el movimiento 
			SELECT INTO montocuentacorriente  sum(monto) * elmovimiento.elsigno
				FROM facturaventacupon 
				NATURAL JOIN valorescaja 
/*KR 03-10-18 hablado con andrea, ej ND 6848 2 1 con forma pago transferencia(8) debia generar movimiento en cta cte.		*/
				WHERE  /*idformapagotipos = 3 AND*/
				 nrofactura = rfactventa.nrofactura AND 
				 tipocomprobante = rfactventa.tipocomprobante AND 
				 nrosucursal = rfactventa.nrosucursal AND
				 tipofactura = rfactventa.tipofactura;

			 IF elmovimiento.tipomovimiento ILIKE '%Deuda%' THEN 
			      IF (rorigenctacte.origentabla = 'clientectacte') THEN 
				 --MaLaPi En la deuda, siempre el origen es un informe de facturacion 21 
					INSERT INTO ctactedeudacliente (idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto
						,nrocuentac,importe,idcomprobante,saldo,fechavencimiento) 
					VALUES(21,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte ,now(),vmovconcepto
						,10311,montocuentacorriente, vidcomprobante, montocuentacorriente,CURRENT_DATE + 30);
			      END IF;
			      IF (rorigenctacte.origentabla = 'prestadorctacte') THEN 
				 --MaLaPi En la deuda, siempre el origen es un informe de facturacion 21 
					INSERT INTO ctactedeudaprestador(idcomprobantetipos,idprestadorctacte,fechamovimiento,movconcepto
						,nrocuentac,importe,idcomprobante,saldo,fechavencimiento) 
					VALUES(21,rorigenctacte.clavepersonactacte,now(),vmovconcepto
						,10311,montocuentacorriente, vidcomprobante, montocuentacorriente,CURRENT_DATE + 30);
			      END IF;
			      --MaLaPi 12-12-2017 Para mantener compatibilidad con la vieja version de ctasctes
			      INSERT INTO ctactedeudanoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac
			      ,importe,idcomprobante,saldo,nrodoc)
			      VALUES(21,rfactventa.barra,rorigenctacte.clavepersonactacte::varchar,now(),vmovconcepto,10311
			      ,montocuentacorriente,vidcomprobante,montocuentacorriente,rfactventa.nrodoc);
			
		       ELSE -- ES un pago

			       IF (rorigenctacte.origentabla = 'clientectacte') THEN 
				 --MaLaPi En la deuda, siempre el origen es un informe de facturacion 21 
					INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto
						,nrocuentac,importe,idcomprobante,saldo) 
					VALUES(21,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte,now(),vmovconcepto
						,10311,montocuentacorriente, vidcomprobante, montocuentacorriente);
			      END IF;
			      IF (rorigenctacte.origentabla = 'prestadorctacte') THEN 
				 --MaLaPi En la deuda, siempre el origen es un informe de facturacion 21 
					INSERT INTO ctactepagoprestador(idcomprobantetipos,idprestadorctacte,fechamovimiento,movconcepto
						,nrocuentac,importe,idcomprobante,saldo) 
					VALUES(21,rorigenctacte.clavepersonactacte,now(),vmovconcepto
						,10311,montocuentacorriente, vidcomprobante, montocuentacorriente);
			      END IF;	
				--MaLaPi 12-12-2017 Para mantener compatibilidad con la vieja version de ctasctes
				INSERT INTO ctactepagonoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac
				,importe,idcomprobante,saldo,nrodoc)
				VALUES(21,rfactventa.barra,rorigenctacte.clavepersonactacte::varchar,now(),vmovconcepto,10311
				,montocuentacorriente,vidcomprobante,montocuentacorriente,rfactventa.nrodoc);


			 END IF; --DE SI ES DEUDA O PAGO EL MOVIMIENTO

	END IF;
       END IF;

RETURN idinformefacturacion::text;

END;
$function$
