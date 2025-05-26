CREATE OR REPLACE FUNCTION public.far_actualizarplancoberturamedicamento(pmnroregistro character varying, pidafiliado bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE

  	cursorarticulos CURSOR FOR

      select distinct 1 as idplan,mnroregistro,multiplicador as coporcentaje,0 as comontofijo,'Migrado desde plancoberturafarmacia' as cocomentario

from plancoberturafarmacia

     join manextra using(idmonodroga)

     join medicamento using(mnroregistro)

where mnroregistro= pmnroregistro and nullvalue(fechafinvigencia);

	rarticulo RECORD;

	rplan RECORD;

        rpa RECORD;

	rartexistente record;

	elidmovimientostock integer;

	elidarticulo bigint;

	elidajuste  integer;

	resp boolean;

BEGIN

    OPEN cursorarticulos;

   -- start transaction;

    FETCH cursorarticulos into rarticulo;

    WHILE  found LOOP

           select into rplan * from far_plancoberturamedicamento 

           where mnroregistro=pmnroregistro;

           if not found then begin

                 insert into far_plancoberturamedicamento(idplancobertura,mnroregistro,pcmporcentaje,pcmmontofijo,pcmcomentario)

                 values(rarticulo.idplan,rarticulo.mnroregistro,rarticulo.coporcentaje,rarticulo.comontofijo,rarticulo.cocomentario);

              end;

           else

               IF (rplan.pcmporcentaje <> rarticulo.coporcentaje) THEN

                 BEGIN

                      update far_plancoberturamedicamento set pcmfechafin=now()

                      where mnroregistro=pmnrorgistro;

                      insert into far_plancoberturamedicamento(idplancobertura,mnroregistro,pcmporcentaje,pcmmontofijo,pcmcomentario)

                      values(rarticulo.idplan,rarticulo.mnroregistro,rarticulo.coporcentaje,rarticulo.comontofijo,rarticulo.cocomentario);

                 END;

               END IF;

           end if;

     SELECT INTO rpa * FROM far_plancoberturaafiliado WHERE idafiliado = pidafiliado AND idplancobertura = rarticulo.idplan;

     IF NOT FOUND THEN

                 insert into far_plancoberturaafiliado(idafiliado,idplancobertura)

                 values(pidafiliado,rarticulo.idplan);

                 insert into far_plancoberturaafiliadoobrasocial(idafiliado,idplancobertura,idobrasocial,pcaoprioridad)

                 values (pidafiliado,rarticulo.idplan,1,1);

     END IF;

    fetch cursorarticulos into rarticulo;

    END LOOP;

    close cursorarticulos;

return 'true';

END;

$function$
