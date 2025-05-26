CREATE OR REPLACE FUNCTION public.insertarrtpie()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN;
 
--CURSORES
  csql refcursor;

--RECORD
  elem RECORD;
  
BEGIN
respuesta = true;
 
OPEN csql FOR  SELECT  idrecetariotpitem, idcentrorecetariotpitem, far_cantconsumida_rtpi_v1(idrecetariotpitem, idcentrorecetariotpitem) as cantconsumida , rtpicantidadauditada, idvalidacionitem, idcentrovalidacionitem
FROM recetariotpitem AS rtpi LEFT JOIN recetarioitemestado as rie ON (rtpi.idrecetariotpitem= rie.idrecetarioitem and rtpi.idcentrorecetariotpitem = rie.idcentrorecetarioitem)
WHERE nullvalue(rie.idrecetarioitemestado); 
FETCH csql INTO elem;  


  WHILE FOUND LOOP

	IF (elem.cantconsumida=elem.rtpicantidadauditada) THEN
		PERFORM far_cambiarestadorecetarioitem(elem.idrecetariotpitem, elem.idcentrorecetariotpitem, 5, 'Se vendio toda la cantidad auditada. ');

		  PERFORM  far_cambiarestadovalidacionitem(null,null, T.idvalidacionitem, T.idcentrovalidacionitem,5) FROM (
			SELECT idvalidacionitem,idcentrovalidacionitem  
                        FROM far_validacionitems  
			WHERE idvalidacionitem= elem.idvalidacionitem AND idcentrovalidacionitem=elem.idcentrovalidacionitem) AS T;

	ELSE --SE supone es menor 
		PERFORM far_cambiarestadorecetarioitem(elem.idrecetariotpitem, elem.idcentrorecetariotpitem, 4, 'Se presento el recetario en la farmacia. Hay cantidades aun por vender. ');
                PERFORM  far_cambiarestadovalidacionitem(null,null, T.idvalidacionitem, T.idcentrovalidacionitem,1) FROM (
			SELECT idvalidacionitem,idcentrovalidacionitem  
                        FROM far_validacionitems  
			WHERE idvalidacionitem= elem.idvalidacionitem AND idcentrovalidacionitem=elem.idcentrovalidacionitem) AS T;
	END IF;
              
          
     
FETCH csql INTO elem;
END LOOP;
CLOSE csql;
return respuesta;
END;$function$
