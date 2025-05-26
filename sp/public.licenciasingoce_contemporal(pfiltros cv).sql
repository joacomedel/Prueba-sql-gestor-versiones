CREATE OR REPLACE FUNCTION public.licenciasingoce_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
    
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_licenciasingoce_contemporal
AS (

select 
t.*, apellido, nombres,legajosiu,idlic,fechainilic,fechafinlic,motivolic,concat(nrodoc,'-',barra) as nroafiliado,fechafinos,telefono,
email
, '1-Apellido#apellido@2-Nombres#nombres@3-NroAfiliado#nroafiliado@4-FechaFinOS#fechafinos@5-Telefono#telefono@6-Email#email@7-Importe#importe@8-Mes#mes@9-Anio#anio@10-IdAporte#idaporte@11-CentroRegional#idcentroregionaluso@12-Periodo#periodo@13-IdRecibo#idrecibo@14-Comprobante#elcomprobante@15-Nroinforme#nroinforme'::text as mapeocampocolumna 
    
 FROM licsinhab 
NATURAL JOIN cargo 
NATURAL JOIN persona 
LEFT JOIN (SELECT 
aportesafiliados.anio,aportesafiliados.mes,aportesafiliados.importe,pagofechaingreso,aportesafiliados.nrodoc,aportesafiliados.barra,idaporte,idcentroregionaluso,
concat(descrip , ' - ', anio) as periodo,idrecibo, CASE WHEN nullvalue(aportefacturado.nrofactura) THEN 'No Facturado' ELSE concat(tcv.desccomprobanteventa,'|',aportefacturado.tipofactura,'|',aportefacturado.nrosucursal,'|',aportefacturado.nrofactura) END AS  elcomprobante,nroinforme,idcentroinformefacturacion,fechainforme,nrocliente,idinformefacturaciontipo,nrofactura,tipocomprobante,nrosucursal,tipofactura,idtipofactura
,aportefacturado.idformapagotipos
FROM (SELECT anio, mes, importe, ajpfechaingreso as pagofechaingreso, nrodoc, barra, idaporte, idcentroregionaluso 				FROM aportejubpen				
UNION SELECT anio, mes, importe, alicfechaingreso as pagofechaingreso, nrodoc, barra, idaporte, idcentroregionaluso 				FROM aporteuniversidad 			 
) AS aportesafiliados 
JOIN tmeses on (tmeses.idmes = aportesafiliados.mes) 			
LEFT JOIN 			(SELECT if.*,informefacturacionaporte.idaporte, informefacturacionaporte.idcentroregionaluso 			
FROM informefacturacionaporte 
LEFT JOIN informefacturacion AS if USING (nroinforme,	idcentroinformefacturacion) 				 
LEFT JOIN informefacturacionestado USING (nroinforme,	idcentroinformefacturacion)					
WHERE nullvalue(fechafin) AND informefacturacionestado.idinformefacturacionestadotipo<> 5) 			as aportefacturado  USING (idaporte, idcentroregionaluso) 			
LEFT JOIN tipocomprobanteventa AS tcv ON(tipocomprobante = idtipo) 	
join aporte  USING (idaporte, idcentroregionaluso) 	
) as t USING(nrodoc,barra)
WHERE 
     fechainilic>= rfiltros.fechadesde   AND   fechainilic<= rfiltros.fechahasta
AND CASE WHEN nullvalue(rfiltros.nrodoc) THEN true ELSE  nrodoc ilike concat('%',rfiltros.nrodoc,'%') END
	oRDER BY  t.anio *100 + t.mes DESC);
	
	
	
return true;
END;
$function$
