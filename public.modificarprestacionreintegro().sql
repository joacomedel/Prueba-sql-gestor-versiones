CREATE OR REPLACE FUNCTION public.modificarprestacionreintegro()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Es llamado desde reintegros cuando se modifica las prestaciones de un reintegro
dado , se utiliza la una tabla temporal tempreintegromodificado.
Modifica la tabla reintegroprestacion y reintegro*/

DECLARE
--REGISTROS
    relreintegro RECORD; 
    rrec  RECORD; 
    rexistetabla RECORD;
--CURSOR
    rrecreintegro CURSOR FOR
                  SELECT *
                             FROM tempreintegromodificado;

BEGIN

 SELECT INTO relreintegro * FROM tempreintegromodificado;
    DELETE FROM reintegroprestacion
           WHERE reintegroprestacion.anio= relreintegro.anio AND reintegroprestacion.nroreintegro=relreintegro.nroreintegro 
           AND reintegroprestacion.idcentroregional=relreintegro.idcentroregional;

    IF (iftableexistsparasp('tempitems')) THEN 
      SELECT INTO rexistetabla SUM(amuc)as amuc,SUM(afiliado) as afiliado,SUM(sosunc) as sosunc,max(idplancob) as idplancob FROM  tempitems; 
      IF FOUND AND rexistetabla.afiliado > 0 THEN 
           
           INSERT INTO reintegroprestacion(nroreintegro,anio,tipoprestacion,observacion,importe,cantidad,idcentroregional)
          SELECT relreintegro.nroreintegro,relreintegro.anio,tipoprestacion,text_concatenar(obsprestacion), sum(tempitems.afiliado)as importe, sum(tempitems.cantidad) as cantidad,relreintegro.idcentroregional
           FROM tempitems  
           GROUP BY tipoprestacion;

      ELSE 
            RAISE EXCEPTION ' No es posible el expender el reintegro. El importe es incorrecto!! .  %  ',rexistetabla.afiliado;
      
      END IF;

            
                 	 
                 
    ELSE 
        OPEN rrecreintegro;	
	FETCH rrecreintegro INTO rrec;
	
	WHILE  found LOOP
	   INSERT INTO reintegroprestacion(nroreintegro,anio,tipoprestacion,importe,observacion,prestacion,cantidad,idcentroregional)
		         VALUES(rrec.nroreintegro,rrec.anio,rrec.tipoprestacion,(case when nullvalue(rrec.importe) then 0 else rrec.importe end),rrec.observacion,rrec.prestacion,rrec.cantidad,rrec.idcentroregional);
              
            FETCH rrecreintegro INTO rrec;
	END LOOP;
	CLOSE rrecreintegro ;
    END IF;
 



   
  
     UPDATE reintegro SET rimporte = T.importe  FROM 
     (SELECT sum(importe) as importe,nroreintegro,anio,idcentroregional 
      FROM  reintegroprestacion 
      WHERE nroreintegro=relreintegro.nroreintegro  AND anio=relreintegro.anio AND idcentroregional= relreintegro.idcentroregional
      GROUP BY nroreintegro,anio,idcentroregional) AS T
      WHERE  reintegro.nroreintegro=T.nroreintegro AND reintegro.anio=T.anio AND reintegro.idcentroregional= T.idcentroregional;
	RETURN 'true';
END;

$function$
