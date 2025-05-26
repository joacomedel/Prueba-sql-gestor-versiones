CREATE OR REPLACE FUNCTION public.crearliquidacionestadoitem(idliquidacionaux bigint, idcentroliquidacionaux integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   
   
  salida Boolean =false;
 cursorliquidacionitem refcursor;
  rregistroaux RECORD;


BEGIN


 OPEN cursorliquidacionitem for select * from far_liquidacion JOIN far_liquidacionitems as fli USING(idliquidacion,idcentroliquidacion) where idliquidacion=idliquidacionaux and idcentroliquidacion=idcentroliquidacionaux;






FETCH cursorliquidacionitem into rregistroaux;

WHILE FOUND LOOP
            INSERT INTO far_liquidacionitemestado
                 (liefechaini,liefechafin,idestadotipo,idliquidacionitem,idcentroliquidacionitem,liedescripcion)
                 VALUES(now(),null,1,rregistroaux.idliquidacionitem,rregistroaux.idcentroliquidacion,'estado creado desde sp crearliquidacionestadoitem');


       salida=true;

    FETCH cursorliquidacionitem into rregistroaux;

END LOOP;
CLOSE cursorliquidacionitem;












return salida;   

END;
$function$
