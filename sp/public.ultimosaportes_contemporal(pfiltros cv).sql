CREATE OR REPLACE FUNCTION public.ultimosaportes_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
    
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_ultimosaportes_contemporal
AS (
   
    SELECT  apellido,nombres,
    CASE WHEN centroregional.crdescripcion IS NOT NULL THEN centroregional.crdescripcion ELSE 'SIN CENTRO REGIONAL' END as centroregional,
    aportesafiliados.anio, 
    aportesafiliados.mes, 
    round(aportesafiliados.importe::numeric,2) as importeaporte,
     to_char(aportesafiliados.pagofechaingreso,'DD/MM/YYYY') pagofechaingreso, 
    aportesafiliados.nrodoc, 
    aportesafiliados.barra, 
    aportesafiliados.idaporte, 
    aportesafiliados.idcentroregionaluso,
    CASE WHEN (aportefacturado.nroinforme) IS NULL  THEN 'Sin Informe' 			
    ELSE concat(aportefacturado.nroinforme::varchar,'|',aportefacturado.idcentroinformefacturacion::varchar) END AS informefacturacion,
    concat(tmeses.descrip , ' - ', anio) as periodo
    , to_char(aportefacturado.fechaemision,'DD/MM/YYYY') as fechafactura
    --, aportefacturado.fechaemision as fechafactura

    ,				CASE WHEN (aportefacturado.nrofactura) IS NULL  THEN 'No Facturado' 			ELSE concat(tcv.desccomprobanteventa,'|',aportefacturado.tipofactura,'|',aportefacturado.nrosucursal,'|',aportefacturado.nrofactura) END AS elcomprobante,
    ccdp.saldodeuda, ccdp.recibo, ccdp.fecharecibo
    --, importepagadodeuda,ccdp.descripcion
    ,estados.descrip as estado, date_part('year',age(persona.fechanac)) as edad, 
    to_char(adherente.fechaini,'DD/MM/YYYY') as fechainicio, 
    to_char(persona.fechafinos,'DD/MM/YYYY') as fechaegreso,case when (bs.cantcarga) IS NULL  then 0 else bs.cantcarga end as cantcarga
    ,CASE WHEN aportefacturado.tipofactura ILIKE 'NC' THEN (-1)*aportefacturado.importectacte ELSE aportefacturado.importectacte END AS importectacte ,			
    saldopago,importepagadopago,
    --'1-Apellido#apellido@2-Nombres#nombres@3-CentroRegional#centroregional@4-AnioAporte#anio@5-MesAporte#mes@6-ImporteAporte#importeaporte@7-FechaIngresoAporte#pagofechaingreso@8-Nrodoc#nrodoc@9-Barra#barra@10-Idaporte#idaporte@11-CentroRegionalAporte#idcentroregionaluso@12-InformeFacturacion#informefacturacion@13-Periodo#periodo@14-Factura#elcomprobante@15-Total Facturado#importectacte@16-Saldo Deuda#saldodeuda@17-Recibo/s#recibo@18-FechaRecibo/s#fecharecibo@19-Total Pagado Deuda#importepagadodeuda@20-Forma Pago#descripcion@21-Saldo Pago#saldopago@22-Total Pagado Pago#importepagadopago@23-Estado Afiliado#estado@24-Edad#edad@25-Fecha Ingreso#fechainicio@26-Fecha Egreso#fechaegreso@27-Cant. de Carga#cantcarga'::text as mapeocampocolumna
    '1-Apellido#apellido@2-Nombres#nombres@3-CentroRegional#centroregional@4-AnioAporte#anio@5-MesAporte#mes@6-ImporteAporte#importeaporte@7-FechaIngresoAporte#pagofechaingreso@8-Nrodoc#nrodoc@9-Barra#barra@10-Idaporte#idaporte@11-CentroRegionalAporte#idcentroregionaluso@12-InformeFacturacion#informefacturacion@13-Periodo#periodo@14-Fecha De Factura#fechafactura@15-Factura#elcomprobante@16-Total Facturado#importectacte@17-Saldo Deuda#saldodeuda@18-Recibo/s#recibo@19-FechaRecibo/s#fecharecibo@20-Total Pagado Deuda#importepagadodeuda@21-Forma Pago#descripcion@22-Saldo Pago#saldopago@23-Total Pagado Pago#importepagadopago@24-Estado Afiliado#estado@25-Edad#edad@26-Fecha Ingreso#fechainicio@27-Fecha Egreso#fechaegreso@28-Cant. de Carga#cantcarga'::text as mapeocampocolumna
    FROM 			
        ( SELECT anio, mes, importe, ajpfechaingreso as pagofechaingreso, nrodoc,tipodoc, barra, idaporte, idcentroregionaluso 				
        FROM aportejubpen				
            UNION 			
        SELECT anio, mes, importe, alicfechaingreso as pagofechaingreso, nrodoc,tipodoc, barra, idaporte, idcentroregionaluso 				
        FROM aporteuniversidad 			 
        ) AS aportesafiliados   -- Me traigo los aportes
    JOIN tmeses on (tmeses.idmes = aportesafiliados.mes) 	
    LEFT JOIN 	
        ( SELECT if.*,informefacturacionaporte.idaporte, informefacturacionaporte.idcentroregionaluso , fv.importectacte, fv.fechaemision   			
        FROM informefacturacionaporte 
        LEFT JOIN informefacturacion AS if USING (nroinforme,	idcentroinformefacturacion) 				 
        LEFT JOIN informefacturacionestado USING (nroinforme,idcentroinformefacturacion)	
        LEFT JOIN facturaventa fv USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
        WHERE (fechafin) IS NULL  
            AND if.nrofactura IS NOT NULL         -- BelenA 12/05/25 a pedido de Andrea no traigo los que no fueron facturados y agrego la fecha de la emision de la fv
            AND informefacturacionestado.idinformefacturacionestadotipo<> 5
        ) 			
        as aportefacturado  USING (idaporte, idcentroregionaluso) 	-- Busco las facturas de los aportes	
    --- BelenA 12/05/25 cambio para que el recibo no repita sino que aparezca en 1 sola fila
    LEFT JOIN 
        (   SELECT t.idcomprobante, t.saldodeuda, t.fechamovimientodeuda, array_to_string(array_agg(t.recibo), ', ') AS recibo , 
            array_to_string(array_agg(to_char(fecharecibo,'DD/MM/YYYY')), ', ') AS fecharecibo
            ,sum(t.importepagadodeuda) AS importespagadodeuda, t.importedeuda
            FROM (
                SELECT ccdc.idcomprobante , ccdc.saldo  as saldodeuda, ccdc.fechamovimiento as fechamovimientodeuda, text_concatenar(concat(cccp.idcomprobante, '-',cccp.idcentropago)) as recibo,
                fecharecibo,
                sum(importeimp) as importepagadodeuda, 
                text_concatenar(concat(vc.descripcion,' '))descripcion, 
                ccdc.importe as importedeuda
                FROM ctactedeudacliente ccdc 
                LEFT JOIN ctactedeudapagocliente ccdpc USING(iddeuda, idcentrodeuda) 
                LEFT JOIN ctactepagocliente cccp USING(idpago,idcentropago)
                LEFT JOIN recibo r ON cccp.idcomprobante=r.idrecibo AND cccp.idcentropago =r.centro and (reanulado) IS NULL  
                LEFT JOIN recibocupon rc USING(idrecibo, centro) 
                LEFT JOIN valorescaja vc USING(idvalorescaja) 
                
                GROUP BY ccdc.idcomprobante, ccdc.saldo, ccdc.fechamovimiento, fecharecibo, ccdc.importe
                ) T
            GROUP BY t.idcomprobante, t.saldodeuda, t.fechamovimientodeuda, t.importedeuda
        ) as ccdp 
        ON (idcomprobante = aportefacturado.nroinforme*100+aportefacturado.idcentroinformefacturacion)

    --KR 18-04-22 http://glpi.sosunc.org.ar/front/ticket.form.php?id=4992
    LEFT JOIN 
        ( SELECT cccp.idcomprobante, cccp.saldo  as saldopago, cccp.fechamovimiento as fechamovimientopago, text_concatenar(concat(cccp.idcomprobante, '-',cccp.idcentropago)) as recibo, sum(importeimp) as importepagadopago
        FROM ctactepagocliente cccp 
        LEFT JOIN ctactedeudapagocliente ccdpc USING(idpago,idcentropago) 
        LEFT JOIN  ctactedeudacliente ccdc  USING(iddeuda, idcentrodeuda) 
        GROUP BY cccp.idcomprobante, cccp.saldo ,  cccp.fechamovimiento 
        ) as ccpd 
        ON (ccpd.idcomprobante  = aportefacturado.nroinforme*100+aportefacturado.idcentroinformefacturacion)

    LEFT JOIN tipocomprobanteventa AS tcv ON(tipocomprobante = idtipo) 
    JOIN persona 	USING(nrodoc,tipodoc)  
    LEFT JOIN tarjeta USING(nrodoc,tipodoc)
    LEFT JOIN afilsosunc USING(nrodoc, tipodoc) 
    LEFT JOIN estados USING(idestado) 
    LEFT JOIN 
        (SELECT count(*) cantcarga, benefsosunc.nrodoctitu, benefsosunc.tipodoctitu 
        FROM benefsosunc 
        LEFT JOIN beneficiariosborrados bb USING(nrodoc, tipodoc) 
        WHERE (bb.nrodoc) IS NULL  GROUP BY benefsosunc.nrodoctitu, benefsosunc.tipodoctitu
        ) bs ON (persona.nrodoc=bs.nrodoctitu AND persona.tipodoc =bs.tipodoctitu)
    --LEFT JOIN (SELECT max(mes) as ultimomes, max(anio) as ultimoanio, nrodoc, tipodoc FROM recibo FROM aportejubpen GROUP BY nrodoc, tipodoc) as ultaporte 	

    LEFT JOIN tarjetaestado USING(idtarjeta,idcentrotarjeta) 
    LEFT JOIN centroregional on(tarjetaestado.idcentrotarjetaestado=centroregional.idcentroregional)   --- BelenA 12/05/25 cambio el JOIN por un LEFT JOIN ya que hay casos que no me los traia
    LEFT JOIN (
            SELECT max(fechaini) as fechaini,nrodoc, tipodoc   
            -- BelenA 12/05/25 Se daban casos en el que el jubilado habia pasado de ser jubilado, a docente, 
            -- a nuevamente jubilado y me duplicaba la tabla, asi que dejo el max para que me traiga el ultimo
            FROM histobarras 
            WHERE  (barra=35 or barra=36) 

            GROUP BY nrodoc, tipodoc
        ) as adherente USING(nrodoc, tipodoc)

    WHERE    (aportesafiliados.barra =35 or aportesafiliados.barra = 36) 

    AND pagofechaingreso >= (rfiltros.fechadesde::date  - INTERVAL '1 year')
    AND aportefacturado.fechaemision >= rfiltros.fechadesde
    AND aportefacturado.fechaemision <= rfiltros.fechahasta


    AND (aportesafiliados.nrodoc = rfiltros.nrodoc or (rfiltros.nrodoc) IS NULL )	
    AND (tarjetaestado.idcentrotarjeta = rfiltros.idcentroregional or (rfiltros.idcentroregional) IS NULL  )	
    --AND CASE WHEN tarjetaestado.idestadotipo IS NOT NULL THEN tarjetaestado.idestadotipo<>4 ELSE TRUE END 
    AND CASE WHEN tarjetaestado.idestadotipo IS NOT NULL THEN tarjetaestado.idestadotipo=3 ELSE TRUE END
    AND (tefechafin) IS NULL 
    
    ORDER BY   aportesafiliados.barra,apellido,nombres,aportesafiliados.anio,aportesafiliados.mes

);
     

return true;
END;$function$
