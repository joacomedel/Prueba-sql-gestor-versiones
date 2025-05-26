CREATE OR REPLACE FUNCTION public.alerta_descuentosnoprocesados()
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
resultado = concat('<span><b>Datos de DHs No procesados</b></span>');
resultado = concat(resultado,'<table border="1">
<tr><th>Id.</th><th>LegajoSiu</th><th>Importe</th><th>Dep. Uni.</th><th>MesAñoProc/F.Fin Lab</th><th>Nro.Cargo</th><th>Nro.Liquidacion/NroDoc</th><th>Categoria</th><th>Tipo Error</th></tr>');

							
OPEN calertas FOR 

SELECT  concat('<tr><td>',idinfomeerrordescuentosplanilla,'</td><td>',legajosiu,'</td><td>',importe,'</td><td>',null,'</td><td>',concat(mesingreso,'-',anioingreso),'</td><td>',nrocargo,'</td><td>',nroliquidacion,'</td><td>',null,'</td><td>','Error en legajosiu o nrocargo','</td></tr>') as fila
		FROM infomeerrordescuentosplanilla
                WHERE mesingreso = date_part('month', current_date -30) and anioingreso=date_part('year', current_date - 30)
UNION 

SELECT  concat('<tr><td>',idtdesignaciones,'</td><td>',legajosiu,'</td><td>',null,'</td><td>',iddepen,'</td><td>',fechafinlab,'</td><td>',idcargo ,' </td><td>',concat(descrip, ' ',nrodoc),'</td><td>',idcateg,'</td><td>',tipoinforme,'</td></tr>') as fila
		FROM tdesignaciones NATURAL JOIN tiposdoc
;

FETCH calertas into ralerta;
WHILE  found LOOP

      resultado = concat(resultado,ralerta.fila,' '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;

resultado = concat(resultado,'</table> '::text);
return resultado;
END;


$function$
