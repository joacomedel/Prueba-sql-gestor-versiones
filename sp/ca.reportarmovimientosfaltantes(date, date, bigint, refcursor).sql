CREATE OR REPLACE FUNCTION ca.reportarmovimientosfaltantes(date, date, bigint, refcursor)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
*PARAMETROS : $1 fecha ini
              $2 fecha fin
              $3 idpersona
*/


DECLARE

indice date;
codpersona bigint;
BEGIN
SET search_path = ca, pg_catalog;



indice = $1;
codpersona = $3;
WHILE indice < $2   LOOP

IF $3 = 0 THEN
        INSERT INTO temporalmas(fecha,codigopersona,penombre , peapellido , documento,ltdescripcion,sedescripcion)
		(  SELECT  indice, idpersona, penombre,peapellido,  documento ,  ltdescripcion,  sedescripcion
			FROM (
			SELECT indice, idpersona,  penombre,peapellido, concat(tdnombre , ' : ' , penrodoc) as documento ,  ltdescripcion,  sedescripcion
			FROM persona
            natural join tipodocumento
            natural join empleado
            natural join sector
            natural join licencia
            natural join licenciatipo
			WHERE lifechainicio <= indice and lifechafin >= indice
			UNION
			SELECT indice, idpersona,  penombre, peapellido, concat( tdnombre , ' : ' , penrodoc) as documento,  'No Ficho' as ltdescripcion,  sedescripcion
			FROM persona
            natural join tipodocumento
            natural join empleado
            natural join sector
            natural join jornada
            natural join jornadahorario
            LEFT JOIN ( 	
                 SELECT * FROM movimientos 	
                 NATURAL JOIN auditoriamovimiento 	
                 WHERE amfecha = indice 	
                       and idmovimientotipo = 1 ) as t USING(idpersona)
			WHERE jornadahorario.jhdia = (select date_part('dow',indice::date)+1)
            and jornada.jorfechainicio <= indice
            and jornada.jorfechafin >= indice and t.idmovimiento is null
			) as t
      );
ELSE

INSERT INTO temporalmas(fecha,codigopersona,penombre , peapellido , documento,ltdescripcion,sedescripcion)
		(
			SELECT  indice, idpersona,  penombre,peapellido,  documento ,  ltdescripcion,  sedescripcion
		 	        FROM (
			             SELECT indice, idpersona,  penombre,peapellido, concat(tdnombre , ' : ' , penrodoc )as documento ,  ltdescripcion,  sedescripcion
			             FROM persona
                         natural join tipodocumento
                         natural join empleado
                         natural join sector
                         natural join licencia
                         natural join licenciatipo
                     WHERE lifechainicio <= indice
                           and lifechafin >= indice
                           AND idpersona = codpersona
			UNION
			SELECT indice, idpersona,  penombre, peapellido, concat( tdnombre , ' : ' , penrodoc) as documento,  'No Ficho' as ltdescripcion,  sedescripcion
			       FROM persona
                   natural join tipodocumento
                   natural join empleado
                   natural join sector
                   natural join jornada
                   natural join jornadahorario
                   LEFT JOIN ( 	SELECT * FROM movimientos 	
                                       NATURAL JOIN auditoriamovimiento 	
                                       WHERE amfecha = indice 	
                                       and idmovimientotipo = 1 ) as t USING(idpersona)
		          	WHERE jornadahorario.jhdia = (select date_part('dow',indice::date)+1)
                      and jornada.jorfechainicio <= indice
                      and jornada.jorfechafin >= indice
                      and t.idmovimiento is null AND idpersona = codpersona
			) as t);

END IF;

 indice = indice + CAST('1 days' AS INTERVAL);

END  LOOP;

return 	true;
END;
$function$
