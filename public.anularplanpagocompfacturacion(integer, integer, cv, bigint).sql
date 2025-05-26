CREATE OR REPLACE FUNCTION public.anularplanpagocompfacturacion(integer, integer, character varying, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD
  rsolprestamo RECORD;    
BEGIN
  SELECT INTO rsolprestamo * FROM cuentacorrientedeudafacturaventa NATURAL JOIN cuentacorrientedeuda JOIN prestamocuotas ON(cuentacorrientedeuda.idcomprobante = prestamocuotas.idprestamocuotas *10 + prestamocuotas.idcentroprestamocuota)  
			     JOIN prestamosolicitudfinanciacion USING(idprestamo,idcentroprestamo)
  LEFT JOIN cuentacorrientedeudapago USING(iddeuda, idcentrodeuda) 
			     WHERE nrosucursal=$1 AND nrofactura=$4 AND tipofactura=$3 AND tipocomprobante=$2 ;
  IF FOUND THEN 
     IF (nullvalue(rsolprestamo.idpago)) THEN
	INSERT INTO tempconfiguracionprestamo(cancelar,idsolicitudfinanciacion,idcentrosolicitudfinanciacion, idprestamo, idcentroprestamo) 
	VALUES(true, rsolprestamo.idsolicitudfinanciacion,rsolprestamo.idcentrosolicitudfinanciacion, rsolprestamo.idprestamo, rsolprestamo.idcentroprestamo);
	PERFORM abmsolicitudfinanciacion();
     ELSE 
        RAISE EXCEPTION 'No es posible anular el comprobante. Se ha generado pago/s.  !! Id.Pago %', concat(rsolprestamo.idpago,' ',rsolprestamo.idcentropago) ;
         
     END IF;
  END IF; 
           
RETURN true;
END;$function$
