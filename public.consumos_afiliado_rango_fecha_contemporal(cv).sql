CREATE OR REPLACE FUNCTION public.consumos_afiliado_rango_fecha_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
  elafiliado RECORD; 
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

    SELECT INTO elafiliado * FROM consumos_afiliado_sigesobserver_contemporal(null); 

     CREATE TEMP TABLE temp_consumos_afiliado_rango_fecha_contemporal AS (
SELECT
filtrado.*  ,barra
,concat(apellido,' ',nombres) as aapellidoynombre
FROM(
            SELECT
                 mes
                 ,anio
                 ,afiliado
                --,barra  
                --,concat(apellido,' ',nombres) as aapellidoynombre
                ,expendio
                ,codigobarra 
                ,adescripcion
                ,cantidad
                ,   pagososunc
                ,  preciomedicamento
                ,   cobertura
                , monodroga
                --,rechazo.cantidad as CR
                --,filtroobserver.cantidad as cantidad
                --,CASE WHEN nullvalue(rechazo.cantidad) THEN filtroobserver.cantidad ELSE (filtroobserver.cantidad-rechazo.cantidad) END as cantidad

            FROM (
            SELECT 
            extract(month from ovfechaemision) as mes
            ,extract(year from ovfechaemision) as anio
            ,nrodoc as afiliado
           -- ,concat(apellido,' ',nombres) as aapellidoynombre
           , 'Farmacia Propia' as expendio
            ,acodigobarra as codigobarra
            ,adescripcion
            ,sum(ovicantidad) as cantidad
    
            , ROUND(SUM(oviimonto)::numeric, 2) as pagososunc
            ,ROUND(SUM(oviprecioventa)::numeric, 2) as preciomedicamento
            , oviiporcentajecobertura as cobertura
            ,monnombre as monodroga

            FROM far_ordenventa
            NATURAL JOIN far_ordenventaestado
            NATURAL JOIN far_ordenventaitem
            NATURAL JOIN far_ordenventaitemimportes
            NATURAL JOIN far_afiliado
            NATURAL JOIN far_articulo 
            left join far_medicamento using(idarticulo, idcentroarticulo)
            left join manextra using (mnroregistro) 
            left join monodroga using (idmonodroga)

            LEFT JOIN (
                        SELECT *
                        FROM far_ordenventaitemitemfacturaventa
                        WHERE tipofactura= 'NC'
                        ) as conNC USING (  idordenventaitem,idcentroordenventaitem)

            WHERE
              ovfechaemision>= rparam.fechadesde   AND   ovfechaemision<= rparam.fechahasta
              AND   idordenventaestadotipo=3
              AND nullvalue(ovefechafin )
              AND far_afiliado.idobrasocial=1
              AND idcentroordenventa=99
              AND idvalorescaja=59
              AND nullvalue(tipofactura)
            GROUP BY afiliado,codigobarra,mes,anio,adescripcion,expendio,   monnombre, oviiporcentajecobertura
 ) as filtroobserver
             ) as filtrado
        LEFT JOIN persona ON (afiliado = nrodoc)

                WHERE
                cantidad >= CASE WHEN nullvalue(rparam.cantidad) THEN 6 ELSE rparam.cantidad END
                AND CASE WHEN nullvalue(rparam.afiliado) THEN true ELSE  afiliado ilike concat('%',rparam.afiliado,'%') END
ORDER BY afiliado,mes,anio

);

           /* UNION


            SELECT 
            extract(month from rofechaventa) as mes
            ,extract(year from rofechaventa) as anio
            ,nrodoc as afiliado
           -- ,concat(apellido,' ',nombres) as aapellidoynombre
           ,rofarmacia as expendio
            ,rocodbarras as codigobarra
            ,adescripcion
            ,sum(rocantidad ) as cantidad
            FROM temp_consumos_afiliado_sigesobserver_contemporal
            LEFT JOIN far_articulo ON (acodigobarra=rocodbarras)
            LEFT JOIN persona ON (SUBSTRING(ronroafiliado, 1, 8) = nrodoc)

            WHERE
              rofechaventa>= rparam.fechadesde   AND   rofechaventa<= rparam.fechahasta 
              AND   roautorizada='S'
            GROUP BY afiliado,codigobarra,mes,anio,adescripcion,expendio
            ) as filtroobserver
            LEFT JOIN
            (
            SELECT 
                extract(month from rofechaventa) as mes
                ,extract(year from rofechaventa) as anio
                ,nrodoc as afiliado 
                ,rofarmacia as expendio
                ,rocodbarras as codigobarra
                --,adescripcion
                ,sum(rocantidad ) as cantidad
                FROM temp_consumos_afiliado_sigesobserver_contemporal
                LEFT JOIN far_articulo ON (acodigobarra=rocodbarras)
                LEFT JOIN persona ON (SUBSTRING(ronroafiliado, 1, 8) = nrodoc)

                WHERE
                  rofechaventa>= rparam.fechadesde   AND   rofechaventa  <= rparam.fechahasta
                  AND   roautorizada='N' AND NOT nullvalue(rofechaanulacion)
                GROUP BY codigobarra,afiliado,mes,anio,expendio
              ) as rechazo USING(codigobarra,afiliado,mes,anio,expendio)

         ) as filtrado
        LEFT JOIN persona ON (afiliado = nrodoc)

                WHERE
                cantidad >= CASE WHEN nullvalue(rparam.cantidad) THEN 6 ELSE rparam.cantidad END
                AND CASE WHEN nullvalue(rparam.afiliado) THEN true ELSE  afiliado ilike concat('%',rparam.afiliado,'%') END
ORDER BY afiliado,mes,anio


       );*/
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
