CREATE OR REPLACE FUNCTION public.fix_cuentacorrientepagos_eliminar(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
 
    rpago  RECORD;  
	rcuentacorrientedeudapagoordenpago   RECORD;  
	rdeudapago   RECORD;  
	
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
	
	cursor_ctactedeuda refcursor;
   
     hay_minuta boolean;
r_minimp record;
hay_asientogenerico boolean;
r_asientogenerico record;
     los_pago varchar; 
	 resp boolean;
BEGIN

    /***** 
     El propósito del siguiente scrip es eliminar pagos de la cuenta corriente de un afiliado
    *****/ 
    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    -- La siguiente consulta permite identificar las deudas que deben ser eliminadas
    -- Va a variar dependiendo del tipo de deuda que se desea eliminar
	
     -- 1 busco el pago 
	 
	 SELECT INTO rdeudapago  *
	 FROM cuentacorrientedeudapago
	 JOIN cuentacorrientepagos USING (idpago,idcentropago)
     WHERE idpago=rfiltros.idpago AND idcentropago= rfiltros.idcentropago;
	 
	 --- Actualizo el saldo de la deuda 
	 UPDATE cuentacorrientedeuda SET saldo = saldo + rdeudapago.importeimp
	 WHERE iddeuda = rdeudapago.iddeuda
      	   AND idcentrodeuda = rdeudapago.idcentrodeuda ;
	 
	 RAISE NOTICE '>>>>(SI) se actualizo el saldo <  (%)  > de la deuda (iddeuda,idcentrodeuda) (%)(%)  >> ',rdeudapago.importeimp , rdeudapago.iddeuda , rdeudapago.idcentrodeuda ;
     

	 -- Busco minuta de imputacion 
	 SELECT INTO rcuentacorrientedeudapagoordenpago *
     FROM cuentacorrientedeudapagoordenpago
     WHERE  idpago=rfiltros.idpago AND idcentropago= rfiltros.idcentropago;
	IF FOUND THEN
				--- Eliminar asiento de la minuta
				SELECT INTO resp contabilidad_eliminarasiento(idasientogenerico,idcentroasientogenerico)
				FROM  asientogenerico 
				WHERE idcomprobantesiges = concat( rcuentacorrientedeudapagoordenpago.nroordenpago,'|',rcuentacorrientedeudapagoordenpago.idcentroordenpago) 
						AND agdescripcion ilike '%actualizarCuponFactturaVenta%' ;
				 RAISE NOTICE '>>>>(SI) se elimino el asiento de la minuta de imputacion (%) - (%) >> ', rcuentacorrientedeudapagoordenpago.nroordenpago,rcuentacorrientedeudapagoordenpago.idcentroordenpago  ;
  
                -- elimino la minuta de imputacion 
    			DELETE FROM cuentacorrientedeudapagoordenpago WHERE idpago=rfiltros.idpago AND idcentropago= rfiltros.idcentropago;
  			    RAISE NOTICE '>>>>(SI) se elimino de  cuentacorrientedeudapagoordenpago idpago= (%) - (%) >> ', rfiltros.idpago , rfiltros.idcentropago;

				-- elimino el registro de imputacion 
				DELETE FROM cuentacorrientedeudapago WHERE idpago=rfiltros.idpago AND idcentropago= rfiltros.idcentropago;
				RAISE NOTICE '>>>>(SI) se elimino de  cuentacorrientedeudapago idpago= (%) - (%) >> ',rfiltros.idpago ,  rfiltros.idcentropago;
   ELSE 
   
   				RAISE NOTICE '>>>>(NO) se encontro infro en  cuentacorrientedeudapagoordenpago idpago= (%) - (%) >> ', rfiltros.idpago , rfiltros.idcentropago;

   END IF;
   DELETE FROM cuentacorrientepagos WHERE idpago=rfiltros.idpago AND idcentropago= rfiltros.idcentropago;

  RAISE NOTICE '>>>>(SI) se elimino de  cuentacorrientepagos idpago= (%) - (%) >> ', rfiltros.idpago ,rfiltros.idcentropago;

	 
 return '';
END;

$function$
