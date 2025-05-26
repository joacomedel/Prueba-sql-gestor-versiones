CREATE OR REPLACE FUNCTION ca.antiguedadlaboral(integer, date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elidpersona INTEGER;
       lafecha date;
       aniosaniguedad INTEGER;
BEGIN
elidpersona =$1;
lafecha = $2;
SELECT INTO aniosaniguedad  CASE  WHEN extract(YEAR from age(to_timestamp(concat(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),
               emfechainicioantiguedad)) >=1
                        THEN extract(YEAR FROM age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),
         emfechainicioantiguedad) )+1

      WHEN ( extract(YEAR from age(concat( to_timestamp(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),
              emfechainicioantiguedad)) =0 and  extract(MONTH from age( concat(to_timestamp(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),emfechainicioantiguedad)) >= 6  )
         THEN 1
         ELSE 0
         END as anios 
FROM ca.empleado
WHERE idpersona = elidpersona;




return aniosaniguedad;
END;
$function$
