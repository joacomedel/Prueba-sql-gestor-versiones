CREATE OR REPLACE FUNCTION public.modificaralcancecobertura()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  porreintegro BOOLEAN;

 ridalcancecobertura integer;
 
  elem RECORD;

  elem2 RECORD;
  
  

BEGIN

/*
 CREATE TEMP TABLE temp_alta_modifica_alcance_cobertura (  nrodoc varchar,  tipodoc integer,  iddisc integer,  fechavtodisc date,  idalcancecobertura integer,  idcentroalcancecobertura integer,  cantidad integer,  porcentaje integer,  idnomenclador varchar,  idcapitulo varchar,  idsubcapitulo varchar,  fecha_desde date, fecha_hasta date, idpractica varchar,  idcertdiscapacidad integer,  seaudita boolean,  serepite boolean,  prioridad integer,  periodo varchar,  idcentrocertificadodiscapacidad integer,  idprestador integer,  fmifechaauditoria date,  idusuario integer,  fmiporreintegro boolean,  fmidescripcion varchar,  idfichamedica integer,  idcentrofichamedica integer ) ;

INSERT INTO temp_alta_modifica_alcance_cobertura  (idcertdiscapacidad,idcentrocertificadodiscapacidad,nrodoc,tipodoc,iddisc,fechavtodisc,idalcancecobertura,idcentroalcancecobertura,cantidad,porcentaje,idnomenclador,idcapitulo,idsubcapitulo,fecha_desde,fecha_hasta,idpractica,seaudita,serepite,prioridad,periodo,idprestador,fmifechaauditoria,idusuario,fmiporreintegro,fmidescripcion,idfichamedica,idcentrofichamedica)VALUES (93,1,'04600830',1,103,'2021-04-27',35,1,20,100,'03','02','01','2018-02-01','2019-02-28','32',TRUE,TRUE,1,'m','10788','20-02-2018',25,FALSE,'cirugia programada Uretroplastia T-T x via perineal (Dr Daniel Castro) Sta 2 dias internacion',1051,1);

*/

     SELECT INTO elem * FROM temp_alta_modifica_alcance_cobertura ;

   
                 /*la cobertura se modifica*/
                 IF not nullvalue(elem.idalcancecobertura) THEN
                          UPDATE alcancecobertura  SET  cantidad = elem.cantidad
                                , porcentaje = elem.porcentaje
                                , idnomenclador = elem.idnomenclador
                                , idcapitulo = elem.idcapitulo
                    , idsubcapitulo = elem.idsubcapitulo
                    , fecha_desde = elem.fecha_desde
                     , fecha_hasta = elem.fecha_hasta
                     , idpractica = elem.idpractica
                      , seaudita = elem.seaudita
 , serepite = elem.serepite
 , prioridad = elem.prioridad
 , periodo = elem.periodo
 , idprestador = elem.idprestador
                          WHERE idalcancecobertura = elem.idalcancecobertura and idcentroalcancecobertura=elem.idcentroalcancecobertura;
                    
    /*carga tupla en fichamedicaitem*/
     
                IF not nullvalue(elem.idfichamedicaitem) THEN
        
                        
                       UPDATE fichamedicaitem  SET  fmifechaauditoria = elem.fmifechaauditoria
                                          , idprestador = elem.idprestador
                                          , idusuario = elem.idusuario
                                           , fmiporreintegro = elem.fmiporreintegro
                                          , fmicantidad = elem.cantidad
                                          , fmidescripcion = elem.fmidescripcion
                                          , idfichamedica = elem.idfichamedica
                                         , idnomenclador = elem.idnomenclador
                                       , idcapitulo = elem.idcapitulo
                                      , idsubcapitulo = elem.idsubcapitulo
                                     , idpractica = elem.idpractica
            
                          WHERE idfichamedicaitem = elem.idfichamedicaitem and idcentrofichamedicaitem=elem.idcentrofichamedicaitem;
                 
                 else

                            INSERT INTO fichamedicaitem 
                            (fmifechaauditoria,idprestador,idusuario,fmiporreintegro,fmicantidad,fmidescripcion,idfichamedica,
                            idcentrofichamedica,idnomenclador,idcapitulo,idsubcapitulo,idpractica)                    
 values(elem.fmifechaauditoria,elem.idprestador,elem.idusuario,elem.fmiporreintegro,elem.cantidad,elem.fmidescripcion,elem.idfichamedica,elem.idcentrofichamedica,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica);
                            elem.idcentrofichamedicaitem = centro();
                            elem.idfichamedicaitem = currval('"public"."fichamedicaitem_idfichamedicaitem_seq"'::text::regclass);

                  end if;

                      UPDATE mapea_certdisc_alcancecobertura SET idfichamedicaitem =  elem.idfichamedicaitem
                                                                , idcentrofichamedicaitem =  elem.idcentrofichamedicaitem
                            WHERE idcertdiscapacidad =elem.idcertdiscapacidad  AND idcentrocertificadodiscapacidad = elem.idcentrocertificadodiscapacidad
                                 AND idalcancecobertura = elem.idalcancecobertura AND idcentroalcancecobertura =elem.idcentroalcancecobertura
                                 AND nullvalue(idfichamedicaitem);
                    respuesta=true;

                 ELSE   /*se carga nueva cobertura*/
                          
                          INSERT INTO alcancecobertura (cantidad,porcentaje,idnomenclador,idcapitulo,idsubcapitulo,fecha_desde,fecha_hasta,idpractica,seaudita,serepite,prioridad,periodo,idprestador)
                          VALUES (elem.cantidad,elem.porcentaje,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.fecha_desde,elem.fecha_hasta,elem.idpractica,elem.seaudita,elem.serepite,elem.prioridad,elem.periodo,elem.idprestador);
                       respuesta=false; 
                      
                 ridalcancecobertura =currval('alcancecobertura_idalcancecobertura_seq');
                         
                      IF not nullvalue(elem.idcertdiscapacidad) THEN
                          INSERT INTO mapea_certdisc_alcancecobertura (idcertdiscapacidad,idcentrocertificadodiscapacidad,idalcancecobertura,idcentroalcancecobertura,idfichamedicaitem,idcentrofichamedicaitem)
                          VALUES (elem.idcertdiscapacidad,elem.idcentrocertificadodiscapacidad,ridalcancecobertura,centro(),elem.idfichamedicaitem,elem.idcentrofichamedicaitem);
                     
                     
                       
                      end if;


                  /*carga tupla en fichamedicaitem*/
     
                   /* INSERT INTO fichamedicaitem (fmifechaauditoria,idprestador,idusuario,fmiporreintegro,fmicantidad,fmidescripcion,idfichamedica,
idcentrofichamedica,idnomenclador,idcapitulo,idsubcapitulo,idpractica)
                    values(elem.fmifechaauditoria,elem.idprestador,elem.idusuario,elem.fmiporreintegro,elem.cantidad,elem.fmidescripcion,elem.idfichamedica,elem.idcentrofichamedica,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica);*/



                 END IF;


       

       
 

return respuesta;
END;
$function$
