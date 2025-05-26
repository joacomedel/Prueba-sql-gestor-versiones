CREATE OR REPLACE FUNCTION public.libroiva_ventas_con_asientos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--DROP TABLE  temp_libroiva_ventas_contemporal;
CREATE  temp TABLE temp_libroiva_ventas_con_asientos_contemporal
AS (
       SELECT FV.fechadesde, FV.fechahasta,
               concat (tipofactura,' ',desccomprobanteventa,' ',lpad(nrosucursal,4,'0'),'-',lpad(nrofactura,8,'0')) as idcomprobante 		
	       ,fechaemision  
               ,anulada
	       ,concat(nrocliente,'-',tipodoc,' - ',c.denominacion) as razonsocial
	       ,concat(cuitini,'-',cuitmedio,'-',cuitfin) as cuit
               ,CASE WHEN (nullvalue(ci.descripcioniva)) THEN 'CONSUMIDOR FINAL' ELSE ci.descripcioniva END as ivacliente

	       ,case when nrosucursal in (2,3,4,16,19,20) then 'Farmacia' 
                     when nrosucursal in (9,17) then 'Recreacion' 
                     else 'Obra Social' end as actividad
	    --   ,case when nrosucursal in (2,3,4,16,19,20) then 2 else 1 end as idactividad 

  ,case when nrosucursal in (2,3,4,16,19,20) then 2 
                     when nrosucursal in (9,17) then 3
                     else 1 end as idactividad

--              ,round( (iva105 + iva21 +iva27)::numeric,6) as iva
,(iva105 + iva21 +iva27) as iva
--               ,round(  (  iva105sdesc +iva21sdesc +iva27sdesc)::numeric,6)as ivacdesc
,(iva105sdesc +iva21sdesc +iva27sdesc )as ivacdesc
--               ,round(netogravado::numeric,6)as netogravado 
,netogravado
               ,NoGravado
--               ,round(iva105::numeric,6) as iva105 
,iva105
              --  ,round(iva21::numeric,6) as iva21
,iva21
           --    ,round(iva27::numeric,6)as iva27
,iva27
 --              ,round(iva0desc::numeric,6)as iva0desc
,iva0desc
--               ,round(iva105sDesc::numeric,6)as iva105sDesc
,iva105sDesc
--               ,round(iva21sDesc::numeric,6)as iva21sDesc
,iva21sDesc
--               ,round(iva27sDesc::numeric,6) as iva27sDesc
,iva27sDesc

-- PARA VER DESPUESSS ,round((netogravado + nogravado + iva105 + iva21 +iva27 + iva0desc + iva105sdesc + iva21sdesc + iva27sdesc  )::numeric,3) as importetotal,

              ,importetotalcabecera as importetotal
              ,importetotalcabecera,nrosucursal
              ,case when (centro=1 or centro=99 or centro=12 or centro=7 or centro=11 ) then 915 else 916 end as jurisdiccion
,aa.losasientos
-- bienes de uso=2, el resto de las cuentas=1
,case when jer.lasjerarquias ilike '%jerarquia:1.02.02.%' then 2::integer else 1::integer end as tipogasto
,FV.tipofactura
,0::double precision as descuento
,0::double precision as recargo
,tc.desccomprobanteventa as clase
, neto_iva105
, neto_iva21
, neto_iva27
,ci.idcondicioniva as idcondicioniva	
,'1-Comprobante#idcomprobante@2-Fecha Emision#fechaemision@3-Fecha Anulacion#anulada@4-RazonSocial#razonsocial@5-Cuit#cuit@6-TipoIvaCliente#ivacliente@7-tipoGasto#tipogasto@8-Id Actividad#idactividad@9-Actividad#actividad@10-IVA#iva@11-IVAcDesc#ivacdesc@12-NetoGravado#netogravado@13-NoGravado#nogravado@14-iva105#iva105@15-iva21#iva21@16-iva27#iva27@17-iva0Desc#iva0desc@18-iva105sDesc#iva105sdesc@19-iva21sDesc#iva21sdesc@20-iva27sDesc#iva27sdesc@21-imptotal#importetotal@22-importetotalcabecera#importetotalcabecera@23-nrosucursal#nrosucursal@24-jurisdiccion#jurisdiccion@25-losasientos#losasientos@26-neto_iva105#neto_iva105@27-neto_iva21#neto_iva21@28-neto_iva27#neto_iva27@29-idcondicioniva#idcondicioniva'::text as mapeocampocolumna
FROM 
    
      ( SELECT pffechadesde fechadesde,pffechahasta fechahasta,
               tipofactura,tipocomprobante,nrosucursal,nrofactura  

                ,SUM(
                     
                      (case when   not nullvalue(anulada) THEN (0) else 1 end)      -- Si esta anulada retorno 0
                     * (case when vc.tipofactura in ('NC') THEN (-1) else 1 end)  -- Si es una NC el importe resta
                     * (case when (idconcepto=50840 and porcentaje<>0 and centro = 99 ) then vi.importe/(1+porcentaje) --Tener en cuenta que los items de la factura en la farmacia se guardan sin iva, pero el descuento ya tiene incluido el iva
                        else CASE WHEN idconcepto=50840 AND centro <> 99 and porcentaje<>0 THEN 0   
                             ELSE case when ( porcentaje = 0 ) then 0  ELSE vi.importe END END 
                               
                            end )
                      
/*    * (case when (idconcepto=50840 and porcentaje<>0 ) then ( vi.importe/(1+porcentaje) ) else (case when (porcentaje<>0 ) then vi.importe else 0 end) END)    -- importe gravado  
*/
                ) as netogravado
		
                ,SUM((case when   not nullvalue(anulada) THEN (0) else 1 end) * (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) * (case when porcentaje=0 then vi.importe else 0 end)) as nogravado
		,SUM((case when   not nullvalue(anulada) THEN (0) else 1 end) * (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) * (case when porcentaje=.105 then (vi.importe*porcentaje ) else 0 end)*  (case when vi.importe > 0 then 1 else 0 end) ) as iva105
		,SUM((case when   not nullvalue(anulada) THEN (0) else 1 end) 
                      * (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) 
                      * (case when porcentaje=.21 then  (vi.importe *porcentaje ) else 0 end)
                      * (case when vi.importe > 0 then 1 else 0 end) 
 ) as iva21
		,SUM((case when   not nullvalue(anulada) THEN (0) else 1 end) * (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) * (case when porcentaje=.27 then (vi.importe *porcentaje ) else 0 end) *  (case when vi.importe > 0 then 1 else 0 end) ) as iva27
                ,SUM((case when   not nullvalue(anulada) THEN (0) else 1 end) 
                 * (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) 
* (case when porcentaje=0 then (vi.importe) else 0 end) * (case when vi.importe < 0 then 1 else 0 end) ) as iva0desc
                ,SUM((case when   not nullvalue(anulada) THEN (0) else 1 end) 
* (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) 
* (case when porcentaje=.105 then (vi.importe/(1+porcentaje) * porcentaje ) else 0 end) * (case when vi.importe < 0 then 1 else 0 end) ) as iva105sdesc
		,SUM((case when   not nullvalue(anulada) THEN (0) else 1 end) 
* (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) 
* (case when porcentaje=.21 then (vi.importe/(1+porcentaje) * porcentaje ) else 0 end) * (case when vi.importe < 0 then 1 else 0 end)) as iva21sdesc
		,SUM((case when   not nullvalue(anulada) THEN (0) else 1 end) 
* (case when VC.tipofactura in ('NC') THEN (-1) else 1 end)
* (case when porcentaje=.27 then (vi.importe/(1+porcentaje) * porcentaje ) else 0 end) * (case when vi.importe < 0 then 1 else 0 end)) as iva27sdesc
      
,((MIN(CASE WHEN (nullvalue(importeamuc)) THEN 0 ELSE importeamuc END )  
                            +MIN(CASE WHEN (nullvalue(importeefectivo)) THEN 0 ELSE importeefectivo END ) 
                            +MIN(CASE WHEN (nullvalue(importesosunc)) THEN 0 ELSE importesosunc END  ) 
                            +MIN(CASE WHEN (nullvalue(importedebito)) THEN 0 ELSE importedebito END ) 
                            +MIN(CASE WHEN (nullvalue(importectacte)) THEN 0 ELSE importectacte END ) 
                            +MIN(CASE WHEN (nullvalue(importecredito)) THEN 0 ELSE importecredito END  
                          ))*(case when   not nullvalue(min(anulada)) THEN (0) else 1 end) * (case when tipofactura in ('NC') THEN (-1) else 1 end) )  as importetotalcabecera 
   ,SUM(
     (case when not nullvalue(anulada) THEN (0) else 1 end) 
     * (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) 
     * (case when porcentaje=.105 then (vi.importe ) else 0 end)
     * (case when vi.importe > 0 then 1 else 0 end) ) as  neto_iva105

   ,SUM(
    (case when   not nullvalue(anulada) THEN (0) else 1 end) 
    * (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) 
    * (case when porcentaje=.21 then  (vi.importe ) else 0 end)
    * (case when vi.importe > 0 then 1 else 0 end)  ) as neto_iva21
		
   ,SUM(
    (case when   not nullvalue(anulada) THEN (0) else 1 end) 
    * (case when VC.tipofactura in ('NC') THEN (-1) else 1 end) 
    * (case when porcentaje=.27 then (vi.importe ) else 0 end) 
    * (case when vi.importe > 0 then 1 else 0 end) ) as neto_iva27
    
       FROM contabilidad_periodofiscalfacturaventa
       natural join contabilidad_periodofiscal cpf
       NATURAL JOIN  facturaventa  as vc
      
       LEFT JOIN itemfacturaventa as vi using (tipofactura,tipocomprobante,nrosucursal,nrofactura)
       LEFT JOIN tipoiva USING (idiva)
       WHERE --idconcepto <> 50840 and 

            ( nullvalue(vi.nrofactura) or idconcepto <> 20821  )and 
             idperiodofiscal = rfiltros.idperiodofiscal
 ---and nrofactura = 622
       GROUP BY pffechadesde,pffechahasta,
                tipofactura,tipocomprobante,nrosucursal,nrofactura
) as FV  
JOIN facturaventa USING (tipofactura,tipocomprobante,nrosucursal,nrofactura)
LEFT  JOIN asientogenerico_darasientocomprobante as aa ON (concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura) = aa.idcomprobantesiges)
LEFT  JOIN asientogenerico_darjerarquiacuentas as jer ON (concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura) = jer.idcomprobantesiges)
JOIN tipocomprobanteventa tc ON (tipocomprobante=idtipo)
LEFT JOIN cliente c ON (nrodoc=c.nrocliente and tipodoc=c.barra)
LEFT JOIN condicioniva ci USING(idcondicioniva) --condicion iva del cliente
-- WHERE not nullvalue(anulada) and
order by facturaventa.nrosucursal,facturaventa.tipofactura,desccomprobanteventa,facturaventa.nrofactura,facturaventa.fechaemision

);

return true;
END;
$function$
