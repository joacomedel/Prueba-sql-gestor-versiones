CREATE OR REPLACE FUNCTION ca.tr_guardarhistoricosectorempleado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
       elnuevoreg record;
       rusuario record;
BEGIN

        elnuevoreg = NEW;
        SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
        IF NOT FOUND THEN
              rusuario.idusuario = 25;
        END IF;


        --- 1- actualizar la fecha fin del actual historico del sector al empleado
        UPDATE ca.empleadosector SET esfechafin = now() WHERE idpersona = elnuevoreg.idpersona AND nullvalue(esfechafin);


        --- 2 - ingresar el nuevo sector al que se encuentra vinculado el empleado
       
       INSERT INTO ca.empleadosector (idpersona,  idsector)VALUES(elnuevoreg.idpersona,elnuevoreg.idsector);


  RETURN NEW;
END;
$function$
