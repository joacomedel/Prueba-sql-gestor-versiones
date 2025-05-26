CREATE OR REPLACE FUNCTION public.cuentacorrientes_consaldo_detalle_contemporal(character varying)
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

    dfechadesde=rfiltros.fechadesde;
    dfechahasta=rfiltros.fechahasta;



  CREATE TEMP TABLE temp_cuentacorrientes_consaldo_detalle_contemporal
    AS (
        SELECT
            iddeuda,idctacte,t.nombres,t.apellido,t.barra,t.nrodoc,idconcepto,fechamovimiento
            ,CASE WHEN nullvalue(prestamo.fechaprestamo) THEN fechamovimiento ELSE fechaprestamo END as fechaprestamo
            ,idcomprobante,movdeuda ,to_char(impdeuda,'9999999990.00') as impdeuda
            ,to_char(saldodeuda,'9999999990.00') as saldodeuda ,to_char(importepagado,'9999999990.00') as importepagado ,concat (usuario.nombre, ' ' ,usuario.apellido) as elusuario
            , p.email as correoafil , p.descrip as localidadafiliado   
            --, '1-Codigo#idconcepto@2-IDDEUDA#iddeuda@3-CtaCte#idctacte@4-Nombres#nombres@5-Apellido#apellido@6-Barra#barra@7-Nro.Doc#nrodoc@8-FechaMovimiento#fechamovimiento@9-FechaPrestamo#fechaprestamo@10-Comprobante#idcomprobante@11-Concepto#movdeuda@12-Importe#impdeuda@13-Saldo#saldodeuda@14-Importe Pagado#importepagado@15-Emitio Orden#elusuario'::text as mapeocampocolumna    
            , '1-Codigo#idconcepto@2-IDDEUDA#iddeuda@3-CtaCte#idctacte@4-Nombres#nombres@5-Apellido#apellido@6-Barra#barra@7-Nro.Doc#nrodoc@8-Correo Afiliado#correoafil@9-localidad Afiliado#localidadafiliado@10-FechaMovimiento#fechamovimiento@1-FechaPrestamo#fechaprestamo@12-Comprobante#idcomprobante@13-Concepto#movdeuda@14-Importe#impdeuda@15-Saldo#saldodeuda@16-Importe Pagado#importepagado@17-Emitio Orden#elusuario'::text as mapeocampocolumna
        FROM (SELECT cuentacorrientedeuda.iddeuda ,cuentacorrientedeuda.idctacte ,persona.nombres 
            ,persona.apellido ,persona.barra ,persona.nrodoc ,cuentacorrientedeuda.idconcepto 
            ,cuentacorrientedeuda.fechamovimiento ,cuentacorrientedeuda.idcomprobante 
            ,cuentacorrientedeuda.movconcepto as movdeuda ,cuentacorrientedeuda.importe as impdeuda 
            ,cuentacorrientedeuda.importe - CASE WHEN nullvalue(pagosctacte.importepagado) THEN 0 ELSE pagosctacte.importepagado END as saldodeuda 
            , CASE WHEN nullvalue(pagosctacte.importepagado) THEN 0 ELSE pagosctacte.importepagado END as importepagado 
            FROM cuentacorrientedeuda NATURAL JOIN persona 
            LEFT JOIN ( SELECT sum(importeimp) as importepagado,iddeuda,idcentrodeuda 
                        FROM cuentacorrientedeudapago NATURAL JOIN cuentacorrientepagos 
                        WHERE cuentacorrientedeudapago.fechamovimientoimputacion <= dfechahasta GROUP BY iddeuda,idcentrodeuda ) as pagosctacte USING(iddeuda,idcentrodeuda) 
            WHERE 
                (cuentacorrientedeuda.importe - CASE WHEN nullvalue(pagosctacte.importepagado) THEN 0 ELSE pagosctacte.importepagado END) >= '0.01' 
                AND TRUE AND TRUE AND fechamovimiento >= dfechadesde AND fechamovimiento <= dfechahasta

        ORDER BY persona.apellido ,persona.nrodoc ,cuentacorrientedeuda.fechamovimiento ) as t
        
        LEFT JOIN (
                SELECT *
                FROM persona
                LEFT JOIN direccion USING (iddireccion, idcentrodireccion)
                LEFT JOIN localidad USING (idlocalidad)
                ) AS p USING (nrodoc, barra)

        LEFT JOIN informefacturacion on (idcomprobante=((nroinforme*100)+idcentroinformefacturacion))
        LEFT JOIN facturaorden USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) 
        LEFT JOIN ordenrecibo USING(nroorden, centro)
        LEFT JOIN recibousuario USING(idrecibo, centro)
        LEFT JOIN usuario USING(idusuario)

        LEFT JOIN prestamocuotas ON (idcomprobante= concat(idprestamocuotas::varchar, idcentroprestamocuota::varchar) )
        LEFT JOIN prestamo USING (idprestamo, idcentroprestamo)

        LEFT JOIN recibo ON (ordenrecibo.idrecibo=recibo.idrecibo AND ordenrecibo.centro=recibo.centro)


        WHERE   CASE WHEN NOT nullvalue(informefacturacion.tipofactura) THEN 
                    NOT (informefacturacion.tipofactura ilike '% NC %') 
                ELSE
                    nullvalue(informefacturacion.tipofactura)
                END
                AND
                nullvalue(recibo.reanulado)

        GROUP BY iddeuda, idctacte, t.nombres, t.apellido, t.barra, t.nrodoc, idconcepto, fechamovimiento, idcomprobante, movdeuda, impdeuda, saldodeuda, importepagado, elusuario
        , prestamo.idprestamo, prestamo.idcentroprestamo, p.email , p.descrip

    );
     

return 'Ok';
END;
$function$
