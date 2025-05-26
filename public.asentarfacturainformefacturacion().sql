CREATE OR REPLACE FUNCTION public.asentarfacturainformefacturacion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--REGISTROS
elem RECORD;
reginfo RECORD;

--VARIABLES

resp BOOLEAN;
tipodocfac INTEGER DEFAULT 0;
sumimporte DOUBLE PRECISION;
impefect DOUBLE PRECISION=0;
impctacte DOUBLE PRECISION=0;
idformapagoinfo INTEGER;


--CURSORES
informe CURSOR FOR SELECT * FROM tempinformeafacturar;
tinforme RECORD;

informefac CURSOR FOR SELECT * FROM tempfacturainforme;
tinformefac RECORD;


items CURSOR FOR SELECT * FROM tempitemsinforme;
iteminforme RECORD;

facturavtacupon CURSOR FOR SELECT * FROM tempfacturaventacupon;
tfaccupon RECORD;


BEGIN


open informe;
FETCH informe into tinforme;

SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(tinforme.centro,tinforme.tipocomprobante,tinforme.tipofactura,tinforme.nrosucursal);

       IF (tinforme.barra< 100) THEN
              SELECT INTO tipodocfac tipodoc FROM persona WHERE nrodoc=tinforme.nrodoc AND barra= tinforme.barra;
       END IF;

       INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra)
      VALUES(tinforme.tipocomprobante,elem.nrosucursal,elem.nrofactura,tinforme.nrodoc,tipodocfac,1000,tinforme.centro,now(),tinforme.tipofactura,tinforme.barra);





open items;
FETCH items into iteminforme;
      WHILE FOUND LOOP
            iteminforme.importe = round(CAST (iteminforme.importe AS numeric),2);

            INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
            VALUES(iteminforme.tipocomprobante,elem.nrosucursal,iteminforme.tipofactura,elem.nrofactura,iteminforme.idconcepto,iteminforme.cantidad,iteminforme.importe,iteminforme.descripcion,1);
        FETCH items into iteminforme;
        END LOOP;
close items;


--sumo los items para saber cuanto va en la cabecera (tabla facturaventa)

SELECT INTO sumimporte sum(importe) FROM itemfacturaventa WHERE tipocomprobante=tinforme.tipocomprobante AND nrosucursal=elem.nrosucursal AND

nrofactura=elem.nrofactura AND tipofactura=tinforme.tipofactura;
sumimporte = round(CAST(sumimporte  AS numeric),2);


--updateo la tabla informefacturacion para saber cual es la factura correspondiente al mismo
--updateo la tabla facturaventa para saber cual es la forma de pago de la factura y el monto de la misma

open informefac;
FETCH informefac into tinformefac;

 -- SELECT INTO idformapagoinfo idformapagotipos FROM informefacturacion WHERE informefacturacion.nroinforme=tinformefac.nroinforme AND informefacturacion.idcentroinformefacturacion=tinformefac.idcentroinformefacturacion;
  SELECT INTO reginfo idformapagotipos, idinformefacturaciontipo,nroinforme,idcentroinformefacturacion,barra
  FROM informefacturacion WHERE informefacturacion.nroinforme=tinformefac.nroinforme AND informefacturacion.idcentroinformefacturacion=tinformefac.idcentroinformefacturacion;

IF (reginfo.idformapagotipos=2) THEN
                impefect=sumimporte;
ELSE
                impctacte=sumimporte;
END IF;

UPDATE facturaventa SET importeamuc=0,importeefectivo=impefect,importedebito=0,importecredito=0,importectacte=impctacte,importesosunc=0,formapago=reginfo.idformapagotipos
        WHERE tipocomprobante=tinforme.tipocomprobante AND nrosucursal= elem.nrosucursal AND nrofactura=elem.nrofactura AND tipofactura=tinforme.tipofactura;

    WHILE FOUND LOOP
       UPDATE informefacturacion SET tipocomprobante=tinformefac.tipocomprobante,nrosucursal=tinformefac.nrosucursal,nrofactura=tinformefac.nrofactura,tipofactura=tinformefac.tipofactura
       WHERE nroinforme=tinformefac.nroinforme AND idcentroinformefacturacion=tinformefac.idcentroinformefacturacion;

  -- SELECT INTO tipoinforme idinformefacturaciontipo FROM informefacturacion WHERE nroinforme=tinformefac.nroinforme AND idcentroinformefacturacion=tinformefac.idcentroinformefacturacion;

--cambio el estado del informefacturacion a FACTURADO
   SELECT INTO resp * FROM cambiarestadoinformefacturacion(tinformefac.nroinforme,tinformefac.idcentroinformefacturacion,4,'GENERADO DESDE SP asentarfacturainformefacturacion');
   FETCH informefac into tinformefac;
    END LOOP;
CLOSE informefac;


--vinculo la factura con la/s forma/s de pago
open facturavtacupon;
FETCH facturavtacupon into tfaccupon;
      WHILE FOUND LOOP

            tfaccupon.monto = round(CAST (tfaccupon.monto AS numeric),2);

            INSERT INTO facturaventacupon(nrofactura, tipocomprobante, nrosucursal,
            tipofactura, idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon)
            VALUES(tfaccupon.nrofactura, tfaccupon.tipocomprobante, elem.nrosucursal, tfaccupon.tipofactura,
             tfaccupon.idvalorescaja, tfaccupon.autorizacion, tfaccupon.nrotarjeta,tfaccupon.monto,
             tfaccupon.cuotas, tfaccupon.nrocupon);
        FETCH facturavtacupon into tfaccupon;
        END LOOP;
close facturavtacupon;
CLOSE informe;

--SI EL INFORME ES DE TIPO APORTES LLAMO A UN SP QUE INSERTE LOS ITEMS IVA Y DE BONIFICACION
IF ((reginfo.idinformefacturaciontipo=6) and (reginfo.barra=35  or reginfo.barra=36)) THEN

   PERFORM modificaritemfacturajubilados(reginfo.nroinforme,reginfo.idcentroinformefacturacion);

END IF;
return resp;
END;$function$
