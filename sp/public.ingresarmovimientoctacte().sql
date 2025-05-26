CREATE OR REPLACE FUNCTION public.ingresarmovimientoctacte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
       elnuevoreg record;
       elprestador record;
       numerofac varchar;
       rmovimientotipo RECORD;
       resp  RECORD;
BEGIN

 
  elnuevoreg = NEW;

  /* Esto va a permitir generar deudas desde resumentes */
  SELECT INTO rmovimientotipo * 
  FROM tipofacturatipomovimiento 
  WHERE  tipofactura = NEW.tipofactura OR
          (  nullvalue(NEW.tipofactura) 
             AND nullvalue(NEW.idrecepcionresumen) -- siempre y cuando la factura no esta asociada a un resumen
             AND nullvalue(NEW.idcentroregionalresumen) 
             AND (tipofactura='RES')
          ) 
          AND tftafectactacte;



  IF FOUND THEN -- Si el tipo de factura se encuentra en esta tabla entonces se debe generar movimientos en la cta.cte.
     IF rmovimientotipo.tipomovimiento ilike 'Deuda' THEN --Se debe generar deuda en cta cte
       SELECT INTO resp * FROM ingresarmovimientodeudactacte(NEW.idrecepcion,NEW.idcentroregional);
     END IF;
     IF rmovimientotipo.tipomovimiento ilike 'Pago' THEN --Se debe generar pago en cta cte
	 SELECT INTO resp * FROM ingresarmovimientopagoctacte(NEW.idrecepcion,NEW.idcentroregional);
     END IF;
     
 END IF;
   RETURN NEW;
END;$function$
