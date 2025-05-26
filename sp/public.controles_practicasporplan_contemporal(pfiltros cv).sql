CREATE OR REPLACE FUNCTION public.controles_practicasporplan_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	pidsubcapitulo varchar;
	pidpractica varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_controles_practicasporplan_contemporal
AS (
		/*select  
                idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,
                case when auditoria then 'Si' else 'No' end as auditoria,cobertura,ppccantpractica, 
				case when ppcperiodo='a' then 'Anual'
				else case when ppcperiodo='m' then 'Mensual'
				else 'Sin definir' end  end as ppcperiodo,
				ppccantperiodos,serepite,
                '1-Nomenclador#idnomenclador@2-Capitulo#idcapitulo@3-Subcapitulo#idsubcapitulo@4-Practica#idpractica@5-Descripcion de practica#pdescripcion@6-Auditoria#auditoria@7-Cobertura#cobertura@8-Cantidad de practicas#ppccantpractica@9-Periodo#ppcperiodo'::text as mapeocampocolumna 

				from 
				practica
				natural join practicaplan
				natural join plancobertura
				where
				activo
	            AND (nullvalue(rfiltros.idplancobertura ) OR idplancobertura = rfiltros.idplancobertura  ) 
				order by idnomenclador, idcapitulo,idsubcapitulo,idpractica*/



                    /*
                          select  
                                idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,
                                pdescripcion,auditoria,
								cobertura,ppccantpractica, 
				case when ppcperiodo='a' then 'Anual'
				else case when ppcperiodo='m' then 'Mensual'
				else 'Sin definir' end  end as ppcperiodo,
				ppccantperiodos,serepite,
                				'1-Nomenclador#idsubespecialidad@2-Capitulo#idcapitulo@3-Subcapitulo#idsubcapitulo@4-Practica#idpractica@5-Descripcion de practica#pdescripcion@6-Auditoria#auditoria@7- Cobertura#cobertura@8-Cantidad de practicas#ppccantpractica@9-Periodo#ppcperiodo'::text as mapeocampocolumna 

                                from asocconvenio natural join convenioplancob  natural join plancobertura
                                     natural join practicaplan natural join practica  natural join practicavalores 
                                        
                                     WHERE  
                                    (nullvalue(rfiltros.idplancobertura ) OR idplancobertura = rfiltros.idplancobertura  )  
                                     and not internacion
                                     AND idcentroregional = centro() AND (nullvalue(accr.accrfechafin) OR accr.accrfechafin > Current_date)  
                                     and idasocconv=154
                                     AND idnomenclador = idsubespecialidad
                                     order by  acdecripcion
                    */




                     /*Modificaciones hechas por Albany y Facundo el dia 15/10/2024 debido a que la consulta recuperaba mas valores de los esperados -no coincidian a dicho plan-. Se agregan subconsultas para filtrar mas el resultado*/
                  /*  select distinct
                                sub.idsubespecialidad,sub.idcapitulo,sub.idsubcapitulo,sub.idpractica,
                                sub.pdescripcion, pp.cobertura,pp.ppccantpractica, 
				case when pp.auditoria then 'Verdadero' else 'Falso' end as ppauditoria,
                                case when pp.ppcperiodo='a' then 'Anual'
				else case when pp.ppcperiodo='m' then 'Mensual'
				else 'Sin definir' end  end as ppcperiodo,
				pp.ppccantperiodos,pp.serepite,
                				'1-Nomenclador#idsubespecialidad@2-Capitulo#idcapitulo@3-Subcapitulo#idsubcapitulo@4-Practica#idpractica@5-Descripcion de practica#pdescripcion@6-Auditoria#ppauditoria@7-Cobertura#cobertura@8-Cantidad de practicas#ppccantpractica@9-Periodo#ppcperiodo'::text as mapeocampocolumna 
                                FROM asocconvenio NATURAL JOIN convenioplancob c NATURAL JOIN plancobertura pc NATURAL JOIN
                                    (practicaplan pp INNER JOIN
                                    (SELECT p.*, pv.internacion, pv.idsubespecialidad FROM practica p INNER JOIN practicavalores pv ON (p.idnomenclador = pv.idsubespecialidad AND p.idcapitulo = pv.idcapitulo AND p.idsubcapitulo = pv.idsubcapitulo AND p.idpractica = pv.idpractica) WHERE idasocconv = '154' AND NOT internacion) sub
                                    ON (pp.idnomenclador = sub.idnomenclador AND pp.idcapitulo = sub.idcapitulo AND pp.idsubcapitulo = sub.idsubcapitulo AND pp.idpractica = sub.idpractica))
                                    NATURAL JOIN asocconveniocentroregional accr
                                     WHERE  
                                     (nullvalue(rfiltros.descripcion) OR (pc.descripcion = rfiltros.descripcion))
                                     AND idcentroregional = centro()  
                                     AND c.idasocconv=154
                                     AND (nullvalue(accr.accrfechafin) OR accr.accrfechafin > Current_date)


*/

 
SELECT concat(p.idnomenclador,'.',p.idcapitulo,'.',p.idsubcapitulo,'.',p.idpractica) as lapractica,  pc.descripcion  as plancobertura , pdescripcion , 
pp.cobertura,pp.ppccantpractica, 
				case when pp.auditoria then 'Verdadero' else 'Falso' end as ppauditoria,
                                case when pp.ppcperiodo='a' then 'Anual'
				else case when pp.ppcperiodo='m' then 'Mensual'
				else 'Sin definir' end  end as ppcperiodo,
				pp.ppccantperiodos,pp.serepite
FROM practica 	p
LEFT JOIN practicaplan pp  ON (
                         ( p.idnomenclador=pp.idnomenclador  and p.idcapitulo=pp.idcapitulo 
                           and p.idsubcapitulo=pp.idsubcapitulo  and p.idpractica=pp.idpractica ) -- Join por primary key
                           OR (p.idnomenclador=pp.idnomenclador AND (pp.idcapitulo='**' OR pp.idsubcapitulo='**' OR pp.idpractica='**'))
                        )
LEFT JOIN plancobertura  pc USING(idplancobertura 	)
WHERE activo    

AND  ( concat(p.idnomenclador,'.',p.idcapitulo,'.',p.idsubcapitulo,'.',p.idpractica)  ilike concat(rfiltros.codigofiltrado,'%')
       OR concat(pp.idnomenclador,'.',pp.idcapitulo,'.',pp.idsubcapitulo,'.',pp.idpractica)  ilike concat(rfiltros.codigofiltrado,'%'))

AND (pc.idplancobertura=rfiltros.idplancobertura  OR nullvalue(pc.idplancobertura)) 


ORDER BY p.idnomenclador,p.idcapitulo,p.idsubcapitulo,p.idpractica
 
				);





  

return true;
END;
$function$
