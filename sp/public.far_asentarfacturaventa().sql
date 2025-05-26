CREATE OR REPLACE FUNCTION public.far_asentarfacturaventa()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

elidarticulo integer;
elidcentroarticulo integer;
tipoorden integer;
idpago integer;
elcomprobante varchar(100);
eliditemfactventa bigint;
resp boolean;
vretorno VARCHAR;

--REGISTROS
elem record;
itemfact refcursor;

cformaspago refcursor;
unaformaspago record;
rfactventa record;
rorden record;
unitemfact record;
tfaccupon record;
rfacturaventa record;

impamuc DOUBLE PRECISION=0;
impctacte DOUBLE PRECISION=0;
impefect DOUBLE PRECISION=0;
elporcentaje DOUBLE PRECISION=0;

--CURSORES

cfactventa CURSOR FOR SELECT * FROM tempfacturaventa;
corden CURSOR FOR SELECT * FROM temporden;
cfactventacupon CURSOR FOR SELECT * FROM tempfacturaventacupon JOIN valorescaja USING (idvalorescaja);
elidiva INTEGER;
importedescuento  DOUBLE PRECISION;

sumaconiva DOUBLE PRECISION;
sumaexento DOUBLE PRECISION;
BEGIN

     SELECT INTO rorden * FROM temporden LIMIT 1;
     IF FOUND AND  rorden.idcomprobantetipos <> 44 THEN

       SELECT INTO rfacturaventa * FROM expendio_asentarfacturaventa_2();
  
       elcomprobante = concat(rfacturaventa.tipocomprobante,'|',rfacturaventa.tipofactura,'|',rfacturaventa.nrosucursal,'|',rfacturaventa.nrofactura);

     ELSE  
     importedescuento = 0;
     sumaconiva = 0;
     sumaexento = 0;
     /* Cambio el estado de las ordenes a estado facturado */
    -- SELECT INTO resp far_cambiarestadoordenventa(nroorden,centro,3) FROM temporden;

     /* Se guarda la cabecera de la factura */
     open cfactventa;
     FETCH cfactventa into rfactventa;
    /* if (not nullvalue( rfactventa.importedescuento) AND rfactventa.importedescuento >0)THEN
           -- Si se realizo un decuento en caja
          importedescuento = rfactventa.importedescuento;
     END IF;*/
     SELECT into elem *
     FROM devolvernrofactura(centro(),rfactventa.tipocomprobante,rfactventa.tipofactura,rfactventa.nrosucursal);

     INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra)
            VALUES(rfactventa.tipocomprobante,rfactventa.nrosucursal,elem.sgtenumero,
                 rfactventa.nrodoc,rfactventa.barra,1000,centro(),current_date,rfactventa.tipofactura, rfactventa.barra);

     elcomprobante = concat(elem.tipocomprobante,'|',elem.tipofactura,'|',elem.nrosucursal,'|',elem.sgtenumero);

     /* Se vincula las ordenes a la factura generadas*/
     open corden;
     FETCH corden into rorden;
     WHILE FOUND LOOP
                 tipoorden = rorden.idcomprobantetipos;
                 INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,  nrofactura, nroorden, centro, idcomprobantetipos)
                 VALUES(elem.tipocomprobante,elem.nrosucursal, elem.tipofactura,elem.sgtenumero,
                 rorden.nroorden,rorden.centro,rorden.idcomprobantetipos);
