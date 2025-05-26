CREATE OR REPLACE FUNCTION public.rrhh_oficinadigital_permiso()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de la licencia  a la estructura de oficina digital (uncoma) */

DECLARE

--RECORD    
     rpermiso RECORD;
     rlicencia RECORD;
--VARIABLES 
     vlicenciaestado INTEGER; 
BEGIN
  
  SELECT INTO rpermiso * FROM ofa_tipolicencialicenciatipo WHERE idtipolic = NEW.idtipolic;
 

  IF (TG_OP = 'UPDATE') THEN -- se trata de una modificacion 
     SELECT INTO rlicencia * FROM ofa_permisopersonallicencia WHERE idcertificado = NEW.idcertificado;
     
      
     vlicenciaestado = CASE WHEN NEW.estado = 0 or NEW.estado = 6 THEN 4 ELSE NEW.estado END; 
     PERFORM w_rrhh_abmlicencias(concat('{"idlicencia":',rlicencia.idlicencia,',', '"accion":"w_licencia_accion_modificar"',',','"lifechainicio":','"',NEW.fechadesde,'"',',', '"lifechafin":','"',NEW.fechahasta,'"',',', '"idlicenciatipo":','"',rpermiso.idlicenciatipo,'"',',', '"idlicenciaestadotipo":','"',vlicenciaestado,'"',',',
   '"leobservacion":"Desde oficina digital-rrhh_oficinadigital_permiso"','}')::jsonb);
      
  ELSE 
    IF (TG_OP = 'INSERT') THEN  
       
        INSERT INTO ofa_permisopersonallicencia(idcertificado) VALUES(NEW.idcertificado);
       
        PERFORM w_rrhh_abmlicencias(concat('{"idlicenciatipo":', rpermiso.idlicenciatipo 	,',', '"accion":"w_licencia_accion_nuevo"',',',    '"lifechainicio":','"',to_char(to_date(NEW.fechadesde,'yyyy-mm-dd'), 'DD-MM-YYYY'),'"',',', '"lifechafin":','"',to_char(to_date(NEW.fechahasta,'yyyy-mm-dd'), 'DD-MM-YYYY'),'"',',', '"origen":"ofa"',',"idpersona":',NEW.idpersona,',', '"idcertificado":',NEW.idcertificado,',', 
'"leobservacion":"Desde oficina digital-rrhh_oficinadigital_permiso"','}')::jsonb);
    END IF;
  END IF;
return NEW;
END;$function$
