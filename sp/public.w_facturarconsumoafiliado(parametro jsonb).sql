CREATE OR REPLACE FUNCTION public.w_facturarconsumoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
SELECT w_facturarconsumoafiliado('{"NroAfiliado":null,"Barra":null,"NroDocumento":"18217355","TipoDocumento":"DNI","Track":null
,"centro": 1, "idrecibo": 785695, "nroorden": 1014722, "ctdescripcion": "Orden online"}');

*{"centro": 1, "idrecibo": 785695, "nroorden": 1014722, "ctdescripcion": "Orden online"}"
-- De esta consulta se deben sacar los pendientes
select * 
from orden 
NATURAL JOIN ordenrecibo
NATURAL JOIN cambioestadosorden
LEFT JOIN facturaorden USING(nroorden,centro)
LEFT JOIN facturaventa_wsafip USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
where tipo = 56 AND (nullvalue(facturaorden.nrofactura) OR nullvalue(nrofactura_afip))
AND nullvalue(ceofechafin)
AND idordenventaestadotipo = 1

CREATE TEMP TABLE temp_recibocliente (     idrecibo bigint,     centro INTEGER,      nrodoc VARCHAR,     tipodoc INTEGER,     accion VARCHAR DEFAULT 'autogestion',     idformapagotipos INTEGER,     idvalorescaja INTEGER );

SELECT * FROM expendio_asentarfacturaventa_global();
*/
DECLARE
       respuestajson jsonb;
       ivajson jsonb;
       rfacturaventa public.facturaventa%rowtype;
       rrecibo RECORD;
       rdevolver RECORD;
       rcliente RECORD;	
       rverificafactura RECORD;
       r_factura_afip RECORD;
       r_itemfacturaventa  RECORD;
       
	
begin

--La a factura de venta ya esta generada y solo tengo que llamar al WS.
 
--MaLaPi 20-07-2020 Modifico para que soporte IVA 


  
      -- VAS  28-11-2023 Verifico si se encuentra la referencia al registro de la afip
       SELECT INTO r_factura_afip *
       FROM facturaventa_wsafip
       WHERE  tipofactura = (parametro->>'tipofactura')::VARCHAR
              AND nrofactura =(parametro->>'nrofactura')::bigint
              AND nrosucursal = (parametro->>'nrosucursal')::integer
              AND tipocomprobante = (parametro->>'tipocomprobante')::integer;

--RAISE EXCEPTION 'Los parametros de:  % %',r_factura_afip,parametro;


       IF NOT FOUND THEN  -- Si no se encuentra lo inserto
                INSERT INTO facturaventa_wsafip(nrofactura, tipocomprobante, nrosucursal, tipofactura,idrecibo,centro) 
                VALUES((parametro->>'nrofactura')::bigint,(parametro->>'tipocomprobante')::integer,(parametro->>'nrosucursal')::integer,parametro->>'tipofactura' ,(parametro->>'idrecibo')::bigint,(parametro->>'centro')::integer);
       END IF;




    --- 01-12-2023 Verifico si el comprobante tiene el concepto de IVA. (Las facturas de prestaciones medicas NO tienen IVA)
    SELECT INTO r_itemfacturaventa * 
    FROM itemfacturaventa 
    WHERE nrofactura =  rfacturaventa.nrofactura 
          AND nrosucursal =  rfacturaventa.nrosucursal
	  AND tipofactura =  rfacturaventa.tipofactura 
          AND tipocomprobante =  rfacturaventa.tipocomprobante
  	  AND idconcepto = 20821;
     IF FOUND THEN  --- VAS 28-11-2023 Si hay info del IVA se debe crear el json del mismo
   
		SELECT INTO ivajson array_to_json(array_agg(row_to_json(t))) as "Iva"
		FROM (
			select round(sum(importe)::numeric,2) as "BaseImp",round(sum((importe*0.105))::numeric,2)  as "Importe",4 as "Id" 
			from itemfacturaventa 
			where nrofactura =  rfacturaventa.nrofactura AND nrosucursal =  rfacturaventa.nrosucursal
		                         AND tipofactura =  rfacturaventa.tipofactura AND tipocomprobante =  rfacturaventa.tipocomprobante
				 AND idconcepto <> 20821
			GROUP BY nrofactura,tipofactura,nrosucursal,tipocomprobante
		) as t;
     END IF ; ---- --- 01-12-2023 Verifico si el
 

    ----- Se busca la info para generar los datos del comprobante
    SELECT  INTO rdevolver 1 as "CantReg",nrosucursal as "PtoVta",
     CASE WHEN tipofactura = 'FA' AND tipocomprobante = 1 THEN 6
      WHEN tipofactura = 'FA' AND tipocomprobante = 2 THEN 1
      WHEN tipofactura = 'NC' AND tipocomprobante = 1 THEN 8
      WHEN tipofactura = 'NC' AND tipocomprobante = 2 THEN 2 
      ELSE 123 END as "CbteTipo"
		, 1 as "Concepto",
		 CASE WHEN tipocomprobante = 1 THEN 96 ELSE 80 END as "DocTipo"
		 ,CASE WHEN tipocomprobante = 1 THEN facturaventa.nrodoc ELSE concat(cliente.cuitini,cliente.cuitmedio,cliente.cuitfin) END as "DocNro"
                 ,nrofactura as "CbteDesde",nrofactura as "CbteHasta"
 ,to_char(CASE WHEN fechaemision + 5::integer <= CURRENT_DATE THEN current_date ELSE fechaemision END,'YYYYMMDD') as "CbteFch"
		,round((CASE WHEN nullvalue(importeefectivo) THEN 0 ELSE importeefectivo END  + CASE WHEN nullvalue(importectacte) THEN 0 ELSE importectacte END  )::numeric,2) as "ImpTotal"
		,0 as  "ImpNeto"
		,round((CASE WHEN nullvalue(importeefectivo) THEN 0 ELSE importeefectivo END  + CASE WHEN nullvalue(importectacte) THEN 0 ELSE importectacte END  )::numeric,2) as "ImpTotConc",0 as "ImpOpEx"
		,0 as "ImpIVA",0 as "ImpTrib",'PES' as "MonId"
		,1 as "MonCotiz",concat(facturaventa_wsafip.idrecibo,'-',facturaventa_wsafip.centro) as "Recibo"
		--,ivajson as "Iva"
                ,nrofactura as nrofacturaoriginal
                ,concat(cliente.cuitini,cliente.cuitmedio,cliente.cuitfin) as cuit
	from facturaorden 
	JOIN facturaventa USING(nrofactura,nrosucursal,tipofactura,tipocomprobante,centro)
        LEFT JOIN facturaventa_wsafip USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
	LEFT JOIN cliente ON nrodoc = cliente.nrocliente AND tipodoc = cliente.barra
	WHERE tipofactura = parametro->>'tipofactura' AND nrofactura = parametro->>'nrofactura' AND nrosucursal = parametro->>'nrosucursal' AND tipocomprobante = parametro->>'tipocomprobante'
        AND nullvalue(nrofacturafiscal); 


      --Malapi 02-08-2019 Si la factura tiene importe 0, no debe ser generada, largo un error. 
      IF rdevolver."ImpTotal" = 0 THEN 
               RAISE EXCEPTION 'La factura tiene importe cero  %',rdevolver;
                               
       END IF;
               	






	 respuestajson = row_to_json(rdevolver);

      return respuestajson;

end;$function$
