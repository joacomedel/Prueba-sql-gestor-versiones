CREATE OR REPLACE FUNCTION public.afip_generarcomprobantesnc(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE

    r_totalcomp RECORD;
    r_compfiscal RECORD;
    c_compfiscal refcursor;
    rorden_analiz RECORD;

BEGIN
-- SELECT afip_generarcomprobantesnc('');

        /* 5153 fila(s) SELECT facturaventa_actualizarcabecera(
concat('{tipocomprobante=',tipocomprobante,',tipofactura=',tipofactura,',nrosucursal=',nrosucursal,',nrofactura=',nrofactura,'}')
)
FROM facturaventa
WHERE nrosucursal= 1001 */
        -- 0 limpio estructuras
delete from afip1001_itemfacturaventa_generarcomp  ;
delete from afip1001_facturaventacupon_generarcomp    ; 
delete from afip1001_facturaventa_generarcomp;

     -- 1 busco los comprobantes emitidos en la sucursal 1001
         OPEN c_compfiscal  FOR  SELECT   *
                                 FROM facturaventa
                                 WHERE nrosucursal = 1001 and tipofactura = 'FA' -- and nrofactura= 1100
                                 ORDER BY nrofactura
                                 --limit 1000
                                 ;
          FETCH c_compfiscal INTO r_compfiscal;
          WHILE FOUND LOOP
                -- busco la orden facturada en el comprobante y todos sus comprobantes fiscales de la sucursal 1001
                  --RAISE NOTICE '>>>>  ANALIZANDO FACTURA (%)', r_compfiscal.nrofactura;
			SELECT INTO r_totalcomp  nroorden,centro,SUM(importe) as importe
			FROM (	SELECT  facturaorden.nroorden,facturaorden.centro , fv.tipocomprobante,fv.tipofactura,fv.nrosucursal,fv.nrofactura
					,(fv.importesosunc +
					fv.importeefectivo +
					fv.importedebito +
					fv.importectacte +
					fv.importecredito +
					fv.importeamuc) * ( CASE WHEN (fv.tipofactura='NC') THEN (-1) ELSE 1  end )  as importe 

				FROM ( SELECT nroorden,centro
				FROM facturaorden
				WHERE tipocomprobante = r_compfiscal.tipocomprobante
					and tipofactura =  r_compfiscal.tipofactura
					and nrosucursal = r_compfiscal.nrosucursal
					and nrofactura = r_compfiscal.nrofactura
				) as t
				NATURAL JOIN facturaorden  
				NATURAL JOIN  facturaventa fv 
			
				WHERE nrosucursal = 1001  
				     --- and nullvalue(afip1001_facturaventa_generarcomp.nroorden) es una ORDEN que aun NO analice
			) as R
			group by  nroorden,centro ; 
            -- Corroboro si es una orden analizada
            SELECT INTO rorden_analiz *
            FROM afip1001_facturaventa_generarcomp
            WHERE nroorden = r_totalcomp.nroorden;
            IF( NOT FOUND ) THEN
                        IF (r_totalcomp.importe > 1  ) THEN ---es una ORDEN que aun NO analice
			--	RAISE NOTICE '>>  ANALIZANDO ORDEN (%)', r_totalcomp.nroorden;
                        	 -- genero una NC para anular comprobante
                        	-- raise notice 'genero una NC para anular comprobante';
                      
                        	INSERT INTO afip1001_facturaventa_generarcomp  (nroorden , centro_orden, tipocomprobante ,
					nrosucursal ,  nrofactura,  nrodoc ,  tipodoc ,  ctacontable ,  centro, 
					importectacte,  fechaemision ,
					formapago ,  tipofactura ,  anulada ,  barra,fgcimportenuevocom ) VALUES
					(r_totalcomp.nroorden , r_totalcomp.centro, r_compfiscal.tipocomprobante ,
					r_compfiscal.nrosucursal ,  r_compfiscal.nrofactura,  r_compfiscal.nrodoc ,  r_compfiscal.tipodoc ,  r_compfiscal.ctacontable ,  r_compfiscal.centro,
					r_compfiscal.importectacte,  r_compfiscal.fechaemision , 
                               		r_compfiscal.formapago ,  'NC' ,  r_compfiscal.anulada ,  r_compfiscal.barra,r_totalcomp.importe);

					INSERT INTO afip1001_itemfacturaventa_generarcomp  (  importe,cantidad , nrosucursal, nrofactura, tipocomprobante,tipofactura, idconcepto
					,descripcion, idiva)(
					SELECT  SUM(CASE WHEN tipofactura='FA' THEN 1 ELSE -1 END  * importe) as importe,SUM(cantidad) as cantidad, 
					r_compfiscal.nrosucursal	,r_compfiscal.nrofactura	,r_compfiscal.tipocomprobante	,'NC', idconcepto ,descripcion ,idiva
					FROM  ( SELECT nroorden,centro
						FROM facturaorden
						WHERE tipocomprobante = r_compfiscal.tipocomprobante
							and tipofactura =  r_compfiscal.tipofactura
							and nrosucursal = r_compfiscal.nrosucursal
							and nrofactura = r_compfiscal.nrofactura
					) as t
					NATURAL JOIN facturaorden  
					NATURAL JOIN  itemfacturaventa fv 
                                        WHERE nrosucursal = 1001  
					GROUP BY nrosucursal	,nrofactura	,tipocomprobante	,tipofactura, idconcepto ,descripcion , idiva
					);
					
					 
					INSERT INTO afip1001_facturaventacupon_generarcomp  ( centro, cuotas,   
						idvalorescaja, monto,  nrofactura, nrosucursal,  tipocomprobante, tipofactura)
					 VALUES ( 1, 1, 100, r_totalcomp.importe,  r_compfiscal.nrofactura, r_compfiscal.nrosucursal,  r_compfiscal.tipocomprobante, 'NC');
					
 

                		ELSE
                         		-- no deberia generar nada
                         		IF(r_totalcomp.importe<>0)THEN
						INSERT INTO afip1001_facturaventa_generarcomp  ( nroorden , centro_orden, tipocomprobante ,
						nrosucursal ,  nrofactura,  nrodoc ,  tipodoc ,  ctacontable ,  centro,  
						importectacte, fechaemision ,	formapago ,  tipofactura ,  anulada ,  barra ,fgcimportenuevocom) VALUES (
						r_totalcomp.nroorden , r_totalcomp.centro, r_compfiscal.tipocomprobante ,
						r_compfiscal.nrosucursal ,  r_compfiscal.nrofactura,  r_compfiscal.nrodoc ,  r_compfiscal.tipodoc ,  r_compfiscal.ctacontable ,  r_compfiscal.centro,
						r_compfiscal.importectacte,  r_compfiscal.fechaemision ,  r_compfiscal.formapago ,  'FA' ,  r_compfiscal.anulada ,  r_compfiscal.barra,r_totalcomp.importe);
					END IF;	
               		END IF;	
                END IF;

                FETCH c_compfiscal INTO r_compfiscal;
          END LOOP;
  
    

RETURN true;
END;
$function$
