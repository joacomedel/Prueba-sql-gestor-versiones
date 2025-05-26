CREATE OR REPLACE FUNCTION public.informacion_reintegros_pagos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        
	rfiltros record;
        
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_informacion_reintegros_pagos_contemporal
	AS (
		SELECT datosotp.fechaemision::varchar  AS fechaemision
        , CONCAT(datosotp.tipofactura , ' ' , to_char(datosotp.nrosucursal, '0000') , '-' ,  to_char(datosotp.nrofactura, '00000000')) AS nrocomprobante
        ,importeefectivo AS importecomprobante
        
        ,opcmontototal as importeopc
        ,CONCAT(idordenpagocontable,'-',idcentroordenpagocontable) as elidordenpagocontable
        ,datosotp.elreintegro  AS ids
        ,opcfechaingreso
        ,case when nullvalue(datospago.popmonto) then 0 else datospago.popmonto end  as montopago
        ,datospago.popobservacion as tipoformapagodesc 
        ,ordenpagocontable.opcobservacion
        ,ordenpagocontableestadotipo.opcetdescripcion
        ,datosotp.denominacion  AS titularopc


                , T.importeprestacion
        , T.tipoprestacion
        , T.nrocuentac
, T.nroorden, T.centro
  --,'1-Nro.Comprobante#nrocomprobante@2-Fecha Comp#fechaemision@3-Importe Comp.#importecomprobante@4-Titular#titularopc@5-OPC#elidordenpagocontable@6-Fecha OPC#opcfechaingreso@7-Obs. OPC#opcobservacion@8-Importe OPC#importeopc@9-Reintegro/Factura/Turismo#ids@10-Monto Pago#montopago@11-Forma Pago#tipoformapagodesc@12-Estado OPC#opcetdescripcion@13-Nro.Certificado#idretencionprestador@14-Reg. Retencion#descripretencion@15-$ Retenido#rpmontototal@16-$ Valores a Compensar#montovalorescompensar'::text as mapeocampocolumna
--        ,'1-Nro.Comprobante#nrocomprobante@2-Fecha Comp#fechaemision@3-Importe Comp.#importecomprobante@4-Titular#titularopc@5-OPC#elidordenpagocontable@6-Fecha OPC#opcfechaingreso@7-Obs. OPC#opcobservacion@8-Importe OPC#importeopc@9-Reintegro/Factura/Turismo#ids@10-Monto Pago#montopago@11-Forma Pago#tipoformapagodesc@12-Estado OPC#opcetdescripcion@13-Importe Prestacion#importeprestacion@14-Tipo Prestacion#tipoprestacion@15-Nrocuenta#nrocuentac'::text as mapeocampocolumna

-- BelenA nuevos datos:
,T.observacion as observacionreintegro,
T.descrip as descriplocalidad,
T.btdescripcion as tipoafiliado,
--CONCAT (datocomprobante.comptipofac,datocomprobante.completra, datocomprobante.comppuntodeventa,' - ',datocomprobante.compnrocomprobante) as comprobantereintegro,
datocomprobante.concatenated_compnrocomprobante as comprobantereintegro,
datocomprobante.ccmonto as montocomprobante,
--CONCAT (datousuario.nombre, ' ' , datousuario.apellido) as usuarioreintegro
CONCAT (T.nombreusuario, ' ' , T.apellidousuario) as usuarioreintegro,
T.fechaemision as emisionfactura


,'1-Nro.Comprobante#nrocomprobante@2-Fecha Comp#fechaemision@3-Importe Comp.#importecomprobante@4-Titular#titularopc@5-OPC#elidordenpagocontable@6-Fecha OPC#opcfechaingreso@7-Obs. OPC#opcobservacion@8-Importe OPC#importeopc@9-Reintegro/Factura/Turismo#ids@10-Monto Pago#montopago@11-Forma Pago#tipoformapagodesc@12-Estado OPC#opcetdescripcion@13-Importe Prestacion#importeprestacion@14-Tipo Prestacion#tipoprestacion@15-Nrocuenta#nrocuentac@16-Observacion Reintegro#observacionreintegro@17-Localidad#descriplocalidad@18-Tipo Afiliado#tipoafiliado@19-Comprobante Reintegro#comprobantereintegro@20-Monto Comprobante#montocomprobante@21-Usuario Reintegro#usuarioreintegro@22-Fecha Factura#emisionfactura'::text as mapeocampocolumna


FROM ordenpagocontable 
JOIN ordenpagocontableestado using (idcentroordenpagocontable, idordenpagocontable) 
NATURAL JOIN ordenpagocontableestadotipo 


LEFT JOIN (SELECT idordenpagocontable, idcentroordenpagocontable, idordenpagotipo
           FROM ordenpagocontableordenpago NATURAL JOIN ordenpago JOIN ordenpagotipo USING(idordenpagotipo)) 
           AS opcoptipo USING (idordenpagocontable, idcentroordenpagocontable)  

LEFT JOIN (SELECT idcentroordenpagocontable, idordenpagocontable, tipofactura,nrosucursal,nrofactura,CONCAT(nroreintegro,'-',anio,'-',idcentroregional) as elreintegro ,to_char(fechaemision,'DD/MM/YYYY') as fechaemision ,
                        CASE WHEN importeefectivo=0 THEN importectacte ELSE importeefectivo END AS importeefectivo, denominacion 
                        --importeefectivo,  
        FROM ordenpagocontablereintegro 
        NATURAL JOIN informefacturacionexpendioreintegro AS ifex 
        JOIN informefacturacionestado USING (nroinforme, idcentroinformefacturacion)
        JOIN  informefacturacion AS if USING (nroinforme, idcentroinformefacturacion)
        LEFT JOIN  facturaventa AS fv USING (nrofactura, tipocomprobante, nrosucursal, tipofactura) 
        JOIN cliente AS c ON(fv.nrodoc=c.nrocliente AND fv.barra=c.barra)

        WHERE nullvalue(fechafin) AND idinformefacturacionestadotipo<>5 
        ) AS datosotp USING(idcentroordenpagocontable, idordenpagocontable)

LEFT JOIN (SELECT sum(popmonto) AS popmonto, idordenpagocontable,idcentroordenpagocontable, text_concatenar(popobservacion) as popobservacion
        FROM pagoordenpagocontable
        WHERE idvalorescaja <>67 -- Para que no se vean las retenciones suss
                AND idvalorescaja <>65 -- Para que no se vean las retenciones ganancias 
                AND idvalorescaja <>80 -- Para que no se vean Valores a Compensar
        GROUP BY idordenpagocontable,idcentroordenpagocontable
                ) AS datospago USING(idordenpagocontable,idcentroordenpagocontable)

LEFT JOIN (
                SELECT concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' , to_char(nrofactura, '00000000')) AS nrofacturaconformato,
                        fechaemision, 
                        importeefectivo as importeOT, 
                        CONCAT(reintegroorden.nroreintegro,'-',reintegroorden.anio,'-',reintegroorden.idcentroregional) as elreintegro, 
                        concat(nroorden, '-',centro) as laorden, 
                        facturaventa.nrofactura as nrofactura,
                        facturaventa.tipofactura as tipofactura,
                        idordenpagocontable,idcentroordenpagocontable,

                        reintegroprestacion.importe as importeprestacion,
                        tipoprestaciondesc as tipoprestacion,
                        nrocuentac, reintegroorden.nroorden, reintegroorden.centro,
                        reintegroprestacion.observacion
                        , usuario.nombre as nombreusuario, usuario.apellido as apellidousuario
                        ,localidad.descrip, barratipo.btdescripcion, facturaventa.anulada

                        FROM facturaventa 
                        NATURAL JOIN informefacturacion 
                        NATURAL JOIN informefacturacionexpendioreintegro 
                        NATURAL JOIN reintegroorden  
                        NATURAL JOIN ordenpagocontablereintegro

                        LEFT JOIN reintegroprestacion USING (nroreintegro, anio, idcentroregional)
                        LEFT JOIN tipoprestacion USING (tipoprestacion)


        LEFT JOIN persona USING (nrodoc)
        LEFT JOIN direccion USING (iddireccion, idcentrodireccion)
        LEFT JOIN nrobarratipo ON (persona.barra = nrobarratipo.nrobarra)
        LEFT JOIN localidad USING (idlocalidad)
        LEFT JOIN barratipo USING (idbarratipo)

        LEFT JOIN ordenrecibo USING (nroorden, centro)
        LEFT JOIN recibousuario USING (idrecibo, centro)
        LEFT JOIN usuario USING (idusuario) 


                GROUP BY nrofacturaconformato, fechaemision, 
                importeOT, elreintegro, laorden 
                , facturaventa.nrofactura, 
                facturaventa.tipofactura, ordenpagocontablereintegro.idordenpagocontable, ordenpagocontablereintegro.idcentroordenpagocontable 
                ,reintegroprestacion.importe, tipoprestacion.tipoprestaciondesc, tipoprestacion.nrocuentac, reintegroorden.nroorden, reintegroorden.centro,reintegroprestacion.observacion
                ,usuario.nombre,usuario.apellido, localidad.descrip, barratipo.btdescripcion, facturaventa.anulada

                ) as T USING(idordenpagocontable,idcentroordenpagocontable)

LEFT JOIN ordenestados USING (nroorden, centro)

LEFT JOIN  (
        SELECT sum(ccmontoo) as ccmonto, STRING_AGG(CONCAT (datoscomprobante.comptipofac,datoscomprobante.completra, datoscomprobante.comppuntodeventa,' - ',datoscomprobante.compnrocomprobante) , ' | ') AS concatenated_compnrocomprobante, 
nroorden , centro
        FROM ( 
                SELECT sum(monto) as ccmontoo, cc.comptipofac, cc.completra, cc.comppuntodeventa, cc.compnrocomprobante , nroorden , centro

                FROM catalogoordencomprobante

                LEFT JOIN(
                        SELECT ccmonto as monto, cctipofactura as comptipofac,
                        ccletra as completra, ccpuntodeventa as comppuntodeventa, ccnrocomprobante as compnrocomprobante , *
                        FROM catalogocomprobante

                        GROUP BY idcatalogocomprobante, idcentrocatalogocomprobante, cctipofactura,ccletra,ccpuntodeventa,ccnrocomprobante
                        ) AS cc
                        on (cc.idcatalogocomprobante=catalogoordencomprobante.idcatalogocomprobante and
                        cc.idcentrocatalogocomprobante=catalogoordencomprobante.idcentrocatalogocomprobante)

                GROUP BY cc.comptipofac, cc.completra, cc.comppuntodeventa, cc.compnrocomprobante, 
                 nroorden , centro
                ) as datoscomprobante
                GROUP BY nroorden , centro

        ) as datocomprobante on(T.nroorden=datocomprobante.nroorden and T.centro=datocomprobante.centro)

/*
WHERE CASE WHEN nullvalue(NULL) THEN TRUE ELSE opcfechaingreso >= NULL END
        AND CASE WHEN nullvalue(NULL) THEN TRUE ELSE opcfechaingreso <= NULL END
        AND nullvalue(opcfechafin)
        AND  (idordenpagotipo=2) 
        AND nullvalue(ordenestados.idordenestadotipos)
        AND CASE WHEN nullvalue('2024-06-01') THEN TRUE ELSE T.fechaemision>= '2024-06-01' END
        AND CASE WHEN nullvalue('2024-06-10') THEN TRUE ELSE T.fechaemision<= '2024-06-10' END
*/



   WHERE /*opcfechaingreso >= rfiltros.fechadesde  
   AND opcfechaingreso <= rfiltros.fechahasta AND nullvalue(opcfechafin) */

        CASE WHEN nullvalue(rfiltros.fechadesde) THEN TRUE ELSE opcfechaingreso >= rfiltros.fechadesde END
        AND CASE WHEN nullvalue(rfiltros.fechahasta) THEN TRUE ELSE opcfechaingreso <= rfiltros.fechahasta END
        AND nullvalue(opcfechafin)
        AND (idordenpagotipo=2) 
        AND nullvalue(ordenestados.idordenestadotipos)
        AND CASE WHEN nullvalue(rfiltros.fechaotaini) THEN TRUE ELSE T.fechaemision>= rfiltros.fechaotaini END
        AND CASE WHEN nullvalue(rfiltros.fechaotbfin) THEN TRUE ELSE T.fechaemision<= rfiltros.fechaotbfin END
        AND nullvalue(T.anulada)



GROUP BY datosotp.fechaemision, datosotp.elreintegro 
,ordenpagocontable.idordenpagocontable, ordenpagocontable.idcentroordenpagocontable 
,T.importeprestacion, T.tipoprestacion, T.nrocuentac
,datosotp.tipofactura, 
datosotp.nrosucursal, 
datosotp.nrofactura, 
datosotp.importeefectivo, 
ordenpagocontable.opcmontototal, opcfechaingreso, datospago.popmonto, 
datospago.popobservacion, ordenpagocontable.opcobservacion, ordenpagocontableestadotipo.opcetdescripcion
,datosotp.denominacion
,T.nroorden, T.centro,
T.observacion,
descriplocalidad,
tipoafiliado,
comprobantereintegro,
montocomprobante,
usuarioreintegro,
T.fechaemision

ORDER BY idordenpagocontable
		

	);
  

return true;
END;
$function$
