CREATE OR REPLACE FUNCTION public.ctacte_movimientosconsaldo_contemporal(parametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$ 
DECLARE
       
--RECORD
       rfiltros RECORD;
     
--VARIABLES
       vdatosconcepto VARCHAR;
       vnrooden VARCHAR;
       
       
BEGIN
DECLARE
       
--RECORD
       rfiltros RECORD;
     
--VARIABLES
     
       
       
BEGIN
  EXECUTE sys_dar_filtros(parametro) INTO rfiltros;

--segun tkt 4560 piden especificamente que se saquen las deudas de aporte
  CREATE TEMP TABLE temp_ctacte_movimientosconsaldo_contemporal
    AS (
     SELECT mccc.nroconcepto,ccdc.nrocuentac, concat(iddeuda,'-', idcentrodeuda) as eliddeuda, concat(clientectacte.nrocliente, '-',p.barra) as nroafiliado,  p.apellido, nombres, p.barra, fechamovimiento,movconcepto,importe,saldo, login as emitioorden
       FROM ctactedeudacliente ccdc join clientectacte using(idclientectacte,idcentroclientectacte) JOIN persona p ON p.nrodoc=clientectacte.nrocliente join (SELECT DISTINCT ON(nrocuentac) nrocuentac, nroconcepto  FROM mapeocuentascontablesconcepto  ORDER BY  nrocuentac, nroconcepto desc) as mccc on mccc.nrocuentac =ccdc.nrocuentac LEFT JOIN informefacturacion if on ccdc.idcomprobante=((if.nroinforme*100)+if.idcentroinformefacturacion ) LEFT JOIN facturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) LEFT JOIN facturaorden fo USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) LEFT JOIN ordenrecibo ore ON (fo.nroorden=ore.nroorden and fo.centro=ore.centro)
 LEFT JOIN  recibousuario ru ON (ore.idrecibo=ru.idrecibo and fo.centro=ru.centro) LEFT JOIN usuario USING(idusuario) 
           
                
      WHERE (clientectacte.nrocliente = rfiltros.nrodoc or rfiltros.nrodoc is null)  and ccdc.saldo >0
          and ccdc.nrocuentac<>'10826'  and ccdc.fechamovimiento >=rfiltros.fechadesde AND ccdc.fechamovimiento <=rfiltros.fechahasta
      GROUP BY mccc.nroconcepto,ccdc.nrocuentac, iddeuda,idcentrodeuda,clientectacte.nrocliente, clientectacte.barra,  p.apellido, nombres, p.barra,fechamovimiento,movconcepto,importe,saldo, login 
  
      UNION 

      SELECT ccd.idconcepto,ccd.nrocuentac, concat(iddeuda,'-', idcentrodeuda) as eliddeuda, concat(p.nrodoc, '-',p.barra) as nroafiliado,  p.apellido, nombres, p.barra, fechamovimiento,movconcepto,importe,saldo, login as emitioorden
       FROM cuentacorrientedeuda ccd NATURAL JOIN persona p JOIN clientectacte ccc ON (p.nrodoc=ccc.nrocliente and p.tipodoc = ccc.barra) LEFT JOIN informefacturacion if on ccd.idcomprobante=((if.nroinforme*100)+if.idcentroinformefacturacion ) LEFT JOIN facturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) LEFT JOIN facturaorden fo USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) LEFT JOIN ordenrecibo ore ON (fo.nroorden=ore.nroorden and fo.centro=ore.centro)
 LEFT JOIN  recibousuario ru ON (ore.idrecibo=ru.idrecibo and fo.centro=ru.centro) LEFT JOIN usuario USING(idusuario) 
        WHERE   (p.nrodoc = rfiltros.nrodoc or rfiltros.nrodoc is null)  and ccd.saldo >0 and (p.barra=35 or p.barra=36)
           and ccd.fechamovimiento >=rfiltros.fechadesde AND ccd.fechamovimiento <=rfiltros.fechahasta 
      GROUP BY ccd.idconcepto,ccd.nrocuentac, iddeuda,idcentrodeuda,p.nrodoc, p.barra,  p.apellido, nombres, p.barra,fechamovimiento,movconcepto,importe,saldo, login 
      ORDER BY apellido ,fechamovimiento 

);
     

return 'Ok';
END;

END;$function$
