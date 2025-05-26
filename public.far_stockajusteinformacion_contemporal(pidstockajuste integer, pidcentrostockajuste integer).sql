CREATE OR REPLACE FUNCTION public.far_stockajusteinformacion_contemporal(pidstockajuste integer, pidcentrostockajuste integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
BEGIN
 
CREATE TEMP TABLE temp_far_stockajusteinformacion_contemporal 
AS (
SELECT case when far_stockajusteitem.idsigno<0 then 'Resta' else 'Suma' end as operacion,
         case when saesautomatico  then 'Si' else 'No' end as esautomatico
        ,concat(far_stockajusteitem.idarticulo ,'-',far_stockajusteitem.idcentroarticulo) as elarticulo			
	,concat(far_stockajuste.idstockajuste ,'-', far_stockajuste.idcentrostockajuste) as idcomprobante
	,safecha,sadescripcion,login,saiimporteunitario,saicantidad,saiimportetotal,saialicuotaiva,saiimporteiva
        ,saicantidadactual + (far_stockajusteitem.idsigno * saicantidad) as stockresultante, saicantidadactual as stockobservado	,adescripcion,acodigobarra,aactivo,lstock as stockactual
,CASE WHEN nullvalue(preciocompra) THEN 0 ELSE preciocompra END AS preciocompra
,pcfechafini
	--,far_preciocomprafecha(far_stockajusteitem.idarticulo,far_stockajusteitem.idcentroarticulo,safecha::date) as preciocompra
	,rporcentajeganacia , rdescripcion

 ,'1-IdComprobante#idcomprobante@2-Fecha Creacion#safecha@3-Comentario#sadescripcion@4-Automatico#esautomatico@5-Articulo#elarticulo@6-Cod.Barra#acodigobarra@7-Descripcion#adescripcion@8-Operacion#operacion@9-Cantidad#saicantidad@10-Imp.Unitario#saiimporteunitario@11-Iva#saialicuotaiva@12-Imp.Iva#saiimporteiva@13-Imp.Total#saiimportetotal@14-Precio Compra#preciocompra@15-StockActualObservacion#stockobservado@16-Stock Resultante#stockresultante@17-Stock Actual#stockactual@18-Porc. Ganancia#rporcentajeganacia@19-Rubro#rdescripcion@20-F.Inicio Precio Compra#pcfechafini' as mapeocampocolumna


FROM  far_stockajuste 
JOIN  far_stockajusteitem USING(idstockajuste,idcentrostockajuste)			
JOIN far_articulo USING(idarticulo,idcentroarticulo)		NATURAL JOIN far_rubro 	
LEFT JOIN far_preciocompra  USING(idarticulo,idcentroarticulo)
LEFT JOIN usuario USING(idusuario) 
LEFT JOIN far_lote ON(far_articulo.idarticulo=far_lote.idarticulo 
	and far_articulo.idcentroarticulo=far_lote.idcentroarticulo 
	AND idcentrolote =far_stockajuste.idcentrostockajuste)			
WHERE  idstockajuste =  pidstockajuste 			
	AND idcentrostockajuste = pidcentrostockajuste	
AND (((pcfechafini <= safecha OR nullvalue(pcfechafini)) AND (pcfechafin >= safecha OR nullvalue(pcfechafin)) )
       )					
ORDER BY adescripcion
);
     

return true;
END;$function$
