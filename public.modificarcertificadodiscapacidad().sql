CREATE OR REPLACE FUNCTION public.modificarcertificadodiscapacidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
 
  respuesta BOOLEAN;
  porreintegro BOOLEAN;

 tempoidalcancecobertura integer;
 
  elem RECORD;
 elem2 RECORD;
  tempo RECORD;
tablatempo RECORD;
  
   cursorcie10s refcursor;
   cursortablatemp refcursor;
   aux RECORD;
   rusuario record;
   elidusuario INTEGER; 
BEGIN
    
respuesta = true;
/* Se guarda la informacion del usuario que genero certificado de discapacicad */
     elidusuario = sys_dar_usuarioactual();
       SELECT INTO elem * FROM temp_alta_modifica_certificado_discapacidad ; 
       IF elem.iddisc = 135 THEN -- 22-09-2022 MaLaPi Verifico si me llaman para crear un certificado de uso interno o es una certificado normal
             SELECT INTO tempo * FROM certificadodiscapacidad WHERE iddisc = elem.iddisc AND nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
             IF FOUND THEN 
                     UPDATE temp_alta_modifica_certificado_discapacidad SET idcertdiscapacidad = tempo.idcertdiscapacidad,fechavtodisc = '1999-12-31' WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;  
             END IF;

       END IF;

--MaLaPi 22-09-2022 Ahora inicio el proceso clasico
       SELECT INTO elem * FROM temp_alta_modifica_certificado_discapacidad ; 
       IF nullvalue(elem.idcertdiscapacidad) THEN --El certificado no existe
                       INSERT INTO certificadodiscapacidad(nrocertificado,nrodoc,tipodoc,iddisc,fechavtodisc,fechainiciodisc,entemitecert,porcentdisc,juntacertificadora,acompanante,cif,idusuario)                                       VALUES(elem.nrocertificado,elem.nrodoc,elem.tipodoc,elem.iddisc,elem.fechavtodisc,elem.fechainiciodisc,elem.entemitecert,elem.porcentdisc,elem.juntacertificadora,elem.acompanante,elem.cif,elidusuario);
                     elem.idcertdiscapacidad =currval('certificadodisc_seq');

                 ELSE
                      -- si existe certificado discapacidad
                          UPDATE certificadodiscapacidad  SET  nrocertificado = elem.nrocertificado 
                                , iddisc = elem.iddisc
                                , fechavtodisc = elem.fechavtodisc
                                , fechainiciodisc = elem.fechainiciodisc
                                , entemitecert = elem.entemitecert
                                , porcentdisc = elem.porcentdisc
                              , juntacertificadora = elem.juntacertificadora
                              , acompanante = elem.acompanante
                             , cif = elem.cif
                             ,idusuario= elidusuario                     
                          WHERE idcertdiscapacidad = elem.idcertdiscapacidad and idcentrocertificadodiscapacidad=elem.idcentrocertificadodiscapacidad;
       END IF;
              --actualizo plancobpersona
       IF elem.iddisc <> 135 THEN --MaLaPi 22-09-2022 Se trata de un Certificado de uso Interno, no se agrega al plan de cobertura de Discapacidad
                  SELECT INTO aux * FROM plancobpersona WHERE plancobpersona.nrodoc = elem.nrodoc AND plancobpersona.tipodoc=elem.tipodoc and idplancoberturas=13;
                  IF NOT FOUND THEN 
                             INSERT INTO plancobpersona(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso,pcpfechafin) 
                               VALUES(13,elem.nrodoc,elem.tipodoc,13,now(),elem.fechavtodisc); 
                   ELSE
                              UPDATE plancobpersona SET pcpfechafin=elem.fechavtodisc, pcpfechaalta=now(), pcpfechaingreso=now()    
                                       WHERE plancobpersona.nrodoc = elem.nrodoc AND plancobpersona.tipodoc=elem.tipodoc and idplancoberturas=13;
                   END IF;
        END IF;
        IF elem.iddisc <> 135 THEN --MaLaPi 22-09-2022 Se trata de un Certificado de uso Interno, no se agrega al plan de cobertura de Discapacidad
                -- actualizo discpersona
                SELECT INTO aux * FROM discpersona WHERE discpersona.nrodoc = elem.nrodoc AND discpersona.tipodoc=elem.tipodoc and discpersona.iddisc=elem.iddisc;
                IF NOT FOUND THEN 
                         INSERT INTO discpersona(iddisc,nrodoc,tipodoc,fechavtodisc,entemitecert,porcentdisc,idusuario) 
                                       VALUES(elem.iddisc,elem.nrodoc,elem.tipodoc,elem.fechavtodisc,elem.entemitecert,elem.porcentdisc,elidusuario); 
                ELSE
                         UPDATE discpersona SET fechavtodisc=elem.fechavtodisc, entemitecert=elem.entemitecert, porcentdisc=elem.porcentdisc, idusuario=elidusuario    
                         WHERE discpersona.nrodoc = elem.nrodoc AND discpersona.tipodoc=elem.tipodoc and discpersona.iddisc=elem.iddisc ;
                END IF; 
         END IF;
           

  delete from cie10_certificadodiscapacidad where idcertdiscapacidad=elem.idcertdiscapacidad;
  OPEN cursortablatemp FOR SELECT * FROM temp_cie10_certificadodiscapacidad;
  FETCH cursortablatemp INTO tablatempo;
       WHILE  found   LOOP

         IF not nullvalue(tablatempo.idcertdiscapacidad) THEN
                 INSERT INTO cie10_certificadodiscapacidad(idcie10,idcertdiscapacidad,idcentrocertificadodiscapacidad)
          VALUES(tablatempo.idcie10,tablatempo.idcertdiscapacidad,tablatempo.idcentrocie10certificadodiscapacidad);
          ELSE   
                 INSERT INTO cie10_certificadodiscapacidad(idcie10,idcertdiscapacidad,idcentrocertificadodiscapacidad)
          VALUES(tablatempo.idcie10,elem.idcertdiscapacidad,centro());
                         
         END IF;

        FETCH cursortablatemp INTO tablatempo;
       END LOOP;
return respuesta;
END;
$function$
