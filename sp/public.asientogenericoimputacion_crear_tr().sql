CREATE OR REPLACE FUNCTION public.asientogenericoimputacion_crear_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
      registro RECORD;
     elasiento character varying;
     rimp RECORD;
     rminuta_imp RECORD;
     resp boolean;

BEGIN
	  -- pidoperacion formato: 'iddeuda|idcentrodeuda|idpago|idcentropago'  
      --- comenta VAS 01-04-2022 perform asientogenericoimputacion_crear(concat(NEW.iddeuda,'|',NEW.idcentrodeuda,'|',NEW.idpago,'|',NEW.idcentropago));
      --- Busco la imputacion
      
        RAISE NOTICE 'SYS::iddeuda, idpago, importe (%) (%) (%)',NEW.iddeuda , NEW.idpago,NEW.importeimp;

       IF (TG_OP = 'UPDATE') THEN -- se trata de una modificacion 
                     RAISE NOTICE 'SYS:: es un UPDATE ';
      
                     SELECT INTO rimp * FROM cuentacorrientedeudapago WHERE iddeuda = NEW.iddeuda AND idcentrodeuda=NEW.idcentrodeuda 
                                                                  AND idpago= NEW.idpago AND  idcentropago=NEW.idcentropago
                                                                ---  AND abs(NEW.importeimp-importeimp)<>0
                                                                 ;   
                     IF FOUND THEN 
                               RAISE NOTICE 'SYS:: HA hay reg en deudapago ';
                               -- La imputacion ya existia se verifica si hay cambios en el importe de la imputacion. Si es asi se debe anular la minuta de la imputacion actual
                                RAISE NOTICE 'SYS:: existe una NEW.importeimp y rimp.importeimp (%) (%) ',NEW.importeimp , rimp.importeimp;
                                -- BelenA 04/04/24  Modifico ligeramente la consulta para que busque la minuta de imputacion que no esta anulada
                                -- Ya que pudiendo desimputar y volver a imputar, termina teniendo más de una minuta de imputacion
                                SELECT INTO rminuta_imp *   
                                FROM cuentacorrientedeudapagoordenpago
                                JOIN ordenpago USING (nroordenpago, idcentroordenpago)
                                JOIN cambioestadoordenpago USING (nroordenpago, idcentroordenpago)

                                WHERE iddeuda = NEW.iddeuda AND idcentrodeuda=NEW.idcentrodeuda 
                                     AND idpago= NEW.idpago AND  idcentropago=NEW.idcentropago 
                                     AND nullvalue(ceopfechafin) AND idtipoestadoordenpago!=4;

                                IF FOUND THEN
                               RAISE NOTICE 'SYS:: existe una rminuta_imp.nroordenpago rminuta_imp.idcentroordenpago (%) (%) ',rminuta_imp.nroordenpago , rminuta_imp.idcentroordenpago;
                                       SELECT INTO resp anularminutapago(rminuta_imp.nroordenpago, rminuta_imp.idcentroordenpago ); 
                                 ELSE -- 110822 la imputacion no se registro a partir de una minuta por lo que se debe revertir el asiento de la imputacion
                                        perform asientogenerico_revertir(idasientogenerico*100+idcentroasientogenerico) 
                                        FROM asientogenerico 
                                        WHERE idcomprobantesiges = concat(NEW.iddeuda,'|',NEW.idcentrodeuda,'|',NEW.idpago,'|',NEW.idcentropago)
                                              and idasientogenericocomprobtipo=9;
                                     
                            
                                END IF;

                      END IF; -- 
           ELSE 
                    RAISE NOTICE 'SYS:: NO ES un UPDATE ';
           END IF; 

           IF (NEW.importeimp<>0) THEN --  importeimp=0  vas 240123      
                 perform  contabilidad_generarminutaimputacion (concat('{iddeuda=' ,NEW.iddeuda,',idcentrodeuda=', NEW.idcentrodeuda, ',idpago=', NEW.idpago, ' , idcentropago=',NEW.idcentropago,'}'));
 
                 -- corroboro si fue generada la minuta de imputacion
                 SELECT INTO registro * FROM cuentacorrientedeudapagoordenpago 
                 WHERE iddeuda = NEW.iddeuda AND idcentrodeuda=NEW.idcentrodeuda AND idpago= NEW.idpago AND  idcentropago=NEW.idcentropago;
                 IF NOT FOUND THEN
                          SELECT INTO elasiento asientogenericoimputacion_crear(concat(NEW.iddeuda,'|',NEW.idcentrodeuda,'|',NEW.idpago,'|',NEW.idcentropago));
           
                 END IF;
           END IF;  -- importeimp=0 vas 240123  
        return NEW;
END;
$function$
