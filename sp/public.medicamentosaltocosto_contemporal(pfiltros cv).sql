CREATE OR REPLACE FUNCTION public.medicamentosaltocosto_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;
  relem RECORD;
  rvalorescaja RECORD;
  rfiltros RECORD;
  vquery text;
   
  cursorcc refcursor;
  varrvalorescaja  varchar[];
  varrlongitud integer;
  vvalorescaja  varchar;
  vcontador integer;
BEGIN
  
 
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
--(rfiltros.idconac= 1) con asientos contables
        
CREATE TEMP TABLE temp_medicamentosaltocosto_contemporal
AS (
	SELECT
codfactura
,ovfechaemision as fechaemision
,ovrfechauso as fechareceta
--Remito
,concat('DNI:',nrodoc) as nrodoc
,concat(apellido,' ',nombres) as aapellidoynombre
            ,acodigobarra as codigobarra
            ,adescripcion as descripcion
            ,ovicantidad as cantidad
            ,extract(month from ovfechaemision) as mes
            ,extract(year from ovfechaemision) as anio 
            ,'Farmacia Propia' as expendio, 
'1-CodFactura#codfactura@2-Fechaemision#fechaemision@3-FechaReceta#fechareceta@4-Nrodoc#nrodoc@5-ApellidoyNombres#aapellidoynombre@6-Codigobarra#codigobarra@7-Descripcion#descripcion@8-Cantidad#cantidad@9-Mes#mes@10-Anio#anio@11-Expendio#expendio'::text as mapeocampocolumna
	FROM far_ordenventa
            NATURAL JOIN far_ordenventareceta
            NATURAL JOIN far_ordenventaestado
            NATURAL JOIN far_ordenventaitem
            NATURAL JOIN far_ordenventaitemimportes
            NATURAL JOIN far_afiliado
            NATURAL JOIN far_articulo
            JOIN persona USING(nrodoc,tipodoc)
            LEFT JOIN (
                        SELECT idordenventaitem,idcentroordenventaitem, concat(tipofactura,'-',nrofactura,'-',nrosucursal,'-',tipocomprobante) as codnc,fechaemision as facturafechaemision
                        FROM far_ordenventaitemitemfacturaventa
                        NATURAL JOIN facturaventa
                        WHERE tipofactura= 'NC'
                        ) as conNC USING (  idordenventaitem,idcentroordenventaitem)

            LEFT JOIN (
                        SELECT  idordenventaitem,idcentroordenventaitem, concat(tipofactura,'-',nrofactura,'-',nrosucursal,'-',tipocomprobante) as codfactura,fechaemision as facturafechaemision
                        FROM far_ordenventaitemitemfacturaventa
NATURAL JOIN facturaventa
                        WHERE tipofactura <> 'NC'
                        ) as conFA USING (  idordenventaitem,idcentroordenventaitem)

            WHERE
              ovfechaemision>= rfiltros.fechadesde   AND   ovfechaemision<= rfiltros.fechahasta
              AND idordenventaestadotipo=3
              AND nullvalue(ovefechafin )
              AND far_afiliado.idobrasocial=1
              AND idcentroordenventa=1
              AND idvalorescaja=59
              AND nullvalue(conNC.codnc)
           AND (nrodoc = rfiltros.nrodoc or nullvalue(rfiltros.nrodoc))
ORDER BY nrodoc,mes,anio

 );

return true;
END;$function$
