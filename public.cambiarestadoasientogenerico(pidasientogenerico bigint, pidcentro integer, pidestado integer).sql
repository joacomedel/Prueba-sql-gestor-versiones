CREATE OR REPLACE FUNCTION public.cambiarestadoasientogenerico(pidasientogenerico bigint, pidcentro integer, pidestado integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$begin
     UPDATE asientogenericoestado SET agefechafin= NOW() WHERE idasientogenerico=$1 AND idcentroasientogenerico=$2 AND nullvalue(agefechafin);
     INSERT INTO asientogenericoestado (tipoestadofactura,idasientogenerico,idcentroasientogenerico) VALUES($3,$1,$2);
     return true;
end;$function$
