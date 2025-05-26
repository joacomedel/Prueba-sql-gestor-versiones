CREATE OR REPLACE FUNCTION public.obtenerdatosfichamedicaauditada_masvalores__(pnroorden bigint, pcentro integer, pidasocconv bigint, paramcategoria character varying, pcategoriaapagar character varying, pesodonto character varying)
 RETURNS SETOF type_fichamedicaauditadamasvalores
 LANGUAGE sql
AS $function$

/*pnroorden nroorden, pcentro centro, pidasocconv idasocconv,paramcategoria categoria, pcategoriaapagar categoriaapagar,pesodonto esOdonto*/
SELECT 
	 fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,orden.nroorden,itemmodificado.tipo, orden.centro, nombres, apellido,idfichamedicapreauditada,idcentrofichamedicapreauditada 
	,  iditem, cantidad,importeitem 
	,concat(idnomenclador , '.' , idcapitulo , '.' , idsubcapitulo , '.' , idpractica) as practica,idnomenclador
	,idcapitulo,idsubcapitulo,idpractica ,cobertura,fechaemision,idasocconv,itemmodificado.malcance 
	,itemmodificado.nromatricula,itemmodificado.mespecialidad,idplancovertura,auditada,pdescripcion,nrodoc,tipodoc 
	,idprestador,fechauso,case when nullvalue(ordenestados.nroorden) then FALSE    ELSE TRUE    END AS anulada,nrodocuso,tipodoc as tipodocuso 
	, importepv, idasocconvord,importexcategoria, importexcategorihistuno,importexcategorihistdos,importexcategorihisttres
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
                  ,fpa.tipo,pvc.importe as importexcategoria
		 
		   ,pvch1.importe as importexcategorihistuno
		   ,pvch2.importe as importexcategorihistdos
		   ,pvch3.importe as importexcategorihisttres
		 
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
			      LEFT JOIN practicavalores ON( case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END =practicavalores.idasocconv AND 
								 fpa.idnomenclador=practicavalores.idsubespecialidad 
					      AND fpa.idcapitulo=practicavalores.idcapitulo 
					     AND fpa.idsubcapitulo=practicavalores.idsubcapitulo 
					      AND  fpa.idpractica=practicavalores.idpractica) 
						  LEFT JOIN  practicavaloresxcategoria as pvc ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END =pvc.idasocconv AND 
						       fpa.idnomenclador=pvc.idsubespecialidad 
				  AND fpa.idcapitulo=pvc.idcapitulo 
				  AND fpa.idsubcapitulo=pvc.idsubcapitulo 
						  AND fpa.idpractica=pvc.idpractica 
						  AND pvc.pcategoria = paramcategoria) 
				  LEFT JOIN  practicavaloresxcategoriahistorico as pvch1 ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch1.idasocconv AND
								       pvch1.idsubespecialidad = fpa.idnomenclador 
							   AND pvch1.idcapitulo = fpa.idcapitulo  
 								AND pvch1.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch1.idpractica = fpa.idpractica 
								  AND pvch1.pcategoria = paramcategoria AND pvch1.pvxchordenhistorico = 1)
		          LEFT JOIN  practicavaloresxcategoriahistorico as pvch2 ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch2.idasocconv AND
								       pvch2.idsubespecialidad = fpa.idnomenclador 
							   AND pvch2.idcapitulo = fpa.idcapitulo  
                                AND pvch2.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch2.idpractica = fpa.idpractica 
								  AND pvch2.pcategoria = paramcategoria AND pvch2.pvxchordenhistorico = 2 )
		           LEFT JOIN  practicavaloresxcategoriahistorico as pvch3 ON (  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch3.idasocconv AND
								       pvch3.idsubespecialidad = fpa.idnomenclador 
							   AND pvch3.idcapitulo = fpa.idcapitulo  
								AND pvch3.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch3.idpractica = fpa.idpractica 
								  AND pvch3.pcategoria = paramcategoria AND pvch3.pvxchordenhistorico = 3) 
		 
						LEFT JOIN  practicavaloresxcategoria as pvcapagar ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvcapagar.idasocconv AND 
						       fpa.idnomenclador=pvcapagar.idsubespecialidad 
						  AND fpa.idcapitulo=pvcapagar.idcapitulo 
				  AND fpa.idsubcapitulo=pvcapagar.idsubcapitulo 
						  AND  fpa.idpractica=pvcapagar.idpractica 
						  AND pvcapagar.pcategoria = pcategoriaapagar ) 
					WHERE nroorden=  pnroorden     AND centro =   pcentro
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
			 ,pvc.importe as importexcategoria
		     ,pvch1.importe as importexcategorihistuno
		 	 ,pvch2.importe as importexcategorihistdos
		 	 ,pvch3.importe as importexcategorihisttres
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
				  WHERE nrorecetario=  pnroorden AND recetario.centro = pcentro
						  
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
								ON( case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =practicavalores.idasocconv AND fpa.idnomenclador=practicavalores.idsubespecialidad  AND fpa.idcapitulo=practicavalores.idcapitulo 
								AND fpa.idsubcapitulo=practicavalores.idsubcapitulo  AND fpa.idpractica=practicavalores.idpractica) 	
				  LEFT JOIN  practicavaloresxcategoria as pvc ON(case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvc.idasocconv AND
								       pvc.idsubespecialidad = fpa.idnomenclador
								   AND pvc.idcapitulo =fpa.idcapitulo  AND pvc.idsubcapitulo = fpa.idsubcapitulo
								  AND  pvc.idpractica = fpa.idpractica 
								  AND pvc.pcategoria = paramcategoria) 
				 LEFT JOIN  practicavaloresxcategoriahistorico as pvch1 ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch1.idasocconv AND
								       pvch1.idsubespecialidad = fpa.idnomenclador 
							   AND pvch1.idcapitulo = fpa.idcapitulo  AND pvch1.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch1.idpractica = fpa.idpractica 
								  AND pvch1.pcategoria = paramcategoria AND pvch1.pvxchordenhistorico = 1)
		          LEFT JOIN  practicavaloresxcategoriahistorico as pvch2 ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch2.idasocconv AND
								       pvch2.idsubespecialidad = fpa.idnomenclador 
							   AND pvch2.idcapitulo = fpa.idcapitulo  AND pvch2.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch2.idpractica = fpa.idpractica 
								  AND pvch2.pcategoria = paramcategoria AND pvch2.pvxchordenhistorico = 2 )
		           LEFT JOIN  practicavaloresxcategoriahistorico as pvch3 ON (  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch3.idasocconv AND
								       pvch3.idsubespecialidad = fpa.idnomenclador 
							   AND pvch3.idcapitulo = fpa.idcapitulo  AND pvch3.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch3.idpractica = fpa.idpractica 
								  AND pvch3.pcategoria = paramcategoria AND pvch3.pvxchordenhistorico = 3) 
				  LEFT JOIN  practicavaloresxcategoria as pvcapagar ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END =pvcapagar.idasocconv AND 
					       fpa.idnomenclador=pvcapagar.idsubespecialidad 
						  AND fpa.idcapitulo=pvcapagar.idcapitulo
				  AND fpa.idsubcapitulo=pvcapagar.idsubcapitulo 
						  AND  fpa.idpractica=pvcapagar.idpractica 
						  AND pvcapagar.pcategoria = pcategoriaapagar ) 
				WHERE nroorden=  pnroorden AND centro =   pcentro
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
			 ,pvc.importe as importexcategoria
		     ,pvch1.importe as importexcategorihistuno
		     ,pvch2.importe as importexcategorihistdos
		     ,pvch3.importe as importexcategorihisttres
		 
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
						   WHERE nroorden=  pnroorden AND centro = pcentro
						  GROUP BY nroorden,centro 
						  ) as imporden 
				   LEFT JOIN  fichamedicapreauditadaitemconsulta USING(nroorden,centro) 
				   LEFT JOIN fichamedicapreauditada as a USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
				   LEFT JOIN fichamedica USING(idfichamedica,idcentrofichamedica) 
				   LEFT JOIN practica ON (CASE WHEN nullvalue(a.idnomenclador) THEN CASE WHEN nullvalue(pesodonto) THEN '12' ELSE '14' END ELSE a.idnomenclador END = practica.idnomenclador 
					  AND CASE WHEN nullvalue(a.idcapitulo) THEN CASE WHEN nullvalue(pesodonto) THEN '42' ELSE '01' END  ELSE a.idcapitulo END = practica.idcapitulo 
						     AND CASE WHEN nullvalue(a.idsubcapitulo) THEN '01' ELSE a.idsubcapitulo END = practica.idsubcapitulo 
                           AND CASE WHEN nullvalue(a.idpractica) THEN CASE WHEN nullvalue(pesodonto) THEN '01' ELSE '00' END ELSE a.idpractica 
                              END = practica.idpractica 

 ) 
						) as fpa 
				  LEFT JOIN practicavalores 
								ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =practicavalores.idasocconv AND fpa.idnomenclador=practicavalores.idsubespecialidad  AND fpa.idcapitulo=practicavalores.idcapitulo 
								AND fpa.idsubcapitulo=practicavalores.idsubcapitulo  AND fpa.idpractica=practicavalores.idpractica) 	
				  LEFT JOIN  practicavaloresxcategoria as pvc ON(case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvc.idasocconv AND
								       pvc.idsubespecialidad = fpa.idnomenclador
								   AND pvc.idcapitulo =fpa.idcapitulo  AND pvc.idsubcapitulo = fpa.idsubcapitulo
								  AND  pvc.idpractica = fpa.idpractica 
								  AND pvc.pcategoria = paramcategoria) 
				  LEFT JOIN  practicavaloresxcategoriahistorico as pvch1 ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch1.idasocconv AND
								       pvch1.idsubespecialidad = fpa.idnomenclador 
							   AND pvch1.idcapitulo = fpa.idcapitulo  AND pvch1.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch1.idpractica = fpa.idpractica 
								  AND pvch1.pcategoria = paramcategoria AND pvch1.pvxchordenhistorico = 1)
		          LEFT JOIN  practicavaloresxcategoriahistorico as pvch2 ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch2.idasocconv AND
								       pvch2.idsubespecialidad = fpa.idnomenclador 
							   AND pvch2.idcapitulo = fpa.idcapitulo  AND pvch2.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch2.idpractica = fpa.idpractica 
								  AND pvch2.pcategoria = paramcategoria AND pvch2.pvxchordenhistorico = 2 )
		           LEFT JOIN  practicavaloresxcategoriahistorico as pvch3 ON (  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END  =pvch3.idasocconv AND
								       pvch3.idsubespecialidad = fpa.idnomenclador 
							   AND pvch3.idcapitulo = fpa.idcapitulo  AND pvch3.idsubcapitulo = fpa.idsubcapitulo 
								  AND  pvch3.idpractica = fpa.idpractica 
								  AND pvch3.pcategoria = paramcategoria AND pvch3.pvxchordenhistorico = 3) 
				  LEFT JOIN  practicavaloresxcategoria as pvcapagar ON(  case when not nullvalue(pidasocconv) then pidasocconv    ELSE fpa.idasocconvord END =pvcapagar.idasocconv AND 
					       fpa.idnomenclador=pvcapagar.idsubespecialidad 
						  AND fpa.idcapitulo=pvcapagar.idcapitulo
				  AND fpa.idsubcapitulo=pvcapagar.idsubcapitulo 
						  AND  fpa.idpractica=pvcapagar.idpractica 
						  AND pvcapagar.pcategoria = pcategoriaapagar ) 
				WHERE nroorden=  pnroorden AND centro =   pcentro
		) as itemmodificado USING(nroorden,centro) 

LEFT JOIN ordenestados on(ordenestados.nroorden=orden.nroorden and ordenestados.centro=orden.centro) 
LEFT JOIN ordenesutilizadas ON(orden.nroorden =ordenesutilizadas.nroorden  AND orden.centro=ordenesutilizadas.centro AND 
case when itemmodificado.tipo<>14 THEN orden.tipo ELSE 14 END =ordenesutilizadas.tipo ) 
WHERE orden.nroorden= pnroorden AND orden.centro =  pcentro;
$function$
