CREATE OR REPLACE FUNCTION public.obtenerdatosfichamedicaauditada(bigint, integer, bigint, character varying, character varying, character varying)
 RETURNS SETOF type_fichamedicaauditada
 LANGUAGE sql
AS $function$
/*$1 nroorden, $2 centro, $3 idasocconv,$4 categoria, $5 categoriaapagar,$6 esOdonto*/
SELECT 
	 fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,orden.nroorden,itemmodificado.tipo, orden.centro, nombres, apellido,idfichamedicapreauditada,idcentrofichamedicapreauditada 
	,  iditem, cantidad,importeitem 
	,concat(idnomenclador , '.' , idcapitulo , '.' , idsubcapitulo , '.' , idpractica) as practica,idnomenclador
	,idcapitulo,idsubcapitulo,idpractica ,cobertura,fechaemision,idasocconv,itemmodificado.malcance 
	,itemmodificado.nromatricula,itemmodificado.mespecialidad,idplancovertura,auditada,pdescripcion,nrodoc,tipodoc 
	,idprestador,fechauso,case when nullvalue(ordenestados.nroorden) then FALSE    ELSE TRUE    END AS anulada,nrodocuso,tipodoc as tipodocuso 
	, importepv, idasocconvord,importexcategoria, importexcategoriaant as anteriorvalorcategoria 
        ,iimportexcategoriaapagar,idpiezadental, idletradental, idzonadental	,fmpacantidad 
	,CASE WHEN nullvalue(idfichamedicapreauditada) THEN  false ELSE true END as extendida
	,idprestadorotro::bigint 
        
	
	 FROM  orden 
	 NATURAL JOIN  consumo 
	 NATURAL JOIN persona 
	 LEFT JOIN ( 
	     SELECT fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,idfichamedicapreauditada,idcentrofichamedicapreauditada
         ,fpa.nroorden,cantidad,iditem
		  ,importeitem,fmpacantidad 
		  ,fpa.idnomenclador 
		  ,fpa.idcapitulo 
		  ,fpa.idsubcapitulo 
		  ,fpa.idpractica 
		  ,fpa.centro,fpa.cobertura,fpa.pdescripcion 
		  ,fpa.malcance,fpa.nromatricula,fpa.mespecialidad,idplancovertura,auditada 
		  ,practicavalores.importe as importepv, fpa.idasocconvord
                  ,fpa.tipo,pvc.importe as importexcategoria,pvch.importe as importexcategoriaant 
		  ,pvcapagar.importe as iimportexcategoriaapagar
		  ,idpiezadental, idletradental, idzonadental
                  ,null as idprestadorotro   


		   FROM 
		   ( -- Ordenes con practicas
		    SELECT fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,idfichamedicapreauditada,idcentrofichamedicapreauditada 
		  ,orden.nroorden,cantidad,item.iditem, importe as importeitem,fmpacantidad
		  ,CASE WHEN nullvalue(a.idnomenclador) THEN item.idnomenclador ELSE a.idnomenclador END as idnomenclador 
		  ,CASE WHEN nullvalue(a.idcapitulo) THEN item.idcapitulo ELSE a.idcapitulo END as idcapitulo 
		  ,CASE WHEN nullvalue(a.idsubcapitulo) THEN item.idsubcapitulo ELSE a.idsubcapitulo END as idsubcapitulo 
		  ,CASE WHEN nullvalue(a.idpractica) THEN item.idpractica ELSE a.idpractica END as idpractica 
		  ,orden.centro,cobertura,pdescripcion 
		  ,ordvalorizada.malcance,ordvalorizada.nromatricula,ordvalorizada.mespecialidad,idplancovertura,auditada 
		  ,idasocconv as idasocconvord,orden.tipo,idpiezadental, idletradental, idzonadental
		   FROM ordvalorizada  NATURAL JOIN orden      NATURAL JOIN itemvalorizada            NATURAL JOIN item    
		  LEFT JOIN ordenodonto ON(itemvalorizada.nroorden =ordenodonto.nroorden AND itemvalorizada.centro=ordenodonto.centro AND itemvalorizada.iditem=ordenodonto.iditem)
		
		   LEFT JOIN fichamedicapreauditadaitem 
                   ON(itemvalorizada.iditem = fichamedicapreauditadaitem.iditem AND itemvalorizada.centro=fichamedicapreauditadaitem.centro AND itemvalorizada.nroorden=fichamedicapreauditadaitem.nroorden)

			LEFT JOIN fichamedicapreauditada as a USING(idcentrofichamedicapreauditada,idfichamedicapreauditada) 
				LEFT JOIN fichamedica USING(idfichamedica,idcentrofichamedica) 
		   LEFT JOIN practica ON (CASE WHEN nullvalue(a.idnomenclador) THEN item.idnomenclador ELSE a.idnomenclador END = practica.idnomenclador 
			    AND CASE WHEN nullvalue(a.idcapitulo) THEN item.idcapitulo ELSE a.idcapitulo END = practica.idcapitulo 
			    AND CASE WHEN nullvalue(a.idsubcapitulo) THEN item.idsubcapitulo ELSE a.idsubcapitulo END = practica.idsubcapitulo 
			    AND CASE WHEN nullvalue(a.idpractica) THEN item.idpractica ELSE a.idpractica END = practica.idpractica ) 
			   ) as  fpa  				
			      LEFT JOIN practicavalores ON( case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END =practicavalores.idasocconv AND 
								 fpa.idnomenclador=practicavalores.idsubespecialidad 
					      AND fpa.idcapitulo=practicavalores.idcapitulo 
					     AND fpa.idsubcapitulo=practicavalores.idsubcapitulo 
					      AND  fpa.idpractica=practicavalores.idpractica) 
						  LEFT JOIN  practicavaloresxcategoria as pvc ON(  case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END =pvc.idasocconv AND 
						       fpa.idnomenclador=pvc.idsubespecialidad 
				  AND fpa.idcapitulo=pvc.idcapitulo 
				  AND fpa.idsubcapitulo=pvc.idsubcapitulo 
						  AND fpa.idpractica=pvc.idpractica 
						  AND pvc.pcategoria = $4) 
						LEFT JOIN  practicavaloresxcategoriahistorico as pvch ON(  case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END  =pvch.idasocconv AND 
						       fpa.idnomenclador=pvch.idsubespecialidad 
					  AND fpa.idcapitulo=pvch.idcapitulo 
				  AND fpa.idsubcapitulo=pvch.idsubcapitulo
						  AND  fpa.idpractica=pvch.idpractica 
						  AND pvch.pcategoria = $4 AND nullvalue(pvxchfechafin)) 
						LEFT JOIN  practicavaloresxcategoria as pvcapagar ON(  case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END  =pvcapagar.idasocconv AND 
						       fpa.idnomenclador=pvcapagar.idsubespecialidad 
						  AND fpa.idcapitulo=pvcapagar.idcapitulo 
				  AND fpa.idsubcapitulo=pvcapagar.idsubcapitulo 
						  AND  fpa.idpractica=pvcapagar.idpractica 
						  AND pvcapagar.pcategoria = $5 ) 
					WHERE nroorden=  $1     AND centro =   $2
		 UNION
--Para Recetarios
		 SELECT fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,idfichamedicapreauditada,idcentrofichamedicapreauditada,nroorden,1 as cantidad, iditem   
			 ,importeitem,fmpacantidad   
			 ,fpa.idnomenclador 
			 ,fpa.idcapitulo 
			 ,fpa.idsubcapitulo 
			 ,fpa.idpractica 
			 ,centro,null as cobertura,pdescripcion   
			 ,null as malcance,null as nromatricula, null as mespecialidad,idplancovertura,false as auditada   
			 ,practicavalores.importe as importepv, fpa.idasocconvord
                         ,fpa.tipo
			 ,pvc.importe as importexcategoria,pvch.importe as importexcategoriaant
			 ,pvcapagar.importe as iimportexcategoriaapagar
			 ,null as idpiezadental,null as idletradental, null as idzonadental
                         ,idprestadorotro
			FROM
			 (
			  SELECT fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,idfichamedicapreauditada,idcentrofichamedicapreauditada,nroorden,1 as cantidad,idrecetarioitem as iditem 
				   ,importe as importeitem,fmpacantidad 
			           ,CASE WHEN nullvalue(a.idnomenclador) THEN practica.idnomenclador ELSE a.idnomenclador END as idnomenclador 
			           ,CASE WHEN nullvalue(a.idcapitulo) THEN practica.idcapitulo ELSE a.idcapitulo END as idcapitulo 
				   ,CASE WHEN nullvalue(a.idsubcapitulo) THEN practica.idsubcapitulo ELSE a.idsubcapitulo END as idsubcapitulo 
				   ,CASE WHEN nullvalue(a.idpractica) THEN practica.idpractica ELSE a.idpractica END as idpractica 
				   ,imporden.centro,null as cobertura,pdescripcion 
				   ,null as malcance,null as nromatricula, null as mespecialidad,idplancovertura,false as auditada 
				   ,idasocconv as idasocconvord,imporden.tipo,idprestadorotro 
				  FROM ( SELECT nrorecetario as nroorden,recetario.centro,idplancovertura,idrecetarioitem,idcentrorecetarioitem,idasocconv,CASE WHEN (tipo = 4 OR tipo=53) THEN 14 ELSE tipo END as tipo,importe, idprestador as idprestadorotro 
				  FROM recetario
                                  LEFT JOIN recetarioitem USING(nrorecetario,centro) 
				  LEFT JOIN orden ON nrorecetario = nroorden AND recetario.centro = orden.centro
				  WHERE nrorecetario=  $1 AND recetario.centro = $2
						  
						  ) as imporden 
				   LEFT JOIN  fichamedicapreauditadaitemrecetario USING(idrecetarioitem,idcentrorecetarioitem,centro) 
				   LEFT JOIN fichamedicapreauditada as a USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
				   LEFT JOIN fichamedica USING(idfichamedica,idcentrofichamedica) 
				   LEFT JOIN practica ON (CASE WHEN nullvalue(a.idnomenclador) THEN '98' ELSE a.idnomenclador END = practica.idnomenclador 
					  AND CASE WHEN nullvalue(a.idcapitulo) THEN '01' ELSE a.idcapitulo END = practica.idcapitulo 
						     AND CASE WHEN nullvalue(a.idsubcapitulo) THEN '01' ELSE a.idsubcapitulo END = practica.idsubcapitulo 
						     AND CASE WHEN nullvalue(a.idpractica) THEN '01' ELSE a.idpractica END = practica.idpractica ) 
						) as fpa 
				  LEFT JOIN practicavalores 
								ON( case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END  =practicavalores.idasocconv AND fpa.idnomenclador=practicavalores.idsubespecialidad  AND fpa.idcapitulo=practicavalores.idcapitulo 
								AND fpa.idsubcapitulo=practicavalores.idsubcapitulo  AND fpa.idpractica=practicavalores.idpractica) 	
				  LEFT JOIN  practicavaloresxcategoria as pvc ON(case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END  =pvc.idasocconv AND
								       pvc.idsubespecialidad = fpa.idnomenclador
								   AND pvc.idcapitulo =fpa.idcapitulo  AND pvc.idsubcapitulo = fpa.idsubcapitulo
								  AND  pvc.idpractica = fpa.idpractica 
								  AND pvc.pcategoria = $4) 
				  LEFT JOIN  practicavaloresxcategoriahistorico as pvch ON(  case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END  =pvch.idasocconv AND
								       pvch.idsubespecialidad = fpa.idnomenclador 
							   AND pvch.idcapitulo = fpa.idcapitulo  AND pvch.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch.idpractica = fpa.idpractica 
								  AND pvch.pcategoria = $4 AND nullvalue(pvxchfechafin))
				  LEFT JOIN  practicavaloresxcategoria as pvcapagar ON(  case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END =pvcapagar.idasocconv AND 
					       fpa.idnomenclador=pvcapagar.idsubespecialidad 
						  AND fpa.idcapitulo=pvcapagar.idcapitulo
				  AND fpa.idsubcapitulo=pvcapagar.idsubcapitulo 
						  AND  fpa.idpractica=pvcapagar.idpractica 
						  AND pvcapagar.pcategoria = $5 ) 
				WHERE nroorden=  $1 AND centro =   $2
		 UNION
-- Para obtener consultas
		 SELECT fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,idfichamedicapreauditada,idcentrofichamedicapreauditada,nroorden,1 as cantidad,null as iditem   
			 ,importeitem,fmpacantidad   
			 ,fpa.idnomenclador 
			 ,fpa.idcapitulo 
			 ,fpa.idsubcapitulo 
			 ,fpa.idpractica 
			 ,centro,null as cobertura,pdescripcion   
			 ,null as malcance,null as nromatricula, null as mespecialidad,idplancovertura,false as auditada   
			 ,practicavalores.importe as importepv, fpa.idasocconvord
                         ,fpa.tipo
			 ,pvc.importe as importexcategoria,pvch.importe as importexcategoriaant
			 ,pvcapagar.importe as iimportexcategoriaapagar
			,null as idpiezadental,null as idletradental, null as idzonadental
                        ,null as idprestadorotro 
			FROM
			 (
			  SELECT fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,idfichamedicapreauditada,idcentrofichamedicapreauditada,nroorden,1 as cantidad,null as iditem 
				   ,importeitem,fmpacantidad 
					      ,CASE WHEN nullvalue(a.idnomenclador) THEN practica.idnomenclador ELSE a.idnomenclador END as idnomenclador 
					   ,CASE WHEN nullvalue(a.idcapitulo) THEN practica.idcapitulo ELSE a.idcapitulo END as idcapitulo 
						   ,CASE WHEN nullvalue(a.idsubcapitulo) THEN practica.idsubcapitulo ELSE a.idsubcapitulo END as idsubcapitulo 
						   ,CASE WHEN nullvalue(a.idpractica) THEN practica.idpractica ELSE a.idpractica END as idpractica 
					   ,centro,null as cobertura,pdescripcion 
						   ,null as malcance,null as nromatricula, null as mespecialidad,idplancovertura,false as auditada 
					   ,idasocconv as idasocconvord, orden.tipo
						    FROM ordconsulta 
						    NATURAL JOIN orden 
						    NATURAL JOIN (SELECT sum(importe) as importeitem,nroorden,centro 
						  FROM importesorden 
						   WHERE nroorden=  $1 AND centro = $2
						  GROUP BY nroorden,centro 
						  ) as imporden 
				   LEFT JOIN  fichamedicapreauditadaitemconsulta USING(nroorden,centro) 
				   LEFT JOIN fichamedicapreauditada as a USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
				   LEFT JOIN fichamedica USING(idfichamedica,idcentrofichamedica) 
				   LEFT JOIN practica ON (CASE WHEN nullvalue(a.idnomenclador) THEN CASE WHEN nullvalue($6) THEN '12' ELSE '14' END ELSE a.idnomenclador END = practica.idnomenclador 
					  AND CASE WHEN nullvalue(a.idcapitulo) THEN CASE WHEN nullvalue($6) THEN '42' ELSE '01' END  ELSE a.idcapitulo END = practica.idcapitulo 
						     AND CASE WHEN nullvalue(a.idsubcapitulo) THEN '01' ELSE a.idsubcapitulo END = practica.idsubcapitulo 
                           AND CASE WHEN nullvalue(a.idpractica) THEN CASE WHEN nullvalue($6) THEN '01' ELSE '00' END ELSE a.idpractica 
                              END = practica.idpractica 

 ) 
						) as fpa 
				  LEFT JOIN practicavalores 
								ON(  case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END  =practicavalores.idasocconv AND fpa.idnomenclador=practicavalores.idsubespecialidad  AND fpa.idcapitulo=practicavalores.idcapitulo 
								AND fpa.idsubcapitulo=practicavalores.idsubcapitulo  AND fpa.idpractica=practicavalores.idpractica) 	
				  LEFT JOIN  practicavaloresxcategoria as pvc ON(case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END  =pvc.idasocconv AND
								       pvc.idsubespecialidad = fpa.idnomenclador
								   AND pvc.idcapitulo =fpa.idcapitulo  AND pvc.idsubcapitulo = fpa.idsubcapitulo
								  AND  pvc.idpractica = fpa.idpractica 
								  AND pvc.pcategoria = $4) 
				  LEFT JOIN  practicavaloresxcategoriahistorico as pvch ON(  case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END  =pvch.idasocconv AND
								       pvch.idsubespecialidad = fpa.idnomenclador 
							   AND pvch.idcapitulo = fpa.idcapitulo  AND pvch.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch.idpractica = fpa.idpractica 
								  AND pvch.pcategoria = $4 AND nullvalue(pvxchfechafin))
				  LEFT JOIN  practicavaloresxcategoria as pvcapagar ON(  case when not nullvalue($3) then $3    ELSE fpa.idasocconvord END =pvcapagar.idasocconv AND 
					       fpa.idnomenclador=pvcapagar.idsubespecialidad 
						  AND fpa.idcapitulo=pvcapagar.idcapitulo
				  AND fpa.idsubcapitulo=pvcapagar.idsubcapitulo 
						  AND  fpa.idpractica=pvcapagar.idpractica 
						  AND pvcapagar.pcategoria = $5 ) 
				WHERE nroorden=  $1 AND centro =   $2
		) as itemmodificado USING(nroorden,centro) 

LEFT JOIN ordenestados on(ordenestados.nroorden=orden.nroorden and ordenestados.centro=orden.centro) 
LEFT JOIN ordenesutilizadas ON(orden.nroorden =ordenesutilizadas.nroorden  AND orden.centro=ordenesutilizadas.centro AND 
case when itemmodificado.tipo<>14 THEN orden.tipo ELSE 14 END =ordenesutilizadas.tipo ) 
WHERE orden.nroorden= $1 AND orden.centro =  $2;
$function$
