CREATE OR REPLACE FUNCTION public.guardarmodificardatoscliente()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

cursordatoscliente CURSOR FOR SELECT * FROM tempcliente;
regcliente RECORD;

cursordireccion CURSOR FOR SELECT * FROM tempdireccion;
regdireccion RECORD;
datoscliente RECORD;

BEGIN


open cursordatoscliente;
FETCH cursordatoscliente into regcliente;
 
     WHILE FOUND LOOP
           UPDATE cliente SET idcondicioniva = regcliente.idcondicioniva
                              ,cuitini = regcliente.cuitini
	                      ,cuitmedio = regcliente.cuitmedio
                              ,cuitfin = regcliente.cuitfin
                              ,telefono= regcliente.telefono
                              ,email= regcliente.email
                              ,denominacion= rtrim(regcliente.denominacion)
            WHERE nrocliente = regcliente.nrocliente AND barra = regcliente.barra ;

            SELECT INTO datoscliente * FROM cliente WHERE 	nrocliente = regcliente.nrocliente AND barra = regcliente.barra ;
            IF FOUND THEN 
              IF datoscliente.idtipocliente = 2 THEN
                        UPDATE personajuridicabis SET denominacion =regcliente.denominacion
                                                      ,cuitini=regcliente.cuitini
                                                      ,cuitmedio=regcliente.cuitmedio
                                                      ,cuitfin=regcliente.cuitfin
	                WHERE nrocliente = regcliente.nrocliente AND barra = regcliente.barra ;

        
              END IF;
            END IF;

            IF not nullvalue(regcliente.cccdtohaberes) THEN
                UPDATE clientectacte SET cccdtohaberes = regcliente.cccdtohaberes  WHERE nrocliente =regcliente.nrocliente AND barra = regcliente.barra;
            END IF;
      FETCH cursordatoscliente into regcliente;
      END LOOP;

CLOSE cursordatoscliente;


open cursordireccion;
FETCH cursordireccion into regdireccion;
 
     WHILE FOUND LOOP
           UPDATE direccion SET barrio = regdireccion.barrio
                              ,calle = regdireccion.calle
	                      ,nro = regdireccion.nro
                              ,tira = regdireccion.tira
                              ,piso= regdireccion.piso
                              ,dpto= regdireccion.dpto
                              ,idprovincia= regdireccion.idprovincia
                              ,idlocalidad= regdireccion.idlocalidad
            WHERE iddireccion = regdireccion.iddireccion AND idcentrodireccion = regdireccion.idcentrodireccion ;


	
	
      FETCH cursordireccion into regdireccion;
      END LOOP;

CLOSE cursordireccion;

return true;
END;
$function$
