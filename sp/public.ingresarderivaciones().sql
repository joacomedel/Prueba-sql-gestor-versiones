CREATE OR REPLACE FUNCTION public.ingresarderivaciones()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que ingresa o modifica la informacion de derivaciones*/
DECLARE

 unacomp RECORD;
 rgrupoacompaniante RECORD;
 lapersona RECORD;
 losacomp refcursor;
 losreintegros refcursor;
 unreintegro RECORD;
 rreintegro RECORD;
 laderivacion RECORD;
 
 respuesta boolean;

BEGIN
    
 SELECT INTO laderivacion * FROM tempderivaciones;
 
 IF (laderivacion.idcentoregionalorigen = 0) THEN
    laderivacion.idcentoregionalorigen = null;
 END IF;
 SELECT INTO lapersona  * FROM persona WHERE nrodoc = laderivacion.nrodoc AND barra = laderivacion.barra;

        IF (nullvalue(laderivacion.idderivacion) )THEN
          INSERT INTO derivacion(nrodoc,tipodoc,dfechaingreso,dfechasalida,idcentoregionalorigen,idlocalidaddestino,
             idprovinciadestino,ddestinodescripcion,ddiagnostico,idcentroderivacion)
             VALUES(lapersona.nrodoc,lapersona.tipodoc,laderivacion.dfechaingreso,laderivacion.dfechasalida,laderivacion.idcentoregionalorigen,laderivacion.idlocalidaddestino,
             laderivacion.idprovinciadestino,laderivacion.ddestinodescripcion,laderivacion.ddiagnostico,centro());
             laderivacion.idderivacion = currval('derivacion_idderivacion_seq');
             laderivacion.idcentroderivacion = centro();
             
        ELSE 
        
         UPDATE derivacion SET nrodoc = lapersona.nrodoc,
           tipodoc = lapersona.tipodoc,
           dfechaingreso = laderivacion.dfechaingreso,
           dfechasalida = laderivacion.dfechasalida,
           idcentoregionalorigen = laderivacion.idcentoregionalorigen,
           idlocalidaddestino = laderivacion.idlocalidaddestino,
           idprovinciadestino = laderivacion.idprovinciadestino,
           ddestinodescripcion = laderivacion.ddestinodescripcion,
           ddiagnostico = laderivacion.ddiagnostico,
           idcentroderivacion = laderivacion.idcentroderivacion
           WHERE idderivacion = laderivacion.idderivacion 
                 AND idcentroderivacion = laderivacion.idcentroderivacion;
                 
             
        END IF;
        
        IF (laderivacion.hayviaticos) THEN
           IF (nullvalue(laderivacion.idderivacionviatico)) THEN 
              INSERT INTO derivacionviatico(dvcantidaddias,dvcantidadpersonas,dvimporteporpersona,dvimportetotal,idderivacion,idcentroderivacion)
               VALUES (laderivacion.dvcantidaddias,laderivacion.dvcantidadpersonas,laderivacion.dvimporteporpersona,laderivacion.dvimportetotal,laderivacion.idderivacion,laderivacion.idcentroderivacion);

           ELSE
               UPDATE derivacionviatico SET dvcantidadpersonas = laderivacion.dvcantidadpersonas
                                            ,dvimporteporpersona = laderivacion.dvimporteporpersona
                                            ,dvimportetotal = laderivacion.dvimportetotal
                                            ,dvcantidaddias = laderivacion.dvcantidaddias
               WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion 
                     AND idderivacionviatico = laderivacion.idderivacionviatico;
           
           END IF;
        ELSE
           DELETE FROM derivacionviatico WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion 
                     AND idderivacionviatico = laderivacion.idderivacionviatico; 
        END IF;
        
        IF (laderivacion.haytransporte) THEN
           IF (nullvalue(laderivacion.idderivaciontransporte)) THEN
              INSERT INTO derivaciontransporte(idderivaciontransportetipos,dtfechasalida,dtfecharegreso,dtcantidadpasajes
              ,dtimporteporpasaje,dtimportetotalpasaje,dtimportecombustible,dtimportereconocido,idderivacion,idcentroderivacion) 
              VALUES(laderivacion.idderivaciontransportetipos,laderivacion.dtfechasalida,laderivacion.dtfecharegreso,laderivacion.dtcantidadpasajes
              ,laderivacion.dtimporteporpasaje,laderivacion.dtimportetotalpasaje,laderivacion.dtimportecombustible,laderivacion.dtimportereconocido
              ,laderivacion.idderivacion,laderivacion.idcentroderivacion);
           ELSE
              UPDATE derivaciontransporte SET idderivaciontransportetipos = laderivacion.idderivaciontransportetipos
                                              ,dtfechasalida = laderivacion.dtfechasalida
                                              ,dtfecharegreso = laderivacion.dtfecharegreso
                                              ,dtcantidadpasajes = laderivacion.dtcantidadpasajes
                                              ,dtimporteporpasaje = laderivacion.dtimporteporpasaje
                                              ,dtimportetotalpasaje = laderivacion.dtimportetotalpasaje
                                              ,dtimportecombustible = laderivacion.dtimportecombustible
                                              ,dtimportereconocido = laderivacion.dtimportereconocido
                                             
              WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion 
                     AND idderivaciontransporte = laderivacion.idderivaciontransporte; 
           END IF;
        ELSE
           DELETE FROM derivaciontransporte 
            WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion 
                     AND idderivaciontransporte = laderivacion.idderivaciontransporte; 
        END IF;
      
        IF (laderivacion.hayalojamiento) THEN
           IF (nullvalue(laderivacion.idderivacionalojamiento)) THEN
              INSERT INTO derivacionalojamiento (idalojamientoderivacion,adcantidadnoches,daimportepornoche
              ,damportetotal,idderivacion,idcentroderivacion) 
              VALUES (laderivacion.idalojamientoderivacion,laderivacion.adcantidadnoches,laderivacion.daimportepornoche,laderivacion.damportetotal
              ,laderivacion.idderivacion,laderivacion.idcentroderivacion);
           ELSE
              UPDATE derivacionalojamiento 
                     SET idalojamientoderivacion = laderivacion.idalojamientoderivacion
                     ,adcantidadnoches = laderivacion.adcantidadnoches
                     ,daimportepornoche = laderivacion.daimportepornoche
                     ,damportetotal = laderivacion.damportetotal             
              WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion 
                     AND idderivacionalojamiento = laderivacion.idderivacionalojamiento; 
           END IF;
        ELSE
           DELETE FROM derivacionalojamiento
              WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion 
                     AND idderivacionalojamiento = laderivacion.idderivacionalojamiento; 
          
        END IF;
        DELETE FROM derivacionacompaniante WHERE idderivacion = laderivacion.idderivacion
                                           AND idcentroderivacion = laderivacion.idcentroderivacion;
        OPEN losacomp FOR SELECT * FROM tempgrupoacompaniante;
        FETCH losacomp INTO unacomp;
        WHILE  found LOOP
               SELECT INTO rgrupoacompaniante * FROM derivacionacompaniante
                     WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion 
                     AND danrodoc = unacomp.danrodoc
                     AND datipodoc = unacomp.datipodoc; 
                     IF FOUND THEN
                        UPDATE derivacionacompaniante SET 
                                                      idderivacionacompaniante = rgrupoacompaniante.idderivacionacompaniante
                                                      ,danombres = unacomp.danombres
                                                      ,daapellidos = unacomp.daapellidos
                                                      WHERE idderivacion = laderivacion.idderivacion
                                                       AND idcentroderivacion = laderivacion.idcentroderivacion 
                                                       AND danrodoc = unacomp.danrodoc
                                                       AND datipodoc = unacomp.datipodoc; 
                     ELSE
                            INSERT INTO derivacionacompaniante (danrodoc,datipodoc,danombres,daapellidos,idderivacion,idcentroderivacion)
                            VALUES(unacomp.danrodoc,unacomp.datipodoc,unacomp.danombres,unacomp.daapellidos,laderivacion.idderivacion,laderivacion.idcentroderivacion);
                     END IF;
                       
                FETCH losacomp INTO unacomp;
                END LOOP;
                CLOSE losacomp;
                
                DELETE FROM derivacionreintegro WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion ;
                
        OPEN losreintegros FOR SELECT * FROM tempreintegros;
        FETCH losreintegros INTO unreintegro;
        WHILE  found LOOP
        
               SELECT INTO rreintegro * FROM derivacionreintegro
                     WHERE idderivacion = laderivacion.idderivacion
                     AND idcentroderivacion = laderivacion.idcentroderivacion 
                     AND nroreintegro = unreintegro.nroreintegro
                     AND idcentroregional = unreintegro.idcentroregional
                     AND anio = unreintegro.anio
                     AND tipoderivacion = unreintegro.tipoderivacion; 
                     IF FOUND THEN
                        UPDATE derivacionreintegro SET 
                        	tipoderivacion = unreintegro.tipoderivacion
                        WHERE idderivacion = laderivacion.idderivacion
                        AND idcentroderivacion = laderivacion.idcentroderivacion 
                        AND nroreintegro = unreintegro.nroreintegro
                        AND idcentroregional = unreintegro.idcentroregional
                        AND anio = unreintegro.anio; 
                     ELSE
                            INSERT INTO derivacionreintegro (nroreintegro,idcentroregional,anio,tipoderivacion,idderivacion,idcentroderivacion)
                            VALUES(unreintegro.nroreintegro,unreintegro.idcentroregional,unreintegro.anio,unreintegro.tipoderivacion,laderivacion.idderivacion,laderivacion.idcentroderivacion);
                     END IF;
                       
                FETCH losreintegros INTO unreintegro;
                END LOOP;
                CLOSE losreintegros;
              
 RETURN TRUE;
END;
$function$
