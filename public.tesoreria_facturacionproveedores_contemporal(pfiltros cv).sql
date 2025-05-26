CREATE OR REPLACE FUNCTION public.tesoreria_facturacionproveedores_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	 
	rfiltros record;
        vqueryac varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
--(rfiltros.idconac= 1) con asientos contables
IF (rfiltros.idconac= 1) THEN 
         
CREATE TEMP TABLE temp_tesoreria_facturacionproveedores_contemporal
AS (
	SELECT fecha as fecharecepcion, concat(rlf.numeroregistro,'-', rlf.anio) as numeroregistro,prestador.pdescripcion, 
concat(rlf.letra, ' ',rlf.puntodeventa, ' ' , lpad(numero,8,0)) as numfactura,  CASE WHEN rlf.idtipocomprobante=4 THEN (-1)*rlf.monto ELSE rlf.monto END monto, CASE WHEN rlf.idtipocomprobante=4 THEN (-1)*rlf.monto ELSE rlf.monto END as apagar, rlf.fechaemision,fechavenc,concat(idordenpagocontable,'-',idcentroordenpagocontable) as laopc, CASE WHEN rlf.idtipocomprobante=4 THEN (-1)*popmonto ELSE popmonto END AS lopagado, replace(popobservacion,'--INFO BANCA--','')  as popobservacion, opcetdescripcion, opcfechaingreso as fechapago, 
CASE WHEN fechavenc <= CURRENT_DATE THEN 'Vencida' WHEN fechavenc-current_date<=10 THEN 'Prox. a Vencer' ELSE '' END as estadofactura, descripcionsiges,
concat (usuario.apellido, ' ', usuario.nombre ) as elusuario,CONCAT(factura.nroordenpago,'-',factura.idcentroordenpago) AS lamp, fp.importedebito, EXTRACT(MONTH FROM fecha) as mes,tipocomprobantedesc as tipocomp,CASE WHEN nullvalue(ag.idasientogenerico) THEN ' ' ELSE concat(ag.idasientogenerico,'|',ag.idcentroasientogenerico) END AS idasientocontable
,CASE WHEN not nullvalue(ag.agfechacontable) THEN ag.agfechacontable END AS agfechacontable,concat(pa.pdescripcion, ' ', pa.pcuit) elagrupado,prestador.pcuit cuitprestador,
round(CAST((CASE WHEN rlf.idtipocomprobante=4 THEN (-1)*ccp.saldo ELSE ccp.saldo END ) AS numeric),2)  saldo,
 '5-N. Factura#numfactura@1-N. Registro#numeroregistro@4-Prestador#pdescripcion@2-F. Recepcion#fecharecepcion@7-F. Emision#fechaemision@9-$Total#monto@10-Pagar#apagar@11-OPC#laopc@12-$Pagado#lopagado@13-F.Pago Pago#fechapago@14-Datos Pago#popobservacion@15-Estado OPC#opcetdescripcion@8-Vto. Factura#fechavenc@16-Estado#estadofactura@17-Usuario Carga#elusuario@3-Mes#mes@6-Tipo Comprobante#tipocomp@18-ID Asiento Contable#idasientocontable@19-F. Contable#agfechacontable@20-CUIT#cuitprestador@21-Agrupador#elagrupado@22-Saldo (Reporte de Cta Cte)#saldo'::text as mapeocampocolumna
	FROM recepcion NATURAL JOIN reclibrofact as rlf LEFT JOIN tipocomprobante USING(idtipocomprobante) LEFT  join prestador USING (idprestador) JOIN multivac.mapeocatgasto  ON (rlf.catgasto=multivac.mapeocatgasto.idcategoriagastosiges)	LEFT JOIN usuario  on (rlf.idusuariocarga=usuario.idusuario)  
        LEFT JOIN prestador pa on pa.idprestador=prestador.idcolegio
	LEFT JOIN ordenpagocontablereclibrofact AS opcrlf USING(numeroregistro,anio)  
        LEFT JOIN factura ON (rlf.numeroregistro= factura.nroregistro AND rlf.anio= factura.anio) 
        LEFT JOIN ctactepagoprestador ccp ON ccp.idcomprobante=((rlf .numeroregistro*10000)+rlf .anio)
        LEFT JOIN (SELECT sum(debito) as importedebito, nroregistro, anio FROM facturaprestaciones GROUP BY nroregistro, anio) AS fp  ON (fp.nroregistro= factura.nroregistro AND fp.anio= factura.anio)  
        LEFT JOIN cambioestadoordenpago ceop ON (factura.nroordenpago= ceop.nroordenpago AND factura.idcentroordenpago= ceop.idcentroordenpago AND idtipoestadoordenpago= 1 ) 
	LEFT JOIN ordenpagocontable USING (idordenpagocontable,idcentroordenpagocontable) 
	LEFT  JOIN ordenpagocontableestado USING (idordenpagocontable,idcentroordenpagocontable) 
	LEFT JOIN ordenpagocontableestadotipo USING(idordenpagocontableestadotipo) 
	LEFT JOIN pagoordenpagocontable AS popc USING(idordenpagocontable,idcentroordenpagocontable)
        LEFT JOIN asientogenerico ag ON ( idcomprobantesiges = concat(rlf.numeroregistro,'|',rlf.anio))	
	WHERE  nullvalue(opcfechafin) AND rlf.idtipocomprobante <> 3  AND rlf.catgasto <> 4 AND rlf.fechaemision >=rfiltros.fechadesde
	AND rlf.fechaemision <=rfiltros.fechahasta
        ORDER BY fechaemision

 );

