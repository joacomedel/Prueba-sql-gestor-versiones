CREATE OR REPLACE FUNCTION public.existefkey()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

 	
  	cdeudas refcursor;
    respuesta boolean;
  	runpago  RECORD;
	runadeuda  RECORD;
BEGIN
     respuesta =true;

  IF ( NOT EXISTS (
    SELECT * FROM pg_constraint WHERE conname = 'facturaorden_nrofactura_fkey'
    ) or  NOT EXISTS (
    SELECT * FROM pg_constraint WHERE conname = 'itemfacturaventa_nrofactura_fkey'
    )
 or  NOT EXISTS (
    SELECT * FROM pg_constraint WHERE conname = 'facturaventacupon_nrofactura_fkey'
    ) 
or  NOT EXISTS(
   SELECT * FROM pg_constraint WHERE conname = 'facturaventanofiscal_nrofactura_fkey'
   ) 
or  NOT EXISTS (
     SELECT * FROM pg_constraint WHERE conname = 'facturaventausuario_tipocomprobante_fkey'
  )


or  NOT EXISTS (
     SELECT * FROM pg_constraint WHERE conname = 'facturaventacuponlote_fk1'
  )

or  NOT EXISTS (
     SELECT * FROM pg_constraint WHERE conname = 'contabilidad_periodofiscalfacturaventa_nrofactura_fkey'
  )
or  NOT EXISTS (
     SELECT * FROM pg_constraint WHERE conname = 'controlcajafacturaventa_nrofactura_fkey'
  )


    ) THEN respuesta =false;
END IF;

RETURN respuesta;
END;
$function$
