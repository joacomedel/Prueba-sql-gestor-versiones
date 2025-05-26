CREATE OR REPLACE FUNCTION public.saldo_a_cuenta_proveedor_cliente_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       --RECORD
	rfiltros RECORD;

BEGIN
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

  CREATE TEMP TABLE temp_saldo_a_cuenta_proveedor_cliente_contemporal AS (
	
        SELECT *
            ,'1-Descripcion#descripcion@2-Tipo CtaCte.#tipoctacte@3-Tipo Movimiento#tipomovimiento@4-Id. Movimiento#idmovimiento@5-Centro Movimiento#idcentromovimiento@6-Comprobante#idcomprobante@7-Concepto#movconcepto@8-Fecha Movimiento#fechamovimiento@9-Importe#importe@10-Saldo#saldo'::text as mapeocampocolumna 
        FROM (SELECT --*
        iddeuda as idmovimiento, idcentrodeuda as idcentromovimiento, 'Deuda' as tipomovimiento, idcomprobante, idcomprobantetipos, fechamovimiento, movconcepto, importe, saldo, pdescripcion as descripcion, 'Proveedor' as tipoctacte
        FROM ctactedeudaprestador
        NATURAL JOIN prestadorctacte
        JOIN prestador ON (prestadorctacte.idprestador = prestador.idprestador)
        WHERE movconcepto ilike '%Generacion OPC%'
                AND saldo <>0 


        UNION


        SELECT --*
        idpago as idmovimiento, idcentropago as idcentromovimiento, 'Pago' as tipomovimiento, idcomprobante, idcomprobantetipos, fechamovimiento, movconcepto, importe, saldo, pdescripcion as descripcion, 'Proveedor' as tipoctacte
        FROM ctactepagoprestador
        NATURAL JOIN prestadorctacte
        JOIN prestador ON (prestadorctacte.idprestador = prestador.idprestador)
        WHERE movconcepto ilike '%Generacion OPC%'
                AND saldo <>0 


        UNION


        SELECT --*
        iddeuda as idmovimiento, idcentrodeuda as idcentromovimiento, 'Deuda' as tipomovimiento, idcomprobante, idcomprobantetipos, fechamovimiento, movconcepto, importe, saldo, denominacion as descripcion, 'Cliente' as tipoctacte
        FROM ctactedeudacliente
        NATURAL JOIN clientectacte
        NATURAL JOIN cliente 
        WHERE movconcepto ilike '%Pago a cuenta%'
                AND saldo <>0 


        UNION


        SELECT --*
        idpago as idmovimiento, idcentropago as idcentromovimiento, 'Pago' as tipomovimiento, idcomprobante, idcomprobantetipos, fechamovimiento, movconcepto, importe, saldo, denominacion as descripcion, 'Cliente' as tipoctacte
        FROM ctactepagocliente
        NATURAL JOIN clientectacte
        NATURAL JOIN cliente 
        WHERE movconcepto ilike '%Cobro a cuenta%'
                AND saldo <>0 

        ) as datos
        WHERE fechamovimiento::date >= rfiltros.fechadesde AND fechamovimiento::date <= rfiltros.fechahasta


        order by fechamovimiento desc 



    ); 

return true;
END;
$function$
