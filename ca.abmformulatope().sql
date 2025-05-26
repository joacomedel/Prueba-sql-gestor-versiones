CREATE OR REPLACE FUNCTION ca.abmformulatope()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

       camformulatope refcursor;
       untope record;
BEGIN
      OPEN camformulatope FOR SELECT * FROM temptope;
      FETCH camformulatope INTO untope;
      WHILE FOUND LOOP
            if (untope.idformulatope = 0) THEN
               -- updateo la fecha fin del anterior   
               UPDATE ca.formulatope
               SET astcctfechahasta = untope.astcctfechadesde
               WHERE nullvalue(astcctfechahasta) and idformula = untope.idformula;

               -- creo una nueva configuracion
               INSERT INTO ca.formulatope (idformula,astcctfechadesde,astcctfechahasta,astcctmonto,astcctmontoalicuota,astporcentaje)
               VALUES(  untope.idformula,untope.astcctfechadesde,untope.astcctfechahasta,untope.astcctmonto,untope.astcctmontoalicuota,untope.astporcentaje   );


            ELSE -- Actualizo los datos existentes
                  
                  UPDATE ca.formulatope SET
                         astcctfechadesde  = untope.astcctfechadesde  ,
                         astcctfechahasta  = untope.astcctfechahasta  ,
                         astcctmonto  = untope.astcctmonto  ,
                         astcctmontoalicuota  = untope.astcctmontoalicuota  ,
                         astporcentaje  = untope.astporcentaje
                  WHERE idformulatope = untope.idformulatope;

            END IF;

      FETCH camformulatope INTO untope;
      END LOOP;
      close camformulatope;


return true;


END;
$function$
