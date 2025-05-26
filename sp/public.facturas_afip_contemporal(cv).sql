CREATE OR REPLACE FUNCTION public.facturas_afip_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_facturas_afip_contemporal AS (
    
         select fechaemision,concat (facturaventa_wsafip.tipofactura, '-', desccomprobanteventa) as comprobante,  nrosucursal,   nrofactura as "FacSistema", nrofacturafiscal as "FacAFIP",	fvcae, nrodoc, denominacion,   importectacte ,fvafechacreacion, fvafechacorrerws,

 '1-fechaemision#fechaemision@2-comprobante#comprobante@3-nrosucursal#nrosucursal@4-FacSistema#FacSistema@5-FacAFIP#FacAFIP@6-fvcae#fvcae@7-nrodoc#nrodoc@8-denominacion#denominacion@9-importectacte#importectacte@10-Fecha_Creacion#fvafechacreacion@11-Fecha_AFIP#fvafechacorrerws'::text as mapeocampocolumna          

        FROM  facturaventa
left  join facturaventa_wsafip using (nrofactura, tipocomprobante, nrosucursal, tipofactura)
join cliente as c on (facturaventa.nrodoc = c.nrocliente and facturaventa.barra = c.barra)

left join tipocomprobanteventa on (facturaventa_wsafip.tipocomprobante= tipocomprobanteventa.idtipo)-- = idtipocomprobante)

where nrosucursal = rparam.nrosucursal

  AND fechaemision <= rparam.fechahasta
   AND fechaemision >= rparam.fechadesde


       );
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
