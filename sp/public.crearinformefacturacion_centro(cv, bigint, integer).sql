CREATE OR REPLACE FUNCTION public.crearinformefacturacion_centro(character varying, bigint, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/*
 * Se pasan por parametro el nrocliente, la barra del cliente y el idinformefacturaciontipo que identifica si el informe es de turismo, asistencial, reciprocidad, amuc.
*/

DECLARE
	
	idnroinforme INTEGER;
	eltipodoc INTEGER;
        labarra INTEGER;
        vcentro INTEGER;
BEGIN
	vcentro=6;

       
	SELECT INTO eltipodoc tipodoc FROM persona WHERE nrodoc=$1 and barra=$2;
        IF FOUND THEN 
                 labarra = eltipodoc;
         	
        else
               labarra =$2;
        END IF;
        INSERT INTO informefacturacion(idcentroinformefacturacion,nrocliente,barra,idinformefacturaciontipo)
                VALUES(vcentro,$1,labarra,$3);
        
    --(*) Recupero el id de informefacturacion
    idnroinforme =  currval('informefacturacion_nroinforme_seq');
	INSERT INTO informefacturacionestado(idinformefacturacionestadotipo,nroinforme,idcentroinformefacturacion,fechaini,descripcion)
        VALUES(1,idnroinforme,vcentro,now(),'Generado Automaticamente desde crearinformefacturacion');

return idnroinforme;
END;
$function$
