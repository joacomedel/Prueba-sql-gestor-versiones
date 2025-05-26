CREATE OR REPLACE FUNCTION public.saldo_ctacte_proveedor_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       --RECORD
	rfiltros RECORD;

BEGIN
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


  CREATE TEMP TABLE temp_saldo_ctacte_proveedor_contemporal AS (
            SELECT colegioagrupador.pdescripcion as nombreagrupador
            ,ctactedeudaprestador.iddeuda
            ,ctactedeudaprestador.idprestadorctacte
            ,ctactedeudaprestador.fechamovimiento
            ,ctactedeudaprestador.idcomprobante
            ,ctactedeudaprestador.movconcepto as movdeuda
            ,ctactedeudaprestador.importe as impdeuda
            ,ROUND (ctactedeudaprestador.saldo::numeric,2) as saldodeuda
            ,prestador.pdescripcion
            ,prestador.idprestador
            ,prestador.nrocuentac
            ,'1-IDMov#iddeuda@2-Fecha Mov#fechamovimiento@3-Comprobante#idcomprobante@4-Concepto#movdeuda@5-Deuda#impdeuda@6-Saldo#saldodeuda@7-NroCuenta#nrocuentac@8-Nombre prestador#pdescripcion@9-Agrupador#nombreagrupador'::text as mapeocampocolumna

            FROM  ctactedeudaprestador
            NATURAL JOIN prestadorctacte
            LEFT JOIN prestador USING (idprestador)
             LEFT JOIN (SELECT * FROM
                           prestador
                           ) as colegioagrupador ON (colegioagrupador.idprestador=prestador.idcolegio)

            WHERE 
            CASE WHEN  nullvalue (rfiltros.nrocuentac) THEN true ELSE prestador.nrocuentac=rfiltros.nrocuentac END
            AND ctactedeudaprestador.fechamovimiento >= rfiltros.fechadesde
            AND ctactedeudaprestador.fechamovimiento <= rfiltros.fechahasta
            AND ctactedeudaprestador.saldo>0
            AND CASE WHEN  nullvalue (rfiltros.idprestador) THEN true ELSE ctactedeudaprestador.idprestadorctacte=rfiltros.idprestador END

            ORDER BY ctactedeudaprestador.fechamovimiento
);

	
return true;
END;
$function$
