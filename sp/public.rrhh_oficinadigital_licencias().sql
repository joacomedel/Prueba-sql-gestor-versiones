CREATE OR REPLACE FUNCTION public.rrhh_oficinadigital_licencias()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de la licencia  a la estructura de oficina digital (uncoma) */

DECLARE

--RECORD    
     rlao RECORD;
--VARIABLES 
     vlicenciaestado INTEGER;
     vidtipolic  INTEGER;
BEGIN
  -- vidtipolic =101; --el tipo de licencia es LAO
  SELECT INTO  vidtipolic idlicenciatipo FROM ofa_tipolicencialicenciatipo WHERE idtipolic = NEW.idtipolic;
 
  
  SELECT INTO rlao * FROM ofa_sollicencia WHERE  idsolicitud = NEW.idsolicitud;
  IF (TG_OP = 'UPDATE') THEN -- se trata de una modificacion 
     
   --  RAISE NOTICE 'rmodlic (%)',rmodlic;
     vlicenciaestado = CASE WHEN NEW.estado = 0 THEN 4 ELSE NULL END; 
     PERFORM w_rrhh_abmlicencias(concat('{"idsolicitud":',NEW.idsolicitud,',"idlicencia":',vidtipolic',', '"accion":"w_licencia_accion_modificar"',',','"lifechainicio":','"',NEW.fechadesde,'"',',', '"lifechafin":','"',NEW.fechahasta,'"',',', '"idlicenciatipo":','"',rlao.idlicenciatipo,'"',',', '"idlicenciaestadotipo":','"',vlicenciaestado,'"',',',
   '"leobservacion":"Desde oficina digital-rrhh_oficinadigital_licencias"','}')::jsonb);
      
  ELSE 
    IF (TG_OP = 'INSERT') THEN  
       
        INSERT INTO ofa_permisopersonallicencia(idsolicitud) VALUES(NEW.idsolicitud);
        PERFORM w_rrhh_abmlicencias(concat('{"idsolicitud":',NEW.idsolicitud,',"idlicenciatipo":',vidtipolic,',', '"accion":"w_licencia_accion_nuevo"',',',    '"lifechainicio":','"',to_char(to_date(NEW.fechadesde,'yyyy-mm-dd'), 'DD-MM-YYYY') ,'"',',', '"lifechafin":','"',to_char(to_date(NEW.fechahasta,'yyyy-mm-dd'), 'DD-MM-YYYY'),'"',',', '"origen":"ofa"',',"idpersona":',rlao.idpersona,',', 
'"leobservacion":"Desde oficina digital-rrhh_oficinadigital_licencias"','}')::jsonb);
    END IF;
  END IF;
return NEW;
END;$function$