/*KR 02-10-20 COMENTO por el proceso que realiza Cristina, emite remitos de farmacia para ordenes de vta de farmacia pero emitidas en sede central
            IF(elem.tipofactura <>'R')THEN */
                 PERFORM far_cambiarestadoordenventa( rorden.nroorden,rorden.centro,3);
      --        END IF; 
      FETCH corden into rorden;
      END LOOP;
      CLOSE corden;

     /* CREO LOS ITEMS DE LA FACTURA */
     IF (tipoorden=44) THEN --   Se esta facturando una orden de farmacia
                 elidarticulo = 0;
                 elidcentroarticulo = 0;
                 OPEN itemfact FOR  SELECT  *
                               FROM  far_ordenventaitem
                               NATURAL JOIN far_articulo
                               JOIN temporden ON (nroorden = idordenventa and idcentroordenventa = centro )
                               ORDER BY idarticulo; -- NO SACAR EL ORDER BY idarticulo este valor se tiene en cuaenta para crear o no un nuevo item de la factura
                 /* GENERO LOS ITEMS DE FACTURA VENTA*/

                 FETCH itemfact into unitemfact;
                 WHILE FOUND LOOP
                        IF (elidarticulo <> unitemfact.idarticulo OR elidcentroarticulo <> unitemfact.idcentroarticulo ) THEN
                                  /*se crea un nuevo item para la factura de venta*/
			                             INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                                         idconcepto,cantidad,importe,descripcion,idiva)
			                             VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                                         unitemfact.actacble,unitemfact.ovicantidad,round(CAST ((unitemfact.ovipreciolista * unitemfact.ovicantidad) AS numeric),2),unitemfact.ovidescripcion,unitemfact.oviidiva);
                                         -- Se guada el vinculo entre el item de una orden venta y el comprobante fiscal
                                         eliditemfactventa = currval('itemfacturaventa_iditem_seq');
                                         elidiva = unitemfact.oviidiva;
                        ELSE
                                  /*se actualiza el item anteriot de la factura de venta*/
                                  UPDATE itemfacturaventa
                                  SET cantidad = cantidad + unitemfact.ovicantidad
                                      , importe = importe + round(CAST((unitemfact.ovipreciolista * unitemfact.ovicantidad) AS numeric),2)
                                  WHERE iditem = eliditemfactventa
                                        and tipocomprobante=elem.tipocomprobante
                                        AND nrosucursal= elem.nrosucursal
                                        AND nrofactura=elem.sgtenumero
                                        AND tipofactura=elem.tipofactura;
                                 importedescuento = importedescuento + unitemfact.oviimpdescuento;
                       END IF;
               
                       INSERT INTO far_ordenventaitemitemfacturaventa (idordenventaitem,idcentroordenventaitem,
                               iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura)
                       VALUES(unitemfact.idordenventaitem,unitemfact.idcentroordenventaitem,
                             eliditemfactventa,elem.sgtenumero, elem.nrosucursal,elem.tipocomprobante,elem.tipofactura );
                       elidarticulo = unitemfact.idarticulo;
                       elidcentroarticulo = unitemfact.idcentroarticulo;
                       importedescuento = importedescuento + unitemfact.oviimpdescuento;
                  FETCH itemfact into unitemfact;
		          END LOOP;
		         
		
      END IF;

   open cfactventacupon;
   FETCH cfactventacupon into tfaccupon;
   WHILE FOUND LOOP

            tfaccupon.monto = round(CAST (tfaccupon.monto AS numeric),2);
           IF ( tfaccupon.idformapagotipos = 3 ) THEN   
              impctacte = impctacte + tfaccupon.monto;
            else
                impefect = impefect + tfaccupon.monto;
            END IF;
            INSERT INTO facturaventacupon(nrofactura, tipocomprobante, nrosucursal,
            tipofactura, idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon,fvcporcentajedto)
            VALUES(elem.sgtenumero, elem.tipocomprobante, elem.nrosucursal, elem.tipofactura,
                   tfaccupon.idvalorescaja, tfaccupon.autorizacion, tfaccupon.nrotarjeta,tfaccupon.monto,
                   tfaccupon.cuotas, tfaccupon.nrocupon,tfaccupon.fvcporcentajedto);
