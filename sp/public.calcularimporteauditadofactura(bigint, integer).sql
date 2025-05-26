CREATE OR REPLACE FUNCTION public.calcularimporteauditadofactura(bigint, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE

elem RECORD;
-- $1  nroregistro
-- $2: anio

--cursor con los datos que se deben cargar en la tabla del nuevo informe
ordenfac CURSOR FOR SELECT nroorden,centro FROM facturaordenesutilizadas WHERE nroregistro=$1 and anio=$2;
regordenfac RECORD;
regimporden RECORD; 
sumimportetotal float;
sumimporte float;


BEGIN

sumimportetotal = 0;

open ordenfac;
FETCH ordenfac INTO regordenfac;
WHILE FOUND LOOP

SELECT  INTO regimporden sum(CASE WHEN nullvalue(fmpaiimportetotal) THEN importe ELSE fmpaiimportetotal END) as importe
,sum(fmpaiimportes) AS imptotal

  FROM 
   (SELECT sum(importe) as importe,nroorden,centro 
                    FROM importesorden 
                    WHERE nroorden =regordenfac.nroorden 
                         AND centro = regordenfac.centro
             GROUP BY nroorden,centro 
   ) as importesorden 
    
    LEFT JOIN (SELECT * FROM  fichamedicapreauditada   NATURAL JOIN (
                              SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada  FROM 
                              fichamedicapreauditadaitemconsulta
                              UNION
                              SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
                              FROM fichamedicapreauditadaitem  
                              NATURAL JOIN itemvalorizada   ) as ordenes
               ) auditada
    USING(nroorden,centro)
  WHERE nroorden =regordenfac.nroorden AND centro = regordenfac.centro;

  UPDATE ordenesutilizadas SET importe = regimporden.imptotal WHERE nroorden =regordenfac.nroorden AND centro = regordenfac.centro;



sumimportetotal = sumimportetotal + regimporden.importe; 
FETCH ordenfac INTO regordenfac;
END LOOP;
CLOSE ordenfac;

return sumimportetotal;
END;
$function$
