CREATE OR REPLACE FUNCTION ca.f_asignacion(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       elmontoayuda DOUBLE PRECISION;
     --  canthijos integer;
       rliquidacion record;
       elconcepto record;
       elconceptoayuda record;
       rinfovinculo record;
BEGIN
--reemplazarparametrosmontohaberes<=montohaberes<=8400
--(integer, integer, integer, integer, varchar)
/*
     codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;
*/

--f_asignacion(#,&, ?,@)


  SELECT INTO elmonto ca.f_asignaciondarmontoescala($1,$2,$3,$4);
  
  
  IF($4=27) THEN -- Si el concepto es Hijo
            SELECT INTO rinfovinculo count(*) as canthijos ,
            public.text_concatenar(concat(videscripcion ,': ',  penombre ,' ',peapellido,' - ')) as paralibro
            , SUM(CASE WHEN extract(YEAR from age(pefechanac) ) >= 4 THEN 1 ELSE 0 END ) as hijosayuda
            FROM ca.empleadopersona
            join ca.empleado as e on (e.idpersona=ca.empleadopersona.idempleado)
            JOIN ca.persona as p ON (ca.empleadopersona.idpersona=p.idpersona) 	
            NATURAL JOIN ca.vinculo
            WHERE idvinculo= 2 and e.idpersona =$3
                  and extract(YEAR from age(pefechanac) ) < 18
            group by e.idpersona;
            
            IF FOUND THEN   -- si tiene hijos el empleado
                     SELECT INTO elconcepto *
                     FROM ca.conceptoempleado
                     WHERE idliquidacion=$1 and idpersona =$3 and idconcepto=$4 ;
                     IF FOUND THEN  -- si tiene configurado el concepto hijo
                              UPDATE ca.conceptoempleado SET  ceporcentaje = rinfovinculo.canthijos
                                                ,cemonto= elmonto
                                                ,cecomentariolibrosueldo = rinfovinculo.paralibro
                               WHERE idliquidacion=$1 and idpersona =$3 and idconcepto=$4 ;
                      ELSE
                                   INSERT INTO ca.conceptoempleado(
                                   cemonto,ceporcentaje,idliquidacion,idpersona,idconcepto,ceunidad,cecomentariolibrosueldo )
                                   VALUES (elmonto,rinfovinculo.canthijos,$1,$3,$4,1,rinfovinculo.paralibro);

                    END IF;
                    -- Verifico si es una liquidacion del mes de marzo para liquidar el concepto ayuda escaolar a todos los que tienen hijos
                    SELECT INTO rliquidacion * FROM ca.liquidacion WHERE idliquidacion=$1 ;
                    IF FOUND and (rliquidacion.limes=3  or (rliquidacion.limes=4 and $3 =99))THEN
                           SELECT INTO elmontoayuda ca.f_asignaciondarmontoescala($1,$2,$3,29);

                           SELECT INTO elconceptoayuda * FROM ca.conceptoempleado
                           WHERE idliquidacion=$1 and idpersona =$3 and idconcepto=29 ;
                          -- VAS 280414 saca comentario bloque  /* Se comento para que se puedan modificar la cantidad de hijos
                          IF FOUND THEN
                               UPDATE ca.conceptoempleado
                               SET  ceporcentaje = rinfovinculo.hijosayuda , cemonto= elmontoayuda
                               WHERE idliquidacion=$1 and idpersona =$3 and idconcepto=29 ;
                           ELSE
                                INSERT INTO ca.conceptoempleado(
                                       cemonto,ceporcentaje,idliquidacion,idpersona,idconcepto,ceunidad )
                                VALUES (elmontoayuda,rinfovinculo.hijosayuda,$1,$3,29,1);
                           END IF;
                          -- VAS 280414  saca comentario bloque  */
                    ELSE
                     /*RESTRICCION !!! este concepto solo se liquida en el mes 3 o 6*/
                 -- Dani comento el 29-04-2015 para q permita en el mes 04 y en forma excepcional agregar la aydua escolar anual al legajo 15 de farmacia.Recordar sacarlo para liquidaciones posteriores.
                 -- Vivi descomento 28-03-2016 para que en la proxima liq se elimine el concepto ayuda
                   IF (rliquidacion.limes<>3 and rliquidacion.limes<>6) THEN
                       DELETE FROM ca.conceptoempleado WHERE idliquidacion=$1 and idpersona =$3 and idconcepto=29;
             
             
                   END IF;

                 END IF;  -- mes =3
           ELSE
                DELETE FROM ca.conceptoempleado WHERE idliquidacion=$1 and idpersona =$3 and idconcepto=27 ;
                 DELETE FROM ca.conceptoempleado WHERE idliquidacion=$1 and idpersona =$3 and idconcepto=29 ;
           END IF;-- tiene hijos

  END IF; -- concepto Hijo
return 	elmonto;
END;
$function$
