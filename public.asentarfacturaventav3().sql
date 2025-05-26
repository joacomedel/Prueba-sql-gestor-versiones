CREATE OR REPLACE FUNCTION public.asentarfacturaventav3()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--REGISTROS
elem RECORD;
esbeneficiario RECORD;
imporden RECORD;
torden RECORD;
itemf RECORD;
itemo RECORD;
tfaccupon RECORD;

--VARIABLES
nrodocumento VARCHAR;
tdoc INTEGER;
barra1 INTEGER;
idpago INTEGER;
impefect DOUBLE PRECISION=0;
impctacte DOUBLE PRECISION=0;
impamuc DOUBLE PRECISION=0;
impsosunc DOUBLE PRECISION=0;
sumimporte DOUBLE PRECISION;
tipoorden BIGINT;
tipofact VARCHAR;
sumimpfvc DOUBLE PRECISION;

--CURSORES

curs refcursor;

ordenespendientes CURSOR FOR SELECT * FROM tempordenespendientes;

items CURSOR FOR SELECT * FROM tempitemsordenespendientes;

facturaordenes CURSOR FOR SELECT * FROM tempfacturaorden;

facturavtacupon CURSOR FOR SELECT * FROM tempfacturaventacupon;



BEGIN


open ordenespendientes;
FETCH ordenespendientes into torden;

      SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(torden.centro,torden.tipocomprobante,torden.tipofactura,torden.nrosucursal);
      tipofact = 'FA';
      SELECT INTO esbeneficiario nrodoctitu,tipodoctitu from benefsosunc
      where (benefsosunc.nrodoc = torden.nrodoc and benefsosunc.tipodoc=torden.tipodoc);
      if found  then
          nrodocumento=esbeneficiario.nrodoctitu;
          tdoc=esbeneficiario.tipodoctitu;
      else
          nrodocumento=torden.nrodoc;
          tdoc = torden.tipodoc;

      END IF;

      SELECT INTO barra1 barra FROM persona
      WHERE (nrodoc = nrodocumento AND tipodoc = tdoc);


      INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra)
      VALUES(torden.tipocomprobante,elem.nrosucursal,elem.nrofactura,nrodocumento,tdoc,1000,torden.centro,current_date,torden.tipofactura,barra1);

      IF (torden.tipofactura ='NC') THEN
         tipofact = 'NC';

      END IF;



open facturaordenes;
FETCH facturaordenes into itemo;

	WHILE FOUND LOOP

            SELECT INTO tipoorden tipo FROM orden WHERE orden.nroorden= itemo.nroorden AND orden.centro=itemo.centro;

            INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,nrofactura,nroorden,centro,idcomprobantetipos)
            VALUES(itemo.tipocomprobante,elem.nrosucursal,itemo.tipofactura,elem.nrofactura,itemo.nroorden,itemo.centro,tipoorden);

            OPEN curs FOR SELECT * FROM importesorden WHERE nroorden = itemo.nroorden AND centro = itemo.centro;
            --voy sumando los importes de las ordenes comprendidas en la factura acorde a la forma de pago
		FETCH curs INTO imporden;
		WHILE FOUND LOOP
			IF imporden.idformapagotipos=1 THEN 
				impamuc= impamuc + imporden.importe;
				
			END IF;
			IF imporden.idformapagotipos=2 THEN 
				impefect= impefect + imporden.importe;
				idpago=2;
			END IF;
			IF imporden.idformapagotipos=3 THEN
				impctacte= impctacte + imporden.importe;
				idpago=3;
			END IF;
			IF imporden.idformapagotipos=6 THEN
				impsosunc= impsosunc + imporden.importe;
				
			END IF;
			FETCH curs INTO imporden;
		END LOOP;
             CLOSE curs;

            
	FETCH facturaordenes into itemo;
      END LOOP;
CLOSE facturaordenes;


