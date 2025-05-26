CREATE OR REPLACE FUNCTION public.consumos_afiliadoxmes_rango_fecha_contemporal(character varying)
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

     CREATE TEMP TABLE temp_consumos_afiliadoxmes_rango_fecha_contemporal AS (
SELECT

     mes
    ,anio
    ,afiliado 
    --,aapellidoynombre
    ,total
    ,concat(apellido, ', ', nombres) as "Apellido y Nombre", concat (nrodoc, '-', barra) "Nro Afil."  ----PA 30/04/2024

--*
FROM(
SELECT
    mes
    ,anio
    ,afiliado 
    --,aapellidoynombre
    ,filtroobserver.cantidad as total

FROM (
            SELECT
              mes,
              anio,
              afiliado,
              sum(cantidad) as cantidad
            FROM(

            SELECT 
             extract(month from ovfechaemision) as mes
            ,extract(year from ovfechaemision) as anio
            ,nrodoc as afiliado
            ,sum(ovicantidad) as cantidad
            ,'0' as roopf 
            FROM far_ordenventa
            NATURAL JOIN far_ordenventaestado
            NATURAL JOIN far_ordenventaitem
            NATURAL JOIN far_ordenventaitemimportes
            LEFT JOIN far_afiliado  ON (nrodoc=oviinrodoc AND idobrasocial=1)
            NATURAL JOIN far_articulo 
            LEFT JOIN (
                        SELECT *
                        FROM far_ordenventaitemitemfacturaventa
                        WHERE tipofactura= 'NC'
                        ) as conNC USING (  idordenventaitem,idcentroordenventaitem)

            WHERE
              ovfechaemision>= rparam.fechadesde  AND   ovfechaemision<= rparam.fechahasta
              AND   idordenventaestadotipo=3 
              AND nullvalue(ovefechafin )
              AND far_afiliado.idobrasocial=1
              AND nullvalue(tipofactura)
            AND idcentroordenventa=99
            AND (idvalorescaja=59 OR idvalorescaja=63)

            GROUP BY afiliado,mes,anio
     ) as filtroobserver1
        GROUP BY afiliado,mes,anio
  ) as filtroobserver 


) as filtrado
left join persona on (afiliado = nrodoc)  --PA 30/04/2024


WHERE
    total >= CASE WHEN nullvalue(rparam.cantidad) THEN 6 ELSE rparam.cantidad END

ORDER BY mes,anio,afiliado



       );
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
