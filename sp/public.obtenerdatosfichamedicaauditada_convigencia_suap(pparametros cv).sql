CREATE OR REPLACE FUNCTION public.obtenerdatosfichamedicaauditada_convigencia_suap(pparametros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$ DECLARE
/*$1 nroorden, $2 centro, $3 idasocconv,$4 categoria, $5 categoriaapagar,$6 esodonto*/
	rfiltros RECORD;
	 
BEGIN 

IF iftableexists('type_fichamedicaauditadav2') THEN 
	DELETE FROM type_fichamedicaauditadav2;
ELSE 

	CREATE TEMP TABLE type_fichamedicaauditadav2 (fmpaiimportes DOUBLE PRECISION,  fmpaiimporteiva DOUBLE PRECISION,  fmpaiimportetotal DOUBLE PRECISION,  nroorden BIGINT,  tipo BIGINT,  centro INTEGER
	,idfichamedicapreauditada BIGINT,  idcentrofichamedicapreauditada INTEGER,  iditem BIGINT,  cantidad INTEGER,  importeitem DOUBLE PRECISION
	,idnomenclador VARCHAR,  idcapitulo VARCHAR,  idsubcapitulo VARCHAR,  idpractica VARCHAR,  cobertura DOUBLE PRECISION,  fechaemision TIMESTAMP WITHOUT TIME ZONE,  idasocconv BIGINT
	, idplancovertura VARCHAR,  auditada BOOLEAN, nrodoc VARCHAR,  tipodoc SMALLINT,  fechauso DATE,  anulada BOOLEAN,  nrodocuso VARCHAR,  tipodocuso SMALLINT,  importepv DOUBLE PRECISION
	,  idasocconvord BIGINT,  importexcategoria DOUBLE PRECISION,  anteriorvalorcategoria DOUBLE PRECISION,  iimportexcategoriaapagar DOUBLE PRECISION
	,  fmpacantidad INTEGER,  extendida BOOLEAN,  idprestadorotro BIGINT,  conveniofechainicio DATE,  conveniofechafin DATE,  convanteriorfechainicio DATE,  convanteriorfechafin DATE);

END IF;

EXECUTE sys_dar_filtros(pparametros) INTO rfiltros;

RAISE NOTICE 'Antes del insert (%)',rfiltros.nroorden ;

INSERT INTO type_fichamedicaauditadav2 (
idnomenclador
,idcapitulo,idsubcapitulo,idpractica
,fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,nroorden,tipo,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada
,iditem,cantidad,importeitem
,cobertura,fechaemision,idasocconv,idplancovertura,auditada,nrodoc,tipodoc
,fechauso,anulada,nrodocuso,tipodocuso
,importepv,idasocconvord,importexcategoria,anteriorvalorcategoria
,iimportexcategoriaapagar,fmpacantidad
,extendida
,conveniofechainicio,conveniofechafin,convanteriorfechainicio,convanteriorfechafin
)
(
SELECT 
	 idnomenclador
	,idcapitulo,idsubcapitulo,idpractica
	,fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,orden.nroorden,itemmodificado.tipo, orden.centro,idfichamedicapreauditada,idcentrofichamedicapreauditada 
	,iditem, cantidad,importeitem 
	,cobertura,orden.fechaemision,idasocconv,idplancovertura,auditada,nrodoc,tipodoc 
	,fechauso,case when nullvalue(ordenestados.nroorden) then FALSE    ELSE TRUE    END AS anulada,nrodocuso,tipodoc as tipodocuso 
	,importepv, idasocconvord,importexcategoria, importexcategoriaant as anteriorvalorcategoria 
        ,iimportexcategoriaapagar,fmpacantidad 
	,CASE WHEN nullvalue(idfichamedicapreauditada) THEN  false ELSE true END as extendida
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
		  ,fpa.centro,fpa.cobertura,idplancovertura,auditada 
		  ,practicavalores.importe as importepv, fpa.idasocconvord
                  ,fpa.tipo,pvc.importe as importexcategoria,pvch.importe as importexcategoriaant 
		  ,pvcapagar.importe as iimportexcategoriaapagar
		     
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
		  ,orden.centro,cobertura,idplancovertura,auditada 
		  ,idasocconv as idasocconvord,orden.tipo,fechaemision
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
					      AND  fpa.idpractica=practicavalores.idpractica AND not practicavalores.internacion) 
			      LEFT JOIN  practicavaloresxcategoria as pvc ON(  case when not nullvalue(rfiltros.idasocconv) then rfiltros.idasocconv    ELSE fpa.idasocconvord END =pvc.idasocconv AND 
						       fpa.idnomenclador=pvc.idsubespecialidad 
				  AND fpa.idcapitulo=pvc.idcapitulo 
				  AND fpa.idsubcapitulo=pvc.idsubcapitulo 
						  AND fpa.idpractica=pvc.idpractica 
						  AND pvc.pcategoria = rfiltros.categoria AND not pvc.internacion ) 
			      LEFT JOIN  practicavaloresxcategoriahistorico as pvch ON(  case when not nullvalue(rfiltros.idasocconv) then rfiltros.idasocconv    ELSE fpa.idasocconvord END  =pvch.idasocconv AND 
						       fpa.idnomenclador=pvch.idsubespecialidad 
					  AND fpa.idcapitulo=pvch.idcapitulo 
				  AND fpa.idsubcapitulo=pvch.idsubcapitulo
						  AND  fpa.idpractica=pvch.idpractica 
						  AND pvch.pcategoria = rfiltros.categoria  
                                                 AND not pvch.internacion
                                                 AND (fechaemision::date <= pvxchfechainivigencia AND (fechaemision::date <= pvxchfechafinvigencia OR nullvalue(pvxchfechafin) )) 
                                                 
                                          ) 
			      LEFT JOIN  practicavaloresxcategoria as pvcapagar ON(  case when not nullvalue(rfiltros.idasocconv) then rfiltros.idasocconv    ELSE fpa.idasocconvord END  =pvcapagar.idasocconv AND 
						   fpa.idnomenclador=pvcapagar.idsubespecialidad 
						  AND fpa.idcapitulo=pvcapagar.idcapitulo 
				                  AND fpa.idsubcapitulo=pvcapagar.idsubcapitulo 
						  AND  fpa.idpractica=pvcapagar.idpractica 
						  AND pvcapagar.pcategoria = rfiltros.categoriaapagar 
                                                  AND not pvcapagar.internacion 
                                                  AND ( fechaemision::date >= pvxchfechainivigencia AND (fechaemision::date <= pvxchfechafinvigencia OR nullvalue(pvxchfechafin)) )
                                                 ) 
					WHERE nroorden=  rfiltros.nroorden     AND centro =   rfiltros.centro
					
		) as itemmodificado USING(nroorden,centro) 

LEFT JOIN ordenestados on(ordenestados.nroorden=orden.nroorden and ordenestados.centro=orden.centro) 
LEFT JOIN ordenesutilizadas ON(orden.nroorden =ordenesutilizadas.nroorden  AND orden.centro=ordenesutilizadas.centro AND 
case when itemmodificado.tipo<>14 THEN orden.tipo ELSE 14 END =ordenesutilizadas.tipo ) 
WHERE orden.nroorden= rfiltros.nroorden AND orden.centro =  rfiltros.centro
); 


 RETURN 'true';
  END;
$function$
