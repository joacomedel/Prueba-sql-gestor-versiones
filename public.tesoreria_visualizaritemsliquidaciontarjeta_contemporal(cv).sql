CREATE OR REPLACE FUNCTION public.tesoreria_visualizaritemsliquidaciontarjeta_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$

DECLARE

  rfiltros record;
  dfechadesde date;
  dfechahasta date;
  iidliquidaciontarjeta int;


BEGIN
 

    EXECUTE sys_dar_filtros($1) INTO rfiltros;

    --dfechadesde=rfiltros.fechadesde;
    --dfechahasta=rfiltros.fechahasta;
    iidliquidaciontarjeta= rfiltros.idliquidaciontarjeta;


  CREATE TEMP TABLE temp_tesoreria_visualizaritemsliquidaciontarjeta_contemporal
    AS (
     SELECT 
      fechaemision::date AS fechaemision,
      concat( facturaventacupon.tipofactura,' ',facturaventacupon.nrosucursal::text,'-',facturaventacupon.nrofactura::text,' ',desccomprobanteventa , ' - ', cli.denominacion, ' ', cli.nrocliente ) AS detallefactura,
      (case when facturaventacupon.tipofactura='NC' then -1 else 1 end) * monto AS monto,
      nrocupon,
      facturaventacupon.idfacturacupon,
      facturaventacupon.centro,
      null AS idrecibocupon,
      null AS idcentrorecibocupon 
      ,      idliquidaciontarjeta
          ,'1-Fecha Emision#fechaemision@2-Detalle#detallefactura@3-Monto#monto@4-Nº Cupon#nrocupon@5-Id Factura#idfacturacupon@6-Centro Factura#centro@7-Id Recibo#idrecibocupon@8-Centro Recibo#idcentrorecibocupon@9-Liquidacion Tarjeta#idliquidaciontarjeta'::text as mapeocampocolumna    

    FROM facturaventacupon    
    NATURAL JOIN facturaventa   
    NATURAL JOIN valorescaja    
    JOIN tipocomprobanteventa on(facturaventa.tipocomprobante=tipocomprobanteventa.idtipo)        
    LEFT JOIN facturaventacuponlote USING(nrofactura,tipocomprobante,nrosucursal,tipofactura,idfacturacupon,centro)       
    LEFT JOIN (SELECT idfacturacupon,centro,tipofactura,tipocomprobante,nrofactura,nrosucursal FROM facturaventacuponestado WHERE idordenventaestadotipo=1 AND nullvalue(fvcefechafin)) AS x           ON (facturaventacupon.idfacturacupon=x.idfacturacupon AND facturaventacupon.centro=x.centro              AND facturaventacupon.tipofactura=x.tipofactura AND facturaventacupon.tipocomprobante=x.tipocomprobante              AND facturaventacupon.nrofactura=x.nrofactura AND facturaventacupon.nrosucursal=x.nrosucursal)     
    LEFT JOIN liquidaciontarjetaitem AS lti on(facturaventacupon.idfacturacupon=lti.idfacturacupon AND  facturaventacupon.centro=lti.centro AND facturaventacupon.nrosucursal=lti.nrosucursal AND  facturaventacupon.nrofactura=lti.nrofactura AND facturaventacupon.tipocomprobante=lti.tipocomprobante AND  facturaventacupon.tipofactura=lti.tipofactura )  
    LEFT JOIN cliente AS cli ON (facturaventa.nrodoc = cli.nrocliente AND facturaventa.tipodoc = cli.barra)        

    WHERE 

        idformapagotipos in (4,5)  AND 
        --idliquidaciontarjeta = rfiltros.idliquidaciontarjeta
        idliquidaciontarjeta = iidliquidaciontarjeta
        AND 'true'  AND 'true'  AND 'true'  AND 'true'  AND 
        nullvalue(facturaventa.anulada)  AND not nullvalue(lti.idfacturacupon)

    UNION     

    SELECT 
          fecharecibo::date AS fechaemision,
          concat('REC ',recibocupon.centro::text,'-',idrecibo::text, ' - ', recibo.imputacionrecibo) AS detallefactura,  
          monto,
          nrocupon,
          null AS idfacturacupon,
          null AS centro,
          recibocupon.idrecibocupon,
          recibocupon.idcentrorecibocupon   
          ,      idliquidaciontarjeta 
          ,'1-Fecha Emision#fechaemision@2-Detalle#detallefactura@3-Monto#monto@4-Nº Cupon#nrocupon@5-Id Factura#idfacturacupon@6-Centro Factura#centro@7-Id Recibo#idrecibocupon@8-Centro Recibo#idcentrorecibocupon@9-Liquidacion Tarjeta#idliquidaciontarjeta'::text as mapeocampocolumna

    FROM recibocupon    
    NATURAL JOIN recibo   
    NATURAL JOIN valorescaja
    JOIN (SELECT distinct nrosucursal,centro FROM talonario) AS tal ON recibocupon.idcentrorecibocupon=tal.centro   
    LEFT JOIN recibocuponlote USING(idrecibocupon,idcentrorecibocupon)      
    LEFT JOIN (SELECT idrecibocupon,idcentrorecibocupon FROM recibocuponestado WHERE idordenventaestadotipo=1 AND nullvalue(rcefechafin)) AS x        ON (recibocupon.idrecibocupon=x.idrecibocupon AND recibocupon.idcentrorecibocupon=x.idcentrorecibocupon)      
    LEFT JOIN liquidaciontarjetaitem AS lti on(recibocupon.idrecibocupon=lti.idrecibocupon AND recibocupon.idcentrorecibocupon=lti.idcentrorecibocupon)       

    WHERE    

        idformapagotipos in (4,5) AND 
        nullvalue(reanulado)   AND 
        --idliquidaciontarjeta = rfiltros.idliquidaciontarjeta
        idliquidaciontarjeta = iidliquidaciontarjeta 
        AND 'true'  AND 'true'  AND 'true'  AND 
        not nullvalue(lti.idrecibocupon)  

    order by fechaemision, detallefactura

    );
     

return 'Ok';
END;
$function$
