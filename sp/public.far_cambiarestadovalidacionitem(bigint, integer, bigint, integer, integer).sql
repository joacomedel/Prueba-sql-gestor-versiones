CREATE OR REPLACE FUNCTION public.far_cambiarestadovalidacionitem(bigint, integer, bigint, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	elidvalidacionitemsestado integer;
   	elidcentrovalidacionitemestado integer;
   	elidvalidacionitem bigint;
   	elidcentrovalidacionitem integer;
   	elidestado integer;
        rusuario record;

BEGIN
     elidvalidacionitemsestado =  $1;
     elidcentrovalidacionitemestado =  $2;
     elidvalidacionitem =  $3;
     elidcentrovalidacionitem =  $4;
     elidestado = $5;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


     UPDATE far_validacionitemsestado
     SET viefechafin = now()
     WHERE idvalidacionitemsestado =elidvalidacionitemsestado and idcentrovalidacionitemsestado = elidcentrovalidacionitemestado
           and nullvalue(viefechafin);

      INSERT INTO far_validacionitemsestado (idvalidacionitemsestadotipo, idvalidacionitem, idcentrovalidacionitem )
                    VALUES(elidestado,elidvalidacionitem,elidcentrovalidacionitem); 


return 'true';
END;
$function$
