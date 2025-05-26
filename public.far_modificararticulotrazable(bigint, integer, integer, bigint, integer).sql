CREATE OR REPLACE FUNCTION public.far_modificararticulotrazable(bigint, integer, integer, bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
  rlaorden RECORD;

--VARIABLES
  resp BOOLEAN;
        
BEGIN

  resp = true;
         
  SELECT INTO rlaorden nrodoc, tipodoc, idobrasocial 
               FROM far_ordenventaitem natural join far_ordenventa join far_afiliado using(idafiliado)
                   WHERE idordenventaitem = $1 AND idcentroordenventaitem = $2;
            

  UPDATE far_articulotrazabilidad SET idordenventaitem= $1,idcentroordenventaitem=$2, 
                        idobrasocial=rlaorden.idobrasocial, nrodoc=rlaorden.nrodoc, tipodoc=rlaorden.tipodoc
                   WHERE idarticulotraza = $4 AND idcentroarticulotraza = $5;
      
  SELECT INTO resp * FROM far_modificararticulotrazabilidadestado($4, $5,$3, concat('Se vende el articulo trazable. Item ','|',  $1, '|' ,$2));

 RETURN resp;     
END;$function$
