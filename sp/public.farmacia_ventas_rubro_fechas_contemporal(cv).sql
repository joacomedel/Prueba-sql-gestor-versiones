CREATE OR REPLACE FUNCTION public.farmacia_ventas_rubro_fechas_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN
     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_farmacia_ventas_rubro_fechas_contemporal AS (

              SELECT  
rdescripcion as rubro,date(ovfechaemision) as fecha, adescripcion as producto,ROUND(CAST(oviprecioventa AS numeric), 2) AS importe  
--,*
 /*
   rdescripcion as rubro, 
    SUM(ovicantidad) as cantidad,
    ROUND(SUM(CAST(oviprecioventa AS numeric)), 2) AS total 
*/
 
	FROM far_ordenventa
 	JOIN far_ordenventaestado using (idordenventa,	idcentroordenventa)  
	
	natural join far_ordenventaitem
natural join far_articulo
natural join far_rubro


where ovfechaemision >= rparam.fdesde
		 and ovfechaemision <= rparam.fhasta

--and idrubro <> 4
and idordenventaestadotipo <>2
and idcentroordenventa = 99
order by rdescripcion,	ovfechaemision
--group by rdescripcion
       );

  
--por ahora ponemos esto. 
     respuesta = 'todook';
     
      
    
return respuesta;
END;$function$
