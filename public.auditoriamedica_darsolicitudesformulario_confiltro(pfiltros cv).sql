CREATE OR REPLACE FUNCTION public.auditoriamedica_darsolicitudesformulario_confiltro(pfiltros character varying)
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
        vparametrojson jsonb;
        vrespuestajson jsonb;
      
BEGIN 
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

     IF rfiltros.accion = 'buscarPreviaUna'  THEN 
	 
	   --MaLaPi 08-09-2022 Implementar para que muestre un auditoria generada a partir de un formulario
	   
	  
     END IF;
     IF rfiltros.accion = 'pendies_Auditoria_Medica'  THEN
	    --MaLaPi 08-09-2022 Implementar para que muestre los formularios que aun no generaron Auditoria Medica
		
       

     END IF;
     IF rfiltros.accion = 'buscarPrevias'  THEN 

              CREATE TEMP TABLE temp_solicitudesformulario_confiltros AS (
	select consumo.nroorden*100+consumo.centro as nroformulario,consumo.nroorden,consumo.centro,nrodoc,tipodoc,nombres,apellido,fechaemision
              ,nullvalue(w_usuariowebtokensession.uwtksttl) as generartoken
              ,idusuariowebtokensession,idcentrousuariowebtokensession,idusuarioweb,uwtkscodigo,uwtksquien,uwtksttl,uwtksfechaingreso, uwtksfechauso, uwtkstoken
,'' as codigosolicituditem,'' as codigosolicitud,'' as textoitem,'' as usuestado,'' as usualta,'' as codarchivo, concat(nombres,' ',apellido)  as nomape
           ,CASE WHEN nullvalue(tienearchivo.idsolicitudauditoria) THEN 'Falta Archivo' ELSE gaarchivonombre END as nombrearchivo
           ,CASE WHEN nullvalue(tienearchivo.idsolicitudauditoria) THEN 'Falta Archivo' ELSE gaarchivodescripcion END as verarchivo
            ,CASE WHEN nullvalue(uwtksfechauso) THEN 'Envio Pendiente' ELSE 'Enviado' END as enviopendiente
             
              FROM consumo 
              NATURAL JOIN orden
               NATURAL JOIN persona
               LEFT JOIN w_usuariowebtokensession ON (consumo.nroorden*100+consumo.centro = uwtkscodigo)
               LEFT JOIN (SELECT idsolicitudauditoria,idcentrosolicitudauditoria,fmifnroorden,fmifcentro,gaarchivonombre,gaarchivodescripcion
                          FROM fichamedicainfoformulario 
                          NATURAL JOIN solicitudauditoria_archivos
                          NATURAL JOIN gestionarchivos 
                          WHERE nullvalue(fmiffechafin)) as tienearchivo ON (fmifnroorden = consumo.nroorden AND fmifcentro = consumo.centro)
               JOIN ordenrecibo_vinculada ON (orvnroordenorigen = consumo.nroorden AND orvcentroorigen = consumo.centro)
               WHERE (rfiltros.nrodoc = '*' OR nrodoc = rfiltros.nrodoc) 
                     AND ((rfiltros.filtracentro  AND consumo.centro = centro()) OR (not rfiltros.filtracentro))
                     AND not anulado
                     AND (nullvalue(uwtksfechauso) OR nullvalue(tienearchivo.idsolicitudauditoria))
               ORDER BY fechaemision DESC
              );  

     END IF;

     
	--MaLaPi 19-09-2022 se hace con un Web Services 
	--IF rfiltros.accion = 'solicitarauditoria'  THEN 

      --  vnroorden = (rfiltros.nroformulario)::bigint / 100;
      --  vcentro = (rfiltros.nroformulario)::bigint  % 100;

--       PERFORM auditoriamedica_conformulario_solicitarauditoria(pfiltros); 
--        CREATE TEMP TABLE temp_solicitudesformulario_confiltros AS (
--         SELECT * FROM fichamedicainfoformulario   WHERE nullvalue(fmiffechafin) AND fmifnroorden = (rfiltros.nroformulario)::bigint / 100 
--                                                            AND	fmifcentro = (rfiltros.nroformulario)::bigint
--       );
--     END IF;

     
     return 'Listo';
END;
$function$