ELSE 
  CREATE TEMP TABLE temp_tesoreria_facturacionproveedores_contemporal
AS (
	SELECT fecha as fecharecepcion, concat(rlf.numeroregistro,'-', rlf.anio) as numeroregistro,prestador.pdescripcion, 
concat(rlf.letra, ' ',rlf.puntodeventa, ' ' , lpad(numero,8,0)) as numfactura,  CASE WHEN rlf.idtipocomprobante=4 THEN (-1)*rlf.monto ELSE rlf.monto END monto, CASE WHEN rlf.idtipocomprobante=4 THEN (-1)*rlf.monto ELSE rlf.monto END as apagar, rlf.fechaemision,fechavenc,concat(idordenpagocontable,'-',idcentroordenpagocontable) as laopc, CASE WHEN rlf.idtipocomprobante=4 THEN (-1)*popmonto ELSE popmonto END AS lopagado, replace(popobservacion,'--INFO BANCA--','')  as popobservacion, opcetdescripcion, opcfechaingreso as fechapago, 
CASE WHEN fechavenc <= CURRENT_DATE THEN 'Vencida' WHEN fechavenc-current_date<=10 THEN 'Prox. a Vencer' ELSE '' END as estadofactura, descripcionsiges,
concat (usuario.apellido, ' ', usuario.nombre ) as elusuario,CONCAT(factura.nroordenpago,'-',factura.idcentroordenpago) AS lamp, fp.importedebito, EXTRACT(MONTH FROM fecha) as mes,tipocomprobantedesc as tipocomp,concat(pa.pdescripcion, ' ', pa.pcuit) elagrupado,prestador.pcuit cuitprestador,round(CAST((CASE WHEN rlf.idtipocomprobante=4 THEN (-1)*ccp.saldo ELSE ccp.saldo END ) AS numeric),2)  saldo

,'5-N. Factura#numfactura@1-N. Registro#numeroregistro@4-Prestador#pdescripcion@2-F. Recepcion#fecharecepcion@7-F. Emision#fechaemision@9-$Total#monto@10-Pagar#apagar@11-OPC#laopc@12-$Pagado#lopagado@13-F.Pago Pago#fechapago@14-Datos Pago#popobservacion@15-Estado OPC#opcetdescripcion@8-Vto. Factura#fechavenc@16-Estado#estadofactura@17-Usuario Carga#elusuario@3-Mes#mes@6-Tipo Comprobante#tipocomp@18-CUIT#cuitprestador@19-Agrupador#elagrupado@20-Saldo (Reporte de Cta Cte)#saldo'::text as mapeocampocolumna
	FROM recepcion NATURAL JOIN reclibrofact as rlf LEFT JOIN tipocomprobante USING(idtipocomprobante) LEFT  join prestador USING (idprestador) JOIN multivac.mapeocatgasto  ON (rlf.catgasto=multivac.mapeocatgasto.idcategoriagastosiges)	LEFT JOIN usuario  on (rlf.idusuariocarga=usuario.idusuario)  
        LEFT JOIN prestador pa on pa.idprestador=prestador.idcolegio
	LEFT JOIN ordenpagocontablereclibrofact AS opcrlf USING(numeroregistro,anio)  
        LEFT JOIN factura ON (rlf.numeroregistro= factura.nroregistro AND rlf.anio= factura.anio) 
        LEFT JOIN ctactepagoprestador ccp ON ccp.idcomprobante=((rlf .numeroregistro*10000)+rlf .anio)
        LEFT JOIN (SELECT sum(debito) as importedebito, nroregistro, anio FROM facturaprestaciones GROUP BY nroregistro, anio) AS fp  ON (fp.nroregistro= factura.nroregistro AND fp.anio= factura.anio)  
        LEFT JOIN cambioestadoordenpago ceop ON (factura.nroordenpago= ceop.nroordenpago AND factura.idcentroordenpago= ceop.idcentroordenpago AND idtipoestadoordenpago= 1 ) 
	LEFT JOIN ordenpagocontable USING (idordenpagocontable,idcentroordenpagocontable) 
	LEFT  JOIN ordenpagocontableestado USING (idordenpagocontable,idcentroordenpagocontable) 
	LEFT JOIN ordenpagocontableestadotipo USING(idordenpagocontableestadotipo) 
	LEFT JOIN pagoordenpagocontable AS popc USING(idordenpagocontable,idcentroordenpagocontable)
       
	WHERE  nullvalue(opcfechafin) AND rlf.idtipocomprobante <> 3  AND rlf.catgasto <> 4 AND rlf.fechaemision >=rfiltros.fechadesde
	AND rlf.fechaemision <=rfiltros.fechahasta
        ORDER BY fechaemision

 );


