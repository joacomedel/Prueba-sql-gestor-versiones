CREATE OR REPLACE FUNCTION public.w_obtenerfacturas2_afip(parametros jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
$data = array(
	'CantReg' 		=> 1, // Cantidad de comprobantes a registrar
	'PtoVta' 		=> $puntoVenta, // Punto de venta
	'CbteTipo' 		=> $tipoComprobante , // Tipo de comprobante (ver tipos disponibles 1 FAC A 3 NC A 6= FA B y 8 = NC B) 
	'Concepto' 		=> 2, // Concepto del Comprobante: (1)Productos, (2)Servicios, (3)Productos y Servicios
	'DocTipo' 		=> 80, // Tipo de documento del comprador (ver tipos disponibles agregaria columna en tipo doc)
	'DocNro' 		=> 27282721371, // Numero de documento del comprador
	'CbteDesde' 	=> $ultimo_comp_emitido+1, // Numero de comprobante o numero del primer comprobante en caso de ser mas de uno
	'CbteHasta' 	=> $ultimo_comp_emitido+1, // Numero de comprobante o numero del ultimo comprobante en caso de ser mas de uno
	'CbteFch' 		=> $fechaEmision, // (Opcional) Fecha del comprobante (yyyymmdd) o fecha actual si es nulo
	'ImpTotal' 		=> $ImpTotal, // Importe total del comprobante
	'ImpTotConc' 	=> $ImpTotConc, // Importe neto no gravado
	'ImpNeto' 		=> $ImpNeto, // Importe neto gravado
	'ImpOpEx' 		=> $ImpOpEx, // Importe exento de IVA
	'ImpIVA' 		=> $ImpIVA, //Importe total de IVA
	'ImpTrib' 		=> $ImpTrib, //Importe total de tributos
	'FchServDesde' 	=> $fechaEmision, // (Opcional) Fecha de inicio del servicio (yyyymmdd), obligatorio para Concepto 2 y 3  -- Poner la fecha de la emision de la orden
	'FchServHasta' 	=> $fechaEmision, // (Opcional) Fecha de fin del servicio (yyyymmdd), obligatorio para Concepto 2 y 3  -- Poner la fecha de la emision de la orden
	'FchVtoPago' 	=> $fechaEmision, // (Opcional) Fecha de vencimiento del servicio (yyyymmdd), obligatorio para Concepto 2 y 3  -- Poner la fecha de la emision de la orden
	'MonId' 		=> 'PES', //Tipo de moneda usada en el comprobante (ver tipos disponibles)('PES' para pesos argentinos) 
	'MonCotiz' 		=> 1, // Cotización de la moneda usada (1 para pesos argentinos)  

	'Iva' 	=> array( // (Opcional) Alícuotas asociadas al comprobante
		array(
			'Id' 		=> $idIVA, // Id del tipo de IVA (ver tipos disponibles Alicuotas de IVA) 
			'BaseImp' 	=> $ImpNeto, // Base imponible
			'Importe' 	=> $ImpIVA // Importe 21
		)
	)
);
*/
DECLARE
       respuestajson jsonb;
       ivajson jsonb;
       cbtesasocjson  jsonb;
       rfacturaventa public.facturaventa%rowtype;
       rrecibo RECORD;
       rdevolver RECORD;
       rcliente RECORD;	
       rverificafactura RECORD;
       
	
begin

	SELECT INTO ivajson array_to_json(array_agg(row_to_json(t))) as "Iva"
	FROM (
		select round(sum(importe)::numeric,2) as "BaseImp",round(sum((importe*0.105))::numeric,2)  as "Importe",4 as "Id" 
		from itemfacturaventa 
		where  tipofactura = parametros->>'tipofactura' AND nrofactura = parametros->>'nrofactura' AND nrosucursal = parametros->>'nrosucursal' AND tipocomprobante = parametros->>'tipocomprobante'
		 AND idconcepto <> 20821
		GROUP BY nrofactura,tipofactura,nrosucursal,tipocomprobante
		) as t;
		
      RAISE NOTICE 'Listo el ivajson %.',ivajson;

--06-04-21 Para NC se envia la info de CbtesAsoc 
       
 SELECT INTO cbtesasocjson  array_to_json(array_agg(row_to_json(t))) as "CbtesAsoc"
	FROM (
		SELECT fvafa.nrosucursal as "PtoVta",
     CASE WHEN fvafa.tipofactura = 'FA' AND fvafa.tipocomprobante = 1 THEN 6
      WHEN fvafa.tipofactura = 'FA' AND fvafa.tipocomprobante = 2 THEN 1
      WHEN fvafa.tipofactura = 'NC' AND fvafa.tipocomprobante = 1 THEN 8
      WHEN fvafa.tipofactura = 'NC' AND fvafa.tipocomprobante = 2 THEN 2 
      ELSE 123 END as "Tipo", fvafa.nrofactura AS "Nro" 
FROM facturaventa_wsafip fvanc 
LEFT JOIN facturaventa_wsafip fvafa ON fvanc.idaporte = fvafa.idaporte AND  fvanc.idcentroregionaluso= fvafa.idcentroregionaluso
WHERE fvanc.nrofactura =parametros->>'nrofactura' AND  fvanc.tipofactura = parametros->>'tipofactura' AND fvanc.nrosucursal = parametros->>'nrosucursal' AND fvanc.tipocomprobante = parametros->>'tipocomprobante' AND nullvalue(fvanc.nrofacturafiscal) AND fvafa.tipofactura = 'FA'
  
		) as t;

      RAISE NOTICE 'Listo el cbtesasocjson %.',cbtesasocjson;

--La factura de venta ya esta generada y solo tengo que llamar al WS.

     IF parametros->>'tipofactura' = 'NC' THEN 
-- Se debe enviar el campo  CbtesAsoc


     IF nullvalue(cbtesasocjson::text) THEN 
        SELECT INTO cbtesasocjson  array_to_json(array_agg(row_to_json(t))) as "CbtesAsoc"
	FROM (
		 SELECT nrosucursal as "PtoVta",
                 CASE WHEN tipofactura = 'FA' AND tipocomprobante = 1 THEN 6
                    WHEN tipofactura = 'FA' AND tipocomprobante = 2 THEN 1
                    WHEN tipofactura = 'NC' AND tipocomprobante = 1 THEN 8
                    WHEN tipofactura = 'NC' AND tipocomprobante = 2 THEN 2 
                       ELSE 123 END as "Tipo", nrofactura AS "Nro" 
                  FROM informefacturacionaporte 
                   NATURAL JOIN informefacturacion where idaporte = parametros->>'idaporte' AND idcentroinformefacturacion = 1 AND tipofactura = 'FA'
                
		) as t;
     END IF;
       RAISE NOTICE 'EN NC  el cbtesasocjson %.',cbtesasocjson;

     SELECT  INTO rdevolver 1 as "CantReg",nrosucursal as "PtoVta",
     CASE WHEN tipofactura = 'FA' AND tipocomprobante = 1 THEN 6
      WHEN tipofactura = 'FA' AND tipocomprobante = 2 THEN 1
      WHEN tipofactura = 'NC' AND tipocomprobante = 1 THEN 8
      WHEN tipofactura = 'NC' AND tipocomprobante = 2 THEN 2 
      ELSE 123 END as "CbteTipo"
		, 1 as "Concepto",
		 CASE WHEN tipocomprobante = 1 THEN 96 
		 ELSE 80 END as "DocTipo"
		 ,CASE WHEN tipocomprobante = 1 THEN facturaventa.nrodoc 
		 ELSE concat(cliente.cuitini,cliente.cuitmedio,cliente.cuitfin) END as "DocNro",nrofactura as "CbteDesde",nrofactura as "CbteHasta"
 ,to_char(fechaemision,'YYYYMMDD') as "CbteFch"
--,'20191230' as "CbteFch"
		,round((CASE WHEN nullvalue(importeefectivo) THEN 0 ELSE importeefectivo END  + CASE WHEN nullvalue(importectacte) THEN 0 ELSE importectacte END  )::numeric,2) as "ImpTotal"
		,round((CASE WHEN nullvalue(importeefectivo) THEN 0 ELSE importeefectivo END + CASE WHEN nullvalue(importectacte) THEN 0 ELSE importectacte END - importe )::numeric,2) as  "ImpNeto"
		,0 as "ImpTotConc",0 as "ImpOpEx"
		,round(importe::numeric,2) as "ImpIVA",0 as "ImpTrib",'PES' as "MonId"
		,1 as "MonCotiz",concat(facturaventa_wsafip.idaporte,'-',facturaventa_wsafip.idcentroregionaluso) as "Recibo"
		,ivajson as "Iva"
                ,cbtesasocjson as "CbtesAsoc"
                ,nrofactura as nrofacturaoriginal
                ,concat(cliente.cuitini,cliente.cuitmedio,cliente.cuitfin) as cuit
	from facturaventa
	JOIN itemfacturaventa USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
        JOIN informefacturacion USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
        JOIN informefacturacionestado USING(nroinforme,idcentroinformefacturacion)
        JOIN informefacturacionaporte USING(nroinforme,idcentroinformefacturacion)
        JOIN facturaventa_wsafip USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
        LEFT JOIN cliente ON nrodoc = cliente.nrocliente AND tipodoc = cliente.barra
	where nullvalue(nrofacturafiscal)  AND nullvalue(fechafin) AND idconcepto = 20821
	AND  tipofactura = parametros->>'tipofactura' AND nrofactura = (parametros->>'nrofactura')::bigint AND nrosucursal = (parametros->>'nrosucursal')::integer AND tipocomprobante = (parametros->>'tipocomprobante')::integer
        ;
         RAISE NOTICE 'EN NC  tengo para devovler %.',rdevolver;
     ELSE 
         RAISE NOTICE 'EN FA  antes de tener para devovler ';
     SELECT  INTO rdevolver 1 as "CantReg",nrosucursal as "PtoVta",
     CASE WHEN tipofactura = 'FA' AND tipocomprobante = 1 THEN 6
      WHEN tipofactura = 'FA' AND tipocomprobante = 2 THEN 1
      WHEN tipofactura = 'NC' AND tipocomprobante = 1 THEN 8
      WHEN tipofactura = 'NC' AND tipocomprobante = 2 THEN 2 
      ELSE 123 END as "CbteTipo"
		, 1 as "Concepto",
		 CASE WHEN tipocomprobante = 1 THEN 96 
		 ELSE 80 END as "DocTipo"
		 ,CASE WHEN tipocomprobante = 1 THEN facturaventa.nrodoc 
		 ELSE concat(cliente.cuitini,cliente.cuitmedio,cliente.cuitfin) END as "DocNro",nrofactura as "CbteDesde",nrofactura as "CbteHasta"
 ,to_char(fechaemision,'YYYYMMDD') as "CbteFch"
--,'20191230' as "CbteFch"
		,round((CASE WHEN nullvalue(importeefectivo) THEN 0 ELSE importeefectivo END  + CASE WHEN nullvalue(importectacte) THEN 0 ELSE importectacte END  )::numeric,2) as "ImpTotal"
		,round((CASE WHEN nullvalue(importeefectivo) THEN 0 ELSE importeefectivo END + CASE WHEN nullvalue(importectacte) THEN 0 ELSE importectacte END - importe )::numeric,2) as  "ImpNeto"
		,0 as "ImpTotConc",0 as "ImpOpEx"
		,round(importe::numeric,2) as "ImpIVA",0 as "ImpTrib",'PES' as "MonId"
		,1 as "MonCotiz",concat(facturaventa_wsafip.idaporte,'-',facturaventa_wsafip.idcentroregionaluso) as "Recibo"
		,ivajson as "Iva"
                --,'' as "Iva"
               -- ,cbtesasocjson as "CbtesAsoc"
                ,nrofactura as nrofacturaoriginal
                ,concat(cliente.cuitini,cliente.cuitmedio,cliente.cuitfin) as cuit
	-- from facturaventa
	FROM itemfacturaventa -- USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
        JOIN informefacturacion USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
        JOIN informefacturacionestado USING(nroinforme,idcentroinformefacturacion)
        JOIN informefacturacionaporte USING(nroinforme,idcentroinformefacturacion)
        JOIN facturaventa_wsafip USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
        LEFT JOIN cliente ON nrodoc = cliente.nrocliente AND tipodoc = cliente.barra
	where nullvalue(nrofacturafiscal)  AND nullvalue(fechafin) AND idconcepto = 20821
	AND  tipofactura = parametros->>'tipofactura' AND nrofactura = (parametros->>'nrofactura')::bigint AND nrosucursal = (parametros->>'nrosucursal')::integer AND tipocomprobante = (parametros->>'tipocomprobante')::integer
         --AND tipofactura = 'FA' AND nrofactura = 14129 AND nrosucursal = 1001 AND tipocomprobante = 1
        ;
           RAISE NOTICE 'EN FA  tengo para devovler %.',rdevolver;
     END IF;



	 respuestajson = row_to_json(rdevolver);

      return respuestajson;

end;$function$
