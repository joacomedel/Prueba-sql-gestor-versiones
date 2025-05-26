CREATE OR REPLACE FUNCTION public.anularminutapagoreintegro(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD 
	rlaminuta RECORD; 
        restadominuta RECORD;
--VARIABLES  
	respuesta BOOLEAN;
	rtaspestadominuta BOOLEAN; 
BEGIN
	respuesta = true;
        SELECT INTO rlaminuta * FROM ordenpago WHERE nroordenpago= $1 AND idcentroordenpago = $2;

	IF rlaminuta.idordenpagotipo = 2 THEN--es una minuta de reintegros
--Verifico que todas las OPC de la minuta esten anuladas, el estado de la minuta no se verifica
        SELECT INTO  restadominuta * FROM ordenpagocontableordenpago NATURAL JOIN ordenpagocontableestado 
		WHERE nroordenpago =  $1 AND idcentroordenpago=$2  and nullvalue(opcfechafin)
                 AND idordenpagocontableestadotipo<>6;	
         --TODAS las OPC estan anuladas entonces revierto el reintegro y lo dejo pendiente
         IF NOT FOUND THEN
		INSERT INTO restados (fechacambio,nroreintegro,anio,tipoestadoreintegro,observacion,idcentroregional) 
		SELECT CURRENT_DATE,nroreintegro,anio,1,concat('Al Ser anulada la MP: ', rlaminuta.nroordenpago, '-' ,rlaminuta.idcentroordenpago),idcentroregional
				 FROM reintegro 
				 WHERE nroordenpago = rlaminuta.nroordenpago AND idcentroordenpago = rlaminuta.idcentroordenpago;
            
                UPDATE reintegroprestacion SET importe = 0 WHERE (anio, nroreintegro,idcentroregional) IN 
               (SELECT anio, nroreintegro,idcentroregional FROM reintegro 
              WHERE nroordenpago = rlaminuta.nroordenpago AND idcentroordenpago = rlaminuta.idcentroordenpago);
  
		UPDATE reintegro SET nroordenpago=NULL, idcentroordenpago= NULL, rimporte= 0
		WHERE nroordenpago = rlaminuta.nroordenpago AND idcentroordenpago = rlaminuta.idcentroordenpago; 
                
		SELECT INTO respuesta  anularminutapago($1,$2);
           
	
        ELSE 
               RAISE EXCEPTION 'La minuta o alguna de sus OPC vinculadas estan en un estado que imposibilita el proceso que desea realizar. MP % % ',$1,$2;
	 

	END IF;
	END IF;
  return respuesta;

END;
$function$
