CREATE OR REPLACE FUNCTION public.alerta_farmacia_ingresoarchivoprecios()
 RETURNS text
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de alerta para la modificacion de precios de articulos de farmacia*/

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
 

resultado = concat('<span><b>Se muestran Archivos Ingresados para actualizar los precios durante el ultimo mes</b></span>');
resultado = concat(resultado,'<table border="1" ><tr><th>Fecha Ingreso</th><th>Archivo</th><th>Cant.Productos Ingresados</th></tr>');
OPEN calertas FOR select concat('<tr><td>',to_char(idfechaingreso,'DD-MM-YYYY HH24:MI:SS'),'</td><td>',idfilename,'</td><td>', count(idacodigobarra) ,'</td></tr>') as fila 
		FROM  informaciondrogueria NATURAL JOIN informaciondrogueriaarticulo
                WHERE idfechaingreso>=CURRENT_DATE-30
                GROUP BY idfechaingreso,idfilename;
FETCH calertas into ralerta;
WHILE  found LOOP

resultado = concat(resultado,ralerta.fila,' '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;

resultado = concat(resultado,'</table> '::text);
return resultado;
END;$function$
