CREATE OR REPLACE FUNCTION public.amasientogenericoitem_formatearmonto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$    BEGIN
         IF (TG_OP = 'INSERT') THEN
             NEW.acimontoconformato = round(NEW.acimonto::numeric,3);
         ELSE 
             IF   (nullvalue (OLD.acimontoconformato) OR  (NEW.acimonto <> OLD.acimonto)) THEN
              UPDATE asientogenericoitem SET acimontoconformato = round(NEW.acimonto::numeric,3)
              WHERE idasientogenericoitem = NEW.idasientogenericoitem 
                    AND idcentroasientogenericoitem = NEW.idcentroasientogenericoitem;
             END IF;
         END IF;
         return NEW;
    END;
    $function$
