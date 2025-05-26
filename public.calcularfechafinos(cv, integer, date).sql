CREATE OR REPLACE FUNCTION public.calcularfechafinos(character varying, integer, date)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
/*
* Recibe como parametros el tipo y numero de documento
* Retorna la fecha fin correspondiente al afiliado
*/
DECLARE
       pnrodoc alias for $1;
       ptipodoc alias for $2;
       fechafinos alias for $3;
       datoPersona RECORD;
       aportePersona RECORD;
       fechaSalida date;
begin
/* Busco los datos de la persona*/

            SELECT INTO datoPersona *
            FROM public.persona WHERE persona.nrodoc=pnrodoc and persona.tipodoc=ptipodoc;
            IF FOUND THEN
               /* Busco el utimo aporte recibido de un jubilado / pensionado*/
                           IF(datoPersona.barra =30 OR datoPersona.barra =32 OR datoPersona.barra =31 OR datoPersona.barra =33 OR datoPersona.barra =37)THEN
                                       fechaSalida = fechafinos + '3 month'::interval;

                           ELSE
                                        fechaSalida = fechafinos + interval '1 month';
                   
                           END IF;
             END IF;
              
return fechaSalida;

end;
$function$
