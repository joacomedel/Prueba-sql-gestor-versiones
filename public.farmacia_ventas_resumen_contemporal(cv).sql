CREATE OR REPLACE FUNCTION public.farmacia_ventas_resumen_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN
     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_farmacia_ventas_resumen_contemporal AS (

              SELECT 
                --date_trunc('day',ovfechaemision)::date  as fechaemision 
                count(*) as cantidadorden
                ,cob

              FROM far_ordenventa 
              NATURAL JOIN far_ordenventatipo 
              NATURAL JOIN far_ordenventaestado 
              NATURAL JOIN far_ordenventaestadotipo 

              NATURAL JOIN (
                  SELECT 
                    idordenventa,
                    idcentroordenventa,
                    CASE WHEN t.idvalorescaja=0 THEN text_concatenar(concat(idvalorescaja,'- Sin Obra Social','|')) ELSE text_concatenar(concat(idvalorescaja,'-',lfdescripcion,'|')) END as cob
                  FROM  (
                    SELECT DISTINCT idordenventa,idcentroordenventa,idvalorescaja
                    FROM  far_ordenventaitem 
                    NATURAL JOIN far_ordenventaitemimportes 
                    --WHERE idvalorescaja  > 0
                    GROUP BY idordenventa,idcentroordenventa,idvalorescaja
                    ORDER BY idvalorescaja) as t
                  LEFT JOIN liquidadorfiscalvalorescaja USING (idvalorescaja)
                  WHERE (lfrequiereliquidar OR idvalorescaja =0)
                    --AND( idvalorescaja = null or nullvalue(null))
                    GROUP BY idordenventa,idcentroordenventa,t.idvalorescaja
              ) as coberturas


              WHERE 
                ovfechaemision >= rparam.fechadesde  AND  ovfechaemision <= rparam.fechahasta
                AND CASE WHEN nullvalue(rparam.idcentroregional) THEN idcentroordenventa=99 ELSE idcentroordenventa = rparam.idcentroregional END 
              GROUP BY  coberturas.cob



       );
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
      
    
return respuesta;
END;$function$
