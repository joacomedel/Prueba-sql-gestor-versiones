CREATE OR REPLACE FUNCTION public.expendio_recalcularimporteorden(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
cursoritem refcursor;
cursororden refcursor;

--RECORD    
rfiltros RECORD;
runaorden RECORD; 
rtieneimporte RECORD;
rorden RECORD;

--VARIABLES
res VARCHAR;

BEGIN

   EXECUTE sys_dar_filtros($1) INTO rfiltros;
   
   SELECT INTO runaorden * FROM consumo LEFT JOIN facturaorden USING(nroorden, centro ) LEFT JOIN facturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) 
LEFT JOIN ordenesutilizadas ou ON (consumo.nroorden=ou.nroorden and consumo.centro =ou.centro  )
      WHERE consumo.nroorden = rfiltros.nroorden AND consumo.centro= rfiltros.centro ;
   IF FOUND THEN 
      --MaLaPi 29-03-2022 Modifico el importe aunque ya se le haya pagado al prestador, pues no me cambia en nada lo que pague.
       IF NOT runaorden.anulado AND (nullvalue(runaorden.nrofactura) or  not nullvalue(runaorden.anulada)) 
              --AND nullvalue(runaorden.nrodocuso)  
              THEN
            UPDATE importesorden SET importe = t.importecorrecto FROM 
                   ( SELECT round(expendio_calcularimporteorden(concat('{','nroorden=',rfiltros.nroorden,', centro=',rfiltros.centro,', idformapagotipos=',idformapagotipos,'}'))::numeric,2) as importecorrecto ,nroorden, centro,idformapagotipos
                     FROM ordenrecibo  natural join importesrecibo 
                     WHERE nroorden = rfiltros.nroorden AND centro= rfiltros.centro 
                    ) as t
            WHERE importesorden.nroorden =t.nroorden and importesorden.centro=t.centro and importesorden.idformapagotipos=t.idformapagotipos;
            UPDATE importesrecibo SET importe = t.importecorrecto FROM 
                   ( SELECT round(expendio_calcularimporteorden(concat('{','nroorden=',rfiltros.nroorden,', centro=',rfiltros.centro,', idformapagotipos=',idformapagotipos,'}'))::numeric,2) as importecorrecto ,idrecibo, centro,idformapagotipos
                     FROM ordenrecibo  natural join importesrecibo 
                     WHERE nroorden = rfiltros.nroorden AND centro= rfiltros.centro 
                    ) as t
            WHERE importesrecibo.idrecibo=t.idrecibo and importesrecibo.centro=t.centro and importesrecibo.idformapagotipos=t.idformapagotipos;

       ELSE 
         RAISE EXCEPTION ' No es posible recalcular el importe de la orden. La misma esta anulada, facturada por la OS o por el prestador  !! %', runaorden;      
       END IF;
   END IF;

 SELECT INTO res * FROM w_importeafiliadoorden(concat(rfiltros.nroorden, '-',rfiltros.centro));

RETURN '';
END;$function$
