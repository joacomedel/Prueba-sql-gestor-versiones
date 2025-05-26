CREATE OR REPLACE FUNCTION public.informe_movimientos_conciliados(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rfiltros record;
        
    
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_informe_movimientos_conciliados
    AS (
        /*SELECT  concat(idasientogenerico,'|',idcentroasientogenerico) as datoasiento, 
            CASE WHEN nullvalue(agdescripcion) THEN bancamovimiento.bmconcepto ELSE agdescripcion END as descripcionasiento,
            idconciliacionbancaria,conciliacionbancariaestadotipo.cbetdescripcion as estadoconcil, bancamovimiento.idbancamovimiento as idbancamovimiento, 
            bancamovimiento.bmfecha as fechabm, bancamovimiento.bmconcepto as conceptobm,
            split_part( bancamovimiento.bmconcepto,':',2)::varchar as observacion,
            case when nullvalue(bancamovimiento.bmdebito)then 0 else bancamovimiento.bmdebito end as bmdebito,
            case when nullvalue(bancamovimiento.bmcredito)then 0 else bancamovimiento.bmcredito end as bmcredito,
            cbicomsiges, cbiimporte, cbicomsigesdetalle as laopc
           --,'1-Nº Conciliacion#idconciliacionbancaria@2-Estado Conciliacion#estadoconcil@3-IDbancamovimiento#idbancamovimiento@4-Fecha#fechabm@5-Nº Asiento#datoasiento@6-Concepto#descripcionasiento@7-Debito#bmdebito@8-Credito#bmcredito@9-Com. Siges#cbicomsiges@10-Monto Conciliado#cbiimporte@11-Detalle OPC#laopc'::text as mapeocampocolumna
            ,'1-Nº Conciliacion#idconciliacionbancaria@2-Estado Conciliacion#estadoconcil@3-IDbancamovimiento#idbancamovimiento@4-Fecha#fechabm@5-Concepto#conceptobm@6-Detalle#observacion@7-Debito#bmdebito@8-Credito#bmcredito@9-Com. Siges#cbicomsiges@10-Monto Conciliado#cbiimporte@11-Nº Asiento#datoasiento@12-Detalle Com SIGES#descripcionasiento'::text as mapeocampocolumna

            FROM conciliacionbancaria  
            NATURAL JOIN  conciliacionbancariaitem   
            JOIN conciliacionbancariaestado  USING (idconciliacionbancaria,idcentroconciliacionbancaria)  
            JOIN conciliacionbancariaestadotipo USING ( idconciliacionbancariaestadotipo)  
            left  JOIN bancamovimiento USING (idbancamovimiento)  
            left  JOIN bancamovimientocodigo on (bancamovimiento.bmcodigo=bancamovimientocodigo.bmcodigo)  
            LEFT JOIN asientogenerico USING (idasientogenerico,idcentroasientogenerico)

            WHERE    true  
            AND idcentroconciliacionbancaria=1 and 
            nullvalue(cbcefechafin) and cbiactivo  
            AND 
            CASE WHEN ( nullvalue(rfiltros.idconciliacionbancaria) ) THEN true ELSE 
            idconciliacionbancaria=rfiltros.idconciliacionbancaria END

            AND 
            CASE WHEN ( nullvalue(rfiltros.fechadesde) ) THEN true ELSE
            bancamovimiento.bmfecha>= rfiltros.fechadesde  END

            AND 
            CASE WHEN ( nullvalue(rfiltros.fechahasta) ) THEN true ELSE
            bancamovimiento.bmfecha <= rfiltros.fechahasta END


            ORDER BY idconciliacionbancaria , bancamovimiento.idbancamovimiento asc
*/

            SELECT 
                    X.*,
                    --'1-Nº Conciliacion#idconciliacionbancaria@2-Estado Conciliacion#estadoconcil@3-IDbancamovimiento#idbancamovimiento@4-Fecha#bmfecha@5-Concepto#bmconcepto@6-Comprobante#bmnrocomprobante@7-Detalle#observacion@8-Debito#bmdebito@9-Credito#bmcredito@10-Com. Siges#cbicomsiges@11-Monto Conciliado#cbiimporte@12-Nº Asiento#datoasiento@13-Detalle Com SIGES#descripcionasiento'::text as mapeocampocolumna
                    '1-Nº Conciliacion#idconciliacionbancaria@2-Estado Conciliacion#estadoconcil@3-IDbancamovimiento#idbancamovimiento@4-Fecha#bmfecha@5-Concepto#bmconcepto@6-Comprobante#bmnrocomprobante@7-Detalle#observacion@8-Debito#bmdebito@9-Credito#bmcredito@10-Fecha Contable#agfechacontable@11-Com. Siges#cbicomsiges@12-Monto Conciliado#cbiimporte@13-Nº Asiento#datoasiento@14-Detalle Com SIGES#descripcionasiento'::text as mapeocampocolumna

                FROM (
                    -- Primer conjunto de movimientos bancarios sin conciliación
                    SELECT 
                        NULL AS idconciliacionbancaria,
                        NULL AS estadoconcil,
                        idbancamovimiento, bmfecha, bmconcepto, bmnrocomprobante,
                        split_part(bmconcepto, ':', 2)::varchar AS observacion,
                        COALESCE(bmdebito, 0) AS bmdebito,
                        COALESCE(bmcredito, 0) AS bmcredito,
                        NULL AS cbicomsiges,
                        NULL AS cbiimporte,
                        NULL AS datoasiento,
                        NULL AS descripcionasiento,
                        idcuentabancaria,
                        NULL AS agfechacontable
                    FROM bancamovimiento  
                    LEFT JOIN bancamovimientocodigo USING (bmcodigo)
                    WHERE bmcprocesacodigo IS NOT NULL
                    AND (bmdebito > 0 OR bmcredito > 0)
                    AND (0.0099 <= (bmdebito + bmcredito) - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar, '{tipomov=banco}'))

                    UNION

                    -- Segundo conjunto de movimientos bancarios conciliados
                    SELECT  
                        idconciliacionbancaria,
                        conciliacionbancariaestadotipo.cbetdescripcion AS estadoconcil,
                        idbancamovimiento, bmfecha, bmconcepto, bmnrocomprobante,
                        split_part(bmconcepto, ':', 2)::varchar AS observacion,
                        COALESCE(bmdebito, 0) AS bmdebito,
                        COALESCE(bmcredito, 0) AS bmcredito,
                        cbicomsiges,
                        cbiimporte,
                        CONCAT(idasientogenerico, '|', idcentroasientogenerico) AS datoasiento,
                        COALESCE(agdescripcion, bmconcepto) AS descripcionasiento,
                        conciliacionbancaria.idcuentabancaria,
                        agfechacontable
                    FROM conciliacionbancaria  
                    NATURAL JOIN conciliacionbancariaitem   
                    JOIN conciliacionbancariaestado USING (idconciliacionbancaria, idcentroconciliacionbancaria)  
                    JOIN conciliacionbancariaestadotipo USING (idconciliacionbancariaestadotipo)  
                    LEFT JOIN bancamovimiento USING (idbancamovimiento)  
                    LEFT JOIN bancamovimientocodigo ON bancamovimiento.bmcodigo = bancamovimientocodigo.bmcodigo  
                    LEFT JOIN asientogenerico USING (idasientogenerico, idcentroasientogenerico)
                    WHERE idcentroconciliacionbancaria = 1
                    AND cbiactivo
                    --AND NULLVALUE(cbcefechafin)
                    AND (cbcefechafin) IS NULL
                ) AS X
/*
                WHERE CASE WHEN NULLVALUE('2024-09-01') THEN true ELSE 
                X.bmfecha >= '2024-09-01' END
                AND CASE WHEN NULLVALUE('2024-09-30') THEN true ELSE 
                X.bmfecha <= '2024-09-30' END
                AND CASE WHEN NULLVALUE(6) THEN true ELSE 
                X.idcuentabancaria <= 6 END
*/
                -- Filtros por fecha y cuenta bancaria
                /*WHERE CASE WHEN NULLVALUE(rfiltros.fechadesde) THEN true ELSE 
                X.bmfecha >= rfiltros.fechadesde END
                AND CASE WHEN NULLVALUE(rfiltros.fechahasta) THEN true ELSE 
                X.bmfecha <= rfiltros.fechahasta END
                AND CASE WHEN NULLVALUE(rfiltros.idcuentabancariabanco) THEN true ELSE 
                X.idcuentabancaria = rfiltros.idcuentabancariabanco END*/
                -- Cambio los nullvalue por is null
                
                WHERE CASE WHEN ((rfiltros.fechadesde) IS NULL) THEN true ELSE 
                X.bmfecha >= rfiltros.fechadesde END
                AND CASE WHEN ((rfiltros.fechahasta) IS NULL) THEN true ELSE 
                X.bmfecha <= rfiltros.fechahasta END
                AND CASE WHEN ((rfiltros.idcuentabancariabanco) IS NULL) THEN true ELSE 
                X.idcuentabancaria = rfiltros.idcuentabancariabanco END

                ORDER BY bmfecha asc
                  );

return true;
END;
$function$
