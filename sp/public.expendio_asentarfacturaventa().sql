CREATE OR REPLACE FUNCTION public.expendio_asentarfacturaventa()
 RETURNS SETOF facturaventa
 LANGUAGE plpgsql
AS $function$declare

/*

CREATE TEMP TABLE temp_recibocliente (
    idrecibo bigint,
    centro INTEGER,
    nrodoc VARCHAR,
    tipodoc INTEGER
);

15-07-2019 MaLaPi: Modifico para que se pueda usar por el facturador de facturas online. Viene con la accion 'atogestion'. 
Ademas se le agregan a la tabla temp_recibocliente los campos idformapagotipos, idvalorescaja para saber que forma de pago se deben facturar y a que forma de pago se deben enviar


*/
--CURSORES
cfactventaitemag refcursor;
cfactventafvcag refcursor;
vestaconfurado BOOLEAN;
--KR 23-03-22 corrijo para que haga una orden - una factura 
cfactventaag CURSOR FOR SELECT nrodoc, tipodoc ,fecharecibo ::date, nroorden, centro, tipo,idrecibo 
                               FROM temp_recibocliente NATURAL JOIN ordenrecibo  NATURAL JOIN orden NATURAL JOIN recibo 
                               -- GROUP BY nrodoc, tipodoc,fecharecibo::date
                               ORDER BY fecharecibo::date ASC;
--RECORD 
   rpta RECORD;
   rfactventa RECORD; 
   rcomprobante RECORD;
   titularfactura  RECORD;
   rusuario RECORD;
   elcomprobante RECORD;
   rfactventaitem RECORD;
   rfactventafvc RECORD;
   rfacturaventa public.facturaventa%rowtype;
   rconfiguracion RECORD;
   vfechafactura date;
--VARIABLES 
 

BEGIN

IF NOT  iftableexists('temitemfacturaventa') THEN

CREATE TEMP TABLE temitemfacturaventa (idconcepto  VARCHAR , 
			  cantidad INTEGER , 
			  importe DOUBLE PRECISION , 
			  descripcion VARCHAR, 
			  idiva INTEGER,
			  subtotal DOUBLE PRECISION,
			  ivaimporte DOUBLE PRECISION
			  ,iditemcc INTEGER );
ELSE

DELETE FROM temitemfacturaventa;

END IF;

IF NOT  iftableexists('tempfacturaventacupon') THEN

    CREATE TEMP TABLE tempfacturaventacupon ( idvalorescaja INTEGER , 
			  autorizacion VARCHAR , 
			  nrotarjeta VARCHAR,  
			  monto DOUBLE PRECISION ,  
			  montodto DOUBLE PRECISION ,  
			  cuotas SMALLINT , 
			  fvcporcentajedto DOUBLE PRECISION ,  
			  nrocupon VARCHAR); 
ELSE

DELETE FROM tempfacturaventacupon;

END IF;

IF NOT  iftableexists('tempfacturaventa') THEN

    CREATE TEMP TABLE tempfacturaventa ( tipocomprobante INTEGER , 
                          nrosucursal INTEGER , 
			  nrofactura BIGINT , 
			  nrodoc VARCHAR, 
			  tipodoc SMALLINT, 
			  ctacontable INTEGER, 
			  centro INTEGER , 
 			  tipofactura VARCHAR(2), 
			  barra BIGINT ,
			  importedescuento DOUBLE PRECISION , 
			  idusuario BIGINT   );
ELSE


DELETE FROM tempfacturaventa;

END IF;  

IF NOT  iftableexists('temporden') THEN

    CREATE TEMP TABLE  temporden ( nroorden BIGINT , 
                                   centro INTEGER , 
                                   idcomprobantetipos BIGINT );
    
ELSE


DELETE FROM temporden;

END IF;

IF NOT  iftableexists('tempfacturaventageneradas') THEN

    CREATE TEMP TABLE tempfacturaventageneradas ( tipocomprobante INTEGER , 
                          nrosucursal INTEGER , 
			  nrofactura BIGINT , 
			  nrodoc VARCHAR, 
			  tipodoc SMALLINT, 
			  tipofactura VARCHAR(2), 
			  barra BIGINT 
			   );  

