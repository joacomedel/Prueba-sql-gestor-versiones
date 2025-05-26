CREATE OR REPLACE FUNCTION public.alta_modifica_ficha_medica_darinfo(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
   rfiltros RECORD;
  
  

BEGIN
--sys_dar_usuarioactual();
respuesta = true;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	 
	 IF rfiltros.queinfo = 'infomedicamentos'  THEN 
		CREATE TEMP TABLE temp_alta_modifica_ficha_medica_darinfo as (
		  SELECT monodroga.monnombre,  far_articulo.adescripcion as articulodescripcion,plancobertura.descripcion as plancobdescripcion
			, CASE WHEN not nullvalue(fichamedicainfomedicamento.idmonodroga) THEN monodroga.monnombre ELSE far_articulo.adescripcion END as descproducto
			, fmimfechafin, concat(fichamedicainfomedicamento.idfichamedicainfomedicamento,'-',fichamedicainfomedicamento.idcentrofichamedicainfomedicamento) as codigomedicamentoinfo 
			, fichamedicainfomedicamento.idfichamedicainfomedicamento , fichamedicainfomedicamento.idcentrofichamedicainfomedicamento 
			, fichamedicainfomedicamento.idplancoberturas 
			,fichamedicainfomedicamento.idarticulo ,  fichamedicainfomedicamento.idcentroarticulo 
			,fichamedicainfomedicamento.idmonodroga ,  idfichamedicainfo ,  idcentrofichamedicainfo 
			, fmimcobertura ,idfichamedica  ,fmttdescripcion  ,idcentrofichamedica ,nrodoc  ,tipodoc  
			,fmfechacreacion  ,fmdescripcion  ,idauditoriatipo  ,idfichamedicatratamiento  ,idcentrofichamedicatratamiento  
			,idfichamedicatratamientotipo  ,fmifecha  ,fmiauditor  ,fmidescripcion  
			,idfichamedicainfotipos  ,auditor  ,false as seleccionado  
			,fmimdosisdiaria
			,fmimmpresentacion
			,cantidadperiodo
			,cantidadtotal
            ,porcentaje 
            ,idnomenclador
            ,idcapitulo
			, idsubcapitulo
			, fecha_desde
			, fecha_hasta
			, idpractica
			, seaudita
			, serepite
			, prioridad
			, periodo
			, idprestador
			,alcancecobertura.idplancoberturas as idplancoberturasemision
               ,acobservacionexpendio
                ,acobservacionauditoria
			,CASE WHEN nullvalue(fmifnroorden) THEN false ELSE true END as generarpendientes
            ,CASE WHEN nullvalue(fmifnroorden) THEN 'Sin Formulario' ELSE concat(fmifnroorden,'00',fmifcentro) END as nroformulario
            ,idgestionarchivos,idcentrogestionarchivos ,saeobservacion, idsolicitudauditoriaitem,idcentrosolicitudauditoriaitem
              
			FROM fichamedica   
			LEFT  JOIN fichamedicatratamiento USING(idfichamedica,idcentrofichamedica)   
			LEFT  JOIN fichamedicatratamientotipo  USING(idfichamedicatratamientotipo)   
			LEFT JOIN fichamedicainfo USING(idfichamedicatratamiento,idcentrofichamedicatratamiento)   
			LEFT JOIN (SELECT idusuario as fmiauditor,concat(nombre , ' ' , apellido) as auditor FROM usuario ) as usuario USING(fmiauditor)   
			LEFT JOIN fichamedicainfomedicamento USING(idfichamedicainfo,idcentrofichamedicainfo) 
			--AT 15-08-2023 Agrego left join para traer la observacion y la fecha fin 
LEFT JOIN (
SELECT idsolicitudauditoriaitem,idcentrosolicitudauditoriaitem,saeobservacion,idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento,saefechafin
FROM solicitudauditoriaitem 
NATURAL JOIN solicitudauditoriaestado
 
) as l USING ( 	idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento 	)
			LEFT JOIN plancobertura USING(idplancoberturas) 
			LEFT JOIN far_articulo USING(idarticulo,idcentroarticulo) 
			LEFT JOIN monodroga USING(idmonodroga) 
			LEFT JOIN mapea_fichamedicainfomedicamento_alcancecobertura USING(idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento)
			LEFT JOIN alcancecobertura USING(idalcancecobertura,idcentroalcancecobertura)
                        LEFT JOIN (SELECT idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento,idsolicitudauditoria,idcentrosolicitudauditoria,fmifnroorden,fmifcentro 
					    FROM fichamedicainfoformulario 
					    NATURAL JOIN solicitudauditoriaitem					    
					  ) as t USING(idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento)
			
 LEFT JOIN (
                                  SELECT idsolicitudauditoria,idcentrosolicitudauditoria,fmifnroorden,fmifcentro,gaarchivonombre,gaarchivodescripcion,idgestionarchivos,idcentrogestionarchivos
                          FROM fichamedicainfoformulario 
                          NATURAL JOIN solicitudauditoria_archivos
                          NATURAL JOIN gestionarchivos 
                          WHERE nullvalue(fmiffechafin)

                          ) as tienearchivo USING(fmifnroorden,fmifcentro) 
--solo busco las fichas de los ultimos 3 anios
			WHERE (fmifecha>= current_date-1095) 
			    AND idauditoriatipo = 5 
			    AND idfichamedicainfotipos=4  
					AND nrodoc=rfiltros.nrodoc
			        AND tipodoc=rfiltros.tipodoc
		--ORDER BY fmifecha DESC
AND nullvalue(l.saefechafin)
			

		
		);
             

     END IF;

return respuesta;
END;
$function$
