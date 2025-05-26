CREATE OR REPLACE FUNCTION public.expendio_asentarfacturaventa_usandoinformefacturacion()
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

*/
--CURSORES
cfactventaag CURSOR FOR SELECT cliente.nrocliente as nrodoc,cliente.barra as tipodoc,tipofactura,idformapagotipos
			,nroinforme,idcentroinformefacturacion,nroorden,centro,idrecibo
			--tipofactura,idtipofactura,idformapagotipos,tipocomprobante
			FROM  ordenrecibo
			-- NATURAL JOIN temp_recibocliente MaLaPi: Esto permite que se facture solo lo que se ve en la ventana, no es la idea.
			NATURAL JOIN cambioestadosorden
			NATURAL JOIN reintegroorden 
			NATURAL JOIN informefacturacionexpendioreintegro
			NATURAL JOIN informefacturacion
			NATURAL JOIN cliente
			NATURAL JOIN recibo
			WHERE nullvalue(ceofechafin) 
				AND idordenventaestadotipo = 1
			--GROUP BY nrodoc, tipodoc,fecharecibo::date
			ORDER BY idrecibo,centro,fecharecibo::date ASC;
--RECORD 
   
   rfactventa RECORD; 
   rcomprobante RECORD;
   rusuario RECORD;
   elcomprobante RECORD;
   rfacturaventa public.facturaventa%rowtype;
   rinforme RECORD;
--VARIABLES 
 

