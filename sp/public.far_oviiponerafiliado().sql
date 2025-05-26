CREATE OR REPLACE FUNCTION public.far_oviiponerafiliado()
 RETURNS trigger
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$DECLARE
       elidafiliado bigint;
       elnrodoc bigint;
       rafiliado record;
BEGIN
  /* New function body */

   elidafiliado = NEW.oviiidafiliadocobertura;
   elnrodoc = NEW.oviinrodoc;
 --  NEW.oviidobrasocial := 1;
  --- NEW.ovitipodoc := 1;
--   RAISE NOTICE 'idafiliado - id   %', NEW.oviidobrasocial;
 --  RAISE NOTICE 'idafiliado - id   %', idafiliado;
-- GK 22-08-2022 agrego control nrodoc
   SELECT INTO rafiliado * FROM far_afiliado WHERE idafiliado = elidafiliado AND nrodoc ilike concat('%',elnrodoc,'%');
  NEW.oviiidobrasocial := rafiliado.idobrasocial;
  NEW.oviitipodoc :=rafiliado.tipodoc;
   NEW.oviinrodoc :=rafiliado.nrodoc;
   

  RETURN NEW;
END;$function$
