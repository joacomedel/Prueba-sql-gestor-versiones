CREATE OR REPLACE FUNCTION public.eliminarprestador(bigint, bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       cprestadores refcursor;
       unprestador record;
       crearordenpagocontable integer;
       elidordenpagocontable bigint;
       numregistro BIGINT;
       elanio integer;
       resp boolean;
       idelimina  BIGINT;
       idreemplaza  BIGINT;
       numcuit varchar;
BEGIN
     idreemplaza = $1;
     idelimina = $2;
   

     OPEN cprestadores FOR
                       SELECT idprestador ,
                       concat(trim (replace(replace(replace(replace(replace (replace(replace( replace (replace ( replace ( replace (replace (replace( replace(UPPER(trim( to_ascii( pdescripcion) )), ' usar', '') ,')' ,'' ),'(',''),'NO USAR',''),'No Usar',''),'NO',''),',',''),'ODONTOLOGICO',''),'NEUQUEN',''),'CIRCULO',''),'.',''),' ',' '),'  ',' '),'USAR',''))
                       ,'%') as pdescrip
                       FROM prestador
                       WHERE --nullvalue(pcuit)
                        --pdescripcion ilike '%Fernandez, Jorge  Alberto%' and
                        pdescripcion ilike '%usar%'
                     --   and idprestador = 3078
                     --  limit 50
                       ;


                       
     FETCH cprestadores into unprestador;
     WHILE FOUND LOOP
             --    numcuit = unprestador.elcuit;
                idelimina = unprestador.idprestador;
                SELECT INTO idreemplaza idprestador
                FROM prestador
                WHERE  true and pdescripcion not ilike '%usar%'
      --  and  not nullvalue(pcuit)
                       and concat(trim (replace(replace(replace(replace(replace (replace(replace( replace (replace ( replace ( replace (replace (replace( replace(UPPER(trim( to_ascii( pdescripcion) )), ' usar', '') ,')' ,'' ),'(',''),'NO USAR',''),'No Usar',''),'NO',''),',',''),'ODONTOLOGICO',''),'NEUQUEN',''),'CIRCULO',''),'.',''),' ',' '),'  ',' '),'(NoUsar)',''))
                       ,'%')
                       ilike unprestador.pdescrip;
                       
        
                 IF ( not nullvalue(idelimina) and not nullvalue(idreemplaza) ) THEN
                        UPDATE ordenesutilizadas SET idprestador =idreemplaza  WHERE idprestador =idelimina;
                        UPDATE recetario SET idprestador =idreemplaza  WHERE idprestador =idelimina;
                        UPDATE recetario SET idfarmacia =idreemplaza  WHERE idfarmacia =idelimina;
                        UPDATE prestadoreliminado SET idprestadorok = idreemplaza  WHERE idprestador =idelimina;
                        UPDATE ordenesconsultaauditadas  SET idprestador = idreemplaza WHERE idprestador =idelimina;
                        UPDATE factura SET idprestador = idreemplaza WHERE idprestador =idelimina;
                        UPDATE reclibrofact SET idprestador = idreemplaza WHERE idprestador =idelimina;
                        UPDATE facturadebitoimputacionpendiente SET idprestador = idreemplaza WHERE idprestador =idelimina;
                        UPDATE far_pedido SET idprestador = idreemplaza WHERE idprestador =idelimina;
                      
--                          UPDATE  SET idprestador = idreemplaza WHERE idprestador =idelimina;

                        DELETE FROM matricula  WHERE idprestador =idelimina;
                        DELETE FROM profesional  WHERE idprestador =idelimina;
                        DELETE FROM personajuridica  WHERE idprestador =idelimina;
                        DELETE FROM matricula WHERE idprestador =idelimina;
                        DELETE FROM multivac.mapeoprestadores WHERE idprestadorsiges =idelimina;
                        DELETE FROM prestadortiporetencion  WHERE idprestador =idelimina;
                        DELETE FROM prestador WHERE idprestador =idelimina;
                        
                        
                        
                        
                 END IF;
          FETCH cprestadores into unprestador;
     END LOOP;


   return 'true';

END;
$function$
