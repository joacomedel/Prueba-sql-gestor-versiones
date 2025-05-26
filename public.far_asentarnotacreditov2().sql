CREATE OR REPLACE FUNCTION public.far_asentarnotacreditov2()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

elidiva integer;
tipoorden integer;
idpago integer;
elcomprobante varchar(100);
eliditemfactventa bigint;
resp boolean;
importetotal DOUBLE PRECISION=0;

--REGISTROS
elem record;

cformaspago refcursor;
unaformaspago record;
elitemordenventa record;
itemfact refcursor;
rnotacredito  record;
rfactventa record;
unitemfact record;
tfaccupon record;
ritemfacturaorig record;
impamuc DOUBLE PRECISION=0;
impctacte DOUBLE PRECISION=0;
impefect DOUBLE PRECISION=0;
elporcentaje DOUBLE PRECISION=0;
importesiniva DOUBLE PRECISION=0;
importedescuento DOUBLE PRECISION=0;

sumaexento DOUBLE PRECISION=0;
sumaconiva DOUBLE PRECISION=0;

--CURSORES

cfactventa CURSOR FOR SELECT * FROM tempfacturaventa WHERE tipofactura = 'FA';
cnotacredito CURSOR FOR SELECT * FROM tempfacturaventa WHERE tipofactura = 'NC';
citemfactventa CURSOR FOR SELECT * FROM temitemfacturaventa  JOIN tipoiva using (idiva) WHERE cantidad <> 0;
cfactventacupon CURSOR FOR SELECT * FROM tempfacturaventacupon JOIN valorescaja USING (idvalorescaja) WHERE monto<> 0;
BEGIN

     /* Cambio el estado de las ordenes a estado facturado
     SELECT far_cambiarestadoordenventa(nroorden,centro,5) FROM temporden;
     */
     open cfactventa;
     FETCH cfactventa into rfactventa;

     /* Se guarda la cabecera de la factura */
     open cnotacredito;
     FETCH cnotacredito into rnotacredito;
     SELECT into elem *
     FROM devolvernrofactura(centro(),rnotacredito.tipocomprobante,rnotacredito.tipofactura,rnotacredito.nrosucursal);

     INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra)
            VALUES(rnotacredito.tipocomprobante,rnotacredito.nrosucursal,elem.sgtenumero,
                 rnotacredito.nrodoc,rnotacredito.barra,1000,centro(),current_date,rnotacredito.tipofactura, rnotacredito.barra);




     elcomprobante = concat(rnotacredito.tipocomprobante,'|',rnotacredito.tipofactura,'|',rnotacredito.nrosucursal,'|',elem.sgtenumero);

     open citemfactventa;
     FETCH citemfactventa into unitemfact;
     WHILE FOUND LOOP
                          /* busco los datos de los item de la factura*/


                          SELECT INTO ritemfacturaorig	round(CAST (( importe/cantidad ) AS numeric),2) as importeunit 	, *
                          FROM itemfacturaventa
                          WHERE iditem = unitemfact.iditem and
                                nrofactura = rfactventa.nrofactura and
                                nrosucursal = rfactventa.nrosucursal and
                                tipocomprobante = rfactventa.tipocomprobante and
                                tipofactura = rfactventa.tipofactura;

                         importetotal = importetotal + ( ritemfacturaorig.importeunit *  unitemfact.cantidad);
                         importesiniva =  ( ritemfacturaorig.importeunit *  unitemfact.cantidad);

                          ----- evaluo el tipo ivba del item
                          IF (unitemfact.idiva = 1 ) THEN
                               sumaexento = sumaexento + round(CAST((ritemfacturaorig.importeunit * unitemfact.cantidad) AS numeric),2);
                          ELSE
                               sumaconiva = sumaconiva + round(CAST((ritemfacturaorig.importeunit * unitemfact.cantidad) AS numeric),2);
                          END IF;

                        --importetotal = importetotal + round(CAST (unitemfact.importe AS numeric),2);
                        --importesiniva = unitemfact.importe / (1 +unitemfact.porcentaje);


			            INSERT INTO itemfacturaventa (tipocomprobante,nrosucursal,tipofactura,nrofactura,
                        idconcepto,cantidad,importe,descripcion,idiva)
			            VALUES(rnotacredito.tipocomprobante,
                        rnotacredito.nrosucursal,
                        rnotacredito.tipofactura,
                        elem.sgtenumero,
                        unitemfact.idconcepto,
                        unitemfact.cantidad,
                        round(CAST (importesiniva AS numeric),2),
                        unitemfact.descripcion,
                        unitemfact.idiva);
                        /* Recupero cada uno de los items para actualizar el stock de los articulos que son devueltos  */
                           -- Se guada el vinculo entre el item de una orden venta y el comprobante fiscal
                        eliditemfactventa = currval('itemfacturaventa_iditem_seq');

                      --  INSERT INTO temitemfacturaventa(iditem,idconcepto,cantidad,importe,descripcion,idiva)  VALUES (142177, '666',1,'27.6','PETIT ENFANT 0A1 NEUT 240M LIN',1);

                        UPDATE far_ordenventaitemitemfacturaventa
                        SET ovcantdevueltas = ovcantdevueltas + unitemfact.cantidad
                         WHERE iditem = unitemfact.iditem and
                              nrofactura = rfactventa.nrofactura and
                              nrosucursal = rfactventa.nrosucursal and
                              tipocomprobante = rfactventa.tipocomprobante and
                              tipofactura = rfactventa.tipofactura;

                        SELECT INTO elitemordenventa *
                        FROM far_ordenventaitemitemfacturaventa
                        WHERE iditem = unitemfact.iditem and
                              nrofactura = rfactventa.nrofactura and
                              nrosucursal = rfactventa.nrosucursal and
                              tipocomprobante = rfactventa.tipocomprobante and
                              tipofactura = rfactventa.tipofactura;

                       INSERT INTO far_ordenventaitemitemfacturaventa (idordenventaitem,idcentroordenventaitem,
                               iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas)
                        VALUES(elitemordenventa.idordenventaitem,elitemordenventa.idcentroordenventaitem,
                             eliditemfactventa,elem.sgtenumero, rnotacredito.nrosucursal,rnotacredito.tipocomprobante,rnotacredito.tipofactura,
                             unitemfact.cantidad);
                        elidiva = unitemfact.idiva;
     FETCH citemfactventa into unitemfact;
     END LOOP;
    CLOSE citemfactventa;

    /* Ingreso el descuento de la factura */
     importedescuento = rnotacredito.importedescuento;
     IF(importedescuento<>0)THEN
             -- Calculo los monto de descuentos para los diferentes tipo de iva
             elporcentaje = importedescuento / (sumaexento+sumaconiva);	
             IF (sumaexento <> 0 ) THEN
                     elidiva = 1;
                     INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                         idconcepto,cantidad,importe,descripcion,idiva)
                     VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                                       50840,1,round(CAST ( (sumaexento * elporcentaje ) AS numeric),2)*-1,'Descuentos IVA EXENTO',elidiva);

             END IF;
             IF (sumaconiva <> 0 ) THEN
                     elidiva = 2;
                     INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                         idconcepto,cantidad,importe,descripcion,idiva)
                       VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                                       50840,1,round(CAST ((sumaconiva * elporcentaje ) AS numeric),2)*-1,'Descuento IVA 21%',elidiva);

             END IF;

             importetotal = importetotal - (round(CAST (importedescuento AS numeric),2)*-1);
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
            VALUES(elem.sgtenumero, rnotacredito.tipocomprobante, rnotacredito.nrosucursal, rnotacredito.tipofactura,
                   tfaccupon.idvalorescaja, tfaccupon.autorizacion, tfaccupon.nrotarjeta,tfaccupon.monto,
                   tfaccupon.cuotas, tfaccupon.nrocupon,tfaccupon.fvcporcentajedto);
   FETCH cfactventacupon into tfaccupon;
   END LOOP;
   CLOSE cfactventacupon;



    --- Se ingresan las formas de pago que no estan vinculadas al afiliado
   /*OPEN cformaspago FOR  SELECT idvalorescaja , SUM((oviimonto / ovicantidad)*temitemfacturaventa.cantidad)as oviimonto, oviiautorizacion
   FROM itemfacturaventa
   NATURAL JOIN far_ordenventaitemitemfacturaventa
   NATURAL JOIN far_ordenventaitem
   NATURAL JOIN far_ordenventaitemimportes
   join temitemfacturaventa using(iditem)
   WHERE  idvalorescaja <>0
   group by idvalorescaja ,oviiautorizacion;*/

   OPEN cformaspago FOR  SELECT idvalorescaja , SUM((oviimonto / ovicantidad)*temitemfacturaventa.cantidad)as oviimonto, oviiautorizacion
   FROM itemfacturaventa
   NATURAL JOIN (
           SELECT  iditem, nrofactura,nrosucursal,tipocomprobante,tipofactura, MIN(idordenventaitem) as idordenventaitem,        MIN(idcentroordenventaitem) as  idcentroordenventaitem
           FROM far_ordenventaitemitemfacturaventa
           group by iditem, nrofactura,nrosucursal,tipocomprobante,tipofactura
   ) as T
   NATURAL JOIN far_ordenventaitem
   NATURAL JOIN far_ordenventaitemimportes
   JOIN temitemfacturaventa using(iditem)
   WHERE  idvalorescaja <>0
   group by idvalorescaja ,oviiautorizacion;

   FETCH cformaspago into unaformaspago;
   WHILE FOUND LOOP

           INSERT INTO facturaventacupon (nrofactura, tipocomprobante, nrosucursal, tipofactura,
             idvalorescaja,   monto,nrocupon, nrotarjeta, cuotas , autorizacion )
            VALUES(elem.sgtenumero, elem.tipocomprobante, elem.nrosucursal, elem.tipofactura,
                   unaformaspago.idvalorescaja,round(CAST (unaformaspago.oviimonto AS numeric),2) ,'','',0,unaformaspago.oviiautorizacion
                   );
            impctacte = impctacte + round(CAST (unaformaspago.oviimonto AS numeric),2);

   FETCH cformaspago into unaformaspago;
   END LOOP;
   CLOSE cformaspago;
   /* Actualizo el importe en cta cte del comprobante importetotal */

   UPDATE facturaventa SET importectacte = impctacte ,importeefectivo=impefect
   WHERE tipocomprobante=rnotacredito.tipocomprobante
                   AND nrosucursal= rnotacredito.nrosucursal
                   AND nrofactura=elem.sgtenumero
                   AND tipofactura=rnotacredito.tipofactura;





  -- Creo la temporal para actualizar el stock de los articulos de comprobante

  CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
  INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)
       VALUES(concat(' Comprobante NC ',elem.sgtenumero ,'|',rnotacredito.tipocomprobante, '|', rnotacredito.nrosucursal, '|', rnotacredito.tipofactura) ,6);
  SELECT INTO resp * FROM far_movimientostocknuevo('facturaventa',concat(elem.sgtenumero ,'|', rnotacredito.tipocomprobante, '|',rnotacredito.nrosucursal, '|', rnotacredito.tipofactura));



   /* se guarda la relacion entre el comprobante y el usuario que esta logeado */
   IF ( not nullvalue(rnotacredito.idusuario) ) THEN
           INSERT INTO  facturaventausuario ( nrosucursal,nrofactura,tipofactura,tipocomprobante,idusuario)
           VALUES ( elem.nrosucursal,elem.sgtenumero, elem.tipofactura, elem.tipocomprobante,rnotacredito.idusuario );
   END IF;


  /* Se guarda la fecha de emision del no fiscal de la factura*/
    INSERT INTO facturaventanofiscal(tipocomprobante,nrosucursal,nrofactura,tipofactura)
VALUES (elem.tipocomprobante,elem.nrosucursal,elem.sgtenumero,elem.tipofactura );



   CLOSE cfactventa;
   CLOSE cnotacredito;

  /* se devuelve el comprobante generado */
return elcomprobante;
END;
$function$
