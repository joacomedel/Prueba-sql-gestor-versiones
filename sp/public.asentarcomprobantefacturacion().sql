CREATE OR REPLACE FUNCTION public.asentarcomprobantefacturacion()
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
existe BOOLEAN;
esND BOOLEAN DEFAULT FALSE;
vimporteitem double precision;
vimporteiva double precision;
fvfechaemision  date;
todook VARCHAR;
vmtoctacte BOOLEAN DEFAULT TRUE;

--REGISTROS
elem record;
itemfact refcursor;
recfp record;
rfactventa record;
rorden record;
unitemfact record;
tfaccupon record;
elcomprobante record; 
rfactcc record;
rtipoiva record;
rtemporal RECORD;
rconfigprestamo RECORD;

--CURSORES

cfactventa CURSOR FOR SELECT * FROM tempfacturaventa;
cfactventacupon CURSOR FOR SELECT sum(monto) as monto,idvalorescaja,autorizacion,nrotarjeta,cuotas,nrocupon
                              FROM tempfacturaventacupon GROUP BY idvalorescaja,autorizacion,nrotarjeta,cuotas,nrocupon;




cfactventaitem refcursor; 
cfactventacc refcursor;
--CURSOR FOR SELECT * FROM tempcentrocostos;


BEGIN
     vmtoctacte = TRUE;

     
     /* Se guarda la cabecera de la factura */
     open cfactventa;
     FETCH cfactventa into rfactventa;
--KR 22-06-21 ME fijo si debo generar mto en la cta cte correspondiente
     IF (existecolumtemp('tempfacturaventa','fvgeneramvtoctacte')) THEN
        vmtoctacte= rfactventa.fvgeneramvtoctacte;
     END IF;