open items;
FETCH items into itemf;
		WHILE FOUND LOOP

                        itemf.importe = round(CAST (itemf.importe AS numeric),2);
			INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
			VALUES(itemf.tipocomprobante,elem.nrosucursal,itemf.tipofactura,elem.nrofactura,itemf.idconcepto,itemf.cantidad,itemf.importe,itemf.descripcion,1);
		FETCH items into itemf;
		END LOOP;
close items;

SELECT INTO sumimporte sum(importe) FROM itemfacturaventa WHERE tipocomprobante=torden.tipocomprobante AND nrosucursal=elem.nrosucursal AND nrofactura=elem.nrofactura AND tipofactura=torden.tipofactura;
sumimporte = round(CAST(sumimporte  AS numeric),2);
impsosunc = round(CAST (impsosunc AS numeric),2);
impctacte = round(CAST (impctacte AS numeric),2);
impamuc = round(CAST (impamuc AS numeric),2);
impefect = round(CAST (impefect AS numeric),2);

IF (sumimporte=impctacte OR sumimporte=impefect) THEN

		UPDATE facturaventa SET importeamuc= impamuc,importeefectivo=impefect,importedebito=0,importecredito=0,importectacte=impctacte,importesosunc=impsosunc,formapago=idpago
		WHERE tipocomprobante=torden.tipocomprobante AND nrosucursal= elem.nrosucursal AND nrofactura=elem.nrofactura AND tipofactura=torden.tipofactura;
	ELSE
		IF (idpago=2) THEN
			impefect = sumimporte;
		ELSE
			impctacte = sumimporte;
		END IF;
		UPDATE facturaventa SET importeamuc= impamuc,importeefectivo=impefect,importedebito=0,importecredito=0,importectacte=impctacte,importesosunc=impsosunc,formapago=idpago
		WHERE tipocomprobante=torden.tipocomprobante AND nrosucursal= elem.nrosucursal AND nrofactura=elem.nrofactura AND tipofactura=torden.tipofactura;

		

	END IF;

CLOSE ordenespendientes;
--modificacion el dia 28/07/2011 para mantener compatibilidad con facturaventacupon cuando la forma de pago es Nota de Credito


IF (tipofact='NC') THEN --la nota de credito se paga en cta cte.
 IF (idpago=2) THEN 
    INSERT INTO tempfacturaventacupon
(tipocomprobante,nrosucursal,tipofactura,nrofactura,idvalorescaja,cuotas,monto,nrotarjeta,autorizacion,nrocupon)
VALUES(torden.tipocomprobante,elem.nrosucursal,tipofact,elem.nrofactura,2,1,impefect,'','','');
       
 ELSE 
      INSERT INTO tempfacturaventacupon
(tipocomprobante,nrosucursal,tipofactura,nrofactura,idvalorescaja,cuotas,monto,nrotarjeta,autorizacion,nrocupon)
VALUES(torden.tipocomprobante,elem.nrosucursal,tipofact,elem.nrofactura,3,1,impctacte,'','','');
 END IF;
END IF;
open facturavtacupon;
FETCH facturavtacupon into tfaccupon;
      WHILE FOUND LOOP

            tfaccupon.monto = round(CAST (tfaccupon.monto AS numeric),2);
            INSERT INTO facturaventacupon(nrofactura, tipocomprobante, nrosucursal, 
            tipofactura, idvalorescaja, autorizacion, nrotarjeta, monto, 
            cuotas, nrocupon) VALUES(elem.nrofactura, tfaccupon.tipocomprobante, elem.nrosucursal, tfaccupon.tipofactura, 
             tfaccupon.idvalorescaja, tfaccupon.autorizacion, tfaccupon.nrotarjeta,tfaccupon.monto, 
             tfaccupon.cuotas, tfaccupon.nrocupon);
        FETCH facturavtacupon into tfaccupon;
        END LOOP;
close facturavtacupon;


return true;
END;$function$
