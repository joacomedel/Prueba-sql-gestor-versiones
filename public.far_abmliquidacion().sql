CREATE OR REPLACE FUNCTION public.far_abmliquidacion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
cursorov CURSOR FOR SELECT * FROM tfar_liqitem;
rliquidacion RECORD;
esnot VARCHAR DEFAULT 'WHERE ';
ridliquidacionitems integer;

BEGIN


 OPEN cursorov;
    FETCH cursorov into rliquidacion;
    WHILE  found LOOP

        IF nullvalue(rliquidacion.idliquidacion) THEN --no existe la liquidacion

       
         INSERT INTO  far_liquidacion (lidescripcion,idobrasocial,lfechadesde,lfechahasta,pcporcentaje)
                        ( SELECT concat(' Fechas ' ,rliquidacion.lfechadesde , ' - '  ,  rliquidacion.lfechahasta , '. Liquidacion de obra social '
                          , osdescripcion , ' plan '  , pcporcentaje  ),
                          idobrasocial,rliquidacion.lfechadesde,
                          rliquidacion.lfechahasta,pcporcentaje 
                          FROM tfar_liqitem   NATURAL JOIN far_obrasocial
                         );
         rliquidacion.idliquidacion = currval('far_liquidacion_idliquidacion_seq'::regclass);
         rliquidacion.idcentroliquidacion = centro();
         INSERT INTO far_liquidacionestado(idestadotipo,idliquidacion)   VALUES(1,rliquidacion.idliquidacion);
             
         --IF (rliquidacion.enlinea) THEN 
          
              PERFORM  far_cambiarestadoordenventaitemimporte( idordenventaitemimporte
                                         ,idcentroordenventaitemimporte,15,concat('Al generar liquidacion ',rliquidacion.idliquidacion ,'-' ,centro())) as x,
                  idordenventaitemimporte,idcentroordenventaitemimporte
                 FROM ( SELECT idordenventaitemimporte,idcentroordenventaitemimporte
                        FROM far_ordenventa as o   NATURAL  JOIN far_ordenventaitem as fovi 
                        NATURAL JOIN far_ordenventaitemimportes as fovii  
                        JOIN far_configura_reporte as cr ON fovii.idvalorescaja = idvalorcajacoseguro  
                        JOIN facturaorden as fo on o.idordenventa = fo.nroorden and idcentroordenventa = fo.centro NATURAL JOIN facturaventa fv   
                        LEFT JOIN far_ordenventaitemimportesestado  AS oviie  USING(idordenventaitemimporte,idcentroordenventaitemimporte) 
                        LEFT JOIN far_validacion USING(idvalidacion,idcentrovalidacion)   
                        LEFT JOIN far_validacionxml  ON(far_validacion.idvalidacion=far_validacionxml.idvalidacionxml 
                        AND  far_validacion.idcentrovalidacion=far_validacionxml.idcentrovalidacionxml)  
                    WHERE (not nullvalue(vcadenaxml) = rliquidacion.enlinea OR  not cr.crseparavalidacion )
  
                     AND nullvalue(anulada)   AND  idobrasocial = rliquidacion.idobrasocial 
                     AND (oviiporcentajecobertura = rliquidacion.pcporcentaje or 0.0=rliquidacion.pcporcentaje)    
                     AND ((NULLVALUE(oviie.idordenventaestadotipo) AND fechaemision >= rliquidacion.lfechadesde AND 
                  fechaemision <=  rliquidacion.lfechahasta  )OR  (oviie.idordenventaestadotipo=13 and nullvalue(oviie.oveiiefechafin)))   

                  ) as t  
                 WHERE true;
        
        
        ELSE --la liquidacion ya existe
           
            PERFORM  far_cambiarestadoordenventaitemimporte(rliquidacion.idordenventaitemimporte
             ,rliquidacion.idcentroordenventaitemimporte,14,concat('Al ingresar el cupon a liquidacion ',rliquidacion.idliquidacion ,'-',centro()));
-- FROM tfar_liqitem;
           
             INSERT INTO far_liquidacionitems(idliquidacion ,idcentroliquidacion)VALUES(rliquidacion.idliquidacion ,rliquidacion.idcentroliquidacion);
             
             INSERT INTO far_liquidacionitemovii(idliquidacionitem,idcentroliquidacionitem,idordenventaitem,idcentroordenventaitem, idordenventaitemimporte
             ,idcentroordenventaitemimporte)   
              VALUES(currval('far_liquidacionitems_idliquidacionitem_seq'::regclass), centro(),rliquidacion.idordenventaitem,rliquidacion.idcentroordenventaitem,rliquidacion.idordenventaitemimporte,rliquidacion.idcentroordenventaitemimporte);

/* recuperar ultimo movimiento*/
ridliquidacionitems =currval('far_liquidacionitems_idliquidacionitem_seq');
                        

/*inserta el estado de el item de la liquidacion*/

         /*   INSERT INTO far_liquidacionitemestado(idcentroliquidacionitem,idliquidacionitem,
liefechaini,liefechafin,idestadotipo,liedescripcion)   
              VALUES(centro(),ridliquidacionitems,
now(),null,rliquidacion.idestadotipo,rliquidacion.liedescripcion);
          */
--KR 28-06-18 modifique para que guarde el estado actual y modifique el anterior.
         PERFORM  far_cambiarestadoliquidacionitem(ridliquidacionitems, centro(), rliquidacion.idestadotipo, concat(rliquidacion.liedescripcion, 'Desde SP far_abmliquidacion'));

        END IF;
     fetch cursorov into rliquidacion;
        
  END LOOP;
  CLOSE cursorov;

   


return true;
END;
$function$
