CREATE OR REPLACE FUNCTION public.control_consumos_afiliado_rango_mes_calendario_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
  elafiliado RECORD; 
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_control_consumos_afiliado_rango_mes_calendario_contemporal AS (

            SELECT
                 nrodoc
               --,concat(apellido,' ',nombres) as aapellidoynombre
                ,sum(cantidad) AS total
                

            FROM (
                    SELECT 
                        nrodoc
                        , 'Farmacia Propia' as expendio
                        ,sum(ovicantidad) as cantidad -- cantidad vendida
                        ,idvalorescaja
            
                    FROM far_ordenventa
                    NATURAL JOIN far_ordenventaestado --USING (idordenventa,idcentroordenventa)
                    NATURAL JOIN far_ordenventaitem --USING (idordenventa,idcentroordenventa)
                    NATURAL JOIN far_ordenventaitemimportes --USING (idordenventaitem,idcentroordenventaitem)
                    LEFT JOIN far_afiliado  ON (nrodoc=oviinrodoc AND idobrasocial=1)

                    LEFT JOIN (
                        SELECT *
                        FROM far_ordenventaitemitemfacturaventa
                        WHERE tipofactura= 'NC'
                        ) as conNC USING (  idordenventaitem,idcentroordenventaitem)

                    WHERE 
                        (idvalorescaja=59 OR idvalorescaja=63)
                        AND CASE WHEN nullvalue(rparam.afiliado) THEN true ELSE  nrodoc ilike concat('%',rparam.afiliado,'%') END
                        AND (idordenventaestadotipo=3 OR idordenventaestadotipo=1)
                        AND nullvalue(ovefechafin )
                        AND idcentroordenventa=99
                        AND oviimonto!=0
                        AND nullvalue(tipofactura)
                        AND ovfechaemision>= rparam.fechadesde  AND   ovfechaemision <= CURRENT_DATE+1
                    GROUP BY nrodoc,expendio,idvalorescaja
                ) as filtroconsumosafiliado



            --LEFT JOIN persona USING (nrodoc)

            --WHERE
            --cantidad >= CASE WHEN nullvalue(rparam.cantidad) THEN 6 ELSE rparam.cantidad END
            --cantidad >=1
            --CASE WHEN nullvalue(rparam.afiliado) THEN true ELSE  nrodoc ilike concat('%',rparam.afiliado,'%') END

            GROUP BY nrodoc
            ORDER BY nrodoc


);


     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