END IF;
     
/* KR 13-08-20 Andrea pidio cambios en los datos a mostrar por mail. Estos eran los antiguos
 '1-F. Imputacion#fechaimputacion@2-N. Factura#numfactura@3-N. Registro#numeroregistro@4-Prestador#pdescripcion@5-F. Recepcion#fecharecepcion@6-F. Emision#fechaemision@7-$Total#monto@8-Pagar#apagar@9-OPC#laopc@10-$Pagado#lopagado@11-F.Pago Pago#fechapago@12-Datos Pago#popobservacion@13-Estado OPC#opcetdescripcion@14-Vto. Factura#fechavenc@15-Estado#estadofactura@16-Tipo#descripcionsiges@17-MP#lamp@18-Usuario MP#elusuario@19-Debito#importedebito@20-ID Asiento Contable#idasientocontable' 
segun su pedido se modifica a:
'5-N. Factura#numfactura@1-N. Registro#numeroregistro@4-Prestador#pdescripcion@2-F. Recepcion#fecharecepcion@7-F. Emision#fechaemision@9-$Total#monto@10-Pagar#apagar@11-OPC#laopc@12-$Pagado#lopagado@13-F.Pago Pago#fechapago@14-Datos Pago#popobservacion@15-Estado OPC#opcetdescripcion@8-Vto. Factura#fechavenc@16-Estado#estadofactura@17-Usuario Carga#elusuario@3-Mes#mes@6-Tipo Comprobante#tipocomprobantedesc'

*/
return true;
END;
$function$
