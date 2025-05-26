CREATE OR REPLACE FUNCTION public.contabilidad_conciliarcuenta_infopaquete_inv()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
	laleyenda character varying;
        rpaquete RECORD; 
        
BEGIN
/**
Este SP retorna el la leyenda a utilizar para armar los paquetes de los mayores
*/

  IF (TG_OP = 'DELETE') THEN
       --- Corrobo que elexista el paquete
      SELECT INTO rpaquete * FROM contabilidad_conciliar_asientogenericoitem 
      WHERE idasientogenericoitem = OLD.idasientogenericoitem 
                  AND idcentroasientogenericoitem = OLD.idcentroasientogenericoitem;
      IF FOUND THEN
     
            DELETE FROM contabilidad_conciliar_asientogenericoitem 
            WHERE idasientogenericoitem = OLD.idasientogenericoitem 
                  AND idcentroasientogenericoitem = OLD.idcentroasientogenericoitem;
      END IF;
RETURN OLD;
  ELSE  -- UPDATE INSERT

  laleyenda =contabilidad_conciliarcuenta_infopaquete(concat('{idasientogenericoitem=',NEW.idasientogenericoitem,',idcentroasientogenericoitem=',NEW.idcentroasientogenericoitem,'}'));
   END IF;
   RETURN NEW;
END;
$function$
