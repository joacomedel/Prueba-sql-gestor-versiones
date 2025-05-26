CREATE OR REPLACE FUNCTION ca.duplicarliquidacion(integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/*
* Este SP genera una nueva liquidacion que es una COPIA de la enviada por parametro
*/
DECLARE
        elidliquidacion integer;
        elidtipo integer;
        elnuevoidliq integer;

BEGIN

     -- duplicar las siguientes tablas:
     --1 liquidacion  / 2- liquidacionempleado / 3- liquidacioncabecera / 4 - conceptoempleado
     elidliquidacion = $1;
     elidtipo = $2;
     
     --1 liquidacion
     INSERT INTO ca.liquidacion(lianio,limes,lifecha,idliquidaciontipo,lifechapago,liingreso,lifechapagoaporte)
            (SELECT lianio,limes,lifecha,elidtipo,lifechapago,liingreso,lifechapagoaporte
            FROM ca.liquidacion
            WHERE idliquidacion = elidliquidacion );
      elnuevoidliq = currval('ca.liquidacion_idliquidacion_seq');

     -- 2- liquidacionempleado
      INSERT INTO ca.liquidacionempleado(idliquidacion,idpersona,leimpneto,leimpbruto,leimpdeducciones,leimpasignacionfam,leimpnoremunerativo)
           (SELECT elnuevoidliq,idpersona,leimpneto,leimpbruto,leimpdeducciones,leimpasignacionfam,leimpnoremunerativo
            FROM ca.liquidacionempleado
            WHERE idliquidacion = elidliquidacion );

    -- 3- liquidacioncabecera
     INSERT INTO ca.liquidacioncabecera(idliquidacion,lcnombreyapellido,emlegajo,penrocuil,lctarea,lccategoria,lcfechaingreso,lcantiguedad,lcbasico,lccontratacion,lcdireccion,lcobrasocial,idpersona,lcsector)
           (SELECT elnuevoidliq ,lcnombreyapellido,emlegajo,penrocuil,lctarea,lccategoria,lcfechaingreso,lcantiguedad,lcbasico,lccontratacion,lcdireccion,lcobrasocial,idpersona,lcsector
            FROM ca.liquidacioncabecera
            WHERE idliquidacion = elidliquidacion );

    

    -- 4 - conceptoempleado
    INSERT INTO ca.conceptoempleado(idliquidacion,cemonto,ceporcentaje,idpersona,idconcepto,ceunidad,cecomentariolibrosueldo,idusuario,cefechamodificacion,cemontofinal)
           (SELECT elnuevoidliq ,cemonto,ceporcentaje,idpersona,idconcepto,ceunidad,cecomentariolibrosueldo,idusuario,cefechamodificacion,cemontofinal
            FROM ca.conceptoempleado
            WHERE idliquidacion = elidliquidacion );

return 	elnuevoidliq;
END;
$function$