--DANI agrego el 07/08/21 porq el campo de la temporal que viene desde java tiene el nombre ctacte , con lo cual sino esta esto no impactaba en la ctacte 
--MaLaPi 01/09/2021 Lo comento, porque en la emision de Comprobantes para Jubilados, se esta poniendo este valor en verdadero pero se usa el campo fvgeneramvtoctacte 
--para determinar su se debe o no generar el movimiento en ctacte.
--MaLaPi 01/09/2021 Si el valor que tiene desde Java es Verdadero, el movimiento lo va a generar igual, por el valor por defecto de esta variable es verdadero.  
--    IF (existecolumtemp('tempfacturaventa','ctacte')) THEN
--        vmtoctacte= rfactventa.ctacte;
--    END IF;

     -- Malapi 12/12/2016 Si se manda el centro del talonario, busco ese talonario, sino uso la funcion centro()
     IF nullvalue(rfactventa.centro) THEN 
         SELECT into elem *
          FROM devolvernrofactura(centro(),rfactventa.tipocomprobante,rfactventa.tipofactura,rfactventa.nrosucursal);

     ELSE
           SELECT into elem *
          FROM devolvernrofactura(rfactventa.centro,rfactventa.tipocomprobante,rfactventa.tipofactura,rfactventa.nrosucursal);
     END IF;
     fvfechaemision = current_date;
     IF (existecolumtemp('tempfacturaventa','fvfechaemision')) THEN
        fvfechaemision = rfactventa.fvfechaemision;
     END IF;
      RAISE NOTICE 'Vamos a generar la factura de (%)',rfactventa; 
     INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra)
            VALUES(rfactventa.tipocomprobante,rfactventa.nrosucursal,elem.sgtenumero,
                 rfactventa.nrodoc,rfactventa.barra,1000,elem.centro,fvfechaemision,rfactventa.tipofactura, rfactventa.barra);
     

    SELECT INTO elcomprobante facturaventa.nrofactura,facturaventa.tipocomprobante,facturaventa.nrosucursal, facturaventa.tipofactura,talonario.timprime 
    			 FROM facturaventa NATURAL JOIN talonario
           		 WHERE tipocomprobante=elem.tipocomprobante AND nrosucursal=elem.nrosucursal AND nrofactura=elem.sgtenumero AND tipofactura=elem.tipofactura;

     
    
      OPEN cfactventaitem FOR SELECT idconcepto  ,descripcion,idiva,  SUM(cantidad)as cantidad ,SUM(CASE WHEN nullvalue(subtotal) THEN importe ELSE subtotal END)as importe,iditemcc,SUM(ivaimporte) as ivaimporte
      FROM temitemfacturaventa
      GROUP BY idconcepto ,descripcion,idiva ,iditemcc;

  
      /* GENERO LOS ITEMS DE FACTURA VENTA*/
     
      FETCH cfactventaitem into unitemfact;
            WHILE FOUND LOOP
                    /*18-10-2013 Malapi: Modifico para que si el idiva <> 1 (No exento) se guarde el item del iva. 
                    */
                   
                    

                    IF (unitemfact.idiva = 2 or unitemfact.idiva =3 ) THEN
                       SELECT INTO rtipoiva * FROM tipoiva WHERE idiva = unitemfact.idiva;
                      IF (nullvalue(unitemfact.ivaimporte)) THEN   --KR 23-01-19 no calcularon el iva en la app    
                           vimporteitem = round(CAST (unitemfact.importe AS numeric),3) / (1 + rtipoiva.porcentaje);
                           vimporteitem = round(CAST (vimporteitem AS numeric),3);
                           vimporteiva = round(CAST (unitemfact.importe AS numeric),3)  - vimporteitem;
                           vimporteiva = round(CAST (vimporteiva AS numeric),3);
                      ELSE --el iva viene calculado desde la app 
                           vimporteitem = round(CAST (unitemfact.importe AS numeric),3);
                           vimporteiva = round(CAST (unitemfact.ivaimporte AS numeric),3); 
                           
                      END IF; 
                     --Guardo el item sin iva
                        INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                    idconcepto,cantidad,importe,descripcion,idiva)
	            VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                        unitemfact.idconcepto,unitemfact.cantidad,vimporteitem,unitemfact.descripcion,unitemfact.idiva);
                     --Guardo el item del iva
                        INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                    idconcepto,cantidad,importe,descripcion,idiva)
	            VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                        rtipoiva.nrocuentac,1,vimporteiva,concat('Iva del ',rtipoiva.descripcion) ,unitemfact.idiva);
                      
                   ELSE 

	            INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                    idconcepto,cantidad,importe,descripcion,idiva)
	            VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                        unitemfact.idconcepto,unitemfact.cantidad,round(CAST (unitemfact.importe AS numeric),3),unitemfact.descripcion,unitemfact.idiva);
                   
                       END IF;
       

       IF  iftableexistsparasp('tempcentrocostos') THEN 

            open cfactventacc FOR SELECT * FROM tempcentrocostos WHERE iditemcc=unitemfact.iditemcc;
	    FETCH cfactventacc into rfactcc;
	    WHILE FOUND LOOP
			INSERT INTO itemfacturaventacentroscosto (nrosucursal,nrofactura,tipocomprobante,                                                  
                                                      tipofactura,idcentrocosto,monto,iditem)                       
                        VALUES(elcomprobante.nrosucursal,
                               elcomprobante.nrofactura,
                               elcomprobante.tipocomprobante,
                               elcomprobante.tipofactura,
			       rfactcc.idcentrocosto,
                               round(CAST (rfactcc.importe AS numeric),3),
/*Dani reemplazo el 28102022 el curval por nextval*/
			       nextval('itemfacturaventa_iditem_seq'));
                        FETCH cfactventacc into rfactcc;
	    END LOOP;
	    CLOSE cfactventacc;
	ELSE
			INSERT INTO itemfacturaventacentroscosto (nrosucursal,nrofactura,tipocomprobante,                                                  
                                                      tipofactura,idcentrocosto,monto,iditem)                       
                        VALUES(elcomprobante.nrosucursal,
                               elcomprobante.nrofactura,
                               elcomprobante.tipocomprobante,
                               elcomprobante.tipofactura,
			       1,
                               round(CAST (unitemfact.importe AS numeric),3),
/*Dani reemplazo el 28102022 el curval por nextval*/
			       nextval('itemfacturaventa_iditem_seq'));
	END IF;
                  FETCH cfactventaitem into unitemfact;
      END LOOP;
      CLOSE cfactventaitem;


   open cfactventacupon;
   FETCH cfactventacupon into tfaccupon;
   WHILE FOUND LOOP

            tfaccupon.monto = round(CAST (tfaccupon.monto AS numeric),3);
            INSERT INTO facturaventacupon(nrofactura, tipocomprobante, nrosucursal,
            tipofactura, idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon,centro)
            VALUES(elem.sgtenumero, elem.tipocomprobante, elem.nrosucursal, elem.tipofactura,
                   tfaccupon.idvalorescaja, tfaccupon.autorizacion, tfaccupon.nrotarjeta,tfaccupon.monto,
                   tfaccupon.cuotas, tfaccupon.nrocupon,elem.centro);
   FETCH cfactventacupon into tfaccupon;
   END LOOP;
   CLOSE cfactventacupon;

   /* Recupero forma pago */
   /*24-09-2013 Malapi: Modifico para que coloque en importectacte todo lo que es cta cte y en importeefectivo todo lo que no es ctacte */

   SELECT INTO recfp  CASE WHEN nullvalue(SUM(monto)) THEN 0 ELSE SUM(monto) END as total     
                              FROM valorescaja 
                              NATURAL JOIN facturaventacupon  
                              WHERE tipofactura = elem.tipofactura
                              AND nrofactura=elem.sgtenumero 
                             AND tipocomprobante = elem.tipocomprobante AND nrosucursal= elem.nrosucursal
                              AND idformapagotipos = 3;

  IF FOUND THEN 
                UPDATE facturaventa SET importectacte= recfp.total
		WHERE tipofactura = elem.tipofactura
                AND nrofactura=elem.sgtenumero AND tipocomprobante = elem.tipocomprobante AND nrosucursal= elem.nrosucursal;
               
	
		
        
  END IF; 

