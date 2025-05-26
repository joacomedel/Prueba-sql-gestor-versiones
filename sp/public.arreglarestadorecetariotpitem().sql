CREATE OR REPLACE FUNCTION public.arreglarestadorecetariotpitem()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSOR
  crecetpitem refcursor;
  
--RECORD
  rrecetpitem RECORD;

--VARIABLES
  resp BOOLEAN;
        
BEGIN

  resp = true;
 OPEN crecetpitem FOR SELECT far_cantconsumida_rtpi_v1(idrecetariotpitem, idcentrorecetariotpitem) as cantconsumida , rtpicantidadauditada, idrecetariotpitem, idcentrorecetariotpitem  
	FROM recetariotpitem as rtpi LEFT JOIN  recetarioitemestado AS rie ON(rtpi.idrecetariotpitem = rie.idrecetarioitem and rtpi.idcentrorecetariotpitem = rie.idcentrorecetarioitem )
	WHERE nullvalue(rie.idrecetarioitem);  

 FETCH crecetpitem into rrecetpitem;
 WHILE  found LOOP
	
 	IF ((CASE WHEN nullvalue(rrecetpitem.cantconsumida) THEN 0 ELSE rrecetpitem.cantconsumida END)=rrecetpitem.rtpicantidadauditada) THEN 
		
		PERFORM far_cambiarestadorecetarioitem(rrecetpitem.idrecetariotpitem, rrecetpitem.idcentrorecetariotpitem, 5, 'Se vendio toda la cantidad auditada. ');
	ELSE 
		PERFORM far_cambiarestadorecetarioitem(rrecetpitem.idrecetariotpitem, rrecetpitem.idcentrorecetariotpitem, 4, 'Se presenta el recetario TP en farmacia. ');
	END IF; 
 FETCH crecetpitem into rrecetpitem;
 END LOOP;
 close crecetpitem;

RETURN resp;     
END;$function$
