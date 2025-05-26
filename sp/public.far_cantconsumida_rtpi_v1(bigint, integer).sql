CREATE OR REPLACE FUNCTION public.far_cantconsumida_rtpi_v1(bigint, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE
  --variables
  cantconsumida INTEGER;
  elidrecetariotpitem alias for $1;
  elidcentrorecetariotpitem alias for $2;

BEGIN

SELECT INTO cantconsumida  SUM(t.cantidad) FROM 
(SELECT 


CASE WHEN nullvalue(ovicantidad) THEN 0
 ELSE ovicantidad END AS cantidad
  FROM recetariotp as r NATURAL JOIN recetariotpitem  JOIN far_medicamento USING(mnroregistro, nomenclado)
LEFT JOIN recetariotpitemuso  USING(idrecetariotpitem, idcentrorecetariotpitem)
LEFT JOIN 
--KR 13-03-18 Modifico para que tome en cuenta las NC de los recetarios y sume las cantidades de las NC, además de restar las cantidades de las OV que no tienen NC asociadas
(SELECT idrecetariotpitem,idcentrorecetariotpitem,idordenventa, idcentroordenventa ,(CASE WHEN nullvalue(ifv.cantidad) THEN ovicantidad ELSE ((cantidad*-1)) END ) AS ovicantidad--,idarticulo,idcentroarticulo 
FROM  far_ordenventa 
NATURAL JOIN far_ordenventaitem  
NATURAL JOIN far_ordenventaestado 
--MaLaPi 13-04-2018 Para que sea mas eficiente solo tomo ordenes que se emiten en el marco de una recetariotp
LEFT JOIN recetariotpitemuso USING(idordenventa, idcentroordenventa)
LEFT JOIN far_ordenventaitemitemfacturaventa AS oviifv USING(idordenventaitem, idcentroordenventaitem)
LEFT JOIN itemfacturaventa AS ifv ON (oviifv.nrofactura=ifv.nrofactura AND oviifv.nrosucursal=ifv.nrosucursal AND oviifv.tipocomprobante=ifv.tipocomprobante AND oviifv.tipofactura=ifv.tipofactura AND ifv.tipofactura='NC' AND idconcepto <>'50840')
WHERE  idordenventaestadotipo<>2 and nullvalue(ovefechafin)     
GROUP BY idrecetariotpitem,idcentrorecetariotpitem,idordenventa, idcentroordenventa,ifv.cantidad,ovicantidad
--MaLaPi 13-04-2018 Para que sea mas eficiente agrego idrecetariotpitem,idcentrorecetariotpitem para qeu el LEFT JOIN sea por clave primaria
) AS TT USING(idrecetariotpitem,idcentrorecetariotpitem,idordenventa, idcentroordenventa /*, idarticulo,idcentroarticulo*/)
--KR 26-01-18 Modifico y saco del left el idarticulo para que descuente la cantidad vendida aun cuando cambian el articulo en el tp 
WHERE  idrecetariotpitem= elidrecetariotpitem AND idcentrorecetariotpitem=elidcentrorecetariotpitem
) AS T ;


return cantconsumida;
END;$function$