ELSE


DELETE FROM tempfacturaventageneradas;

END IF;
RAISE NOTICE 'Iniciando ';
vestaconfurado = false;
vfechafactura = null;
SELECT INTO rconfiguracion * FROM temp_recibocliente LIMIT 1;
IF FOUND THEN
/*
	IF existecolumtemp('temp_recibocliente', 'idvalorescaja') THEN
		vestaconfurado = true;
	END IF;
*/
	-- BelenA 20/09/24 cambio que tenga en cuenta que el idvalorescaja no sea nulo, se cambia la condicion porque ahora temp_recibocliente siempre tiene la columna "idvalorescaja", a veces con nulo y otra veces con valor
	IF (existecolumtemp('temp_recibocliente', 'idvalorescaja') AND NOT nullvalue(rconfiguracion.idvalorescaja) ) THEN
		vestaconfurado = true;
	END IF;
        
-- MaLaPi 12-05-2021 Viene configurado desde el cliente, la fecha que tiene que tener la factura
        IF existecolumtemp('temp_recibocliente', 'fechafactura') THEN
		vfechafactura= rconfiguracion.fechafactura;
	END IF;

END IF;

  OPEN cfactventaag;
  FETCH cfactventaag into rfactventa;
  WHILE  FOUND LOOP

     
   SELECT INTO rcomprobante * FROM talonario 
                WHERE (not vestaconfurado AND tipocomprobante=1 AND nrosucursal=1 AND tipofactura='FA')
                OR (vestaconfurado AND tipocomprobante = 1 AND nrosucursal=rconfiguracion.nrosucursal AND tipofactura=rconfiguracion.tipofactura);
    
--RAISE NOTICE 'Iniciando (vestaconfurado, %)',vestaconfurado;

   SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
   IF NOT FOUND THEN 
        rusuario.idusuario = 25;
   END IF;
   INSERT INTO tempfacturaventa (tipocomprobante, nrosucursal,nrofactura, nrodoc ,  
				tipofactura , barra,idusuario)
		 	    VALUES (rcomprobante.tipocomprobante,rcomprobante.nrosucursal,
		 	      rcomprobante.sgtenumero,rfactventa.nrodoc,rcomprobante.tipofactura,
		 	      rfactventa.tipodoc , rusuario.idusuario); 

--RAISE NOTICE 'Iniciando (% %)',rcomprobante.sgtenumero,rcomprobante.nrosucursal;
          
-- RAISE EXCEPTION 'tempfacturaventa  % %',rcomprobante.sgtenumero,rcomprobante.nrosucursal;
 
--MaLaPi 12/05/2021 si vestaconfurado  es falso, se asume que la forma de pago por defecto es Cta.Cte (3)

UPDATE temp_recibocliente SET idformapagotipos = 3 WHERE nrodoc=rfactventa.nrodoc AND tipodoc= rfactventa.tipodoc;

--KR 27-09-19 no es correcto un sum(importe) porque importesorden.importe tiene el total de los items
  OPEN cfactventaitemag FOR  SELECT nrodoc, tipodoc,fechaemision::date, nrocuentac, sum(cantidad) as cantidad
                                    --- VAS 280425,/*sum(importesorden.importe as importe)*/importesorden.importe
                                    , SUM(iiimporteafiliadounitario) as importe  ---- VAS 280425
                                    , desccuenta,1 as idiva
                FROM  temp_recibocliente NATURAL JOIN ordenrecibo  as orb 
                NATURAL JOIN orden  
                NATURAL JOIN  importesorden 
                NATURAL JOIN itemvalorizada 
                
                JOIN item USING(iditem, centro) 
                JOIN iteminformacion USING(iditem, centro) 
                JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica) 
                NATURAL JOIN cuentascontables  
                WHERE iiimporteafiliadounitario <>0 ---- VAS 280425
                      AND((not vestaconfurado AND idformapagotipos=3 ) 
			OR (vestaconfurado AND idformapagotipos = rconfiguracion.idformapagotipos))
