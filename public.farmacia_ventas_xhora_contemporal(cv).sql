CREATE OR REPLACE FUNCTION public.farmacia_ventas_xhora_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN
     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_farmacia_ventas_xHora_contemporal AS (
        SELECT * 
        FROM (
              SELECT date_trunc('hour',ovfechaemision) as hora,date_trunc('day',ovfechaemision)::date  as fechaemision ,count(*) as cantidadorden 
              FROM far_ordenventa 
              WHERE 
                ovfechaemision >= rparam.fechadesde  AND  ovfechaemision <= rparam.fechahasta
                AND idcentroordenventa = rparam.idcentroregional 
              GROUP BY  date_trunc('day',ovfechaemision),date_trunc('hour',ovfechaemision) order by date_trunc('day',ovfechaemision)
            ) as ordenes
        LEFT JOIN (
                  SELECT date_trunc('hour',fechacreacion) as hora,fechaemision,count(*) as cantidadfactura 
                  FROM facturaventa 
                  WHERE 

                  fechaemision >= rparam.fechadesde  AND fechaemision <= rparam.fechahasta
                  AND centro = rparam.idcentroregional 
                  GROUP BY fechaemision,date_trunc('hour',fechacreacion) 
                  ORDER BY date_trunc('hour',fechacreacion)

                  ) as facturas USING(fechaemision,hora)
        ORDER BY hora

       );
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
      
    
return respuesta;
END;$function$
