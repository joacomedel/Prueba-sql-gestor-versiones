CREATE OR REPLACE FUNCTION public.rrhh_oficinadigital_remanentes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$/* Maneja la info de los remanentes*/

DECLARE

--RECORD    
     rlao RECORD;
--VARIABLES 
     vlicenciaestado INTEGER;
     vidtipolic  INTEGER;
BEGIN
  
  SELECT INTO  vidtipolic idtipolic FROM ofa_tipolicencialicenciatipo WHERE idtipolic = NEW.idtipolic;
 
  
  SELECT INTO rlao * FROM ofa_sollicencia WHERE  idsolicitud = NEW.idsolicitud;
  IF (TG_OP = 'UPDATE') THEN -- se trata de una modificacion 
     
   --  RAISE NOTICE 'rmodlic (%)',rmodlic;
     vlicenciaestado = CASE WHEN NEW.estado = 0 THEN 4 ELSE NULL END; 
     PERFORM w_rrhh_abmlicencias(concat('{"idlicencia":',vidtipolic',', '"accion":"w_licencia_accion_modificar"',',','"lifechainicio":','"',NEW.fechadesde,'"',',', '"lifechafin":','"',NEW.fechahasta,'"',',', '"idlicenciatipo":','"',rlao.idlicenciatipo,'"',',', '"idlicenciaestadotipo":','"',vlicenciaestado,'"',',',
   '"leobservacion":"Desde oficina digital-rrhh_oficinadigital_licencias"','}')::jsonb);
      
  ELSE 
    IF (TG_OP = 'INSERT') THEN  
       

    END IF;
  END IF;
return NEW;
END;$function$
