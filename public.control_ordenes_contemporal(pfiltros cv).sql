CREATE OR REPLACE FUNCTION public.control_ordenes_contemporal(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       
  rfiltros record; 
  
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_control_ordenes_contemporal
AS (
 
  SELECT  
          concat(  orden.nroorden,'-', orden.centro) as nroorden,
          concat(p.apellido,',',p.nombres,' - ',c.nrodoc) as afiliado,               
          c.nrodoc,
          p.barra,
          orden.fechaemision,
          --pt.pttoken as personatoken,
          text_concatenar(pt.pttoken) as personatoken,
          ptutilizado,
          ptfechavencimiento as vtotokenorden,
          fechaauditoria,
          ovetdescripcion as estado,
          CONCAT(u.nombre, ' ', u.apellido) as usuariocambioestado,
          maodescripcion as motivoanulacion,
          ceo.observacion as laobservacion,
          ore.idrecibo,   
          comprobantestipos.ctdescripcion,
case when not nullvalue(nrofactura) then concat(tipofactura,' ',desccomprobanteventa,' ',nrosucursal,' ' ,nrofactura) else '' end  as lafactura,
/*Dani comento 060223         case when nullvalue(importectacte) then 0 else importectacte end + case when nullvalue(importeefectivo) then 0 else importeefectivo end as      importefactura,*/

 case when not  nullvalue(ordenestados.nroorden )then 0 else case when nullvalue(importectacte) then 0 else importectacte end + case when nullvalue(importeefectivo) then 0 else importeefectivo end end as      importefactura,datosrecibo.importe, usuario.login 

,CASE WHEN not nullvalue(bs.nrodoc) THEN  concat('DNI:',ts.nrodoc,'/',ts.barra)
                                                     WHEN not nullvalue(br.nrodoc) THEN  concat('DNI:',tr.nrodoc,'/',tr.barra) 
                                                     ELSE  concat('DNI:',p.nrodoc,'/',p.barra)   END as titular

,impSosunc.importesosunc
   ,'1-Nro Orden#nroorden@2-TipoOrden#ctdescripcion@3-Nrodoc#nrodoc@4-Barra#barra@5-Afiliado#afiliado@6-Afiliado#afiliado@7-Fecha Emisión#fechaemision@8-Usuario Emisión#login@9-Token#personatoken@10-Fecha utilización#ptutilizado@11-Vto Token#vtotokenorden@12-FechaAuditoria#fechaauditoria@13-Estado#estado@14-Modifico Estado#usuariocambioestado@15-Motivo Anulación#motivoanulacion@16-ObservacionAnulacion#laobservacion@17-Recibo#idrecibo@18-Factura#lafactura@19-ImporteFactura#importefactura@20-ImporteRecibo#importe@21-Importe Sosunc#importesosunc@22-Titular#titular'::text as mapeocampocolumna 
 --KR 05-07-21 Faltaba buscar el usuario y cambie la consulta para que joinee con recibo_token Y corregi los join

 FROM orden NATURAL JOIN consumo c NATURAL JOIN ordenrecibo ore 
NATURAL JOIN recibousuario ru
 JOIN usuario on(usuario.idusuario=ru.idusuario)
join comprobantestipos on(idcomprobantetipos=orden.tipo)

NATURAL JOIN 
(select sum(importe) as importe, idrecibo,centro
from importesrecibo
where idformapagotipos<>6
group by idrecibo,centro) as datosrecibo

JOIN persona  p on(p.nrodoc=c.nrodoc and p.tipodoc=c.tipodoc)
LEFT JOIN ordenesutilizadas ou USING (nroorden, centro)
LEFT JOIN ordenestados USING (nroorden, centro)
 LEFT join usuario u on (u.idusuario =oeidusuario) 
left join facturaorden on(facturaorden.nroorden=orden.nroorden and facturaorden.centro=orden.centro) 
left join facturaventa using(nrosucursal,nrofactura,tipofactura,tipocomprobante)
 
left join  tipocomprobanteventa on(facturaorden.tipocomprobante=tipocomprobanteventa.idtipo)
LEFT JOIN cambioestadosorden ceo ON (orden.nroorden= ceo.nroorden and orden.centro= ceo.centro  AND nullvalue(ceofechafin) ) 
LEFT  JOIN far_ordenventaestadotipo USING(idordenventaestadotipo)

LEFT JOIN ordenanuladamotivo oam  ON (orden.nroorden= oam.nroorden and orden.centro= oam.centro )   
LEFT JOIN motivoanulacionorden USING ( idmotivoanulacionorden)

LEFT JOIN recibo_token rt  ON (ore.idrecibo= rt.idrecibo and ore.centro= rt.centro)
LEFT JOIN persona_token pt USING(pttoken)

LEFT JOIN benefsosunc bs ON (bs.nrodoc = p.nrodoc)  -- analiso si es un beneficiario y busco altitular
    LEFT JOIN persona  ts ON (ts.nrodoc = bs.nrodoctitu) --- titular del benef sosunc
    LEFT JOIN benefreci br ON (br.nrodoc = p.nrodoc)   -- analizo si es un beneficiario y busco al titular
    LEFT JOIN persona  tr ON (tr.nrodoc = br.nrodoctitu) --- titular del benef sosunc  



  LEFT JOIN (
    SELECT importe as importesosunc, nroorden, centro
    FROM importesorden
    WHERE idformapagotipos=6)  as impSosunc ON (impSosunc.nroorden=orden.nroorden AND impSosunc.centro=orden.centro)




  WHERE orden.fechaemision::date between rfiltros.fechadesde AND rfiltros.fechahasta    
    AND (orden.nroorden= rfiltros.nroorden OR nullvalue(rfiltros.nroorden))
    AND (orden.centro= rfiltros.idcentroregional OR nullvalue(rfiltros.idcentroregional))
    AND (c.nrodoc= rfiltros.nrodoc OR nullvalue(rfiltros.nrodoc))

    

    
 group by 
 orden.nroorden , orden.centro ,
          p.apellido ,p.nombres ,c.nrodoc,
          c.nrodoc,
          p.barra,
          orden.fechaemision,         
          ptutilizado,
          ptfechavencimiento ,
          fechaauditoria,
          ovetdescripcion  ,
           u.nombre, u.apellido ,
          maodescripcion ,ore.idrecibo,tipofactura,desccomprobanteventa,nrosucursal,nrofactura,importefactura,datosrecibo.importe,ceo.observacion,usuario.login,comprobantestipos.ctdescripcion

,bs.nrodoc,ts.nrodoc,ts.barra,br.nrodoc,tr.nrodoc,tr.barra, p.nrodoc, p.barra
,impsosunc.importesosunc

  --WHERE fechaemision::date between '01/06/2021' AND '19/06/2021' AND nullvalue(ceofechafin) AND nroorden = ;
  ) ;

  

return 'true';
END;$function$
