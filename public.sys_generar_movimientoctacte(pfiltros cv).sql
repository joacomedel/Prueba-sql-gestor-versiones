CREATE OR REPLACE FUNCTION public.sys_generar_movimientoctacte(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--RECORD
        rusuario RECORD;
        rfiltros RECORD;
        rorigenctacte RECORD;
        rmvtoctacte RECORD;

--VARIABLES
        vmovconcepto VARCHAR;
        idinformefacturacion INTEGER;
        elidconcepto INTEGER; 
        elcentroinforme INTEGER; 
	eltipoinforme INTEGER; 
        vcrearinforme BOOLEAN;
        velcomprobantetipo INTEGER;
        vmodificarconc  VARCHAR DEFAULT 'si';
BEGIN

vcrearinforme = false;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
INSERT INTO tempcliente(nrocliente,barra) VALUES(rfiltros.nrodoc,rfiltros.barra);
SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
		FROM (SELECT verifica_origen_ctacte() as origen ) as t;
DROP TABLE tempcliente;

RAISE NOTICE 'velcomprobantetipo 	 (%)',rfiltros;

SELECT INTO velcomprobantetipo 	idcomprobantetipos FROM comprobantestipos WHERE idcomprobantetipos = rfiltros.idcomprobantetipos;

IF NOT FOUND AND nullvalue(rfiltros.nroinforme) THEN
   vcrearinforme = true;
   velcomprobantetipo =21; /*Cuando se debe crear el info el tipo de comprobante es 21 INFORME */
END IF;
       
SELECT INTO rmvtoctacte sum(monto) as monto, nrocuentac,
   case when nullvalue(anulada) then tipomovimiento 
     when rfiltros.tipofactura ILIKE '%NC%' then 'Deuda' 
     when  rfiltros.tipofactura ILIKE '%FA%'  then 'Pago' 
  END AS tipomovimiento, 
  anulada,
  fechaemision
                       FROM facturaventa fv NATURAL JOIN  facturaventacupon f JOIN valorescaja USING(idvalorescaja) JOIN multivac.formapagotiposcuentafondos t on(f.nrosucursal=t.nrosucursal and f.idvalorescaja=t.idvalorescaja) JOIN multivac.mapeocuentasfondos m using(idcuentafondos) JOIN tipofacturatipomovimiento using(tipofactura)			
		WHERE f.nrofactura = rfiltros.nrofactura AND f.tipofactura = rfiltros.tipofactura AND f.tipocomprobante = rfiltros.tipocomprobante AND f.nrosucursal = rfiltros.nrosucursal  AND vcmovimientoctacte
                GROUP BY nrocuentac,tipomovimiento,fechaemision,anulada;


     IF FOUND THEN /*es un comprobante de facturacion pq esta en facturaventacupon asi que genero un informe */
          -- Genero el Informe de Facturacion, el tipo de informe es 14 - Generico pues se usa para deuda o pago
      IF vcrearinforme THEN 
             
            SELECT INTO idinformefacturacion * FROM  crearinformefacturacion(rfiltros.nrodoc,rfiltros.barra,14);
	    INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
					(SELECT centro(), idinformefacturacion, idconcepto, cantidad, SUM(importe) as importe,  descripcion
					FROM itemfacturaventa
					WHERE  nrofactura = rfiltros.nrofactura AND 
					 tipocomprobante = rfiltros.tipocomprobante AND 
					 nrosucursal = rfiltros.nrosucursal AND
					 tipofactura = rfiltros.tipofactura
					 GROUP BY centro(), idinformefacturacion,idconcepto,cantidad,descripcion
					);
	    UPDATE informefacturacion  SET
					 nrofactura = rfiltros.nrofactura ,
					 tipocomprobante = rfiltros.tipocomprobante ,
					 nrosucursal = rfiltros.nrosucursal ,
					 tipofactura = rfiltros.tipofactura,
					 idtipofactura = rfiltros.tipofactura,
					 idformapagotipos = 3
	    WHERE idcentroinformefacturacion = centro() and  nroinforme = idinformefacturacion;
            elcentroinforme = centro();
            eltipoinforme =14;
           ELSE 
		idinformefacturacion = rfiltros.nroinforme;
		elcentroinforme = rfiltros.idcentroinformefacturacion;
		SELECT INTO eltipoinforme idinformefacturaciontipo FROM informefacturacion where nroinforme = rfiltros.nroinforme and idcentroinformefacturacion=rfiltros.idcentroinformefacturacion;
           END IF;
 --KR 06-07-21 
-- Dejo el Informe en estado 4 - Facturado
	   PERFORM  cambiarestadoinformefacturacion(idinformefacturacion,centro(),4,'Generado desde asentarcomprobantefacturaciongenerico x Mov en Cta.Cte' );
--KR 08-11-21 modifico ya que tkt 4569, para aportes no quieren la leyenda modificada
IF (pfiltros ilike '%modificarconcepto%') THEN 
   vmodificarconc = rfiltros.modificarconcepto ;
END IF;

IF (vmodificarconc ilike '%si%') THEN 
--KR 07-09-21 voy en este sp generando los conceptos segun lo solicitan
            SELECT INTO vmovconcepto * from ctacte_movconcepto(pfiltros);
END IF;
            vmovconcepto = concat(vmovconcepto, ' ',CASE WHEN not nullvalue(rfiltros.movconcepto) THEN rfiltros.movconcepto  END, ' Genera ' , rmvtoctacte.tipomovimiento ,' por ', case when nullvalue(rmvtoctacte.anulada) then ' Emision ' ELSE 'Anulacion ' END, 'de ',rfiltros.tipofactura ,' ', rfiltros.nrosucursal::varchar
					,' ',rfiltros.nrofactura::varchar,' Con el Informe ',idinformefacturacion,'-',elcentroinforme); 

   
         IF rmvtoctacte.tipomovimiento ILIKE '%Pago%' AND rorigenctacte.origentabla = 'clientectacte' THEN 
               INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto
						,nrocuentac,importe,idcomprobante,saldo) 
					VALUES(velcomprobantetipo,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte,rmvtoctacte.fechaemision,vmovconcepto
						,rmvtoctacte.nrocuentac,rmvtoctacte.monto*(-1), (idinformefacturacion*100)+elcentroinforme, rmvtoctacte.monto*(-1));
            END IF;
            IF rmvtoctacte.tipomovimiento ILIKE '%Deuda%' AND rorigenctacte.origentabla = 'clientectacte' THEN 
        	INSERT INTO ctactedeudacliente (idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,fechavencimiento)
		VALUES(velcomprobantetipo,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte ,rmvtoctacte.fechaemision,vmovconcepto
		,rmvtoctacte.nrocuentac,rmvtoctacte.monto , (idinformefacturacion*100)+elcentroinforme,rmvtoctacte.monto,rmvtoctacte.fechaemision+ 30);
           END IF;
            IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
              SELECT INTO elidconcepto nroconcepto FROM mapeocuentascontablesconcepto WHERE nrocuentac =rmvtoctacte.nrocuentac order by nroconcepto  asc;
              IF rmvtoctacte.tipomovimiento ILIKE '%Pago%' THEN
                       INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc,idconcepto)
                       VALUES(velcomprobantetipo,rfiltros.barra,concat(rfiltros.nrodoc,rfiltros.barra::varchar),rmvtoctacte.fechaemision,vmovconcepto,rmvtoctacte.nrocuentac, rmvtoctacte.monto*(-1), (idinformefacturacion*100)+elcentroinforme,rmvtoctacte.monto*(-1),rfiltros.nrodoc,elidconcepto);

              ELSE 
                     INSERT INTO cuentacorrientedeuda (idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto, nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
                     (velcomprobantetipo,rfiltros.barra,concat(rfiltros.nrodoc,rfiltros.barra::varchar), rmvtoctacte.fechaemision, vmovconcepto, rmvtoctacte.nrocuentac,rmvtoctacte.monto , (idinformefacturacion*100)+centro(),
                 rmvtoctacte.monto ,elidconcepto,rfiltros.nrodoc,centro() );
 
              END IF;
            END IF;
--KR 06-07-21 Agrego, no estaba y no lo probe, quizas da error. 
            IF rmvtoctacte.tipomovimiento ILIKE '%Pago%' AND rorigenctacte.origentabla = 'prestadorctacte' THEN 
               INSERT INTO ctactepagoprestador(idcomprobantetipos,idprestadorctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo) 
					VALUES(21,rorigenctacte.clavepersonactacte,now(),vmovconcepto,rmvtoctacte.nrocuentac,rmvtoctacte.monto*(-1), (idinformefacturacion*100)+elcentroinforme, rmvtoctacte.monto*(-1));
            END IF;
            IF rmvtoctacte.tipomovimiento ILIKE '%Deuda%' AND rorigenctacte.origentabla = 'prestadorctacte' THEN 
        	INSERT INTO ctactedeudaprestador(idcomprobantetipos,idprestadorctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,fechavencimiento) 
	VALUES(21,rorigenctacte.clavepersonactacte,now(),vmovconcepto,rmvtoctacte.nrocuentac,rmvtoctacte.monto, (idinformefacturacion*100)+elcentroinforme, rmvtoctacte.monto ,rmvtoctacte.fechaemision+ 30);
           END IF;

       END IF;


return '';
END;$function$
