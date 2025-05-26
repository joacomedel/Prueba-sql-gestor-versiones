CREATE OR REPLACE FUNCTION public.far_cambiarestadoliquidacion(bigint, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
--REGISTRO
rovliquidacion RECORD; 
rlaliquidacion RECORD;
rexistedeuda RECORD; 

--CURSOR
covliqitem refcursor;

begin

  UPDATE far_liquidacionestado SET lefechafin= NOW() 
 WHERE idliquidacion=$1 AND  idcentroliquidacion=$2  AND nullvalue(lefechafin);
  INSERT INTO far_liquidacionestado(idestadotipo,idliquidacion,idcentroliquidacion) VALUES($3,$1,$2);


/* KR 06-07-18 Todo esto se hace en los SP correspondientes, ya sea far_cancelarliquidacion o far_cerrarliquidacion. 

  IF $3=5 THEN --SI la liquidacion se cancela libero las ov para otra liquidacion 
     SELECT INTO rlaliquidacion * FROM far_liquidacion  WHERE idliquidacion=$1 AND  idcentroliquidacion=$2 ;
     IF rlaliquidacion.coseguro THEN   
       open covliqitem FOR SELECT * FROM far_liquidacionitems NATURAL JOIN far_liquidacionitemovii 
          WHERE idliquidacion=$1 AND idcentroliquidacion=$2;
	      FETCH covliqitem into rovliquidacion;
	      WHILE FOUND LOOP
                                 
                   PERFORM  far_cambiarestadoordenventaitemimporte(rovliquidacion.idordenventaitemimporte
                                         ,rovliquidacion.idcentroordenventaitemimporte,13,concat('Al cancelar liquidacion ',$1, '-',$2));
                        FETCH covliqitem into rovliquidacion;


	        END LOOP;
	    CLOSE covliqitem;
/*BORRO LOS ITEMS PARA QUE PUEDAN ESTAR EN OTRA LIQUIDACION*/
           DELETE FROM far_liquidacionitemovii 
           WHERE (idordenventaitem, idcentroordenventaitem, idordenventaitemimporte, idcentroordenventaitemimporte) 
            IN  ( SELECT idordenventaitem, idcentroordenventaitem, idordenventaitemimporte, idcentroordenventaitemimporte
                  FROM far_liquidacionitemovii NATURAL join far_liquidacionitems 
                  WHERE  idliquidacion=$1 AND idcentroliquidacion=$2);

     ELSE 
        open covliqitem FOR SELECT * FROM far_liquidacionitems NATURAL JOIN far_liquidacionitemfvc 
               WHERE idliquidacion=$1 AND idcentroliquidacion=$2;
	    FETCH covliqitem into rovliquidacion;
	    WHILE FOUND LOOP 
			 PERFORM  far_cambiarestadofacturaventacupon(rovliquidacion.idfacturacupon,rovliquidacion.centro,rovliquidacion.nrofactura,
                           rovliquidacion.tipocomprobante,rovliquidacion.nrosucursal,rovliquidacion.tipofactura,13,concat('Al cancelar liquidacion ',$1, '-',$2));
                        FETCH covliqitem into rovliquidacion;
	    END LOOP;
	    CLOSE covliqitem;
     END IF;
    /*SI la liquidacion se cierra GENERo la LI*/
   
  END IF;


  SELECT INTO rexistedeuda * FROM informefacturacionliqfarmacia NATURAL JOIN informefacturacion JOIN ctactedeudacliente 
                             ON (idcomprobante=nroinforme * 100 + idcentroinformefacturacion)
                             WHERE idliquidacion = $1 AND idcentroliquidacion=$2;
 
  IF not FOUND AND $3=2  THEN /*KR 22-08 la deuda NO existe */   
         PERFORM far_asentarfacturaliquidacion($1,$2);
  END IF; 
*/

  return true;
end;
$function$
