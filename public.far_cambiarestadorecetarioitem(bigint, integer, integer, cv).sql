CREATE OR REPLACE FUNCTION public.far_cambiarestadorecetarioitem(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	elidrecetarioitem integer;
   	elidcentrorecetarioitem integer;
   	elidestado integer;
        larazon varchar;


BEGIN
     elidrecetarioitem =  $1;
     elidcentrorecetarioitem =  $2;
     elidestado = $3;
     larazon = $4;



     UPDATE recetarioitemestado      
     SET riefechafin = now()
     WHERE idrecetarioitem =elidrecetarioitem
            AND idcentrorecetarioitem = elidcentrorecetarioitem AND nullvalue(riefechafin);

      
     INSERT INTO recetarioitemestado(idrecetarioitem,idcentrorecetarioitem,idtipocambioestado, riedescripcion) 
    VALUES (elidrecetarioitem, elidcentrorecetarioitem, $3,larazon);

return 'true';
END;
$function$
