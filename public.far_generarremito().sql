CREATE OR REPLACE FUNCTION public.far_generarremito()
 RETURNS SETOF far_stockajusteremito
 LANGUAGE plpgsql
AS $function$DECLARE

--CURSORES
    cremitoitem refcursor;
   

--RECORD
    elem RECORD; 
    unremito RECORD; 
    regremitoitem RECORD; 
    rfacvtacupon RECORD; 
    rfacturaventar far_stockajusteremito%ROWTYPE ; 
    rusuario RECORD;
--VARIABLES
    elcomprobante varchar(100);
    cantcomp BIGINT; 
    indice BIGINT; 
    desplazamiento INTEGER;-- DEFAULT 10;
    cont INTEGER;
    primerremito BIGINT;
    elidusuario INTEGER; 
BEGIN
      
     SELECT INTO unremito *  FROM far_stockajusteremitotmp JOIN cliente ON(idprestador=nrocliente);
    
     SELECT INTO cantcomp (count(*)/10)
                  FROM far_stockajuste NATURAL JOIN  far_stockajusteitem  NATURAL JOIN far_articulo
                  WHERE   idstockajuste = unremito.idstockajuste AND idcentrostockajuste=unremito.idcentrostockajuste; --AND idsigno =-1

     indice = 0;
     desplazamiento=10;
     cont =0;
     WHILE (cont <= cantcomp) LOOP

     /*Genero la cabecera del remito */
     SELECT INTO elem * FROM devolvernrofactura(centro(),1,'R',1);
     IF cont =0 THEN
           primerremito = elem.sgtenumero; 
     END IF; 
     INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra)
            VALUES(elem.tipocomprobante,elem.nrosucursal,elem.sgtenumero,
                 unremito.nrocliente,unremito.barra,1000,centro(),current_date,elem.tipofactura, unremito.barra);

     elcomprobante = concat(elem.tipocomprobante,'|',elem.tipofactura,'|',elem.nrosucursal,'|',elem.sgtenumero);

     INSERT INTO far_stockajusteremito (idstockajuste, idcentrostockajuste, 
                   tipocomprobante,nrosucursal,nrofactura,tipofactura,sardescripcion)
            VALUES(unremito.idstockajuste,unremito.idcentrostockajuste,
                 elem.tipocomprobante,elem.nrosucursal,elem.sgtenumero,elem.tipofactura,unremito.motivo);
 
     OPEN cremitoitem FOR
                  SELECT *  
                  FROM far_stockajuste NATURAL JOIN  far_stockajusteitem  NATURAL JOIN far_articulo
                  WHERE   idstockajuste = unremito.idstockajuste AND idcentrostockajuste=unremito.idcentrostockajuste --AND idsigno =-1
                  ORDER BY adescripcion
                  LIMIT desplazamiento OFFSET indice;

  /*Genero los items del remito de a 10 items  */

     FETCH cremitoitem INTO regremitoitem;
   
     WHILE FOUND LOOP
                 IF (NOT nullvalue(regremitoitem.saicantidad)) THEN 
                   INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                        idconcepto,cantidad,importe,descripcion,idiva)
	           VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,
                   elem.sgtenumero,regremitoitem.actacble,regremitoitem.saicantidad,
                   round(CAST (regremitoitem.saiimportetotal AS numeric),2),regremitoitem.adescripcion
                   ,regremitoitem.idiva);
                  END IF;                  
                  FETCH cremitoitem into regremitoitem;
         END LOOP;
     CLOSE cremitoitem;
     indice= indice +10;
     cont = cont +1;
     
     SELECT INTO rfacvtacupon SUM(importe) as monto  FROM  itemfacturaventa  
             WHERE tipocomprobante=elem.tipocomprobante
                   AND nrosucursal= elem.nrosucursal
                   AND nrofactura=elem.sgtenumero
                   AND tipofactura=elem.tipofactura;
     
    IF not (nullvalue(rfacvtacupon.monto)) THEN 
           INSERT INTO facturaventacupon(nrofactura, tipocomprobante, nrosucursal,
            tipofactura, idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon)
            VALUES(elem.sgtenumero, elem.tipocomprobante, elem.nrosucursal, elem.tipofactura,
                  3, 0, 0, round(CAST (rfacvtacupon.monto AS numeric),2),
                   1, 0);
   

   /* se devuelve el comprobante generado */


   /* Se actualiza la cabecera de la factura */
   UPDATE facturaventa SET
                   importeamuc=0,
                   importeefectivo=0,
                   importedebito=0,
                   importecredito=round(CAST (rfacvtacupon.monto AS numeric),2),
                   importectacte=0,
                   importesosunc=0
                  
    WHERE tipocomprobante=elem.tipocomprobante
                   AND nrosucursal= elem.nrosucursal
                   AND nrofactura=elem.sgtenumero
                   AND tipofactura=elem.tipofactura;

  END IF;

  INSERT INTO multivac.facturaventa_migrada(nrofactura, tipocomprobante, nrosucursal,
            tipofactura,centro, iditem, fechamigracion, estaanulada)
            VALUES(elem.sgtenumero, elem.tipocomprobante, elem.nrosucursal, elem.tipofactura,
                 centro(), 0, now(),0 );


/* Se guarda la informacion del usuario que genero el comprobante */
                SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
                IF not found THEN
                   elidusuario = 25;
                ELSE
                    elidusuario = rusuario.idusuario;
                END IF;
                INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                VALUES   (elem.tipocomprobante,elem.nrosucursal,elem.sgtenumero, elem.tipofactura,elidusuario,elem.sgtenumero);

END LOOP;


     FOR rfacturaventar in  SELECT * FROM  far_stockajusteremito 
                            WHERE   idstockajuste = unremito.idstockajuste AND idcentrostockajuste=unremito.idcentrostockajuste 
                             AND nrofactura >= primerremito AND nrofactura <=elem.sgtenumero
    	loop

       return next rfacturaventar;

      end loop;
END;
$function$
