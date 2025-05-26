CREATE OR REPLACE FUNCTION public.modificarcategoriaafilsosunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rcategoria record;      
        resp boolean;
      

BEGIN

SELECT INTO rcategoria *  FROM tcategoria;
IF FOUND THEN 
		IF(not nullvalue(rcategoria.idcateg)) THEN

       
	INSERT INTO categoria (idcateg,porcentaport,seaplica,tipoafil,descrip,seaplicaasi)VALUES
        (rcategoria.idcateg,rcategoria.porcentaport,rcategoria.seAplica,rcategoria.tipoafil,rcategoria.descrip,rcategoria.seaplicaasi);
                END IF;

                

 END IF;

return 'true';
END;
$function$
