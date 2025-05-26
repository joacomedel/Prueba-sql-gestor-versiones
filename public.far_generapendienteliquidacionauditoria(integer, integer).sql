CREATE OR REPLACE FUNCTION public.far_generapendienteliquidacionauditoria(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
BEGIN
/*Dani agrega 310523 para actualizar las tuplas donde se carga un numero no esperado en nrorecetario o centro*/
 update far_ordenventareceta set nrorecetario='', centro='' where (nrorecetario,centro) in 
    (select  nrorecetario,centro from far_ordenventareceta where  
    length(nrorecetario) >9);

INSERT INTO far_ordenventaliquidacionauditada (nroregistro,anio,idordenventaitem, idcentroordenventaitem, idordenventaitemimporte, idcentroordenventaitemimporte,idliquidacion,idcentroliquidacion,
ovlagenerarecetario,nrorecetario,centro) 
(
 SELECT rlf.numeroregistro as nroregistro,rlf.anio,
fli.idordenventaitem, fli.idcentroordenventaitem, fli.idordenventaitemimporte, fli.idcentroordenventaitemimporte
 ,fl.idliquidacion,fl.idcentroliquidacion,
	case when nullvalue(fovr.nrorecetario) AND fovr.nrorecetario = '' then false else true end as ovlagenerarecetario 
	,CAST(nullif(trim(fovr.nrorecetario), '') AS integer) as nrorecetario
	,CAST(nullif(substr(ltrim(replace(replace(fovr.centro, '-', ''), ' ', '')),0,3),'') AS integer)  as centro
 FROM far_ordenventa as fov 
 NATURAL JOIN far_ordenventaitem as fovi NATURAL JOIN far_ordenventaitemimportes as fovii 	


	
 NATURAL JOIN   far_liquidacionitemovii AS fli
 JOIN far_liquidacionitems  USING(idliquidacionitem, idcentroliquidacionitem) 	JOIN far_liquidacionitemestado as flie USING(idliquidacionitem,idcentroliquidacionitem)   
	   
 NATURAL JOIN far_liquidacion  as fl 
/*DAni agrego el 20072020*/
NATURAL JOIN far_obrasocial AS fos 
/*DAni agrego el 20072020*/
 JOIN far_configura_reporte cr ON cr.idobrasocial = fos.idobrasocial AND cr.idvalorcajacoseguro = fovii.idvalorescaja

 JOIN reclibrofact AS rlf ON  (rlf.numero =(trim(lpad(fl.idliquidacion, 8, '0'))))
 LEFT JOIN far_ordenventaliquidacionauditada as ovla 
   ON (fli.idordenventaitem=ovla.idordenventaitem AND fli.idcentroordenventaitem = ovla.idcentroordenventaitem
     AND  fli.idordenventaitemimporte=ovla.idordenventaitemimporte AND fli.idcentroordenventaitemimporte = ovla.idcentroordenventaitemimporte
AND fl.idliquidacion = ovla.idliquidacion 
   AND fl.idcentroliquidacion = ovla.idcentroliquidacion)
 LEFT JOIN far_ordenventareceta AS fovr 
      ON(fovi.idordenventa=fovr.idordenventa AND fovi.idcentroordenventa=fovr.idcentroordenventa) 		   
WHERE  rlf.numeroregistro=$1 AND  rlf.anio = $2 AND nullvalue(ovla.nroregistro)
AND  (idestadotipo=1 and nullvalue(liefechafin))
--WHERE  rlf.numeroregistro=68361 AND  rlf.anio = 2014 AND nullvalue(ovla.nroregistro)
 GROUP BY rlf.numeroregistro,rlf.anio,fl.idliquidacion,fl.idcentroliquidacion,fli.idordenventaitem, fli.idcentroordenventaitem, fli.idordenventaitemimporte, fli.idcentroordenventaitemimporte
,fovr.nrorecetario,fovr.centro


 ORDER BY fli.idordenventaitemimporte

);

return true;

END;
$function$
