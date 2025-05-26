CREATE OR REPLACE FUNCTION public.alerta_tesoreria_ctactearchivossinlegajo()
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
 
resultado = concat('<span><b>Se muestran los datos de afiliados cuyo numero de legajo es nulo</b></span>');
resultado = concat(resultado,'<table border="1" ><tr><th>Afiliado</th><th>Nro.Afiliado</th><th>Fecha Envio</th><th>Mov.Concepto</th><th>Id.Movimiento</th>');
OPEN calertas FOR select concat('<tr><td>',concat(apellido, ' ', nombres),'</td><td>',concat(persona.nrodoc, '-', persona.barra),'</td><td>',fechaenvio ,'</td></tr>','</td><td>',movconcepto,'</td></tr>','</td><td>',concat(idmovimiento,'-',idcentromovimiento),'</td></tr>') as fila 
		FROM  enviodescontarctactev2 NATURAL JOIN persona NATURAL JOIN tiposdoc JOIN afilsosunc USING(nrodoc,tipodoc)        
                LEFT JOIN (SELECT max(legajosiu) as legajosiu,nrodoc,tipodoc FROM cargo GROUP BY nrodoc,tipodoc) as t USING(nrodoc,tipodoc)            
                WHERE enviodescontarctactev2.idenviodescontarctacte = concat(EXTRACT(YEAR FROM now())::text, lpad(EXTRACT(MONTH FROM now())::text,2,'0') )   AND nullvalue(t.legajosiu)
                ORDER BY persona.apellido; 
FETCH calertas into ralerta;
WHILE  found LOOP

resultado = concat(resultado,ralerta.fila,' '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;

resultado = concat(resultado,'</table> '::text);
return resultado;
END;$function$
