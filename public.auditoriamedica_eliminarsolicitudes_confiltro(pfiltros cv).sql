CREATE OR REPLACE FUNCTION public.auditoriamedica_eliminarsolicitudes_confiltro(pfiltros character varying)
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
      
BEGIN 
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

  EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

  IF rfiltros.accion = 'eliminarrseguimiento'  THEN
	vfiltroid = concat(rfiltros.idsolicitudauditoria,'-',rfiltros.idcentrosolicitudauditoria);
     
     

     delete from fichamedicainfomedicamento where (idfichamedicainfomedicamento, idcentrofichamedicainfomedicamento) in (
          select idfichamedicainfomedicamento, idcentrofichamedicainfomedicamento from solicitudauditoriaitem  where idsolicitudauditoria=rfiltros.idsolicitudauditoria AND idcentrosolicitudauditoria =rfiltros.idcentrosolicitudauditoria );

    delete from fichamedicatratamiento where (idfichamedicatratamiento,idcentrofichamedicatratamiento) in (
          select idfichamedicatratamiento,idcentrofichamedicatratamiento from solicitudauditoriaitem  join fichamedicainfomedicamento using (idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento )  join fichamedicainfo using(idfichamedicainfo,idcentrofichamedicainfo)

    where idsolicitudauditoria=rfiltros.idsolicitudauditoria AND idcentrosolicitudauditoria =rfiltros.idcentrosolicitudauditoria );


    delete from fichamedicainfo where (idfichamedicainfo,idcentrofichamedicainfo) in (
           select idfichamedicainfo,idcentrofichamedicainfo from solicitudauditoriaitem  join fichamedicainfomedicamento using 
            (idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento )   where idsolicitudauditoria=rfiltros.idsolicitudauditoria AND idcentrosolicitudauditoria =rfiltros.idcentrosolicitudauditoria 
           );



--esta comentado en alta_modifica_ficha_medica_      
    delete from paseinfodocfichamedicainfomedicamento where (idfichamedicainfomedicamento, idcentrofichamedicainfomedicamento ) in (
         select idfichamedicainfomedicamento, idcentrofichamedicainfomedicamento from solicitudauditoriaitem  where idsolicitudauditoria=rfiltros.idsolicitudauditoria AND 
             idcentrosolicitudauditoria =rfiltros.idcentrosolicitudauditoria );

       

    delete from solicitudauditoria_archivos where idsolicitudauditoria=rfiltros.idsolicitudauditoria AND idcentrosolicitudauditoria =rfiltros.idcentrosolicitudauditoria;
    delete from solicitudauditoriaestado where idsolicitudauditoria=rfiltros.idsolicitudauditoria AND idcentrosolicitudauditoria =rfiltros.idcentrosolicitudauditoria;
    delete from solicitudauditoriaitem where idsolicitudauditoria=rfiltros.idsolicitudauditoria AND idcentrosolicitudauditoria =rfiltros.idcentrosolicitudauditoria;
    delete from solicitudauditoria where idsolicitudauditoria=rfiltros.idsolicitudauditoria AND idcentrosolicitudauditoria =rfiltros.idcentrosolicitudauditoria;

   --MaLaPi 14-09-2022 Si la solicitud esta vinculado a un Formulario, lo vuelvo a dejar pendiente de Seguimiento

    UPDATE fichamedicainfoformulario SET idsolicitudauditoria = null,idcentrosolicitudauditoria = null
				WHERE  idsolicitudauditoria = rfiltros.idsolicitudauditoria  
                                    AND idcentrosolicitudauditoria = rfiltros.idcentrosolicitudauditoria; 

    UPDATE w_usuariowebtokensession   SET  	uwtksfechauso = null, idsolicitudauditoria = null,idcentrosolicitudauditoria = null
                                                                       WHERE  idsolicitudauditoria = rfiltros.idsolicitudauditoria  
                                    AND idcentrosolicitudauditoria = rfiltros.idcentrosolicitudauditoria;  

 END IF;    
 return 'Listo';
END;
$function$
