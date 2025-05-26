CREATE OR REPLACE FUNCTION public.cuentas_corrientes_saldo_detalle_multiples_hojas(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
cursorctacblesumariza refcursor;
  rparam RECORD;
  rctacblesumariza RECORD; 
  rdatosctassumariza RECORD;
  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

        CREATE TEMP TABLE temp_cuentas_corrientes_saldo_detalle_multiples_hojas_h1 AS (
              SELECT cuentacorrientepagos.idpago        ,
                     cuentacorrientepagos.idctacte        ,
                     persona.nombres        ,
                     persona.apellido        ,
                     persona.barra        ,
                     persona.nrodoc        ,
                     cuentacorrientepagos.idconcepto        ,
                     cuentacorrientepagos.fechamovimiento        ,
                     cuentacorrientepagos.idcomprobante        ,
                     cuentacorrientepagos.movconcepto as movpago        ,
                     cuentacorrientepagos.importe as imppago        ,
                     cuentacorrientepagos.saldo as saldopago  ,
                     --'1-IdPago#idpago@2-CtaCte#idctacte@3-Nombre#nombres@4-Apellido#apellido@5-Barra#barra@6-NroDoc#nrodoc@2-IdConcepto#idconcepto@3-Fecha Mov#fechamovimiento@4-Comprobante#idcomprobante@5-Concepto#movconcepto@6-Importe#importe@6-Saldo#saldo'::text as mapeocampocolumna
                     '1-IdPago#idpago@2-CtaCte#idctacte@3-Nombre#nombres@4-Apellido#apellido@5-Barra#barra@6-NroDoc#nrodoc@7-IdConcepto#idconcepto@8-Fecha Mov#fechamovimiento@9-Comprobante#idcomprobante@10-Concepto#movpago@11-Importe#imppago@12-Saldo#saldopago'::text AS mapeocampocolumna

                     --12
              FROM cuentacorrientepagos  
              NATURAL JOIN persona  
              WHERE cuentacorrientepagos.saldo <> 0 AND  TRUE  AND  TRUE  AND  
              fechamovimiento >= rparam.fechadesde AND fechamovimiento <= rparam.fechahasta
              --fechamovimiento >= '2025-04-01' AND fechamovimiento <=  '2025-04-14' 

              ORDER BY  persona.apellido  ,persona.nrodoc  ,cuentacorrientepagos.fechamovimiento
        );

        CREATE TEMP TABLE temp_cuentas_corrientes_saldo_detalle_multiples_hojas_h2 AS (
              SELECT iddeuda,
                     idctacte,
                     t.nombres,
                     t.apellido,
                     t.barra,
                     nrodoc,
                     idconcepto,
                     fechamovimiento,
                     idcomprobante,
                     movdeuda  ,
                     to_char(impdeuda,'9999999990.00') as impdeuda,
                     to_char(saldodeuda,'9999999990.00') as saldodeuda ,
                     to_char(importepagado,'9999999990.00') as importepagado ,
                     concat (usuario.nombre, ' ' ,usuario.apellido) as elusuario  ,
                     '1-IdDeuda#iddeuda@2-CtaCte#idctacte@3-Nombre#nombres@4-Apellido#apellido@5-Barra#barra@6-NroDoc#nrodoc
                     @7-IdConcepto#idconcepto@8-Fecha Mov#fechamovimiento@9-Comprobante#idcomprobante@10-Concepto#movdeuda
                     @11-Importe Deuda#impdeuda@12-Saldo#saldodeuda@13-Importe Pagado#importepagado@14-Usuario#elusuario'::text AS mapeocampocolumna
                     --14

              FROM (
                     SELECT cuentacorrientedeuda.iddeuda        ,cuentacorrientedeuda.idctacte        ,persona.nombres        ,persona.apellido        ,persona.barra        ,persona.nrodoc        ,cuentacorrientedeuda.idconcepto        ,cuentacorrientedeuda.fechamovimiento        ,cuentacorrientedeuda.idcomprobante        ,cuentacorrientedeuda.movconcepto as movdeuda        ,cuentacorrientedeuda.importe as impdeuda        ,cuentacorrientedeuda.importe - CASE WHEN ((pagosctacte.importepagado) IS NULL) THEN 0 ELSE   pagosctacte.importepagado END as saldodeuda        , CASE WHEN ((pagosctacte.importepagado) IS NULL) THEN 0 ELSE   pagosctacte.importepagado END as importepagado  
                     FROM cuentacorrientedeuda  
                     NATURAL JOIN persona  
                     LEFT JOIN ( 
                            SELECT sum(importeimp) as importepagado,iddeuda,idcentrodeuda
                            FROM cuentacorrientedeudapago                 
                            NATURAL JOIN cuentacorrientepagos            
                            WHERE cuentacorrientedeudapago.fechamovimientoimputacion <= '2025-04-14'             
                            GROUP BY iddeuda,idcentrodeuda           
                            ) as pagosctacte   USING(iddeuda,idcentrodeuda)   
                     WHERE (cuentacorrientedeuda.importe - CASE WHEN ((pagosctacte.importepagado) IS NULL) THEN 0 ELSE   pagosctacte.importepagado END)  >= '0.01'   AND  
                     TRUE  AND  TRUE  AND  
                     fechamovimiento >= rparam.fechadesde AND fechamovimiento <= rparam.fechahasta
                     --fechamovimiento >= '2025-04-01' AND fechamovimiento <= '2025-04-14'

                     ORDER BY  persona.apellido  ,persona.nrodoc ,cuentacorrientedeuda.fechamovimiento 
                     ) as t   
              LEFT JOIN informefacturacion on (idcomprobante=((nroinforme*100)+idcentroinformefacturacion)) 
              LEFT JOIN facturaorden USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) 
              LEFT JOIN ordenrecibo USING(nroorden, centro) 
              LEFT JOIN recibousuario USING(idrecibo, centro) 
              LEFT JOIN usuario USING(idusuario)
        );

      CREATE TEMP TABLE temp_cuentas_corrientes_saldo_detalle_multiples_hojas as (
        SELECT '1-Pagos' as titulohoja,'temp_cuentas_corrientes_saldo_detalle_multiples_hojas_h1' as nombretabla
          UNION 
        SELECT '2-Deudas' as titulohoja,'temp_cuentas_corrientes_saldo_detalle_multiples_hojas_h2' as nombretabla
      );
 
     respuesta = 'todook';
     
    
    
return respuesta;
END;
$function$
