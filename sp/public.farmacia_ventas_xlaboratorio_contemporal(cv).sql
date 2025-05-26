CREATE OR REPLACE FUNCTION public.farmacia_ventas_xlaboratorio_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_farmacia_ventas_xlaboratorio_contemporal AS (

        SELECT 
          adescripcion, 
          mcodbarra, 
          SUM(ovicantidad) as cantidadvendida,
          far_darcantidadarticulostock(far_articulo.idarticulo,far_articulo.idcentroarticulo) AS acantidadactual,
          lnombre,    
          pavalor, 
          preciocompra
        FROM far_ordenventa 
        NATURAL JOIN far_ordenventaitem 
        NATURAL JOIN far_articulo  
        NATURAL JOIN far_medicamento 
        NATURAL JOIN medicamento 
        NATURAL JOIN laboratorio 
        NATURAL JOIN far_ordenventaestado   
        NATURAL JOIN far_preciocompra 
        JOIN far_precioarticulo  USING(idarticulo,idcentroarticulo)



        WHERE  
            ovfechaemision >= rparam.fechadesde 
            AND ovfechaemision <= rparam.fechahasta
            AND idlaboratorio = rparam.idlaboratorio
            AND nullvalue(ovefechafin) 
            AND idordenventaestadotipo    <>2
            AND nullvalue(pcfechafin)  
            AND nullvalue(pafechafin)

        GROUP BY adescripcion, mcodbarra, lnombre,    pavalor, preciocompra ,far_articulo.idarticulo,far_articulo.idcentroarticulo
        
        
      ORDER BY adescripcion

       );
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
      
    
return respuesta;
END;$function$
