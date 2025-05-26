CREATE OR REPLACE FUNCTION public.bajarcategoria()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorcate CURSOR FOR SELECT * FROM tempcategoria;
	cate RECORD;
BEGIN

    OPEN cursorcate;
    FETCH cursorcate into cate;
    WHILE  found LOOP

        INSERT INTO categoria (idcateg,descrip,porcentaport,seaplica) VALUES(cate.idcateg,cate.descrip,cate.porcentaport,cate.seaplica);

    fetch cursorcate into cate;
    END LOOP;
    close cursorcate;

return 'true';
END;
$function$
