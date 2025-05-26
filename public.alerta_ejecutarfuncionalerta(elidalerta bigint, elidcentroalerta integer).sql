CREATE OR REPLACE FUNCTION public.alerta_ejecutarfuncionalerta(elidalerta bigint, elidcentroalerta integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    salida boolean;
    rsconfalerta record;

BEGIN
/*
*  retorna verdadero si la funcion vinculada a la alerta debe ejecutarse y falso en caso contrario
*/

           SELECT INTO rsconfalerta *
           FROM  alerta
           NATURAL JOIN alertaconfigura
           NATURAL JOIN alertaconfiguratipo
           WHERE idcentroalerta = elidcentroalerta and  idalerta= elidalerta;
           
           IF ( rsconfalerta.alefechainicio <= now() AND ( nullvalue(rsconfalerta.acfechafinconfigura) OR (rsconfalerta.acfechafinconfigura >= now()) ) ) THEN
                 CASE WHEN (rsconfalerta.acttexto ilike 'Diaria') THEN
                             salida = true;
                        WHEN (rsconfalerta.acttexto ilike 'Mensual' AND  TO_CHAR(date(now()),'DD') ilike TO_CHAR(date(rsconfalerta.alefechainicio),'DD') ) THEN
                             salida = true;
                        WHEN (rsconfalerta.acttexto ilike 'Anual' AND   TO_CHAR(date(now()),'DDMM') ilike TO_CHAR(date(rsconfalerta.alefechainicio),'DDMM') ) THEN
                              salida = true;
                 ELSE
                       salida =false;
                 END  CASE;
          END IF;
RETURN 	salida;
END;
$function$