--   23-03-22  a raiz del cambio una orden - una FA
        --        AND nrodoc=rfactventa.nrodoc AND tipodoc= rfactventa.tipodoc
                  AND nroorden =rfactventa.nroorden AND centro= rfactventa.centro
                --AND  fechaemision::date= rfactventa.fecharecibo ::date 
                GROUP BY  nrodoc, tipodoc,fechaemision::date,nrocuentac,importesorden.importe,desccuenta, idiva
                ORDER BY fechaemision::date ASC;


  FETCH cfactventaitemag into rfactventaitem;
  WHILE  FOUND LOOP
     --RAISE NOTICE 'Importe de temitemfacturaventa (%)', rfactventaitem.importe;
      INSERT INTO temitemfacturaventa(idconcepto,cantidad,importe,descripcion,idiva)
      VALUES(rfactventaitem.nrocuentac,rfactventaitem.cantidad,rfactventaitem.importe,
                  rfactventaitem.desccuenta,rfactventaitem.idiva);
      FETCH cfactventaitemag into rfactventaitem;
  END LOOP;
  CLOSE cfactventaitemag;
--RAISE NOTICE 'YA PASE EL CURSOR DE ITEMS (%, %)', rfactventa.fecharecibo ::date,rconfiguracion.idformapagotipos;
--KR 27-09-19 se modifica pq no corresponde sum(importesorden.importe) 
   OPEN cfactventafvcag FOR SELECT nrodoc, tipodoc,fechaemision::date
--- VAS 280525,importesorden.importe 
  , SUM(iiimporteafiliadounitario) as importe  ---- VAS 280425
/*sum(importesorden.importe) as importe*/
                          FROM  temp_recibocliente NATURAL JOIN ordenrecibo  as orb 
                          NATURAL JOIN orden  NATURAL JOIN  importesorden 
                          NATURAL JOIN itemvalorizada 
                          JOIN iteminformacion USING(iditem, centro) --- VAS 280525 se hace la misma modif. que arriba. Dejo xq no utilizamos el resultado de  la anterior ?
                          WHERE  ((not vestaconfurado AND idformapagotipos=3 ) 
				OR (vestaconfurado AND idformapagotipos = rconfiguracion.idformapagotipos))
