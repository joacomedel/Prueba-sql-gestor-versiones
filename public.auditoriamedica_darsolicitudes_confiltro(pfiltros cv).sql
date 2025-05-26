CREATE OR REPLACE FUNCTION public.auditoriamedica_darsolicitudes_confiltro(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       cvalormedicamento refcursor;
       unvalormed record;
       unvalormedanterior record;
       primero boolean;
        
        rfiltros RECORD;
        rusuario RECORD;
        vfiltroid varchar;
        vfechadesde DATE;
        vfechahasta DATE;
      
BEGIN 
--SELECT * FROM auditoriamedica_darsolicitudes_confiltro('{accion=pendies_Auditoria_Medica, fechadesde=2022-09-28, nrodoc=*, estado=2, fechahasta=2022-09-28}')
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    vfechadesde = CURRENT_DATE - 7::integer;
    vfechahasta = CURRENT_DATE + 1::integer;
    IF pfiltros ilike '%fechadesde=%' THEN
      vfechadesde = rfiltros.fechadesde;
    END IF;
     
    IF pfiltros ilike '%fechahasta=%' THEN
      vfechahasta = rfiltros.fechahasta +1::integer;
    END IF;    

     IF rfiltros.accion = 'buscarPreviaUna'  THEN 
	vfiltroid = concat(rfiltros.idsolicitudauditoria,'-',rfiltros.idcentrosolicitudauditoria);
      --MaLaPi 30-01-2023 Tengo que asignar una fechadesde muy antigua, pues tardan en cargar la auditoria. Limito a 180 dias
        vfechadesde = CURRENT_DATE - 365::integer; 
     END IF;
     IF rfiltros.accion = 'pendies_Auditoria_Medica'  THEN
        IF nullvalue(rfiltros.estado) THEN 
        	vfiltroid = 1; --Estado pendiente de Auditoria Medica
        ELSE
		vfiltroid = rfiltros.estado;
        END IF;

     END IF;

     CREATE TEMP TABLE temp_solicitudauditoria_confiltros AS (
	select *,concat(idsolicitudauditoriaitem,'-',idcentrosolicitudauditoriaitem) as codigosolicituditem,concat(idsolicitudauditoria,'-',idcentrosolicitudauditoria) as codigosolicitud,concat(monnombre,'',adescripcion) as textoitem,sys_dar_usuario(saeidusuario) as usuestado,sys_dar_usuario(saidusuario) as usualta,concat(idgestionarchivos,'-',idcentrogestionarchivos) as codarchivo,CASE WHEN idplancoberturas = 11 THEN concat(persona.sexo,substring(nombres,1,2),substring(apellido,1,2),to_char(fechanac,'DDMMYYYY')) ELSE concat(nombres,' ',apellido) END as nomape
 ,CASE WHEN nullvalue(fmifnroorden) THEN false ELSE true END as generarpendientes
 ,CASE WHEN nullvalue(fmifnroorden) THEN 'Sin Formulario' ELSE concat(fmifnroorden,'00',fmifcentro) END as nroformulario 
 ,CASE WHEN nullvalue(idfichamedicainfomedicamento) THEN 'Sin Auditar' ELSE concat(idfichamedicainfomedicamento,'-',idcentrofichamedicainfomedicamento) END as seaudito
 
		from solicitudauditoria
                NATURAL JOIN persona
		NATURAL JOIN  solicitudauditoriaestado
		NATURAL JOIN  solicitudauditoriaitem 
		LEFT JOIN solicitudauditoriaitem_ext USING(idsolicitudauditoriaitem,idcentrosolicitudauditoriaitem)
		LEFT JOIN prestador USING(idprestador)
		LEFT JOIN plancobertura USING(idplancoberturas)
		LEFT JOIN far_articulo USING(idarticulo,idcentroarticulo)
		LEFT JOIN monodroga USING(idmonodroga)
                LEFT JOIN solicitudauditoria_archivos USING(idsolicitudauditoria,idcentrosolicitudauditoria)
                LEFT JOIN (SELECT idsolicitudauditoria,idcentrosolicitudauditoria,fmifnroorden,fmifcentro FROM fichamedicainfoformulario WHERE not nullvalue(idsolicitudauditoria) ) as t USING(idsolicitudauditoria,idcentrosolicitudauditoria)
		WHERE nullvalue(saefechafin) 
                AND ( rfiltros.nrodoc = '*' OR solicitudauditoria.nrodoc = rfiltros.nrodoc )
                AND ( safechaingreso >= vfechadesde )
                AND ( safechaingreso <= vfechahasta )
		AND ( rfiltros.accion <> 'buscarPreviaUna' OR (rfiltros.accion = 'buscarPreviaUna' AND concat(idsolicitudauditoria,'-',idcentrosolicitudauditoria) = vfiltroid ))
                AND ( rfiltros.accion <> 'pendies_Auditoria_Medica' OR (rfiltros.accion = 'pendies_Auditoria_Medica' AND idsolicitudauditoriaestadotipo  = vfiltroid ))
       ORDER BY safechaingreso DESC
     );

     
     return 'Listo';
END;
$function$
