CREATE OR REPLACE FUNCTION public.far_actualizarplancoberturamedicamento_sosunc(pmnroregistro character varying, pidafiliadososunc bigint, pidafiliadoamuc bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE

/*crear una funcion far_actualizarplancoberturamedicamento_sosunc que haga lo mismo que hace

far_actualizarplancoberturamedicamento pero que tambien cargue en plancoberturaafiliadoobrasocial

y plancoberturaafiliado si el parametro del idafiliado amuc no es nulo.

-- 8 es el plan de amuc */

  	cursorarticulos CURSOR FOR

      select distinct 1 as idplan,mnroregistro,multiplicador as coporcentaje,0 as comontofijo

      ,'Migrado desde plancoberturafarmacia' as cocomentario

from plancoberturafarmacia

     join manextra using(idmonodroga)

     join medicamento using(mnroregistro)

where mnroregistro= pmnroregistro and nullvalue(fechafinvigencia);

	rarticulo RECORD;

	resp boolean;

BEGIN

    OPEN cursorarticulos;

    FETCH cursorarticulos into rarticulo;

    WHILE  found LOOP

  -- Verifico e inserto el plan de cobertura de sosunc en far_plancoberturamedicamento

  -- El plan de cobertura de sosunc es 1. 

	SELECT INTO resp * FROM far_actualizarplancoberturamedicamento_interno(pmnroregistro,1);

  -- Verifico e inserto el plan de cobertura de amuc en far_plancoberturamedicamento

  -- El plan de cobertura de amuc es 8. 

	SELECT INTO resp * FROM far_actualizarplancoberturamedicamento_interno(pmnroregistro,8);

--Idobrasocial sosunc 1 -> prioridad 3

	SELECT INTO resp * FROM far_plancoberturaafiliado_interno(pidafiliadososunc,1,1,3);

--idobrasocial amuc 3 -> prioridad 2

	SELECT INTO resp * FROM far_plancoberturaafiliado_interno(pidafiliadoamuc,8,3,2);

    fetch cursorarticulos into rarticulo;

    END LOOP;

    close cursorarticulos;

return 'true';

END;

$function$