SELECT INTO recfp  CASE WHEN nullvalue(SUM(monto)) THEN 0 ELSE SUM(monto) END as total     
                              FROM valorescaja 
                              NATURAL JOIN facturaventacupon  
                              WHERE tipofactura = elem.tipofactura
                              AND nrofactura=elem.sgtenumero 
                             AND tipocomprobante = elem.tipocomprobante AND nrosucursal= elem.nrosucursal
                              AND idformapagotipos <> 3;
 IF FOUND THEN 
		 UPDATE facturaventa SET importeefectivo= recfp.total
		 WHERE tipofactura = elem.tipofactura
                              AND nrofactura=elem.sgtenumero AND tipocomprobante = elem.tipocomprobante AND nrosucursal= elem.nrosucursal;
 END IF;

-- KR se pone en produccion el 05-02-19
IF iftableexistsparasp('tempconfiguracionprestamo') THEN   
  SELECT INTO rconfigprestamo * FROM tempconfiguracionprestamo; 
  IF FOUND THEN 
       PERFORM abmsolicitudfinanciacion();
  END IF; 
 END IF;

CLOSE cfactventa;

/*KR 18-06-21 Coloco aqui la forma de generar movimientos en las tablas de cta cte (afiliado, cliente y prestador) puede que genere algun error pq hay mucho lio con esto. Avisenme si es asii! */
IF vmtoctacte THEN 
 SELECT INTO todook * FROM sys_generar_movimientoctacte (concat('{nrodoc=' , rfactventa.nrodoc, ',barra =',rfactventa.barra,' , nrofactura= ',elem.sgtenumero,' , tipocomprobante= ',elem.tipocomprobante,', tipofactura= ',
     elem.tipofactura,', nrosucursal= ',elem.nrosucursal, ', nroinforme=',NULL, ', idcentroinformefacturacion= ',NULL,',idcomprobantetipos=',NULL,', movconcepto = ', null, '}'));
END IF;
    RETURN NEXT elcomprobante;
END;
$function$
