CREATE OR REPLACE FUNCTION public.asentarfacturaventafarmacia()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE


tipoorden integer;
idpago integer;
elcomprobante varchar(100);

--REGISTROS
elem refcursor;
itemfact refcursor;

rfactventa record;
rorden record;
unitemfact record;
tfaccupon record;
impamuc DOUBLE PRECISION=0;
impctacte DOUBLE PRECISION=0;

--CURSORES

cfactventa CURSOR FOR SELECT * FROM tempfacturaventa;
corden CURSOR FOR SELECT * FROM temporden;
cfactventacupon CURSOR FOR SELECT * FROM tempfacturaventacupon;




BEGIN

     /* Cambio el estado de las ordenes a estado facturado */
     SELECT far_cambiarestadoordenventa(nroorden,centro,5) FROM temporden;

     /* Se guarda la cabecera de la factura */
     open cfactventa;
     FETCH cfactventa into rfactventa;
     SELECT into elem nrosucursal, sgtenumero as nrofactura
     FROM devolvernrofactura(centro(),rfactventa.tipocomprobante,rfactventa.tipofactura,rfactventa.nrosucursal);

     INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra)
            VALUES(rfactventa.tipocomprobante,rfactventa.nrosucursal,elem.nrofactura,
                 rfactventa.nrodoc,rfactventa.tipodoc,1000,centro(),current_date,rfactventa.tipofactura, rfactventa.barra);

     elcomprobante = concat(rfactventa.tipocomprobante,'|',rfactventa.tipofactura,'|',rfactventa.nrosucursal,'|',elem.nrofactura);
     
     
     /* Se vincula las ordenes a la factura generadas*/
     open corden;
     FETCH corden into rorden;
     WHILE FOUND LOOP
                 tipoorden = rorden.idcomprobantetipos;
                INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,  nrofactura, nroorden, centro, idcomprobantetipos)
                 VALUES(rfactventa.tipocomprobante,rfactventa.nrosucursal, rfactventa.tipofactura,elem.nrofactura,
                 rorden.nroorden,rorden.centro,rorden.idcomprobantetipos);
      FETCH corden into rorden;
      END LOOP;
      CLOSE corden;

     /* CREO LOS ITEMS DE LA FACTURA */
     IF (tipoorden=45) THEN --   Se esta facturando una orden de farmacia
                 SELECT INTO  itemfact *
                 FROM  far_ordenventaitem
                 NATURAL JOIN far_articulo
                 JOIN temfacturaorden ON (nroorden = idordenventa and idcentroordenventa = centro ) ;
                 /* GENERO LOS ITEMS DE FACTURA VENTA*/
                 FETCH itemfact into unitemfact;
                 WHILE FOUND LOOP
			            INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                        idconcepto,cantidad,importe,descripcion,idiva)
			            VALUES(rfactventa.tipocomprobante,rfactventa.nrosucursal,rfactventa.tipofactura,elem.nrofactura,
                        itemfact.actacble,itemfact.ovicantidad,round(CAST (itemfact.ovipreciolista AS numeric),2),itemfact.ovidescripcion,1);
                  FETCH itemfact into unitemfact;
		          END LOOP;
      END IF;

    impctacte = round(CAST (ordenventaimportes(NULL,9) AS numeric),2);
    IF impctacte <> 0 THEN idpago = 3; ELSE idpago = 2; END IF;
    UPDATE facturaventa SET
                   importeamuc=round(CAST ( ordenventaimportes(3,NULL) AS numeric),2)  ,
                   importeefectivo=round(CAST ( ordenventaimportes(NULL,0) AS numeric),2)  ,
                   importedebito=0,
                   importecredito=0,
                   importectacte=round(CAST (ordenventaimportes(NULL,9) AS numeric),2),
                   importesosunc=round(CAST (ordenventaimportes(1,NULL) AS numeric),2),
                   formapago=idpago
    WHERE tipocomprobante=rfactventa.tipocomprobante
                   AND nrosucursal= rfactventa.nrosucursal
                   AND nrofactura=elem.nrofactura
                   AND tipofactura=rfactventa.tipofactura;

   open cfactventacupon;
   FETCH cfactventacupon into tfaccupon;
   WHILE FOUND LOOP

            tfaccupon.monto = round(CAST (tfaccupon.monto AS numeric),2);
            INSERT INTO facturaventacupon(nrofactura, tipocomprobante, nrosucursal,
            tipofactura, idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon)
            VALUES(tfaccupon.nrofactura, tfaccupon.tipocomprobante, elem.nrosucursal, tfaccupon.tipofactura,
                   tfaccupon.idvalorescaja, tfaccupon.autorizacion, tfaccupon.nrotarjeta,tfaccupon.monto,
                   tfaccupon.cuotas, tfaccupon.nrocupon);
   FETCH cfactventacupon into tfaccupon;
   END LOOP;
   CLOSE cfactventacupon;

   /* se devuelve el comprobante generado */
    
return elcomprobante;
END;
$function$
