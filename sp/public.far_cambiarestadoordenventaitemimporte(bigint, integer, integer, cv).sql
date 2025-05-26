CREATE OR REPLACE FUNCTION public.far_cambiarestadoordenventaitemimporte(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare



begin 
     UPDATE far_ordenventaitemimportesestado SET oveiiefechafin= NOW()
     WHERE idordenventaitemimporte=$1 AND  idcentroordenventaitemimporte=$2  AND nullvalue(oveiiefechafin);
     INSERT INTO far_ordenventaitemimportesestado (idordenventaestadotipo,idordenventaitemimporte,idcentroordenventaitemimporte
     ,oviiedescripcion) VALUES($3,$1,$2,$4);
     return true;
end;
$function$
