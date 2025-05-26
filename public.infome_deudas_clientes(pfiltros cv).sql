CREATE OR REPLACE FUNCTION public.infome_deudas_clientes(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rfiltros record;
        
    
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_infome_deudas_clientes
    AS (
            SELECT ctactedeudacliente.iddeuda
            ,ctactedeudacliente.idclientectacte
            ,ctactedeudacliente.fechamovimiento
            ,ctactedeudacliente.idcomprobante
            ,ctactedeudacliente.movconcepto as movdeuda
            ,ctactedeudacliente.importe as impdeuda
            ,ctactedeudacliente.saldo as saldodeuda
            ,cliente.denominacion
            ,cliente.nrocliente
            ,ctactedeudacliente.nrocuentac
            ,'1-IDMov#iddeuda@2-Fecha Mov#fechamovimiento@3-Comprobante#idcomprobante@4-Concepto#movdeuda@5-Deuda#impdeuda@6-Saldo#saldodeuda@7-NroCuenta#nrocuentac@8-Nombre Cliente#denominacion'::text as mapeocampocolumna

            FROM  ctactedeudacliente
            NATURAL JOIN clientectacte

            NATURAL JOIN cliente

            WHERE 
            CASE WHEN  nullvalue (rfiltros.nrocuentac) THEN true ELSE ctactedeudacliente.nrocuentac=rfiltros.nrocuentac END
            AND ctactedeudacliente.fechamovimiento >=  rfiltros.fechadesde
            AND ctactedeudacliente.fechamovimiento <= rfiltros.fechahasta 
            AND ctactedeudacliente.saldo>0
            ORDER BY ctactedeudacliente.fechamovimiento
    );

return true;
END;
$function$
