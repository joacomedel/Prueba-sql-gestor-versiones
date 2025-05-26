CREATE OR REPLACE FUNCTION public.anularordenpagoconsumoturismo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	consumoturismoOP refcursor;
	unconsumot RECORD;
	resultado boolean;
	rordenpago record;
	estado record;

BEGIN

/* Actualizo el motivo del cambio de estado generado por defecto*/
SELECT INTO rordenpago * FROM tempordenpago;

/* Comento VAS 4/04/18 ya que el cmabio de estado de una minuta se genera desde el SP anularminutapago
UPDATE cambioestadoordenpago set ceopfechafin=CURRENT_DATE WHERE nroordenpago=rordenpago.nroordenpago AND ceopfechafin=NULL;
INSERT INTO cambioestadoordenpago(fechacambio,nroordenpago,idtipoestadoordenpago,motivo)
VALUES(CURRENT_DATE,rordenpago.nroordenpago,4,rordenpago.motivo);

*/
--- OJOOOOOO cambiar aplicacion para poner el centro en la temporal, en la actualidad solo se genran minutas en SC
PERFORM anularminutapago(rordenpago.nroordenpago,1 );

OPEN consumoturismoOP FOR SELECT * FROM consumoturismoordenpago WHERE nroordenpago =rordenpago.nroordenpago;
FETCH consumoturismoOP INTO unconsumot;
WHILE  found LOOP
                   /* Cada consumo turismo vinculado a la OP cambiar el estado */
                   SELECT INTO estado * FROM consumoturismoestado
                    WHERE nullvalue(ctefechafin) 
                         and  idconsumoturismo =unconsumot.idconsumoturismo
                         and idcentroconsumoturismo=unconsumot.idcentroconsumoturismo;
                    IF (estado.idconsumoturismoestadotipos <> 3) THEN -- Si el consumo no fue anulado lo cambio de estado
                                UPDATE consumoturismoestado
                                SET ctefechafin =now()
                                WHERE nullvalue(ctefechafin) AND idconsumoturismoestadotipos <> 3
                                      and  idconsumoturismo =unconsumot.idconsumoturismo
                                      and idcentroconsumoturismo=unconsumot.idcentroconsumoturismo;
                                INSERT INTO consumoturismoestado (idconsumoturismo,idcentroconsumoturismo,idconsumoturismoestadotipos)
                                VALUES (unconsumot.idconsumoturismo,unconsumot.idcentroconsumoturismo,1 ) ;
                    END IF;
     FETCH consumoturismoOP INTO unconsumot;
END LOOP;
CLOSE consumoturismoOP;
resultado = 'true';
RETURN resultado;
END;
$function$
