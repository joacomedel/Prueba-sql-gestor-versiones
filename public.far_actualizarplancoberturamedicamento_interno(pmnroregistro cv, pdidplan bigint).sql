CREATE OR REPLACE FUNCTION public.far_actualizarplancoberturamedicamento_interno(pmnroregistro character varying, pdidplan bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE

/* inserta en far_plancoberturamedicamento */

  	cursorarticulo CURSOR FOR

      select distinct pdidplan as idplan ,mnroregistro,CASE WHEN pdidplan = 8 THEN 0.1 ELSE multiplicador END as coporcentaje ,0 as comontofijo

      ,'Migrado desde plancoberturafarmacia' as cocomentario

from plancoberturafarmacia

     join manextra using(idmonodroga)

     join medicamento using(mnroregistro)

where mnroregistro= pmnroregistro and nullvalue(fechafinvigencia);

	rarticulo RECORD;

	rplan RECORD;

        rpa RECORD;

	resp boolean;

BEGIN

    OPEN cursorarticulo;

    FETCH cursorarticulo into rarticulo;

    WHILE  found LOOP

           select into rplan * from far_plancoberturamedicamento 

           where mnroregistro=pmnroregistro AND idplancobertura = rarticulo.idplan;

           if not found then begin

                 insert into far_plancoberturamedicamento(idplancobertura,mnroregistro,pcmporcentaje,pcmmontofijo,pcmcomentario)

                 values(rarticulo.idplan,rarticulo.mnroregistro,rarticulo.coporcentaje,rarticulo.comontofijo,rarticulo.cocomentario);

              end;

           else

               IF (rplan.pcmporcentaje <> rarticulo.coporcentaje) THEN

                 BEGIN

                      update far_plancoberturamedicamento set pcmfechafin=now()

                      where mnroregistro=pmnroregistro AND idplancobertura = rarticulo.idplan; 

                      insert into far_plancoberturamedicamento(idplancobertura,mnroregistro,pcmporcentaje,pcmmontofijo,pcmcomentario)

                      values(rarticulo.idplan,rarticulo.mnroregistro,rarticulo.coporcentaje,rarticulo.comontofijo,rarticulo.cocomentario);

                 END;

               END IF;

           end if;

    fetch cursorarticulo into rarticulo;

    END LOOP;

    close cursorarticulo;

return 'true';

END;

$function$
