CREATE OR REPLACE FUNCTION public.expendio_orden()
 RETURNS type_expendio_orden
 LANGUAGE plpgsql
AS $function$DECLARE
--INTEGER
resp bigint;
respbolean boolean;
rrecibo type_expendio_orden;
--RECORD
rlasordenes RECORD;

BEGIN

SELECT INTO rlasordenes * FROM temporden
                          NATURAL JOIN persona;
 -- RAISE EXCEPTION 'rlasordenes  %  ',rlasordenes.tipo;


/*rlasordenes.tipo = 53  es una orden de consulta de autogestion*/
IF rlasordenes.tipo = 53 OR rlasordenes.tipo = 4 THEN 
	SELECT INTO resp * FROM expendio_asentarconsultarecibo();
        SELECT INTO respbolean *  FROM expendio_insertarrecetarioag();
END IF;
/*es un recetario de tratamiento prolongado*/
IF rlasordenes.tipo =37 THEN 
        SELECT INTO resp * FROM expendio_asentarrecetariotprecibo();
END IF;
IF (rlasordenes.tipo <>53 and rlasordenes.tipo <>37 and rlasordenes.tipo <> 4 ) THEN  
	SELECT INTO resp * FROM expendio_asentarvalorizadarecibo();
END IF;

IF  iftableexists('ttordenesgeneradas')  THEN


 
    IF rlasordenes.tipo<> 55 THEN  
         -- IF rlasordenes.tipo <> 4 THEN  
               SELECT INTO respbolean * FROM expendio_facturarexpendioorden();
          --END IF;
    ELSE --Si es una orden de reintegro genero un informe, no inserto en las tablas de ordenessinfacturas e item
           PERFORM generarinforme_expendioreintegro(); --EL sp me devuelve el nroinforme pero por ahora no lo preciso
    END IF;
 
    

 -- buesco los datos del recibo
     SELECT INTO rrecibo idrecibo,nroorden,centro,ctdescripcion
     FROM recibo
     NATURAL JOIN ordenrecibo
     NATURAL JOIN orden
     JOIN comprobantestipos ON (orden.tipo = comprobantestipos.idcomprobantetipos)
     WHERE centro = centro() and  idrecibo=resp  ;

--KR 24-09-18 agrego para que se llenen las tablas de ficha medica odonto para el expendio de ordenes de odonto
     IF FOUND AND (rlasordenes.tipo =48 ) THEN  
	SELECT INTO respbolean * FROM ficha_medica_cargardesdeorden(rrecibo.nroorden,rrecibo.centro);
    END IF;
      
 END IF;
   
   

    -- nrorecibo centro recibo nroporden centro orden
return rrecibo;
END;
$function$
