CREATE OR REPLACE FUNCTION public.sys_procesararchivodroguerias(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD 
   rfiltros RECORD;
   rcprecioexcel RECORD;
   rprecioarticulo RECORD;
--CURSOR
   cprecioexcel refcursor;
--VARIABLES 
   elidinformaciondrogueria BIGINT;
      
BEGIN 
    --EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

    SELECT INTO rprecioarticulo * FROM far_articulo_temp LIMIT 1;

/*DEJO EL CAMPO fechainformacion por si en algun momento tenemos esa informacion en los archivos, por ahora es now() igual a la fecha de ingreso.*/
    INSERT INTO informaciondrogueria(idfechainformacion,ididusuariocarga,idfilename) 
	VALUES (now(),sys_dar_usuarioactual(),rprecioarticulo.idfilename );
    elidinformaciondrogueria = currval('informaciondrogueria_idinformaciondrogueria_seq');		
 
 

     OPEN cprecioexcel FOR SELECT * FROM far_articulo_temp; 	
     FETCH cprecioexcel INTO rcprecioexcel;
     WHILE FOUND LOOP
           INSERT INTO informaciondrogueriaarticulo(idinformaciondrogueria,idalinea,idacodigobarra,idaprecio ,idatipoprecio,idprecioarticulosugerido, idcentroprecioarticulosuerido  ) 
		VALUES(elidinformaciondrogueria ,rcprecioexcel.fila,rcprecioexcel.codigobarra,rcprecioexcel.precio,rcprecioexcel.tipoprecio,rcprecioexcel.idprecioarticulosugerido,rcprecioexcel.idcentroprecioarticulosuerido  );
           			
			
	 
     FETCH cprecioexcel INTO rcprecioexcel;
     END LOOP;
     CLOSE cprecioexcel;
 
     return 'Listo';
END;$function$
