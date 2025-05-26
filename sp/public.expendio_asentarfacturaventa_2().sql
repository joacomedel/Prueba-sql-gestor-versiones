CREATE OR REPLACE FUNCTION public.expendio_asentarfacturaventa_2()
 RETURNS SETOF facturaventa
 LANGUAGE plpgsql
AS $function$declare

--CURSORES
cfactventaitemag refcursor;
cfactventafvcag refcursor;
crecibos refcursor;
cfactventaag CURSOR FOR SELECT * FROM tempfacturaventa;
--RECORD 
   rpta RECORD;
   rfactventa RECORD; 
   rcomprobante RECORD;
   titularfactura  RECORD;
   rusuario RECORD;
   rrecibo RECORD;
   elcomprobante RECORD;
   rfactventaitem RECORD;
   rfactventafvc RECORD;
   ctacte double precision;
   rfacturaventa public.facturaventa%rowtype;
--VARIABLES 
 

BEGIN

    CREATE TEMP TABLE tempfacturaventageneradas ( tipocomprobante INTEGER , 
                          nrosucursal INTEGER , 
			  nrofactura BIGINT , 
			  nrodoc VARCHAR, 
			  tipodoc SMALLINT, 
			  tipofactura VARCHAR(2), 
			  barra BIGINT 
			   );  
  OPEN cfactventaag;
  FETCH cfactventaag into rfactventa;
  WHILE  FOUND LOOP

-- RAISE EXCEPTION 'tempfacturaventa  % %',rcomprobante.sgtenumero,rcomprobante.nrosucursal;
 
  OPEN cfactventaitemag FOR  SELECT fechaemision::date, nrocuentac, 
                       sum(cantidad) as cantidad,sum(importesorden.importe) as importe, desccuenta,1 as idiva
                       FROM  temporden 
                        NATURAL JOIN orden  
			NATURAL JOIN  importesorden 
			NATURAL JOIN itemvalorizada 
			JOIN item USING(iditem, centro) 
			JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica) 
			NATURAL JOIN cuentascontables  
			WHERE (idformapagotipos = 2 OR idformapagotipos = 3) 
			GROUP BY  fechaemision::date,nrocuentac,desccuenta, idiva
			ORDER BY fechaemision::date ASC;


  FETCH cfactventaitemag into rfactventaitem;
  WHILE  FOUND LOOP

      INSERT INTO temitemfacturaventa(idconcepto,cantidad,importe,descripcion,idiva)
      VALUES(rfactventaitem.nrocuentac,rfactventaitem.cantidad,rfactventaitem.importe,
                  rfactventaitem.desccuenta,rfactventaitem.idiva);
      FETCH cfactventaitemag into rfactventaitem;
  END LOOP;
  CLOSE cfactventaitemag;


   SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacionexpendio() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
   
   INSERT INTO tempfacturaventageneradas (tipocomprobante, nrosucursal,nrofactura,tipofactura)
		 	    VALUES (elcomprobante.tipocomprobante,elcomprobante.nrosucursal,
		 	      elcomprobante.nrofactura,elcomprobante.tipofactura); 
         
     UPDATE reciboautogestionfacturaventa SET 
                                    tipocomprobante=elcomprobante.tipocomprobante,    
                                    nrosucursal=elcomprobante.nrosucursal,
                                    nrofactura=elcomprobante.nrofactura,
                                    tipofactura=elcomprobante.tipofactura
           FROM 
		(  SELECT trc.idrecibo, trc.centro
		   FROM temporden 
		   NATURAL JOIN ordenrecibo as trc 
		   JOIN recibo ON (trc.idrecibo=recibo.idrecibo AND trc.centro=recibo.centro)
		   GROUP BY trc.idrecibo, trc.centro 
              
               ) AS TT
          WHERE reciboautogestionfacturaventa.idrecibo= TT.idrecibo AND 
                    reciboautogestionfacturaventa.centro= TT.centro;
   IF(elcomprobante.tipofactura <>'R')THEN
               PERFORM expendio_cambiarestadoorden (temporden.nroorden, temporden.centro, 3) FROM  temporden;
   END IF;
    ------ Genero la Deuda en Cta.Cte para la Ordenes de Auto_Gestion
   SELECT INTO ctacte sum(monto) as monto FROM tempfacturaventacupon WHERE idvalorescaja = 3 GROUP BY idvalorescaja;
   IF FOUND AND ctacte > 0 THEN 
   OPEN crecibos FOR SELECT trc.idrecibo, trc.centro
		   FROM temporden 
		   NATURAL JOIN ordenrecibo as trc 
		   JOIN recibo ON (trc.idrecibo=recibo.idrecibo AND trc.centro=recibo.centro)
		   GROUP BY trc.idrecibo, trc.centro;
   FETCH crecibos into rrecibo;
   WHILE  FOUND LOOP
       PERFORM expendio_asentarfacturaventa_2_deuda_ctacte(rrecibo.idrecibo::integer,rrecibo.centro); 
   FETCH crecibos into rrecibo;
   END LOOP;
   CLOSE crecibos;
   END IF;     
   --- FIN GENERACION DE LA DEUDA

   DELETE FROM temitemfacturaventa; 
   DELETE FROM temporden; 
   DELETE FROM tempfacturaventacupon;
   DELETE FROM tempfacturaventa;  
 --  RAISE EXCEPTION 'elcomprobante  % %',elcomprobante.nrofactura,elcomprobante.nrosucursal;


   
   /*UPDATE facturaventa SET
                   fechaemision = rfactventa.fecharecibo
              WHERE tipocomprobante=elcomprobante.tipocomprobante
                   AND nrosucursal= elcomprobante.nrosucursal
                   AND nrofactura=elcomprobante.nrofactura
                   AND tipofactura=elcomprobante.tipofactura;*/
                   
      FETCH cfactventaag into rfactventa;
    
 END LOOP;
 CLOSE cfactventaag;

 FOR rfacturaventa in SELECT  facturaventa.* FROM tempfacturaventageneradas  JOIN facturaventa 
                                          USING (tipocomprobante, nrosucursal,nrofactura, tipofactura)
        loop
  return next rfacturaventa;
 END LOOP;


END;
$function$