BEGIN

	CREATE TEMP TABLE tempfacturaventa ( tipocomprobante INTEGER , nrosucursal INTEGER , nrofactura BIGINT , nrodoc VARCHAR, tipodoc SMALLINT, ctacontable INTEGER, centro INTEGER , tipofactura VARCHAR(2), barra BIGINT ,importedescuento DOUBLE PRECISION , idusuario BIGINT  ); 
	CREATE TEMP TABLE tempinforme ( nroinforme BIGINT , idcentroinformefacturacion INTEGER  );
	CREATE TEMP TABLE tempfacturaventacupon ( idvalorescaja INTEGER ,  autorizacion VARCHAR ,  nrotarjeta VARCHAR,  monto DOUBLE PRECISION ,  montodto DOUBLE PRECISION ,  cuotas SMALLINT ,  fvcporcentajedto DOUBLE PRECISION ,  nrocupon VARCHAR); 
	CREATE TEMP TABLE temitemfacturaventa ( idconcepto  VARCHAR , cantidad INTEGER , importe DOUBLE PRECISION , subtotal DOUBLE PRECISION , ivaimporte DOUBLE PRECISION , descripcion VARCHAR, idiva INTEGER,iditemcc INTEGER );
	CREATE TEMP TABLE tempcentrocostos ( importe DOUBLE PRECISION ,idcentrocosto integer NOT NULL,iditemcc INTEGER ) WITHOUT OIDS;
	CREATE TEMP TABLE tempfacturaventageneradas ( tipocomprobante INTEGER , nrosucursal INTEGER ,   nrofactura BIGINT ,   nrodoc VARCHAR,   tipodoc SMALLINT,   tipofactura VARCHAR(2), barra BIGINT  );  

  OPEN cfactventaag;
  FETCH cfactventaag into rfactventa;
  WHILE  FOUND LOOP

   -- Ojo, asumo que hay solo un tipo de comprobante y sucursal de OT por centro  
   SELECT INTO rcomprobante * FROM talonario 
                WHERE centro = centro() AND tipofactura=rfactventa.tipofactura;
    
	RAISE NOTICE 'rcomprobante  % %',rcomprobante.sgtenumero,rcomprobante.nrosucursal;


   SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
   IF NOT FOUND THEN 
        rusuario.idusuario = 25;
   END IF;

	SELECT  INTO rinforme sum(importe) as importe,ifi.descripcion,ifi.nrocuentac as idconcepto, concat(ifi.nrocuentac,' - ',ifi.descripcion) as iditem, cantidad 
			, CASE WHEN not nullvalue(idiva) THEN idiva       
			       WHEN (idinformefacturaciontipo = 4 or idinformefacturaciontipo = 3) THEN 2 ELSE 1 END as idiva
			, CASE WHEN not nullvalue(idiva) THEN porcentaje               
                               WHEN idinformefacturaciontipo = 4 THEN 0.21 ELSE 0.0 END as porcentaje  
		FROM informefacturacionitem as ifi  
		LEFT JOIN tipoiva USING(idiva)  
		LEFT JOIN informefacturacion USING(nroinforme,idcentroinformefacturacion)  	 	
		WHERE   (nroinforme =rfactventa.nroinforme and idcentroinformefacturacion =rfactventa.idcentroinformefacturacion)
		GROUP by ifi.nrocuentac,ifi.descripcion,idinformefacturaciontipo,cantidad,idiva,porcentaje; 

	INSERT INTO tempfacturaventa (tipocomprobante, nrosucursal,nrofactura, nrodoc ,  
				tipofactura , barra,idusuario)
		 	    VALUES (rcomprobante.tipocomprobante,rcomprobante.nrosucursal,
		 	      rcomprobante.sgtenumero,rfactventa.nrodoc,rcomprobante.tipofactura,
		 	      rfactventa.tipodoc , rusuario.idusuario); 

	INSERT INTO tempinforme (nroinforme, idcentroinformefacturacion) 
	VALUES (rfactventa.nroinforme,rfactventa.idcentroinformefacturacion);
        IF rfactventa.idformapagotipos = 9 THEN --MaLaPi 09-08-2018 Se trata de un CHEQUE 
                -- Dejo el ValorCaja 47 - Cheque. Luego hay que ver de buscar la forma que se pueda configurar
	        INSERT INTO tempfacturaventacupon(idvalorescaja,autorizacion,nrotarjeta ,monto ,cuotas,nrocupon,fvcporcentajedto,montodto) 
         	VALUES (47,'2','0',rinforme.importe,'1','0','0','0');  

        
        ELSE  -- MaLaPi 09-08-2018 Se trata de una transferencia.
                 -- Dejo el ValorCaja 45 - Credicoop (Nqn) 24917/1. Luego hay qeu ver de buscar la forma que se pueda configurar
	        INSERT INTO tempfacturaventacupon(idvalorescaja,autorizacion,nrotarjeta ,monto ,cuotas,nrocupon,fvcporcentajedto,montodto) 
         	VALUES (45,'0','0',rinforme.importe,'1','0','0','0');  

        END IF;
	INSERT INTO temitemfacturaventa(idconcepto,cantidad,importe,descripcion,idiva, iditemcc)  
	VALUES (rinforme.idconcepto,rinforme.cantidad,rinforme.importe,rinforme.descripcion,rinforme.idiva ,0); 

	-- Dejo el centro de costos 1 - Obra Social. Luego hay qeu ver de buscar la forma que se pueda configurar
	INSERT INTO tempcentrocostos(importe,idcentrocosto,iditemcc)  VALUES (rinforme.importe,1,0);

	--RAISE EXCEPTION 'tempfacturaventa  % %',rcomprobante.sgtenumero,rcomprobante.nrosucursal;
 	
	SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacioninformes() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
   
	INSERT INTO tempfacturaventageneradas (tipocomprobante, nrosucursal,nrofactura,tipofactura)
		 	    VALUES (elcomprobante.tipocomprobante,elcomprobante.nrosucursal,
		 	      elcomprobante.nrofactura,elcomprobante.tipofactura); 
         
       PERFORM expendio_cambiarestadoorden(rfactventa.nroorden, rfactventa.centro, 3);

	INSERT INTO reciboautogestionfacturaventa(idrecibo,centro,nrosucursal,nrofactura,tipocomprobante,tipofactura,seimprimio)
	VALUES(rfactventa.idrecibo,rfactventa.centro,elcomprobante.nrosucursal,elcomprobante.nrofactura,elcomprobante.tipocomprobante,elcomprobante.tipofactura,false);

	DROP TABLE tempordenpago; -- Se usa en generarminutapagoexpendioreintegro
	DROP TABLE tempordenpagoimputacion; -- Se usa en generarminutapagoexpendioreintegro
	DROP TABLE tempreintegro; ---- Se usa en generarminutapagoexpendioreintegro
	DELETE FROM tempcentrocostos;
	DELETE FROM temitemfacturaventa; 
	DELETE FROM tempfacturaventacupon;
	DELETE FROM tempfacturaventa; 
	DELETE FROM tempinforme ;
   --RAISE EXCEPTION 'elcomprobante  % %',elcomprobante.nrofactura,elcomprobante.nrosucursal;

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
