CREATE OR REPLACE FUNCTION public.obtenerdatosfichamedicaauditada_convigencia(pparametros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$ DECLARE
/*$1 nroorden, $2 centro, $3 idasocconv,$4 categoria, $5 categoriaapagar,$6 esodonto*/
	rfiltros RECORD;
	 
BEGIN 

IF iftableexists('type_fichamedicaauditadav2') THEN 
	DELETE FROM type_fichamedicaauditadav2;
ELSE 

	CREATE TEMP TABLE type_fichamedicaauditadav2 (fmpaiimportes DOUBLE PRECISION,  fmpaiimporteiva DOUBLE PRECISION,  fmpaiimportetotal DOUBLE PRECISION,  nroorden BIGINT,  tipo BIGINT,  centro INTEGER,  nombres VARCHAR,  apellido VARCHAR,  idfichamedicapreauditada BIGINT,  idcentrofichamedicapreauditada INTEGER,  iditem BIGINT,  cantidad INTEGER,  importeitem DOUBLE PRECISION,  practica VARCHAR,  idnomenclador VARCHAR,  idcapitulo VARCHAR,  idsubcapitulo VARCHAR,  idpractica VARCHAR,  cobertura DOUBLE PRECISION,  fechaemision TIMESTAMP WITHOUT TIME ZONE,  idasocconv BIGINT,  malcance VARCHAR,  nromatricula BIGINT,  mespecialidad VARCHAR,  idplancovertura VARCHAR,  auditada BOOLEAN,  pdescripcion VARCHAR,  nrodoc VARCHAR,  tipodoc SMALLINT,  idprestador BIGINT,  fechauso DATE,  anulada BOOLEAN,  nrodocuso VARCHAR,  tipodocuso SMALLINT,  importepv DOUBLE PRECISION,  idasocconvord BIGINT,  importexcategoria DOUBLE PRECISION,  anteriorvalorcategoria DOUBLE PRECISION,  iimportexcategoriaapagar DOUBLE PRECISION,  idpiezadental VARCHAR,  idletradental VARCHAR,  idzonadental VARCHAR,  fmpacantidad INTEGER,  extendida BOOLEAN,  idprestadorotro BIGINT,  conveniofechainicio DATE,  conveniofechafin DATE,  convanteriorfechainicio DATE,  convanteriorfechafin DATE);

END IF;

EXECUTE sys_dar_filtros(pparametros) INTO rfiltros;

RAISE NOTICE 'Antes del insert (%)',rfiltros.nroorden ;

INSERT INTO type_fichamedicaauditadav2 (fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,nroorden,tipo,centro,nombres,apellido,idfichamedicapreauditada,idcentrofichamedicapreauditada
,iditem,cantidad,importeitem
,practica,idnomenclador
,idcapitulo,idsubcapitulo,idpractica,cobertura,fechaemision,idasocconv,malcance
,nromatricula,mespecialidad,idplancovertura,auditada,pdescripcion,nrodoc,tipodoc
,idprestador,fechauso,anulada,nrodocuso,tipodocuso
,importepv,idasocconvord,importexcategoria,anteriorvalorcategoria
,iimportexcategoriaapagar,idpiezadental,idletradental,idzonadental,fmpacantidad
,extendida
--,idprestadorotro
,conveniofechainicio,conveniofechafin,convanteriorfechainicio,convanteriorfechafin
)
(
SELECT 
	 fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,orden.nroorden,itemmodificado.tipo, orden.centro, nombres, apellido,idfichamedicapreauditada,idcentrofichamedicapreauditada 
	,  iditem, cantidad,importeitem 
	,concat(idnomenclador , '.' , idcapitulo , '.' , idsubcapitulo , '.' , idpractica)::VARCHAR as practica,idnomenclador
	,idcapitulo,idsubcapitulo,idpractica ,cobertura,orden.fechaemision,idasocconv,itemmodificado.malcance::VARCHAR 
	,itemmodificado.nromatricula::BIGINT,itemmodificado.mespecialidad::VARCHAR,idplancovertura,auditada,pdescripcion::VARCHAR,nrodoc,tipodoc 
	,idprestador,fechauso,case when nullvalue(ordenestados.nroorden) then FALSE    ELSE TRUE    END AS anulada,nrodocuso,tipodoc as tipodocuso 
	, importepv, idasocconvord,importexcategoria, importexcategoriaant as anteriorvalorcategoria 
        ,iimportexcategoriaapagar,idpiezadental, idletradental, idzonadental	,fmpacantidad 
	,CASE WHEN nullvalue(idfichamedicapreauditada) THEN  false ELSE true END as extendida
	--,CASE WHEN nullvalue(idprestadorotro) THEN 0 ELSE idprestadorotro::bigint END
        ,pvxcfechainivigencia as conveniofechainicio
        ,pvxcfechafinvigencia as  conveniofechafin
	,pvxchfechainivigencia as convanteriorfechainicio
        ,pvxchfechafinvigencia as  convanteriorfechafin 
	
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
                 -- ,null as idprestadorotro   
                   ,pvc.pvxcfechainivigencia
                   ,pvc.pvxcfechafinvigencia   
		   ,pvch.pvxchfechainivigencia
                   ,pvch.pvxchfechafinvigencia
                   ,fechaemision    
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
		  ,idasocconv as idasocconvord,orden.tipo,idpiezadental, idletradental, idzonadental,fechaemision
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
	LEFT JOIN practicavalores ON( case when not nullvalue(rfiltros.idasocconv) then rfiltros.idasocconv    ELSE fpa.idasocconvord END =practicavalores.idasocconv AND 
								 fpa.idnomenclador=practicavalores.idsubespecialidad 
					      AND fpa.idcapitulo=practicavalores.idcapitulo 
					     AND fpa.idsubcapitulo=practicavalores.idsubcapitulo 
					      AND  fpa.idpractica=practicavalores.idpractica
                                              AND not practicavalores.internacion ) 
			      LEFT JOIN  practicavaloresxcategoria as pvc ON(  case when not nullvalue(rfiltros.idasocconv) then rfiltros.idasocconv    ELSE fpa.idasocconvord END =pvc.idasocconv AND 
						       fpa.idnomenclador=pvc.idsubespecialidad 
				  AND fpa.idcapitulo=pvc.idcapitulo 
				  AND fpa.idsubcapitulo=pvc.idsubcapitulo 
						  AND fpa.idpractica=pvc.idpractica
                                                  AND not pvc.internacion     
						  AND pvc.pcategoria = rfiltros.categoria) 
			      LEFT JOIN  practicavaloresxcategoriahistorico as pvch ON(  case when not nullvalue(rfiltros.idasocconv) then rfiltros.idasocconv    ELSE fpa.idasocconvord END  =pvch.idasocconv AND 
						       fpa.idnomenclador=pvch.idsubespecialidad 
					  AND fpa.idcapitulo=pvch.idcapitulo 
				  AND fpa.idsubcapitulo=pvch.idsubcapitulo
						  AND  fpa.idpractica=pvch.idpractica 
                                                 AND not pvch.internacion
						  AND pvch.pcategoria = rfiltros.categoria  
                                                 AND (fechaemision::date >= pvxchfechainivigencia AND (fechaemision::date <= pvxchfechafinvigencia OR nullvalue(pvxchfechafin) )) 
                                                 
                                          ) 
			      LEFT JOIN  practicavaloresxcategoria as pvcapagar ON(  case when not nullvalue(rfiltros.idasocconv) then rfiltros.idasocconv    ELSE fpa.idasocconvord END  =pvcapagar.idasocconv AND 
						   fpa.idnomenclador=pvcapagar.idsubespecialidad 
						  AND fpa.idcapitulo=pvcapagar.idcapitulo 
				                  AND fpa.idsubcapitulo=pvcapagar.idsubcapitulo 
						  AND  fpa.idpractica=pvcapagar.idpractica 
                                                  AND not pvcapagar.internacion 
						  AND pvcapagar.pcategoria = rfiltros.categoriaapagar 
                                                 ) 
					WHERE nroorden=  rfiltros.nroorden     AND centro =   rfiltros.centro
					--AND ( fechaemision >= pvxchfechainivigencia AND fechaemision <= pvxchfechafinvigencia)
		) as itemmodificado USING(nroorden,centro) 

LEFT JOIN ordenestados on(ordenestados.nroorden=orden.nroorden and ordenestados.centro=orden.centro) 
LEFT JOIN ordenesutilizadas ON(orden.nroorden =ordenesutilizadas.nroorden  AND orden.centro=ordenesutilizadas.centro AND 
case when itemmodificado.tipo<>14 THEN orden.tipo ELSE 14 END =ordenesutilizadas.tipo ) 
WHERE orden.nroorden= rfiltros.nroorden AND orden.centro =  rfiltros.centro
); 


 RETURN 'true';
  END;
$function$
