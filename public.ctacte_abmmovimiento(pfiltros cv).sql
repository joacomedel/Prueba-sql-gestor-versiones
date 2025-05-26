CREATE OR REPLACE FUNCTION public.ctacte_abmmovimiento(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD                  
rfiltros RECORD; 
runaorden RECORD;
--VARIABLES 
respuesta varchar;
             
--CURSORES
cursororden refcursor;
             
BEGIN
--MaLaPi 13-05-2021 ya se deja de usar cuando se coloca la minuta en estado liquidable, ahora esas deudas se generan desde la factura de venta
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    
/*la MP se envio a pagar O se anulo, entonces si la orden es online y de cbn genero el mvto en la cta cte del afiliado */
IF (rfiltros.idtipoestadoordenpago=2 OR rfiltros.idtipoestadoordenpago=4) THEN 
  OPEN cursororden FOR  SELECT *
                        FROM factura NATURAL JOIN facturaordenesutilizadas NATURAL JOIN orden NATURAL JOIN ordvalorizada ov NATURAL JOIN ordenrecibo JOIN prestador p ON (ov.nromatricula = p.idprestador) NATURAL JOIN (SELECT DISTINCT idasocconv, acdecripcion FROM asocconvenio where acactivo and aconline ) as asocconvenio 
                        WHERE asocconvenio.idasocconv=127 AND tipo =56 and nroordenpago =rfiltros.nroordenpago AND idcentroordenpago=rfiltros.idcentroordenpago;
  FETCH cursororden INTO runaorden ;
  WHILE FOUND LOOP
       --genero la deuda
    SELECT INTO respuesta *  FROM asentarconsumoctacteV2(runaorden.idrecibo,runaorden.centro,null);
  FETCH cursororden INTO runaorden ;
  END LOOP;
  CLOSE cursororden;
END IF;
 

return '';

END;$function$
