CREATE OR REPLACE FUNCTION public.cajadiaria_reportefacturacion_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
        vwhere varchar;
        vmapeocolumna varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
--KR 03-11-21
vmapeocolumna = CONCAT('1-Fecha Emision#fechaemision@2-Tipo#tipofactura@3-Nro.Factura#nrofactura@4-Cliente#clientefac@5-Nro.Siges#nrosiges@6-TipoAfil#tipoafil@7-CR#crdescripcion@8-Usuario#elusuario @9-Total#total#suma@10-amuc#amuc#suma@11-efectivo#efectivo#suma@12-ctacte#ctacte#suma@13-debito#debito#suma@14-credito#tarjeta#suma@15-reciprocidad#reciprocidad#suma@16-transferencia#transferencia#suma@17-cheque#cheque#suma@18-sosunc#sosunc#suma@19-F.Anulada#anulada', 
case when pfiltros ilike '%idtipofacturaventa%' then '@20-Agrupador#agrupador'  end); 

IF (pfiltros ilike '%excel%') THEN --VIENE de la ventana de caja (lo viejo)
   SELECT INTO vwhere concat( case when pfiltros ilike '%centro%' then concat(' AND (',rfiltros.centro,'=fv.centro or ',rfiltros.centro,'=0) ') end,

case when pfiltros ilike '%nrosucursal%' then concat(' AND (',rfiltros.nrosucursal,'=fv.nrosucursal or ',rfiltros.nrosucursal,'=0) ') end,
case when pfiltros ilike '%compdesde%' then concat(' AND (',rfiltros.compdesde,'<=fv.nrofactura or ',rfiltros.compdesde,'=0) ') end,
case when pfiltros ilike '%comphasta%' then concat(' AND (',rfiltros.comphasta,'>=fv.nrofactura or ',rfiltros.comphasta,'=0) ') end,
case when pfiltros ilike '%idusuario%' then concat(' AND (',rfiltros.idusuario,'=idusuario or ',rfiltros.idusuario,'=0) ') end,
case when pfiltros ilike '%idinformefacturaciontipo%' then concat(' AND (',rfiltros.idinformefacturaciontipo,'=informefacturacion.idinformefacturaciontipo or ',rfiltros.idinformefacturaciontipo,'=0) ') end,
case when pfiltros ilike '%nrocuentac%' and not nullvalue(rfiltros.nrocuentac) then concat(' AND (',rfiltros.nrocuentac ,'=multivac.mapeocuentasfondos.nrocuentac or nullvalue(',rfiltros.nrocuentac,')) ') end,
case when pfiltros ilike '%tipofac%' then concat(' AND (''',rfiltros.tipofac,'''=tipofactura or ''''=(''',rfiltros.tipofac,'''))
      AND fv.tipofactura <>''LI'' /*AND fv.tipofactura <>''R'' */') end
     );


ELSE 
--VIENE de la botonera de reportes 
   SELECT INTO vwhere concat(CASE WHEN pfiltros ilike '%idtipofacturaventa%' THEN concat(' AND (',rfiltros.idtipofacturaventa,'=idtipofacturaventa) ') END, 
                      case when pfiltros ilike '%idprestador%' and not nullvalue(rfiltros.idprestador) then 
         concat(' AND (',rfiltros.idprestador,'=prestador.idprestador) ') END); 
END IF;


/* KR 2019-05-07 MODIFIQUE PARA QUE SEA MAS RAPIDO */

  SELECT INTO vquery concat('CREATE TEMP TABLE temp_cajadiaria_reportefacturacion_contemporal  AS (SELECT  concat(tipofactura,'' '',trim(to_char(fv.nrosucursal, ''0000'')),''-'',trim(to_char(nrofactura,''00000000''))) as nrofactura,fechaemision
,trim(tipofactura) as tipofactura
,case when nullvalue(cliente.denominacion) then '''' else cliente.denominacion end as clientefac
,case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 when not nullvalue(anulada) THEN 0 ELSE 1 END as signo
,concat(cliente.nrocliente,''-'', cliente.barra) as nrosiges
,crdescripcion
,concat(usuario.apellido,'' '',usuario.nombre) as elusuario
,case when persona.barra = 35 or persona.barra = 36 THEN ''Adherente'' 
              ELSE ''Obligatorio'' END as tipoafil
,anulada
,sum(CASE WHEN  not nullvalue(monto) THEN monto ELSE 0 END) * (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI''  THEN 0 ELSE 1 END) as total
,sum(CASE WHEN  vc.idformapagotipos = 1 THEN monto ELSE 0 END)* (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI''  THEN 0 ELSE 1 END)  as amuc
,sum(CASE WHEN  vc.idformapagotipos = 2 THEN monto ELSE 0 END)* (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI'' THEN 0 ELSE 1 END) as efectivo
,sum(CASE WHEN  vc.idformapagotipos = 3 THEN monto ELSE 0 END)* (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI'' THEN 0 ELSE 1 END)  as ctacte
,sum(CASE WHEN  vc.idformapagotipos = 4 THEN monto ELSE 0 END)* (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI'' THEN 0 ELSE 1 END)  as debito
,sum(CASE WHEN  vc.idformapagotipos = 5 THEN monto ELSE 0 END) * (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI''  THEN 0 ELSE 1 END) as tarjeta
,sum(CASE WHEN  vc.idformapagotipos = 6 THEN monto ELSE 0 END) * (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI'' THEN 0 ELSE 1 END) as sosunc
,sum(CASE WHEN  vc.idformapagotipos = 7 THEN monto ELSE 0 END) * (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI'' THEN 0 ELSE 1 END) as reciprocidad
,sum(CASE WHEN  vc.idformapagotipos = 8 THEN monto ELSE 0 END)* (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI'' THEN 0 ELSE 1 END)  as transferencia
,sum(CASE WHEN  vc.idformapagotipos = 9 THEN monto ELSE 0 END) * (case when tipofactura = ''NC'' AND nullvalue(anulada) THEN -1 
              when not nullvalue(anulada) and fv.tipofactura <>''DI'' THEN 0 ELSE 1 END) as cheque '
,CASE WHEN pfiltros ilike '%idtipofacturaventa%' THEN ',case when nullvalue(agrupador.pdescripcion) then ''S/Agrupador'' else agrupador.pdescripcion end  as agrupador' END  
,' FROM facturaventa fv JOIN public.centroregional ON (fv.centro= centroregional.idcentroregional)  
JOIN tipofacturaventa ON fv.tipofactura = tipofacturaventa.idtipofactura
LEFT JOIN facturaventacupon USING(nrofactura,tipocomprobante,nrosucursal,tipofactura)  
LEFT JOIN valorescaja vc USING(idvalorescaja)
LEFT JOIN formapagotipos USING(idformapagotipos)
LEFT JOIN facturaventausuario USING(nrofactura,tipocomprobante,nrosucursal,tipofactura)
LEFT JOIN  usuario USING (idusuario)
LEFT JOIN informefacturacion USING (nrofactura, tipocomprobante, nrosucursal, tipofactura)
LEFT JOIN multivac.formapagotiposcuentafondos USING(idvalorescaja,nrosucursal)
LEFT JOIN multivac.mapeocuentasfondos USING(idcuentafondos)
LEFT JOIN cliente ON(fv.nrodoc=cliente.nrocliente and fv.barra=cliente.barra)
LEFT JOIN persona ON(fv.nrodoc=persona.nrodoc and fv.barra=persona.tipodoc)
-- KR 03-11-21 agregue para reporte de DI de la panelera
LEFT JOIN prestador on(cliente.nrocliente=idprestador)
LEFT JOIN prestador as agrupador on (prestador.idcolegio= agrupador.idprestador)
WHERE fechaemision >= ','''' ,rfiltros.fechaini,'''' ,' AND fechaemision <= ','''' ,rfiltros.fechafin ,'''' ,
vwhere ,
 '
GROUP BY tipofactura,fv.nrosucursal,tipocomprobante,nrofactura,signo,cliente.nrocliente,cliente.denominacion, cliente.barra,crdescripcion,usuario.apellido,usuario.nombre,persona.barra ',
case when pfiltros ilike '%idtipofacturaventa%'  THEN ',agrupador.pdescripcion' END  ,
' ORDER BY fv.nrosucursal, fechaemision ASC)'
); 

 RAISE NOTICE 'vquery(%)',vquery;
 EXECUTE vquery;	

 vquery = 'ALTER TABLE temp_cajadiaria_reportefacturacion_contemporal ADD COLUMN mapeocampocolumna text ';
 EXECUTE vquery;     
 UPDATE temp_cajadiaria_reportefacturacion_contemporal SET mapeocampocolumna = vmapeocolumna  ;
 
return true;
END;
$function$
