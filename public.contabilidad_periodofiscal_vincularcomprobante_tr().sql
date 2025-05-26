CREATE OR REPLACE FUNCTION public.contabilidad_periodofiscal_vincularcomprobante_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
       rtipofacturaconf RECORD;
BEGIN

   
  SELECT INTO rtipofacturaconf * 
  FROM tipofacturatipomovimiento
  WHERE  tipofactura = NEW.tipofactura AND tftliquidacioniva;
  
  IF ( FOUND AND NEW.idprestador <> 2608 )  THEN  -- Es un comprobante que se liquida y ademas no es emitido por sosunc
              perform contabilidad_periodofiscal_vincularcomprobante ( concat('{fechaemicioncomp=',NEW.fechaemision, ',pftipoiva=C ,idrecepcion=',NEW.idrecepcion,',idcentroregional=',NEW.idcentroregional,',pftipoiva=C}'));
  END IF;
  RETURN NEW;
END;
$function$
