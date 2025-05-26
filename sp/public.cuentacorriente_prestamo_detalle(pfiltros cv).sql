CREATE OR REPLACE FUNCTION public.cuentacorriente_prestamo_detalle(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rfiltros record;
        
    
BEGIN
/*SELECT * FROM cuentacorriente_prestamo_detalle('{fechadesde=2024-01-01, fechahasta=2024-12-31, nrodoc=22436372}');

SELECT * FROM temp_cuentacorriente_prestamo_detalle;*/

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_cuentacorriente_prestamo_detalle
    AS (
        SELECT cuentacorrientedeuda.idconcepto as codigo, iddeuda, cuentacorrientedeuda.idctacte, concat(persona.nombres,' ', persona.apellido) as datospersona, persona.nrodoc
          , persona.barra, cuentacorrientedeuda.movconcepto as conceptodeuda, cuentacorrientedeuda.fechamovimiento as fechadeuda
            ,fechaprestamo, idprestamo as prestamo, fechapagoprobable as fechapagocuota, importecuota
            , p.email as correoafil , p.descrip as localidadafiliado, importeimp as importeimputado
            , cuentacorrientepagos.idpago as idpago, cuentacorrientepagos.movconcepto as conceptopago, abs(cuentacorrientepagos.importe) as importepago

            --, '1-ID Deuda#iddeuda@2-Cta Cte#idctacte@3-Persona#datospersona@4-NroDoc#nrodoc@5-Barra#barra@6-Concepto Deuda#conceptodeuda@7-Fecha Deuda#fechadeuda@8-Prestamo#prestamo@9-Fecha Prestamo#fechaprestamo@10-Fecha Pago Cuota#fechapagocuota@11-Importe Cuota#importecuota@12-Importe Imputado#importeimputado@13-ID Pago#idpago@14-Concepto Pago#conceptopago@15-Importe Pago#importepago'::text as mapeocampocolumna
            ,'1-Codigo#codigo@2-ID Deuda#iddeuda@3-Cta Cte#idctacte@4-Persona#datospersona@5-NroDoc#nrodoc@6-Barra#barra@7-Concepto Deuda#conceptodeuda@8-Fecha Deuda#fechadeuda@9-Prestamo#prestamo@10-Fecha Prestamo#fechaprestamo@11-Fecha Pago Cuota#fechapagocuota@12-Importe Cuota#importecuota@13-Importe Imputado#importeimputado@14-ID Pago#idpago@15-Concepto Pago#conceptopago@16-Importe Pago#importepago'::text as mapeocampocolumna


            FROM cuentacorrientedeuda 
            NATURAL JOIN persona 
            LEFT JOIN (
                SELECT *
                FROM persona
                LEFT JOIN direccion USING (iddireccion, idcentrodireccion)
                LEFT JOIN localidad USING (idlocalidad)
                ) AS p USING (nrodoc, barra)

            LEFT JOIN prestamocuotas ON (idcomprobante= concat(idprestamocuotas::varchar, idcentroprestamocuota::varchar) )
            LEFT JOIN prestamo USING (idprestamo, idcentroprestamo)
            LEFT JOIN recibo ON (prestamocuotas.idrecibo=recibo.idrecibo AND prestamocuotas.idcentrorecibo=recibo.centro)

            LEFT JOIN ordenrecibo ON (prestamocuotas.idrecibo=ordenrecibo.idrecibo AND prestamocuotas.idcentrorecibo=ordenrecibo.centro)
            LEFT JOIN recibousuario ON (prestamocuotas.idrecibo=recibousuario.idrecibo AND prestamocuotas.idcentrorecibo=recibousuario.centro)
            LEFT JOIN usuario USING(idusuario)
            LEFT JOIN facturaorden  ON (ordenrecibo.nroorden=facturaorden.nroorden AND ordenrecibo.centro=facturaorden.centro)
            LEFT JOIN cuentacorrientedeudapago USING (iddeuda, idcentrodeuda)
            LEFT JOIN cuentacorrientepagos USING (idpago, idcentropago)


            WHERE 
            --fechaprestamo >= '2024-01-01' AND fechaprestamo <= '2024-12-31'
            CASE WHEN (rfiltros.nrodoc) IS NOT NULL THEN persona.nrodoc=rfiltros.nrodoc ELSE TRUE END
            AND
            fechaprestamo >= rfiltros.fechadesde AND fechaprestamo <= rfiltros.fechahasta
            --fechamovimiento >= dfechadesde AND fechamovimiento <= dfechahasta
            --AND idprestamo=6431
             
 ORDER BY persona.apellido ,persona.nrodoc ,prestamo,cuentacorrientedeuda.fechamovimiento 
                  );

return true;
END;
$function$
