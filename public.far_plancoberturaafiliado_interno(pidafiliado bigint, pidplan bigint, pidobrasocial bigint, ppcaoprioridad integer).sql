CREATE OR REPLACE FUNCTION public.far_plancoberturaafiliado_interno(pidafiliado bigint, pidplan bigint, pidobrasocial bigint, ppcaoprioridad integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE

/* Guarda en la tablas  far_plancoberturaafiliado y far_plancoberturaafiliadoobrasocial */

        rpa RECORD;

	resp boolean;

BEGIN

IF not nullvalue(pidafiliado) THEN

         SELECT INTO rpa * FROM far_plancoberturaafiliado 

		WHERE idafiliado = pidafiliado 

		AND idplancobertura = pidplan;

     IF NOT FOUND THEN

                 insert into far_plancoberturaafiliado(idafiliado,idplancobertura)

                 values(pidafiliado,pidplan);

      END IF;

      SELECT INTO rpa * FROM far_plancoberturaafiliadoobrasocial 

		WHERE idafiliado = pidafiliado 

		AND idplancobertura = pidplan

                AND idobrasocial = pidobrasocial;

      IF NOT FOUND THEN 

                 insert into far_plancoberturaafiliadoobrasocial(idafiliado,idplancobertura,idobrasocial,pcaoprioridad)

                 values (pidafiliado,pidplan,pidobrasocial,ppcaoprioridad);

     END IF;

END IF;

return 'true';

END;

$function$
