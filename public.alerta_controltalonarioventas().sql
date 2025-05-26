CREATE OR REPLACE FUNCTION public.alerta_controltalonarioventas()
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
resultado = concat('<span><b>Talonarios proximos a vencer (60 dias) o proximos a terminar.</b></span>');
resultado = concat(resultado,'<table border="1">
<tr><th>Tipo</th><th>Comp.</th><th>Suc.</th><th>Nro.Final</th><th>Nro.Actual</th><th>Faltan?</th><th>Ctos. Faltan?</th><th>Vto.</th></tr>');
OPEN calertas FOR SELECT  concat('<tr><td>',tipofactura,'</td><td>',CASE WHEN tipocomprobante = 1 THEN 'B' ELSE 'A' END,'</td><td>',nrosucursal,'</td><td>',nrofinal,'</td><td>',sgtenumero,' </td><td>',CASE WHEN (nrofinal - sgtenumero) <= cantidadfacturasantes THEN 'SI' ELSE 'NO' END,'</td><td>',nrofinal - sgtenumero,'</td><td>',to_char(vencimiento,'DD-MM-YYYY'),'</td></tr>') as  fila
		FROM talonario 
		NATURAL JOIN unidadnegociotalonario
		WHERE (vencimiento <= current_date + 60::integer 
		AND vencimiento >= current_date - 5::integer)
			OR (vencimiento >= current_date - 10::integer
			AND (nrofinal - sgtenumero) <= cantidadfacturasantes)
		ORDER BY centro;

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
