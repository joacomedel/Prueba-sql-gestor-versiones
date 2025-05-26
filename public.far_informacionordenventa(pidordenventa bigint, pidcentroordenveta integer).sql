CREATE OR REPLACE FUNCTION public.far_informacionordenventa(pidordenventa bigint, pidcentroordenveta integer)
 RETURNS SETOF type_far_informacionordenventa
 LANGUAGE sql
AS $function$--SELECT * FROM type_far_informacionordenventa;
SELECT case when nullvalue(fovr.regalo) THEN false ELSE true END as esregalo 
,case when nullvalue(fovv.vale) THEN false ELSE true END as esvale
,case when nullvalue(coberturas.cob) THEN '0' ELSE coberturas.cob END as cob
,fov.idordenventa
,fov.idcentroordenventa
FROM far_ordenventa fov
LEFT JOIN (
SELECT idordenventa,idcentroordenventa,text_concatenar(concat(idvalorescaja,'-',lfdescripcion,'|')) as cob
 FROM  (SELECT DISTINCT idordenventa,idcentroordenventa,idvalorescaja
 FROM  far_ordenventaitem
NATURAL JOIN far_ordenventaitemimportes
WHERE idordenventa = pidordenventa AND idcentroordenventa = pidcentroordenveta  AND idvalorescaja  > 0
ORDER BY idvalorescaja) as t
NATURAL JOIN liquidadorfiscalvalorescaja 
GROUP BY idordenventa,idcentroordenventa

) as coberturas USING(idordenventa,idcentroordenventa)

LEFT JOIN (
SELECT DISTINCT idordenventa,idcentroordenventa,true as regalo
FROM  far_ordenventaitem as fovi
JOIN far_ordenventaitemvaleregalo as fovr ON fovr.idordenventaitemoriginal = fovi.idordenventaitem AND fovr.idcentroordenventaitemoriginal = fovi.idcentroordenventaitem	
WHERE idordenventa = pidordenventa AND idcentroordenventa = pidcentroordenveta  
) as fovr USING(idordenventa,idcentroordenventa)


LEFT JOIN (
SELECT DISTINCT idordenventa,idcentroordenventa,true as vale
FROM  far_ordenventaitem as fovi
JOIN far_ordenventaitemvale as fovv ON fovv.idordenventaitemoriginal = fovi.idordenventaitem
                                                  AND fovv.idcentroordenventaitemoriginal = fovi.idcentroordenventaitem	
WHERE idordenventa = pidordenventa AND idcentroordenventa = pidcentroordenveta   
) as fovv USING(idordenventa,idcentroordenventa)
WHERE idordenventa = pidordenventa AND idcentroordenventa = pidcentroordenveta 
--idordenventa = 210605 --coberturas
-- idordenventa = 218462 --vale 
--idordenventa  = 218834 -- regalo

$function$
