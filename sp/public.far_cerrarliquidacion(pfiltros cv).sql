CREATE OR REPLACE FUNCTION public.far_cerrarliquidacion(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
--REGISTRO 
rexistedeuda RECORD; 
rfiltros RECORD;  

BEGIN

 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

 UPDATE far_liquidacion set nroliquidacionorigen  =rfiltros.nroliquidacionorigen WHERE idliquidacion = rfiltros.idliquidacion AND idcentroliquidacion = rfiltros.idcentroliquidacion;

 PERFORM far_cambiarestadoliquidacion(rfiltros.idliquidacion, rfiltros.idcentroliquidacion, rfiltros.idestadotipo);

     SELECT INTO rexistedeuda * 
		FROM informefacturacionliqfarmacia 
		NATURAL JOIN informefacturacion 
		NATURAL JOIN informefacturacionestado
		JOIN ctactedeudacliente  ON (idcomprobante=nroinforme * 100 + idcentroinformefacturacion)
		   WHERE idliquidacion = rfiltros.idliquidacion AND idcentroliquidacion=rfiltros.idcentroliquidacion
		AND (nullvalue(fechafin) AND NOT idinformefacturacionestadotipo=5);
 
  IF NOT FOUND THEN /*KR 22-08 la deuda NO existe */   
         PERFORM far_asentarfacturaliquidacion(rfiltros.idliquidacion,rfiltros.idcentroliquidacion);
         UPDATE ctactedeudacliente SET movconcepto= CONCAT(movconcepto, ' Nro. Liq. Origen: ', rfiltros.nroliquidacionorigen ) WHERE movconcepto ILIKE concat('%',' Liquidacion: ' ,rfiltros.idliquidacion ,' - ' , rfiltros.idcentroliquidacion,'%');
  END IF; 
  return true;
end;$function$
