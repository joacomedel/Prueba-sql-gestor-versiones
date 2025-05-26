CREATE OR REPLACE FUNCTION public.excel_cupones_informacion(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rfiltros record;
        
    
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_excel_cupones_informacion
    AS (
    	SELECT *
        FROM (  SELECT --facturaventacuponlote.nrocomercio
                CASE WHEN NOT (facturaventacuponlote.nrocomercio) IS NULL THEN facturaventacuponlote.nrocomercio ELSE liquidaciontarjeta.nrocomercio END AS nrocomercio
                ,
                nrolote,
                fechacreacion,
                fechaemision::date as fechaemision,
                autorizacion,
                nrotarjeta, 
                (case when facturaventacupon.tipofactura='NC' then -1 else 1 end) * monto as monto,
                cuotas,
                concat(facturaventacupon.tipofactura,' ',facturaventacupon.nrosucursal::text,'-',
                facturaventacupon.nrofactura::text,' ',desccomprobanteventa) as detallefactura,
                valorescaja.descripcion as detallevalor,        nrocupon,facturaventacupon.idfacturacupon,
                facturaventacupon.centro,facturaventacupon.nrosucursal,facturaventacupon.nrofactura,
                facturaventacupon.tipocomprobante,facturaventacupon.tipofactura,facturaventacupon.idvalorescaja,
                null as idrecibocupon,null as idcentrorecibocupon, liquidaciontarjeta.idliquidaciontarjeta , liquidaciontarjeta.ltfechaingreso,  liquidaciontarjeta.ltfechapago   
                ,concat(cuentabancaria.nrocuentac::text,' - ',banco.nombrebanco) as banco
                ,lttotalcupones - CASE WHEN (fimportetotal) IS NULL THEN 0 ELSE fimportetotal END as importeacreditado
                ,fimportetotal as totalgastos,  idformapagotipos, anulada, cuentabancaria.idcuentabancaria, 
                CASE WHEN cuentabancaria.nrocuentac=10377 THEN 10377 ELSE 10374 END as nrocuentacupones     -- BelenA 08/05/25 agrego para que se pueda filtrar por cuenta 10374 y 10377
--                ,'1-Comercio#nrocomercio@2-Autorizacion#autorizacion@3-Factura#detallefactura@4-Fecha#fechacreacion@5-Tarjeta#detallevalor@6-Lote#nrolote@7-Nro Tarjeta#nrotarjeta@8-Cuotas#cuotas@9-Nro Cupon#nrocupon@10-Monto#monto@11-Total Gastos#totalgastos@12-Total Acreditado#importeacreditado@13-Liquidacion#idliquidaciontarjeta@14-Banco#banco'::text as mapeocampocolumna
                ,'1-Comercio#nrocomercio@2-Autorizacion#autorizacion@3-Factura#detallefactura@4-Fecha#fechacreacion@5-Tarjeta#detallevalor@6-Lote#nrolote@7-Nro Tarjeta#nrotarjeta@8-Cuotas#cuotas@9-Nro Cupon#nrocupon@10-Monto#monto@11-Total Gastos#totalgastos@12-Total Acreditado#importeacreditado@13-Liquidacion#idliquidaciontarjeta@14-Fecha Ingreso Liquidacion#ltfechaingreso@15-Fecha Pago Liquidacion#ltfechapago@16-Banco#banco@17-Cuenta Orden Pago#nrocuentacupones'::text as mapeocampocolumna

                FROM facturaventacupon      
                NATURAL JOIN facturaventa       
                NATURAL JOIN valorescaja        
                JOIN tipocomprobanteventa on(facturaventa.tipocomprobante=tipocomprobanteventa.idtipo)        
                LEFT JOIN facturaventacuponlote USING(nrofactura,tipocomprobante,nrosucursal,tipofactura,idfacturacupon,centro)       
                LEFT JOIN (
                		SELECT idfacturacupon,centro,tipofactura,tipocomprobante,nrofactura,nrosucursal FROM facturaventacuponestado WHERE idordenventaestadotipo=1 and (fvcefechafin) IS NULL) as x           on (facturaventacupon.idfacturacupon=x.idfacturacupon and facturaventacupon.centro=x.centro              and facturaventacupon.tipofactura=x.tipofactura and facturaventacupon.tipocomprobante=x.tipocomprobante              and facturaventacupon.nrofactura=x.nrofactura and facturaventacupon.nrosucursal=x.nrosucursal)         
                LEFT JOIN liquidaciontarjetaitem as lti on(facturaventacupon.idfacturacupon=lti.idfacturacupon and  facturaventacupon.centro=lti.centro and facturaventacupon.nrosucursal=lti.nrosucursal and  facturaventacupon.nrofactura=lti.nrofactura and facturaventacupon.tipocomprobante=lti.tipocomprobante and  facturaventacupon.tipofactura=lti.tipofactura )
                LEFT JOIN liquidaciontarjeta USING (idliquidaciontarjeta, idcentroliquidaciontarjeta)
                --LEFT JOIN cuentabancariasosunc USING (idcuentabancaria)
                LEFT JOIN (  --BelenA busco todas las cuentas bancarias que SI tienen liq de tarj
		             SELECT cuentabancariasosunc.*, idvalorescaja
		             FROM cuentabancariasosunc
		             JOIN valorescaja ON (idvalorescaja=idvalorescajacuentab)
		             WHERE liquidatarjetas
		           ) as cuentabancaria USING (idvalorescaja)
                LEFT JOIN banco USING (idbanco)
                LEFT JOIN (
                    select idprestador,idliquidaciontarjeta,idcentroliquidaciontarjeta,sum(fimportetotal) as fimportetotal,text_concatenar(concat(nroregistro,'-',anio,' ')) as nroregistroanio               
                    FROM factura               
                    NATURAL JOIN liquidaciontarjetacomprobantegasto               
                    GROUP BY idliquidaciontarjeta,idcentroliquidaciontarjeta,idprestador              
                ) as facturas   USING (idliquidaciontarjeta,idcentroliquidaciontarjeta)   

                WHERE idformapagotipos in (4,5)  
                and 'true'  and 'true'  and 'true'  
                and 'true'  and 
                fechaemision::date between rfiltros.fechadesde and rfiltros.fechahasta  
                and (anulada) IS NULL          
    			

    UNION       
                SELECT --recibocuponlote.nrocomercio,
                CASE WHEN NOT  (recibocuponlote.nrocomercio) IS NULL THEN recibocuponlote.nrocomercio ELSE liquidaciontarjeta.nrocomercio END AS nrocomercio
                ,nrolote,fecharecibo as fechacreacion,fecharecibo::date as fechaemision,
                autorizacion,nrotarjeta,monto,cuotas,concat('REC ',recibocupon.centro::text,'-',idrecibo::text) as detallefactura,
                valorescaja.descripcion as detallevalor,        nrocupon,null as idfacturacupon,null as centro,null as nrosucursal,
                null as nrofactura,null as tipocomprobante,null as tipofactura,recibocupon.idvalorescaja,recibocupon.idrecibocupon,
                recibocupon.idcentrorecibocupon , liquidaciontarjeta.idliquidaciontarjeta  , liquidaciontarjeta.ltfechaingreso,  liquidaciontarjeta.ltfechapago   
                ,concat(cuentabancaria.nrocuentac::text,' - ',banco.nombrebanco) as banco  
                ,lttotalcupones - CASE WHEN (fimportetotal) IS NULL THEN 0 ELSE fimportetotal END as importeacreditado
                ,fimportetotal as totalgastos, idformapagotipos, reanulado as anulada, cuentabancaria.idcuentabancaria,
                CASE WHEN cuentabancaria.nrocuentac=10377 THEN 10377 ELSE 10374 END as nrocuentacupones     -- BelenA 08/05/25 agrego para que se pueda filtrar por cuenta 10374 y 10377
                --,'1-Comercio#nrocomercio@2-Autorizacion#autorizacion@3-Factura#detallefactura@4-Fecha#fechacreacion@5-Tarjeta#detallevalor@6-Lote#nrolote@7-Nro Tarjeta#nrotarjeta@8-Monto#monto@9-Cuotas#cuotas@10-Nro Cupon#nrocupon@11-Liquidacion#idliquidaciontarjeta@12-Banco#banco@13-Total Acreditado#importeacreditado@13-Total Gastos#totalgastos'::text as mapeocampocolumna
--                ,'1-Comercio#nrocomercio@2-Autorizacion#autorizacion@3-Factura#detallefactura@4-Fecha#fechacreacion@5-Tarjeta#detallevalor@6-Lote#nrolote@7-Nro Tarjeta#nrotarjeta@8-Cuotas#cuotas@9-Nro Cupon#nrocupon@10-Monto#monto@11-Total Gastos#totalgastos@12-Total Acreditado#importeacreditado@13-Liquidacion#idliquidaciontarjeta@14-Banco#banco'::text as mapeocampocolumna
                ,'1-Comercio#nrocomercio@2-Autorizacion#autorizacion@3-Factura#detallefactura@4-Fecha#fechacreacion@5-Tarjeta#detallevalor@6-Lote#nrolote@7-Nro Tarjeta#nrotarjeta@8-Cuotas#cuotas@9-Nro Cupon#nrocupon@10-Monto#monto@11-Total Gastos#totalgastos@12-Total Acreditado#importeacreditado@13-Liquidacion#idliquidaciontarjeta@14-Fecha Ingreso Liquidacion#ltfechaingreso@15-Fecha Pago Liquidacion#ltfechapago@16-Banco#banco@17-Cuenta Orden Pago#nrocuentacupones'::text as mapeocampocolumna

                
                FROM recibocupon        
                NATURAL JOIN recibo     
                NATURAL JOIN valorescaja        
                JOIN (SELECT distinct nrosucursal,centro FROM talonario) as tal on recibocupon.idcentrorecibocupon=tal.centro       
                LEFT JOIN recibocuponlote USING(idrecibocupon,idcentrorecibocupon)          
                LEFT JOIN (SELECT idrecibocupon,idcentrorecibocupon FROM recibocuponestado WHERE idordenventaestadotipo=1 and (rcefechafin) IS NULL) as x          on (recibocupon.idrecibocupon=x.idrecibocupon and recibocupon.idcentrorecibocupon=x.idcentrorecibocupon)        
                LEFT JOIN liquidaciontarjetaitem as lti on(recibocupon.idrecibocupon=lti.idrecibocupon and recibocupon.idcentrorecibocupon=lti.idcentrorecibocupon)
                LEFT JOIN liquidaciontarjeta USING (idliquidaciontarjeta, idcentroliquidaciontarjeta)
				
				LEFT JOIN (  --BelenA busco todas las cuentas bancarias que SI tienen liq de tarj
		             SELECT cuentabancariasosunc.*, idvalorescaja
		             FROM cuentabancariasosunc
		             JOIN valorescaja ON (idvalorescaja=idvalorescajacuentab)
		             WHERE liquidatarjetas
		           ) as cuentabancaria USING (idvalorescaja)
				LEFT JOIN banco USING (idbanco)
                LEFT JOIN (
                    select idprestador,idliquidaciontarjeta,idcentroliquidaciontarjeta,sum(fimportetotal) as fimportetotal,text_concatenar(concat(nroregistro,'-',anio,' ')) as nroregistroanio               
                    FROM factura               
                    NATURAL JOIN liquidaciontarjetacomprobantegasto               
                    GROUP BY idliquidaciontarjeta,idcentroliquidaciontarjeta,idprestador              
                ) as facturas   USING (idliquidaciontarjeta,idcentroliquidaciontarjeta)      

                WHERE    idformapagotipos in (4,5) 
                AND (reanulado) IS NULL   
                and 'true'  and 'true'  and 'true'  
                and fecharecibo::date between rfiltros.fechadesde and rfiltros.fechahasta 

            ) as T
				WHERE  TRUE  
                and case when (rfiltros.idcuentabancariabanco) IS NULL THEN true ELSE T.idvalorescaja=rfiltros.idcuentabancariabanco END
                and case when (rfiltros.cuentabancarias) IS NULL THEN true ELSE T.nrocuentacupones=rfiltros.cuentabancarias END      -- BelenA 08/05/25 agrego para que se pueda filtrar por cuenta 10374 y 10377

                order by nrocupon

    );

return true;
END;
$function$
