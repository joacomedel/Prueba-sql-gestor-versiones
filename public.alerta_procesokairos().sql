CREATE OR REPLACE FUNCTION public.alerta_procesokairos()
 RETURNS character varying
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
resultado = concat('<span><b>Se muestran las ultimas 10 actualizaciones que se corrieron en Kairos.</b></span>');
resultado = concat(resultado,'<table border="1" ><tr><th>Fecha</th><th>Fecha Corrida</th><th>Archivo</th></tr>');
OPEN calertas FOR select concat('<tr><td>',to_char(ikfechainformacion,'DD-MM-YYYY'),'</td><td>',to_char(ikfechaingreso,'HH12:MI:SS PM'),'</td><td>',ikfilename,'</td></tr>') as fila 
		from informacionkairos  
		WHERE  true  
		ORDER BY idinformacionkairos 
		DESC  LIMIT 10;
FETCH calertas into ralerta;
WHILE  found LOOP

      resultado = concat(resultado,ralerta.fila,' '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;

resultado = concat(resultado,'</table> '::text);
return resultado;
END;$function$
