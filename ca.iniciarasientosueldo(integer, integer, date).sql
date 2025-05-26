CREATE OR REPLACE FUNCTION ca.iniciarasientosueldo(integer, integer, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
* Inicializa los asientos de sueldo
* PRE: las liquidaciones correspondientes a ese mes  adeben estar TODAS cerradas
*/
DECLARE
       elmes integer;
       elanio integer;
       codasientosueldo integer;
       rsliquidacion record;
       rsasiento record;
       regasientoconf record;
       cursorconfasiento refcursor;
       fechaasiento date;
       salida boolean;
        anteriorasiento record;
     
BEGIN
     elmes = $1;  -- mes de la liquidacion
     elanio = $2; -- anio de la liquidacion
     fechaasiento = $3; -- fecha del asiento
   

     SET search_path = ca, pg_catalog;
     /* Verifico las liquidaciones  para ese mes y ese anio esten cerradas */
     SELECT INTO rsliquidacion CASE WHEN  ( limes <>12 and limes <>6 ) THEN true
            WHEN (count(*)>=4 and (limes =12 or limes =6) ) THEN true
            ELSE false END as liquidacionescerradas
     FROM ca.liquidacion
     WHERE limes= elmes and lianio= elanio and not nullvalue(lifecha)
     group by limes,lianio;

     IF (NOT FOUND or NOT rsliquidacion.liquidacionescerradas) THEN
              salida = false; -- no existe una liquidacion para ese mes y ese anio
                              -- no se encuentran todas las liquidaciones cerradas correspondientes a ese mes y anio
     ELSE
         SELECT INTO rsasiento * FROM ca.asientosueldo WHERE  limes= elmes and lianio= elanio;
         IF FOUND THEN
             salida = false; --  ya existe un asiento para ese mes y ese año
         ELSE
               /* Recupero la clave del asiento del mes anterior */
           SELECT INTO anteriorasiento * FROM ca.asientosueldo 
           order by lianio desc ,limes  desc limit      1;
   
               -- No exite un asiento sueldo para ese mes y ese año => se crea el asiento inicial
              INSERT INTO ca.asientosueldo (limes, lianio) VALUES (elmes,elanio);
              codasientosueldo = currval('ca.asientosueldo_idasientosueldo_seq');
              
              -- Creo el asiento por defecto configurado para una liquidacion
              -- Donde los importes del asiento se encuentran en 0
--Dani modifico el 11-05-2015 para q traiga las configuraciones vigentes del asiento de sueldo del mes anterior
               open  cursorconfasiento for SELECT    * FROM ca.asientosueldotipoctactble 
                                           natural join ca.asientosueldoctactble 
                                           WHERE asvigente and   
                                              idasientosueldo=anteriorasiento.idasientosueldo;
              FETCH cursorconfasiento INTO regasientoconf ;
               WHILE FOUND LOOP
                     INSERT INTO ca.asientosueldoctactble (idasientosueldo,ascimporte,idasientosueldotipoctactble)
                     VALUES ( codasientosueldo,0, regasientoconf.idasientosueldotipoctactble ) ;
              FETCH cursorconfasiento INTO regasientoconf;
              END LOOP;
              CLOSE cursorconfasiento;
              --Llamar a recalcular de las formulas del asiento
              salida = as_recalcular(codasientosueldo);

         END IF;


     END IF;

return 	salida;
END;
$function$
