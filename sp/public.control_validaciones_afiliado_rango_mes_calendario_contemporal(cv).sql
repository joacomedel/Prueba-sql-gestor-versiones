CREATE OR REPLACE FUNCTION public.control_validaciones_afiliado_rango_mes_calendario_contemporal(character varying)
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
                        crednumero as nrodoc

                        ,sum(cantidadaprobada) as cantidad -- cantidad vendida

            
                    FROM far_validacion
                    --NATURAL JOIN far_ordenvalidaciones
                    NATURAL JOIN far_validacionitems
                    LEFT JOIN far_validacionitemsestado USING (idvalidacionitem,idcentrovalidacionitem) 

                    WHERE
    --                      (idvalorescaja=59 OR idvalorescaja=63)
                      --AND (idordenventaestadotipo=3 OR idordenventaestadotipo=1)
      --                AND nullvalue(ovefechafin )
        --              AND idcentroordenventa=99
          --            AND oviimonto!=0
            --          AND nullvalue(tipofactura)
                       vfecha>= rparam.fechadesde   AND   vfecha <= CURRENT_DATE+1
                      AND fincodigo=1
                      AND codrta=0
                      AND nullvalue(viefechafin) 
                      AND idvalidacionitemsestadotipo=1
                      AND crednumero ilike concat('%',rparam.afiliado,'%')
                      
                    GROUP BY nrodoc
                ) as filtroconsumosafiliado



            LEFT JOIN persona USING (nrodoc)

            WHERE
            --cantidad >= CASE WHEN nullvalue(rparam.cantidad) THEN 6 ELSE rparam.cantidad END
            --cantidad >=1
            CASE WHEN nullvalue(rparam.afiliado) THEN true ELSE  nrodoc ilike concat('%',rparam.afiliado,'%') END

            GROUP BY nrodoc
            ORDER BY nrodoc


);


     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
