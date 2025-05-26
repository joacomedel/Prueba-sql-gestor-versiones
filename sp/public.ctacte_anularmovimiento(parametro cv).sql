CREATE OR REPLACE FUNCTION public.ctacte_anularmovimiento(parametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$ 
DECLARE
        
--CURSOR
       cpracticas refcursor;
--RECORD
       rfiltros RECORD;
       rorigenctacte RECORD;
--VARIABLES
       vidplancoberturas INTEGER;
       
BEGIN
       
 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

 CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
 INSERT INTO tempcliente(nrocliente,barra) VALUES(rfiltros.nrodoc,rfiltros.barra);
 SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
		FROM (SELECT verifica_origen_ctacte() as origen ) as t;
 DROP TABLE tempcliente;
 
 IF rfiltros.tipofactura ILIKE '%FA%' AND rorigenctacte.origentabla = 'clientectacte' THEN 
      INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto
						,nrocuentac,importe,idcomprobante,saldo) 
					VALUES(velcomprobantetipo,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte,rmvtoctacte.fechaemision,vmovconcepto
						,rmvtoctacte.nrocuentac,rmvtoctacte.monto*rmvtoctacte.elsigno, (idinformefacturacion*100)+elcentroinforme, rmvtoctacte.monto*rmvtoctacte.elsigno);
  END IF;
  IF rfiltros.tipofactura ILIKE '%NC%' AND rorigenctacte.origentabla = 'clientectacte' THEN 
        INSERT INTO ctactedeudacliente (idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,fechavencimiento)
		VALUES(velcomprobantetipo,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte ,rmvtoctacte.fechaemision,vmovconcepto
		,rmvtoctacte.nrocuentac,rmvtoctacte.monto*rmvtoctacte.elsigno, (idinformefacturacion*100)+elcentroinforme,rmvtoctacte.monto*rmvtoctacte.elsigno,rmvtoctacte.fechaemision+ 30);
  END IF;
  IF rfiltros.tipofactura ILIKE '%NC%' AND rorigenctacte.origentabla = 'afiliadoctacte'  THEN
        INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc,idconcepto)
                       VALUES(velcomprobantetipo,rfiltros.barra,concat(rfiltros.nrodoc,rfiltros.barra::varchar),rmvtoctacte.fechaemision,vmovconcepto,rmvtoctacte.nrocuentac, rmvtoctacte.monto*rmvtoctacte.elsigno, (idinformefacturacion*100)+elcentroinforme,rmvtoctacte.monto*rmvtoctacte.elsigno,rfiltros.nrodoc,elidconcepto);

  ELSE 
         INSERT INTO cuentacorrientedeuda (idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto, nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
                     (velcomprobantetipo,rfiltros.barra,concat(rfiltros.nrodoc,rfiltros.barra::varchar), rmvtoctacte.fechaemision, vmovconcepto, rmvtoctacte.nrocuentac,rmvtoctacte.monto*rmvtoctacte.elsigno, (idinformefacturacion*100)+centro(),
                 rmvtoctacte.monto*rmvtoctacte.elsigno,elidconcepto,rfiltros.nrodoc,centro() );
 
  END IF;
  
--KR 06-07-21 Agrego, no estaba y no lo probe, quizas da error. 
  IF rfiltros.tipofactura ILIKE '%NC%'  AND rorigenctacte.origentabla = 'prestadorctacte' THEN 
         INSERT INTO ctactepagoprestador(idcomprobantetipos,idprestadorctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo) 
					VALUES(21,rorigenctacte.clavepersonactacte,now(),vmovconcepto,rmvtoctacte.nrocuentac,rmvtoctacte.monto*rmvtoctacte.elsigno, (idinformefacturacion*100)+elcentroinforme, rmvtoctacte.monto*rmvtoctacte.elsigno);
  END IF;
  IF rfiltros.tipofacturaILIKE '%Deuda%' AND rorigenctacte.origentabla = 'prestadorctacte' THEN 
        INSERT INTO ctactedeudaprestador(idcomprobantetipos,idprestadorctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,fechavencimiento) 
	VALUES(21,rorigenctacte.clavepersonactacte,now(),vmovconcepto,rmvtoctacte.nrocuentac,rmvtoctacte.monto*rmvtoctacte.elsigno, (idinformefacturacion*100)+elcentroinforme, rmvtoctacte.monto*rmvtoctacte.elsigno,rmvtoctacte.fechaemision+ 30);
  END IF;

    
 return '';

end;$function$
