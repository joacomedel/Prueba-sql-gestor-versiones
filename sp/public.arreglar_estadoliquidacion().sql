CREATE OR REPLACE FUNCTION public.arreglar_estadoliquidacion()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
        cliqestado refcursor;
	cliqestadoitemliq refcursor;
	cliqestadoimporteitem refcursor;
        unaliquidacion record;
        unaliquidacionitem record;
	unaliquidacionimporteitem record;

BEGIN
     -- 1 - busco las liquidaciones con mas de un estado, recupero el primero para ponerle fechafin que es el vigente
    OPEN cliqestado FOR
          SELECT idliquidacion,idcentroliquidacion,min(idliquidacionestado) as idliquidacionestado , max(lefechaini) as fechafin, idcentroliquidacionestado  
                FROM far_liquidacion NATURAL JOIN far_liquidacionestado
                WHERE nullvalue(lefechafin) 
		GROUP BY  idliquidacion, idcentroliquidacion,idcentroliquidacionestado 
	 	HAVING count(idliquidacionestado) >1
		ORDER BY idliquidacion;
  

     -- 2 se recorre cada uno de los medicamentos y se pone como vigente el ULTIMO VALOR encontrado
     FETCH cliqestado into unaliquidacion;
     WHILE FOUND LOOP
           UPDATE far_liquidacionestado SET lefechafin = unaliquidacion.fechafin
           WHERE far_liquidacionestado.idliquidacionestado = unaliquidacion.idliquidacionestado
                 and far_liquidacionestado.idcentroliquidacionestado = unaliquidacion.idcentroliquidacionestado
		and nullvalue(lefechafin);
             FETCH cliqestado into unaliquidacion;
     END LOOP;
     close cliqestado;


	  -- 1 - busco las liquidaciones con mas de un estado, recupero el primero para ponerle fechafin que es el vigente
     OPEN cliqestadoitemliq FOR
          SELECT idordenventaitem, idcentroordenventaitem, min(idliquidacionitem) as idliquidacionitem , idcentroliquidacionitem,min(idliquidacionitemestado) as idliquidacionitemestado ,max(liefechaini)  as fechafin,idestadotipo,idcentroliquidacionitem

--far_liquidacionitemestado.*,far_ordenventaitem.*,far_ordenventaitemimportes.*
                FROM far_liquidacionitems NATURAL JOIN far_liquidacionitemovii as fliovii NATURAL JOIN far_liquidacionitemestado
                JOIN far_ordenventaitem using (idordenventaitem, idcentroordenventaitem)  
		natural join far_ordenventaitemimportes
                where nullvalue(liefechafin)-- and far_ordenventaitem.idordenventa= 331141
		GROUP BY  idordenventaitem, idcentroordenventaitem ,idestadotipo,idcentroliquidacionitem
		HAVING count(idordenventaitem) >1
		order by idordenventaitem;

     FETCH cliqestadoitemliq into unaliquidacionitem;
     WHILE FOUND LOOP
           UPDATE far_liquidacionitemestado SET liefechafin = unaliquidacionitem.fechafin
           WHERE far_liquidacionitemestado.idliquidacionitemestado = unaliquidacionitem.idliquidacionitemestado
                 and far_liquidacionitemestado.idestadotipo = unaliquidacionitem.idestadotipo
		 and far_liquidacionitemestado.idliquidacionitem = unaliquidacionitem.idliquidacionitem
                 and far_liquidacionitemestado.idcentroliquidacionitem = unaliquidacionitem.idcentroliquidacionitem
	   	 and nullvalue(liefechafin);
               FETCH cliqestadoitemliq into unaliquidacionitem;
     END LOOP;
     close cliqestadoitemliq;

    OPEN cliqestadoimporteitem FOR
          SELECT idordenventaitemimporte, idcentroordenventaitemimporte, min(idordenventaitemimportesaestado) as idordenventaitemimportesaestado , idcentroordenventaitemimportesestado , max(oveiiefechaini)  as fechafin  
          FROM  far_ordenventaitemimportesestado JOIN far_ordenventaitemimportes USING(idordenventaitemimporte, idcentroordenventaitemimporte) 		 join far_ordenventaitem using(idordenventaitem, idcentroordenventaitem )
		WHERE nullvalue(oveiiefechafin) --and far_ordenventaitem.idordenventa= 331141
		GROUP BY idordenventaitemimporte, idcentroordenventaitemimporte,idcentroordenventaitemimportesestado
		HAVING count(idordenventaitemimporte) >1
		order by idordenventaitemimporte;

     FETCH cliqestadoimporteitem into unaliquidacionimporteitem;
     WHILE FOUND LOOP
           UPDATE far_ordenventaitemimportesestado SET oveiiefechafin = unaliquidacionimporteitem.fechafin
           WHERE far_ordenventaitemimportesestado.idordenventaitemimportesaestado = unaliquidacionimporteitem.idordenventaitemimportesaestado
                 and far_ordenventaitemimportesestado.idcentroordenventaitemimportesestado = unaliquidacionimporteitem.idcentroordenventaitemimportesestado
	   	 and nullvalue(oveiiefechafin);
               FETCH cliqestadoimporteitem into unaliquidacionimporteitem;
     END LOOP;
     close cliqestadoimporteitem;




     return 'Listo';
END;$function$