/*Dani modifico el 2020-04-23 para que genere la deuda cuando elijen lanueva forma de pago idvalorescaja=60 Cta.Cte.Farmacia*/
 /*KR 19-05-20 modifico para que gestione el idvalorescaja=960 (Cta Cte Cliente)*/
            IF ( tfaccupon.idvalorescaja = 60 OR tfaccupon.idvalorescaja = 960) THEN   
               PERFORM far_asentarconsumoctacte(elem.sgtenumero,elem.nrosucursal,elem.tipocomprobante,elem.tipofactura);            
            END IF;
         
          
   FETCH cfactventacupon into tfaccupon;
   END LOOP;
   CLOSE cfactventacupon;

     -- modifico VAS 16-04-2014 para generar los descuento exento y 21%far_asentarfacturaventav2
     -- INSERTO EL DESCUENTO COMO item de la factura
     -- modifico KR 26-05-14 para generar dtos por forma de pago
   /*  IF(importedescuento<>0)THEN
                -- Calculo los monto de descuentos para los diferentes tipo de iva
            -- elporcentaje = importedescuento / (sumaexento+sumaconiva);		
             --- Se crea el descuento exento
             IF (sumaexento <> 0) THEN
                        elidiva = 1;
                        INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                         idconcepto,cantidad,importe,descripcion,idiva)
                              VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                               50840,1,round(CAST ( (sumaexento * elporcentaje ) AS numeric),2)*-1,'Descuentos IVA EXENTO',elidiva);
             END IF;
                           --- Se crea el descuento con iva
	     IF ( sumaconiva <> 0 ) THEN
                            elidiva = 2;
                            INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                            idconcepto,cantidad,importe,descripcion,idiva)
                             VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                                50840,1,round(CAST ((sumaconiva * elporcentaje ) AS numeric),2)*-1,'Descuento IVA 21%',elidiva);
             END IF;
	            
     END IF;*/

 
  PERFORM far_guardardescuentosporiva(elem.sgtenumero,elem.nrosucursal,elem.tipocomprobante,elem.tipofactura);

   --- Se ingresan las formas de pago que no estan vinculadas al afiliado
   OPEN cformaspago FOR  SELECT  idvalorescaja, SUM(oviimonto) as oviimonto,oviiautorizacion
   FROM far_ordenventaitemimportes
   NATURAL JOIN far_ordenventaitem
    JOIN temporden ON (nroorden = idordenventa and idcentroordenventa = centro )
   WHERE idvalorescaja <> 0
   group by idvalorescaja ,oviiautorizacion;

   FETCH cformaspago into unaformaspago;
   WHILE FOUND LOOP
            IF (unaformaspago.idvalorescaja = 0 ) THEN
                      impefect = impefect + round(CAST (unaformaspago.oviimonto AS numeric),2) ;
            else
                      impctacte = impctacte + round(CAST (unaformaspago.oviimonto AS numeric),2) ;
            END IF;

            INSERT INTO facturaventacupon (nrofactura, tipocomprobante, nrosucursal, tipofactura,
             idvalorescaja,   monto,nrocupon, nrotarjeta, cuotas , autorizacion)
            VALUES(elem.sgtenumero, elem.tipocomprobante, elem.nrosucursal, elem.tipofactura,
                   unaformaspago.idvalorescaja,round(CAST (unaformaspago.oviimonto AS numeric),2) ,'','',0,unaformaspago.oviiautorizacion);
   FETCH cformaspago into unaformaspago;
   END LOOP;

   /* se devuelve el comprobante generado */

   /* se guarda la relacion entre el comprobante y el usuario que esta logeado*/
   IF ( not nullvalue(rfactventa.idusuario) ) THEN
           INSERT INTO  facturaventausuario ( nrosucursal, nrofactura,tipofactura,tipocomprobante,idusuario)
           VALUES ( elem.nrosucursal,elem.sgtenumero, elem.tipofactura, elem.tipocomprobante ,rfactventa.idusuario );
   END IF;

   /* Se actualiza la cabecera de la factura */
   UPDATE facturaventa SET
                   importeamuc=0  ,
                   importeefectivo=impefect ,
                   importedebito=0,
                   importecredito=0,
                   importectacte=impctacte,
                   importesosunc=0,
                   formapago=idpago
    WHERE tipocomprobante=elem.tipocomprobante
                   AND nrosucursal= elem.nrosucursal
                   AND nrofactura=elem.sgtenumero
                   AND tipofactura=elem.tipofactura;

    /* Se guarda la fecha de emision del no fiscal de la factura*/
    INSERT INTO facturaventanofiscal(tipocomprobante,nrosucursal,nrofactura,tipofactura)
VALUES (elem.tipocomprobante,elem.nrosucursal,elem.sgtenumero,elem.tipofactura );

     END IF;
/*guardo la info de forma de pago de los items (descuento, tarjeta)  tipoorden PREGUNTO SI es 44 ? solo farma guardamos?*/
   IF iftableexists('tempoviiformapago') THEN
        SELECT INTO vretorno * FROM far_facturaventaformapago(elcomprobante);
  
       
   END IF;
return elcomprobante;
END;$function$
