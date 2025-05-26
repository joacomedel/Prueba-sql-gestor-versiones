CREATE OR REPLACE FUNCTION public.fix_cuentacoorrientedeuda_remmplazar_orden_x_informe(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
    vquery varchar;
	  idinformefacturacion INTEGER;
	elconcepto varchar;  
	velcomprobantetipo INTEGER;
	reg_oorden  record;
	cursor_orden refcursor;
    reg_facturaventa  record; 
    reg_informefacturacion  record;
	  rmvtoctacte RECORD;
	 rorigenctacte RECORD;
	  vcrearinforme BOOLEAN;
	  elcentroinforme INTEGER;
	  eltipoinforme  INTEGER;
BEGIN

    /***** 
     El proposito del siguiente script es generar las facturas de ordenes on-line generadas por CMGR que afectaron la 
	 cuenta corriente directamente desde la orden pero no se genero la factura
	 SELECT fix_cuentacoorrientedeuda_remmplazar_orden_x_informe('{nroorden=null}')
    *****/ 
    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    -- La siguiente consulta permite identificar las deudas que deben ser eliminadas
    -- Va a variar dependiendo del tipo de deuda que se desea eliminar
	CREATE TEMP TABLE tempfacturaventa (fvgeneramvtoctacte boolean, tipocomprobante INTEGER , nrosucursal INTEGER , nrofactura BIGINT , nrodoc VARCHAR, tipodoc SMALLINT, ctacontable INTEGER, centro INTEGER , tipofactura VARCHAR(2), barra BIGINT ,importedescuento DOUBLE PRECISION , idinformefacturaciontipo INTEGER , idusuario BIGINT  );
    CREATE TEMP TABLE temporden ( nroorden BIGINT , centro INTEGER ,  idcomprobantetipos BIGINT );
	
	CREATE TEMP TABLE tempfacturaventacupon ( idvalorescaja INTEGER ,  autorizacion VARCHAR ,  nrotarjeta VARCHAR,  monto DOUBLE PRECISION ,  montodto DOUBLE PRECISION ,  montointeres DOUBLE PRECISION ,  cuotas SMALLINT ,  fvcporcentajedto DOUBLE PRECISION ,  nrocupon VARCHAR); 
	CREATE TEMP TABLE temitemfacturaventa (  idconcepto  VARCHAR , cantidad INTEGER , importe DOUBLE PRECISION , subtotal DOUBLE PRECISION , ivaimporte DOUBLE PRECISION , descripcion VARCHAR, idinformefacturaciontipo INTEGER, idiva INTEGER,iditemcc INTEGER );
 	CREATE TEMP TABLE tempconfiguracionprestamo (   tipodoc INTEGER,  cantidadcuotas INTEGER,  nrodoc VARCHAR ,  idsolicitudfinanciacion INTEGER ,  idcentrosolicitudfinanciacion INTEGER ,  idprestamo bigint ,  idcentroprestamo INTEGER ,  importetotal float ,  intereses float ,  importeanticipo float ,  idusuario INTEGER,  importecuota FLOAT  ,  fvtocuotauno DATE,  cancelar BOOLEAN,fechainipago date );
		     -- 1 busco info de las ordenes: nroorden	centro	nrocuentac	desccuenta	imp_afil_importe	iddeuda	idcentrodeuda	idcomprobante	idcomprobantetipos
	 OPEN cursor_orden FOR  
	 			SELECT DISTINCT o.* , io.importe as imp_afil_importe,nrodoc,tipodoc,iddeuda,idcentrodeuda
				FROM orden o
				JOIN importesorden io USING(nroorden,centro)
				LEFT JOIN facturaorden USING(nroorden,centro)
				JOIN cuentacorrientedeuda ON (idcomprobante = (nroorden*100)+1)
				WHERE  nullvalue (facturaorden.nrofactura) -- la orden no esta facturada 
				        AND ( nullvalue(rfiltros.nroorden) OR nroorden = rfiltros.nroorden)
						AND idasocconv = 169
      					AND tipo = 56 
      					AND idformapagotipos = 3 -- para quedarnos con el importe que debe pagar el afiliado 
	 			        AND NOT nullvalue(nrodoc) ---OJO HAY QUE VER ESTA ORDEN
				ORDER BY nroorden
				--limit 10
				;
	 
	        
	FETCH cursor_orden INTO reg_oorden;
	WHILE FOUND LOOP
	   	
  	  		-- dejo limpias las temporales          
   		    DELETE FROM tempfacturaventa;
		    DELETE FROM temporden;
			DELETE FROM tempfacturaventacupon;
			DELETE FROM temitemfacturaventa;
			DELETE FROM tempconfiguracionprestamo;		
			-- por cada una de las ordenes generar informe facturacion
			RAISE NOTICE '/***********************************************************************************************/' ;
			RAISE NOTICE '<nroorden: %/%>' , reg_oorden.nroorden ,  reg_oorden.centro;
			RAISE NOTICE '/***********************************************************************************************/' ;
		
			INSERT INTO tempfacturaventa (fvgeneramvtoctacte,tipocomprobante, nrosucursal,  nrofactura, nrodoc ,    tipofactura , barra/*,importedescuento*/,idinformefacturaciontipo, idusuario) 
			            VALUES (false,1,1002,111,reg_oorden.nrodoc,'FA',1,NULL,NULL);
			INSERT INTO temporden (nroorden, centro, idcomprobantetipos) 
			            VALUES (reg_oorden.nroorden,reg_oorden.centro,2);
			INSERT INTO tempfacturaventacupon (idvalorescaja  ,autorizacion,nrotarjeta ,monto ,cuotas,nrocupon,fvcporcentajedto,montodto,montointeres) 
			            VALUES (3,'0.00','0.00',reg_oorden.imp_afil_importe,'1','0.00','0.0','0.00','0');
			---Busco las practicas que se encuentran en la orden
			INSERT INTO temitemfacturaventa(idconcepto,cantidad,importe,descripcion,idiva, subtotal, ivaimporte, iditemcc)  
			         --   VALUES (reg_oorden.nrocuentac,1,reg_oorden.imp_afil_importe,reg_oorden.desccuenta,1,NULL,NULL,0);
					 (SELECT  cc.nrocuentac as nrocuentac,1 ,SUM(iiimporteafiliadounitario),cc.desccuenta as desccuenta,1,NULL,NULL,0
       				  FROM itemvalorizada  
					  JOIN importesorden io USING(nroorden,centro)
					  JOIN item i USING(iditem,centro)
					  JOIN iteminformacion USING(iditem,centro)
					  JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
					  JOIN cuentascontables cc USING(nrocuentac)
					  WHERE nroorden = reg_oorden.nroorden AND centro = reg_oorden.centro
							AND idformapagotipos = 3 -- para quedarnos con el importe que debe pagar el afiliado 
					   GROUP BY nroorden,centro, cc.nrocuentac  , cc.desccuenta  
					 );
		--OJOOOO	
			 SELECT INTO reg_facturaventa * FROM asentarcomprobantefacturacionexpendio() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
			 RAISE NOTICE '<Factura: %/%>' , reg_facturaventa.nrofactura ,  reg_facturaventa.nrosucursal;							   

			/***********************************************************/
		    /***    CREO EL INFORME ***/
		    /***********************************************************/
			
			CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );

			INSERT INTO tempcliente(nrocliente,barra) 
			VALUES(reg_oorden.nrodoc,reg_oorden.tipodoc);
			SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
			FROM (SELECT verifica_origen_ctacte() as origen ) as t;
			DROP TABLE tempcliente;

		   vcrearinforme = true;
   		   velcomprobantetipo =21; /*Cuando se debe crear el info el tipo de comprobante es 21 INFORME */
       
			SELECT INTO rmvtoctacte sum(monto) as monto, nrocuentac,
   			case when nullvalue(anulada) then tipomovimiento 
    			 when reg_facturaventa.tipofactura ILIKE '%NC%' then 'Deuda' 
     			 when  reg_facturaventa.tipofactura ILIKE '%FA%'  then 'Pago' 
  			END AS tipomovimiento, 
  			anulada,
  			fechaemision
        	FROM facturaventa fv 
			NATURAL JOIN  facturaventacupon f 
			JOIN valorescaja USING(idvalorescaja) 
			JOIN multivac.formapagotiposcuentafondos t on(f.nrosucursal=t.nrosucursal and f.idvalorescaja=t.idvalorescaja) 
			JOIN multivac.mapeocuentasfondos m using(idcuentafondos) 
			JOIN tipofacturatipomovimiento using(tipofactura)			
			WHERE f.nrofactura = reg_facturaventa.nrofactura 
				AND f.tipofactura = reg_facturaventa.tipofactura 
				AND f.tipocomprobante = reg_facturaventa.tipocomprobante 
				AND f.nrosucursal = reg_facturaventa.nrosucursal  AND vcmovimientoctacte
                GROUP BY nrocuentac,tipomovimiento,fechaemision,anulada;

     		IF FOUND THEN /*es un comprobante de facturacion pq esta en facturaventacupon asi que genero un informe */
          -- Genero el Informe de Facturacion, el tipo de informe es 14 - Generico pues se usa para deuda o pago
      				IF vcrearinforme THEN 
             
            				SELECT INTO idinformefacturacion * 
							FROM  crearinformefacturacion(reg_oorden.nrodoc,reg_oorden.tipodoc,14);
	    					INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
								(SELECT centro(), idinformefacturacion, idconcepto, cantidad, SUM(importe) as importe,  descripcion
								 FROM itemfacturaventa
								 WHERE  nrofactura = reg_facturaventa.nrofactura AND 
					 					tipocomprobante = reg_facturaventa.tipocomprobante AND 
					 					nrosucursal = reg_facturaventa.nrosucursal AND
					 					tipofactura = reg_facturaventa.tipofactura
								 GROUP BY centro(), idinformefacturacion,idconcepto,cantidad,descripcion
								);
	    					UPDATE  informefacturacion  SET
					 				 nrofactura = reg_facturaventa.nrofactura ,
									 tipocomprobante = reg_facturaventa.tipocomprobante ,
									 nrosucursal = reg_facturaventa.nrosucursal ,
									 tipofactura = reg_facturaventa.tipofactura,
									 idtipofactura = reg_facturaventa.tipofactura,
									 idformapagotipos = 3
	    					WHERE idcentroinformefacturacion = centro() and  nroinforme = idinformefacturacion;
           					elcentroinforme = centro();
            				eltipoinforme =14;
    				 ELSE 
						 	idinformefacturacion = null;
			 				elcentroinforme = null;
		 					SELECT INTO eltipoinforme idinformefacturaciontipo 
		 					FROM informefacturacion where nroinforme = null and idcentroinformefacturacion=null;
      				 END IF;
 
					-- Dejo el Informe en estado 4 - Facturado
	  				PERFORM  cambiarestadoinformefacturacion(idinformefacturacion,centro(),4,'Generado desde asentarcomprobantefacturaciongenerico x Mov en Cta.Cte' );
			
			END IF;		
			
			/**********************************************************/
               --- Recupero el idinformefacturacion 
              SELECT  INTO reg_informefacturacion * 
			  FROM  informefacturacion 
              WHERE nrofactura = reg_facturaventa.nrofactura
                     AND nrosucursal = reg_facturaventa.nrosucursal
                     AND tipofactura= 'FA';
			  RAISE NOTICE '<informe: %/%>' , reg_informefacturacion.nroinforme ,  reg_informefacturacion.idcentroinformefacturacion;							   
      		 
			 -- actualizar el mov concepto de la deuda con el formato informe facturacion
			 -- actualizaqr el idcomprobante para que apunte al informe de facturacion y el tipo de comprobante
             UPDATE cuentacorrientedeuda  
			 SET    idcomprobante = (reg_informefacturacion.nroinforme*100)+reg_informefacturacion.idcentroinformefacturacion
			        ,idcomprobantetipos = 21
					,movconcepto = concat (movconcepto, ' | Genera Deuda por  Emision de FA ',reg_facturaventa.nrosucursal,' ', reg_facturaventa.nrofactura, ' Con el Informe ', reg_informefacturacion.nroinforme ,'-',reg_informefacturacion.idcentroinformefacturacion )
			 WHERE iddeuda = reg_oorden.iddeuda
			       AND idcentrodeuda = reg_oorden.idcentrodeuda;  
			--- HAY  Pago Coseguro de Orden  01514259- 001. DNI: 25277061: DANEI,FABRIZIO
			--- GUTIERREZ, TAMARA YAEL Nro.Cliente: 31868403-1 Orden/es: 1100655-12 1100656-12  Genera Deuda por  Emision de FA 15 10029 Con el Informe 89243-12
			 
		
		   	 
			  RAISE NOTICE '/***********************************************************************************************/' ;
             FETCH cursor_orden INTO reg_oorden;
			 
    END LOOP;
    CLOSE cursor_orden;
    RETURN true;
END;
$function$
