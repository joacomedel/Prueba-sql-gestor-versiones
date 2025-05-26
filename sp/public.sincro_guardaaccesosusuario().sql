CREATE OR REPLACE FUNCTION public.sincro_guardaaccesosusuario()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
      

BEGIN

INSERT INTO admitemusousuariodiario(idusuario,iditem,aiuudfecha,aiuudcantidad) (
SELECT idusuario,iditem,aiuudfecha,aiuudcantidad
FROM (
SELECT usuario.idusuario,iditem,aiuudfecha,sum(aiuudcantidad::integer) as aiuudcantidad
FROM ( select usodiario as aiuudcantidad
,CAST(usodia AS DATE)  as aiuudfecha
,split_part(claveusuarioclase, '-', 1) as idusuario
,split_part(claveusuarioclase, '-', 2) as clasejava
from sincro_guardaaccesosusuario 
) as t 
JOIN usuario ON ( usuario.idusuario = t.idusuario)
JOIN admitem ON ( admitem.iclaseprincipal = t.clasejava)
GROUP BY usuario.idusuario,iditem,aiuudfecha
) as tt
WHERE (idusuario,iditem,aiuudfecha,aiuudcantidad) 
 NOT  IN (SELECT idusuario,iditem,aiuudfecha,aiuudcantidad 
         FROM admitemusousuariodiario)
);


return true;
END;
$function$
