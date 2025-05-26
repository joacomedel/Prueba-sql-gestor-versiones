CREATE OR REPLACE FUNCTION public.far_limpiarprecarga()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


--Busco precargas con fecha uso null

--CURSORES
cprecargas 
            CURSOR FOR 
                SELECT * 
                FROM far_precargapedido_articulo
                WHERE nullvalue(fechauso);
-- RECORD 
rprecarga record;


BEGIN


	OPEN cprecargas;
	FETCH cprecargas into rprecarga;
	WHILE  FOUND LOOP

	UPDATE far_precargapedido_articulo SET fechauso=now() WHERE idprecargacomprobante= rprecarga.idprecargacomprobante;

	FETCH cprecargas into rprecarga;
	END LOOP;
	CLOSE cprecargas;

return 'true';
END;
$function$
