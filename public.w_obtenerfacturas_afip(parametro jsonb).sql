CREATE OR REPLACE FUNCTION public.w_obtenerfacturas_afip(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
{ "nrosucursal": 1, "tipofactura": "NC", "nrofactura": 5734, "tipocomprobante":1}
*/

DECLARE
       respuestajson jsonb;
       cbtesasocjson jsonb; 
       ivajson jsonb;
       rfacturaventa public.facturaventa%rowtype;
       rrecibo RECORD;
       rdevolver RECORD;
       rcliente RECORD;	
       rverificafactura RECORD;
       
	
begin

--La a factura de venta ya esta generada y solo tengo que llamar al WS.
 
--MaLaPi 20-07-2020 Modifico para que soporte IVA 

SELECT INTO ivajson array_to_json(array_agg(row_to_json(t))) as "Iva"
	FROM (
		select round(sum(importe)::numeric,2) as "BaseImp",round(sum((importe*0.105))::numeric,2)  as "Importe",4 as "Id" 
		from itemfacturaventa 
		where tipofactura = parametro->>'tipofactura' 
            AND nrofactura = parametro->>'nrofactura' 
            AND nrosucursal = parametro->>'nrosucursal'
            AND tipocomprobante = parametro->>'tipocomprobante'
	    AND idconcepto <> 20821
		GROUP BY nrofactura,tipofactura,nrosucursal,tipocomprobante
		) as t;


   SELECT INTO cbtesasocjson  array_to_json(array_agg(row_to_json(t))) as "CbtesAsoc"
	FROM (
		 SELECT nrosucursal as "PtoVta",
                 CASE WHEN tipofactura = 'FA' AND tipocomprobante = 1 THEN 6
                    WHEN tipofactura = 'FA' AND tipocomprobante = 2 THEN 1
                    WHEN tipofactura = 'NC' AND tipocomprobante = 1 THEN 8
                    WHEN tipofactura = 'NC' AND tipocomprobante = 2 THEN 2 
                       ELSE 123 END as "Tipo", nrofactura AS "Nro" 
                  FROM facturaventa 
                  where nrofactura = parametro->>'nrofactura_asoc'  
                        AND tipocomprobante = parametro->>'tipocomprobante_asoc'  
                        AND nrosucursal =  parametro->>'nrosucursal_asoc'  
                        AND tipofactura = parametro->>'tipofactura_asoc'  
) as t;


      RAISE NOTICE 'Listo el cbtesasocjson %.',cbtesasocjson;


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
		,1 as "MonCotiz"
                 -- ,concat(facturaventa_wsafip.idaporte,'-',facturaventa_wsafip.idcentroregionaluso) as "Recibo"
		,ivajson as "Iva"
                ,cbtesasocjson as "CbtesAsoc"
                ,nrofactura as nrofacturaoriginal
                ,concat(cliente.cuitini,cliente.cuitmedio,cliente.cuitfin) as cuit
	 
	FROM facturaventa  
        JOIN itemfacturaventa USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
        LEFT JOIN facturaventa_wsafip USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
	LEFT JOIN cliente ON nrodoc = cliente.nrocliente AND tipodoc = cliente.barra
	 WHERE tipofactura = parametro->>'tipofactura' 
            AND nrofactura = parametro->>'nrofactura' 
            AND nrosucursal = parametro->>'nrosucursal'
            AND tipocomprobante = parametro->>'tipocomprobante'
    --  WHERE tipofactura = 'NC' AND nrofactura = 5734 AND nrosucursal = parametro->>'nrosucursal' AND tipocomprobante = parametro->>'tipocomprobante'
         AND nullvalue(nrofacturafiscal)  AND idconcepto = 20821;

                                   --Malapi 02-08-2019 Si la factura tiene importe 0, no debe ser generada, largo un error. 
                                   IF rdevolver."ImpTotal" = 0 THEN 
                                           RAISE EXCEPTION 'La factura tiene importe cero  %',rdevolver;
                               
                                   END IF;




               	
      respuestajson = row_to_json(rdevolver);

      return respuestajson;


end;$function$
