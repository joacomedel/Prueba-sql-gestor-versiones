CREATE OR REPLACE FUNCTION public.farmacia_ventas_vale_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN
     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  
CREATE TEMP TABLE temp_farmacia_ventas_vale_contemporal AS (
        /*
	 ovivale.ovicantidad  as cantidadvale,
ovi.ovicantidad   as cant2
	*/
	
--vales emitidos en un rango de fecha 
select  
ovi.idordenventa,ovi.idcentroordenventa,nrocliente,ovnombrecliente,ovefechaini,
case when (ovefechafin) is null then '' else ovefechafin::varchar  end as ovefechafin,ovi.ovidescripcion,ovivale.ovicantidad  as cantvale,ovi.ovicantidad as cant ,ovi.oviprecioventa,vnombre,
'1-OrdenVenta#idordenventa@2-CentroOrdenVenta#idcentroordenventa@3-Nrocliente#nrocliente@4-NombreCliente#ovnombrecliente@5-FechaIni#ovefechaini@6-FechaFin#ovefechafin@7-Descripcion#ovidescripcion@8-CantidadVale#cantvale@9-PrecioVenta#oviprecioventa@10-Cantidad#cant@11-Vendedor#vnombre'::text as mapeocampocolumna 
from
far_ordenventaitemvale as ovorig		 
JOIN far_ordenventaitem as ovi  ON(ovi.idordenventaitem =ovorig.idordenventaitemoriginal 
and ovi.idcentroordenventaitem=ovorig.idcentroordenventaitemoriginal )
JOIN far_ordenventaitem as ovivale ON(ovivale.idordenventaitem =ovorig.idordenventaitemvale and ovivale.idcentroordenventaitem=ovorig.idcentroordenventaitemvale )
join far_ordenventa as ov   on(ov.idordenventa =ovi.idordenventa	and ov.idcentroordenventa=ovi.idcentroordenventa )
join far_ordenventaestado as fove on(ov.idordenventa =fove.idordenventa	and ov.idcentroordenventa=fove.idcentroordenventa )
natural join far_vendedor

where  
(ovfechaemision>=rparam.fechadesde )
and
(ovfechaemision<=rparam.fechahasta or rparam.fechahasta is null)
and (ovefechafin)is null and idordenventaestadotipo<>2 	

order by ovi.idordenventaitem ,ovi.idcentroordenventaitem

 
       
);
  
 
 respuesta = 'todook';    
      
    
return respuesta;
END;$function$
