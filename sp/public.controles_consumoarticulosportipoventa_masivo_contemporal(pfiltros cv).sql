CREATE OR REPLACE FUNCTION public.controles_consumoarticulosportipoventa_masivo_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 


 
CREATE TEMP TABLE temp_controles_consumoarticulosportipoventa_masivo_contemporal
AS (
	SELECT  
ovfechaemision,mnombre,ovicantidad,osdescripcion,ovnombrecliente,far_ordenventa.nrocliente,nrorecetario,ftvdescripcion,acodigobarra,



	     '1-Fecha Venta#ovfechaemision@2-Medicamento#mnombre@3-CodigoBarra#acodigobarra@4-Cantidad#ovicantidad@5-OOSS#osdescripcion@6-nombreapellido#ovnombrecliente@7-Nro afiliado#nrocliente@8-Nro recetario#nrorecetario@9-TipoVenta#ftvdescripcion'::text as mapeocampocolumna 

	 

FROM far_ordenventareceta
					NATURAL JOIN far_ordenventa 
					NATURAL JOIN far_ordenventaitem 
					NATURAL JOIN far_articulo
                                        NATURAL JOIN far_ordenventaestado 
					LEFT JOIN far_medicamento USING (idarticulo 	,idcentroarticulo)
					LEFT JOIN manextra USING (mnroregistro)
					LEFT JOIN medicamento USING (mnroregistro)
                                        LEFT join  farmtipoventa using(idfarmtipoventa)
					--LEFT JOIN monodroga USING (idmonodroga)
					LEFT JOIN far_ordenventaitemimportes as fovii using(idordenventaitem,idcentroordenventaitem)
                                        LEFT JOIN facturaorden on (facturaorden.nroorden=far_ordenventa.idordenventa and facturaorden.centro=far_ordenventa.idcentroordenventa)
					
					LEFT JOIN facturaventa USING (nrofactura,nrosucursal,tipocomprobante,tipofactura)
					
					JOIN far_afiliado as fa ON (far_ordenventa.idafiliado = fa.idafiliado AND far_ordenventa.idcentroafiliado = fa.idcentroafiliado )
					 LEFT JOIN far_obrasocial as fo ON(fo.idobrasocial= fovii.oviiidobrasocial)
                                        LEFT JOIN persona p ON (fa.nrodoc=p.nrodoc)
                                        LEFT JOIN persona c ON (fa.nrocliente = c.nrodoc)
					WHERE (idordenventaestadotipo <> 2 AND nullvalue(ovefechafin)) AND
					 
						(ovfechaemision >=rfiltros.fechadesde AND ovfechaemision <=rfiltros.fechahasta )
					
AND nullvalue(anulada)
  AND(idfarmtipoventa=rfiltros.idfarmtipoventa or NULLVALUE(rfiltros.idfarmtipoventa))
and tipofactura='FA'


);


return true;
END;
$function$
