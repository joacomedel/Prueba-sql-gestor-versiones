CREATE OR REPLACE FUNCTION public.far_cambiarestadoordenventa(bigint, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare

 rusuario RECORD;

begin

     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN 
              rusuario.idusuario = 25;
     END IF;

     UPDATE far_ordenventaestado SET ovefechafin= NOW() WHERE idcentroordenventa=$2 AND idordenventa=$1 AND nullvalue(ovefechafin);
     INSERT INTO far_ordenventaestado (idordenventaestadotipo,idordenventa,idcentroordenventa,oveidusuario) VALUES($3,$1,$2,rusuario.idusuario);
     return true;
end;
$function$
