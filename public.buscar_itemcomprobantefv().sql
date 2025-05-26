CREATE OR REPLACE FUNCTION public.buscar_itemcomprobantefv()
 RETURNS SETOF info_itemcomprobantefv
 LANGUAGE plpgsql
AS $function$DECLARE
   rdatosicfv info_itemcomprobantefv;
--VARIABLES
    tieneamuc BOOLEAN;
    elidmutualpadron BIGINT;
--REGISTROS
    rcomprobante RECORD;
    tienemutualp RECORD;
BEGIN
-- Verifico si tiene AMUC
SELECT INTO rcomprobante * FROM temp_facturaventa;
IF FOUND  THEN
FOR rdatosicfv in SELECT   
                    iditem,
                    descripcion, 
                    ovicantidad as    cantidad   ,
                    itemfacturaventa.idiva ,
                    cantdevueltas,
                    itemfacturaventa.idconcepto, 
                    importe,
                    CASE WHEN nullvalue(oviimontoafil) THEN 0 ELSE round( CAST (( oviimontoafil / ovicantidad) AS numeric ),2 ) END as montoafiliado ,   
                    nrofactura,    
                    nrosucursal,
                    tipocomprobante,
                    tipofactura
                  --MaLaPi 20-02-2018 Agrego para que al emitir una nota de credito que se desprende de varias ordenes de ventas tome bien el importe abonado por el afiliado
                    ,idordenventaitem , 
                    idcentroordenventaitem,
                    idordenventa,	
                    idcentroordenventa,
                    --GK 05-04-2022 Agrego datos del desc para facilitar el emitir NC
                    oviifpporcentajedto,
                    idvalorescaja
                  FROM itemfacturaventa	
                  JOIN
                        (SELECT 
                            tipofactura, 
                            tipocomprobante, 
                            nrosucursal, 
                            nrofactura, 
                            iditem,
                            SUM( ovcantdevueltas) as cantdevueltas ,
                            idcentroordenventaitem as idcentroordenventaitem, 
                            idordenventaitem as idordenventaitem	
                        FROM far_ordenventaitemitemfacturaventa 
                        GROUP BY  tipofactura, tipocomprobante, nrosucursal, nrofactura, iditem,idcentroordenventaitem,idordenventaitem
                        )as T USING (tipofactura, tipocomprobante, nrosucursal, nrofactura, iditem)
                  JOIN far_ordenventaitem USING ( idcentroordenventaitem ,idordenventaitem ) 	
                  JOIN (SELECT 
                            SUM(oviimonto) as oviimonto,
                            idordenventaitem , 
                            idcentroordenventaitem,
                            oviifpporcentajedto,
                            far_oviiformapago.idvalorescaja
                        FROM far_ordenventaitemimportes 
                        LEFT JOIN far_oviiformapago USING (idordenventaitemimporte,idcentroordenventaitemimporte)
                        GROUP BY idordenventaitem , idcentroordenventaitem,oviifpporcentajedto,far_oviiformapago.idvalorescaja  )as ImpI USING (idordenventaitem , idcentroordenventaitem) 	
                  LEFT  JOIN (SELECT 
                                SUM(oviimonto) as oviimontoafil,
                                idordenventaitem , 
                                idcentroordenventaitem 	
                             FROM far_ordenventaitemimportes 
                             -- GK 09-05-2022
                             WHERE idvalorescaja = 0 
                             GROUP BY idordenventaitem , idcentroordenventaitem) as ImpAfil USING(idordenventaitem , idcentroordenventaitem)
                  WHERE  
                        cantdevueltas < cantidad 
                        AND  nrofactura= rcomprobante.nrofactura 
                        AND tipofactura = rcomprobante.tipofactura 
                        AND nrosucursal= rcomprobante.nrosucursal
                        AND tipocomprobante= rcomprobante.tipocomprobante
                        -- GK 09-05-2022 Control de null idvalor caja para eleiminar item duplicados 
                        AND (CASE WHEN oviimontoafil!=0 THEN NOT NULLVALUE(ImpI.idvalorescaja) ELSE true END)
                        
        loop
return next rdatosicfv;
end loop;
END IF;

END;
$function$
