CREATE OR REPLACE FUNCTION public.farmacia_consumomedicamentoafiliados_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE      
	 
	rfiltros record;

        
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF (nullvalue(rfiltros.idmonodroga) AND nullvalue(rfiltros.idmonodroga)) THEN
-- MaLaPi 30-10-2018 Lo dejo para que si no filtran la monodroga en lugar de por afiliado, agrupo por monodroga
CREATE TEMP TABLE temp_farmacia_consumomedicamentoafiliados_contemporal
AS (
	SELECT  min(idmonodroga) as idmonodroga, extract('year' from fechauso) as anio, COUNT(monnombre) as cantidad,count(distinct (nrodoc)) as cantidadafiliados, sum(importe) as importesosunc,sum(importevigente) as importemedicamento ,mnombre,monnombre,mpresentacion 
				 FROM recetario 
				 NATURAL JOIN recetarioitem  
				 NATURAL JOIN manextra
				 NATURAL JOIN medicamento
				 NATURAL JOIN monodroga 
				 WHERE fechauso >= rfiltros.fechadesde AND   fechauso <= rfiltros.fechahasta 
--KR 28-12-2022 MODIFICO para que tome en cuenta al afiliado si esta
                                  AND (nrodoc = rfiltros.nrodoc OR nullvalue(rfiltros.nrodoc))
				 GROUP BY extract('year' from fechauso),mnombre,monnombre,mpresentacion
				 ORDER BY extract('year' from fechauso),mnombre,monnombre,mpresentacion
);

ELSE 

CREATE TEMP TABLE temp_farmacia_consumomedicamentoafiliados_contemporal
AS (
	SELECT  COUNT(monnombre) as cantidad  ,monnombre , concat(apellido, ', ', nombres) as elafiliado, concat(nrodoc,'-',barra) as nroafiliado, fechauso
				 FROM recetario NATURAL JOIN persona NATURAL JOIN recetarioitem  
				 NATURAL JOIN manextra NATURAL JOIN monodroga 
				 WHERE fechauso >= rfiltros.fechadesde AND   fechauso <= rfiltros.fechahasta 
				 AND (monodroga.idmonodroga=rfiltros.idmonodroga ) 
				 AND (nrodoc = rfiltros.nrodoc OR nullvalue(rfiltros.nrodoc))
			  	 GROUP BY monnombre ,apellido,nombres,nrodoc,barra,fechauso
				 ORDER BY COUNT(monnombre),fechauso DESC


 


);
END IF;

return true;
END;
$function$
