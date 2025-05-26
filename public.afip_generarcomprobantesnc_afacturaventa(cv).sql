CREATE OR REPLACE FUNCTION public.afip_generarcomprobantesnc_afacturaventa(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE

    elem RECORD;
    r_compfiscal RECORD;
    c_compfiscal refcursor;
 

BEGIN
         -- 1 busco los comprobantes emitidos en la sucursal 1001
         OPEN c_compfiscal  FOR  SELECT * FROM afip1001_facturaventa_generarcomp;
         FETCH c_compfiscal INTO r_compfiscal;
         WHILE FOUND LOOP

                    
                     SELECT into elem *
		     FROM devolvernrofactura(centro(),r_compfiscal.tipocomprobante,r_compfiscal.tipofactura,r_compfiscal.nrosucursal);

		     RAISE NOTICE '>>>>  generando factura FACTURA (%)', elem.sgtenumero;	

                     INSERT INTO facturaventa (tipocomprobante ,nrosucursal ,  nrofactura ,  tipofactura
                                               ,  nrodoc ,  tipodoc ,  ctacontable ,  centro, importectacte,  fechaemision ,
						formapago ,  anulada ,  barra ) 
		      VALUES(elem.tipocomprobante ,elem.nrosucursal ,  elem.sgtenumero,  elem.tipofactura
                             ,  r_compfiscal.nrodoc ,  r_compfiscal.tipodoc ,  r_compfiscal.ctacontable ,  r_compfiscal.centro,
					r_compfiscal.fgcimportenuevocom,  now() , 	r_compfiscal.formapago  ,  r_compfiscal.anulada ,  r_compfiscal.barra);

		      INSERT INTO itemfacturaventa(  importe,cantidad , nrosucursal, nrofactura, tipocomprobante,tipofactura, idconcepto
					,descripcion, idiva)(
					SELECT  SUM(importe) as importe,MIN(cantidad) as cantidad, 
					 elem.nrosucursal	, elem.sgtenumero	, elem.tipocomprobante	, elem.tipofactura, idconcepto ,descripcion ,idiva
					FROM  afip1001_itemfacturaventa_generarcomp
					WHERE tipocomprobante = r_compfiscal.tipocomprobante
							and tipofactura =  r_compfiscal.tipofactura
							and nrosucursal = r_compfiscal.nrosucursal
							and nrofactura = r_compfiscal.nrofactura
					GROUP BY nrosucursal	,nrofactura	,tipocomprobante	,tipofactura, idconcepto ,descripcion , idiva
					);
					
					 
			INSERT INTO facturaventacupon  ( centro, cuotas,idvalorescaja, monto,  nrofactura, nrosucursal,  tipocomprobante, tipofactura)
			(SELECT  centro, cuotas,idvalorescaja, monto,   elem.sgtenumero,  elem.nrosucursal,   elem.tipocomprobante,  elem.tipofactura
			 FROM afip1001_facturaventacupon_generarcomp
			 WHERE tipocomprobante = r_compfiscal.tipocomprobante
				and tipofactura =  r_compfiscal.tipofactura
				and nrosucursal = r_compfiscal.nrosucursal
				and nrofactura = r_compfiscal.nrofactura
			 );
			
		INSERT INTO facturaventausuario(tipocomprobante, nrosucursal, nrofactura, tipofactura,idusuario) 
		VALUES( elem.tipocomprobante, elem.nrosucursal,  elem.sgtenumero,    elem.tipofactura,25);
		           	
                INSERT INTO facturaventa_wsafip (nrofactura,nrosucursal,tipocomprobante,tipofactura ) 
                VALUES(elem.sgtenumero,  elem.nrosucursal,   elem.tipocomprobante,  elem.tipofactura);
                
		INSERT INTO facturaorden (tipocomprobante,nrosucursal,nrofactura,tipofactura ,nroorden, centro,idcomprobantetipos ) 
                VALUES(elem.tipocomprobante,  elem.nrosucursal,elem.sgtenumero,     elem.tipofactura,r_compfiscal.nroorden, r_compfiscal.centro_orden,56);
                
                UPDATE afip1001_facturaventa_generarcomp SET comfiscalgenerado = elem.sgtenumero
                WHERE tipocomprobante = r_compfiscal.tipocomprobante
				and tipofactura =  r_compfiscal.tipofactura
				and nrosucursal = r_compfiscal.nrosucursal
				and nrofactura = r_compfiscal.nrofactura;
                FETCH c_compfiscal INTO r_compfiscal;
          END LOOP;
          CLOSE c_compfiscal;
    

RETURN true;
END;
$function$
