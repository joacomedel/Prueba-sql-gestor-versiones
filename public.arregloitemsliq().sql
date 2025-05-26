CREATE OR REPLACE FUNCTION public.arregloitemsliq()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
--cursor

	creceliq refcursor;
--record
	existere RECORD;
	rliquidacion RECORD;
--VARIABLES
      elidvalorescaja integer;
      importe double precision;

BEGIN
    OPEN creceliq FOR
         /*      SELECT fovii.*,151 AS idliquidacion, t.idordenventa, t.idcentroordenventa FROM 
(SELECT o.*
FROM far_ordenventa as o
JOIN facturaorden as fo on o.idordenventa = fo.nroorden and  idcentroordenventa = fo.centro
NATURAL JOIN facturaventa fv
JOIN far_ordenventaitem as fovi on fovi.idordenventa = fo.nroorden and fovi.idcentroordenventa = fo.centro
NATURAL JOIN far_ordenventaitemimportes as fovii
 JOIN far_liquidacionitemovii as fliovii USING(idordenventaitem,idcentroordenventaitem, idordenventaitemimporte,idcentroordenventaitemimporte)
JOIN far_liquidacionitems as fli USING(idliquidacionitem,idcentroliquidacionitem)
JOIN far_liquidacion USING(idliquidacion)
WHERE idliquidacion= 151 ) as t  NATURAL JOIN far_ordenventaitem as fovi  --USING(idordenventa,idcentroordenventa)
                        NATURAL JOIN far_ordenventaitemimportes as fovii   --USING(idordenventaitem,idcentroordenventaitem )
LEFT JOIN far_liquidacionitemovii as fliovii USING(idordenventaitem,idcentroordenventaitem, idordenventaitemimporte,idcentroordenventaitemimporte)

WHERE nullvalue(fliovii.idordenventaitemimporte) and idvalorescaja=59 -- and oviiporcentajecobertura=0.7
ORDER BY T.idordenventa
 ;  */
SELECT fovii.*,193 AS idliquidacion, o.idordenventa, o.idcentroordenventa
FROM far_ordenventa as o
 NATURAL JOIN far_ordenventaitem as fovi  --USING(idordenventa,idcentroordenventa)
                        NATURAL JOIN far_ordenventaitemimportes as fovii   --USING(idordenventaitem,idcentroordenventaitem )
LEFT JOIN far_liquidacionitemovii as fliovii USING(idordenventaitem,idcentroordenventaitem, idordenventaitemimporte,idcentroordenventaitemimporte)

WHERE nullvalue(fliovii.idordenventaitemimporte) and idvalorescaja=24  and oviiporcentajecobertura=0.7 and o.idordenventa=36611;


   FETCH creceliq into rliquidacion;
   WHILE  FOUND LOOP

	SELECT INTO existere * FROM far_liquidacionitemovii WHERE idordenventaitemimporte=rliquidacion.idordenventaitemimporte AND idcentroordenventaitemimporte=rliquidacion.idcentroordenventaitemimporte;

	IF NOT FOUND THEN
             --si no lo encuentro genero un nuevo recetario 

		PERFORM  far_cambiarestadoordenventaitemimporte(rliquidacion.idordenventaitemimporte
             ,rliquidacion.idcentroordenventaitemimporte,14,concat('Al ingresar el cupon a liquidacion ',rliquidacion.idliquidacion ,'-',centro()));
           
             INSERT INTO far_liquidacionitems(idliquidacion ,idcentroliquidacion)VALUES(rliquidacion.idliquidacion ,centro());
             
             INSERT INTO far_liquidacionitemovii(idliquidacionitem,idcentroliquidacionitem,idordenventaitem,idcentroordenventaitem, idordenventaitemimporte
             ,idcentroordenventaitemimporte)   
              VALUES(currval('far_liquidacionitems_idliquidacionitem_seq'::regclass), centro(),rliquidacion.idordenventaitem,rliquidacion.idcentroordenventaitem,rliquidacion.idordenventaitemimporte,rliquidacion.idcentroordenventaitemimporte);
     
		
	END IF;

        FETCH creceliq into rliquidacion;
        END LOOP;
       CLOSE creceliq;

return 	true;
END;
$function$