--   23-03-22  a raiz del cambio una orden - una FA
                          AND nroorden=rfactventa.nroorden AND centro= rfactventa.centro
                          --AND  fechaemision::date= rfactventa.fecharecibo ::date 
                          GROUP BY  nrodoc, tipodoc,fechaemision::date,importesorden.importe
                          ORDER BY fechaemision::date ASC;

  FETCH cfactventafvcag into rfactventafvc;
  WHILE  FOUND LOOP
        RAISE NOTICE 'Importe de tempfacturaventacupon (%),(%)',vestaconfurado , rfactventafvc.importe;
        
        IF vestaconfurado THEN
           INSERT INTO tempfacturaventacupon (idvalorescaja,autorizacion,nrotarjeta ,monto ,cuotas,nrocupon)
        VALUES(rconfiguracion.idvalorescaja,'','',rfactventafvc.importe,1,'');

        ELSE
          INSERT INTO tempfacturaventacupon (idvalorescaja,autorizacion,nrotarjeta ,monto ,cuotas,nrocupon)
        VALUES(3,'','',rfactventafvc.importe,1,'');

        END IF;
        
      FETCH cfactventafvcag into rfactventafvc;
  END LOOP;
  CLOSE cfactventafvcag;


       
  
   INSERT INTO temporden (nroorden, centro, idcomprobantetipos) VALUES (rfactventa.nroorden, rfactventa.centro,rfactventa.tipo );
   /*  23-03-22  a raiz del cambio una orden - una FA
   SELECT orden.nroorden, orden.centro, tipo 
       FROM temp_recibocliente NATURAL JOIN ordenrecibo NATURAL JOIN orden    
             WHERE nrodoc=rfactventa.nrodoc AND tipodoc= rfactventa.tipodoc;
              -- AND  fechaemision::date= rfactventa.fecharecibo ::date;
*/
--actualizo la fecha de la factura a la fecha de emision de la orden 
   SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacionexpendio () as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
   
   INSERT INTO tempfacturaventageneradas (tipocomprobante, nrosucursal,nrofactura,tipofactura)
		 	    VALUES (elcomprobante.tipocomprobante,elcomprobante.nrosucursal,
		 	      elcomprobante.nrofactura,elcomprobante.tipofactura); 
         
     UPDATE reciboautogestionfacturaventa SET 
                                    tipocomprobante=elcomprobante.tipocomprobante,    
                                    nrosucursal=elcomprobante.nrosucursal,
                                    nrofactura=elcomprobante.nrofactura,
                                    tipofactura=elcomprobante.tipofactura
          /* 23-03-22  a raiz del cambio una orden - una FA
              FROM 
              (SELECT nrodoc, tipodoc ,fecharecibo ::date,trc.idrecibo, trc.centro
                               FROM temp_recibocliente as trc NATURAL JOIN ordenrecibo NATURAL JOIN temporden
                                 JOIN recibo ON (trc.idrecibo=recibo.idrecibo AND trc.centro=recibo.centro)
                                WHERE nrodoc=rfactventa.nrodoc AND tipodoc= rfactventa.tipodoc
                                 AND  fecharecibo::date= rfactventa.fecharecibo ::date 
                                GROUP BY nrodoc, tipodoc,fecharecibo::date,
                                   trc.idrecibo,trc.centro
                                 ORDER BY fecharecibo::date ASC
               ) AS TT*/
          WHERE reciboautogestionfacturaventa.idrecibo= rfactventa.idrecibo AND 
                    reciboautogestionfacturaventa.centro= rfactventa.centro;

--KR 23-03-22 cambio para que sea una orden - una factura
   PERFORM expendio_cambiarestadoorden (rfactventa.nroorden, rfactventa.centro, 3);
         /* FROM  temp_recibocliente NATURAL JOIN ordenrecibo NATURAL JOIN orden
            WHERE nrodoc=rfactventa.nrodoc AND tipodoc= rfactventa.tipodoc
               AND  fechaemision::date= rfactventa.fecharecibo ::date;
        */


   DELETE FROM temitemfacturaventa; 
   DELETE FROM temporden; 
   DELETE FROM tempfacturaventacupon;
   DELETE FROM tempfacturaventa;  
 --  RAISE EXCEPTION 'elcomprobante  % %',elcomprobante.nrofactura,elcomprobante.nrosucursal;


   IF nullvalue(vfechafactura) THEN 
   UPDATE facturaventa SET
                   fechaemision = rfactventa.fecharecibo
              WHERE tipocomprobante=elcomprobante.tipocomprobante
                   AND nrosucursal= elcomprobante.nrosucursal
                   AND nrofactura=elcomprobante.nrofactura
                   AND tipofactura=elcomprobante.tipofactura;
    ELSE 
-- MaLaPi 12-05-2021 Viene configurado desde el cliente, la fecha que tiene que tener la factura
        UPDATE facturaventa SET
                   fechaemision = vfechafactura
              WHERE tipocomprobante=elcomprobante.tipocomprobante
                   AND nrosucursal= elcomprobante.nrosucursal
                   AND nrofactura=elcomprobante.nrofactura
                   AND tipofactura=elcomprobante.tipofactura;
    END IF;
  FETCH cfactventaag into rfactventa;

 END LOOP;
 CLOSE cfactventaag;

 FOR rfacturaventa in SELECT  facturaventa.* FROM tempfacturaventageneradas  JOIN facturaventa 
                                          USING (tipocomprobante, nrosucursal,nrofactura, tipofactura)
        loop
  return next rfacturaventa;
 END LOOP;


END;$function$
