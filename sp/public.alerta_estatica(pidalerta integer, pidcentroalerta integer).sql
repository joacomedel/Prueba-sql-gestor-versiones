CREATE OR REPLACE FUNCTION public.alerta_estatica(pidalerta integer, pidcentroalerta integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	calertas REFCURSOR;
	ralerta RECORD;
	rusuario RECORD;
	resultado TEXT;
        

BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

OPEN calertas FOR SELECT concat('<span><b>',aleasunto,'</b></span> <div>',aletexto,' </div> <span><i> Convoca: ',login,'</i></span>') as fila 
		FROM alerta  
		JOIN usuario ON idusuario = idusuariocreacion  
		NATURAL JOIN alertaconfigura    
		WHERE  idalerta = pidalerta AND idcentroalerta = pidcentroalerta;
FETCH calertas into ralerta;
WHILE  found LOOP

      resultado = concat(resultado,ralerta.fila,' <br> '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;


return resultado;
END;
$function$
