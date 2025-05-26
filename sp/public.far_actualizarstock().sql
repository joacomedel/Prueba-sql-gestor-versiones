CREATE OR REPLACE FUNCTION public.far_actualizarstock()
 RETURNS trigger
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE

    rcomprobante RECORD;
	ccomprobanteitem  refcursor;
	rcomprobanteitem RECORD;
	codremito varchar;
	elidmovimientostock bigint;
	resp boolean;


BEGIN
  /* New function body */
  -- contener el id del movimiento que se esta inserando
  elidmovimientostock = NEW.idmovimientostock;
  -- comprobatetmp es una tabla temporal
  -- que contiene el nombre de la tabla y el id del comprobante que origino el movimiento stock


  SELECT INTO rcomprobante *
         FROM comprobatetmp;


 IF  FOUND THEN
           -- RAISE NOTICE 'far_actualizarstock  ';
                        RAISE NOTICE 'elidmovimientostock - id  % %',elidmovimientostock,rcomprobante;
            -- Verifico si el movimiento se genero a partir de un comprobante "Remito"
            -- calve => idremito
            IF rcomprobante.nombretabla = 'far_remito' THEN
                   SELECT  into resp far_actualizarstockremito(elidmovimientostock,rcomprobante.id);
            END IF;
          
            IF rcomprobante.nombretabla = 'facturaventa' THEN
                   SELECT into resp far_actualizarstockfacturaventa(elidmovimientostock,rcomprobante.id);
            END IF;

            IF rcomprobante.nombretabla = 'far_stockajuste' THEN
                   SELECT into resp far_actualizarstockajuste(elidmovimientostock,rcomprobante.id);
            END IF;

              IF rcomprobante.nombretabla = 'far_ordenventa' THEN
                   SELECT into resp far_actualizarstockordenventa(elidmovimientostock,rcomprobante.id);
            END IF;
       

  END IF;
  RETURN NULL;
END;
$function$
