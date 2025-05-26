CREATE OR REPLACE FUNCTION public.cerrarregistros()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
     cregistros CURSOR FOR SELECT  *
                        FROM  sigesregistro 
                        WHERE nullvalue(srprocesados) LIMIT 1;
                       
     elem RECORD;
     relestado RECORD;
     respuesta Boolean;

BEGIN
    
OPEN cregistros;
FETCH cregistros INTO elem;
WHILE  found LOOP


    SELECT INTO relestado * FROM festados WHERE anio=elem.anio AND nroregistro=elem.nroregistro AND nullvalue(fefechafin);
    IF (relestado.tipoestadofactura =0) THEN 
        IF(elem.idusuario <> null) THEN 
               select log_registrar_conexion(elem.idusuario,'TCargarOrdenDeFacturaTodas'); 
        END IF;
        SELECT INTO respuesta guardarprestacionesfacturaorden(elem.nroregistro,elem.anio);
        UPDATE sigesregistro SET srprocesados=now() WHERE  anio=elem.anio AND nroregistro=elem.nroregistro;
    END IF;
   

fetch cregistros into elem;
END LOOP;
CLOSE cregistros;


return respuesta;
END;
$function$
