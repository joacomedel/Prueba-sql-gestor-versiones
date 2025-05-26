CREATE OR REPLACE FUNCTION public.cambiarestadocupon(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	
	datotarjeta RECORD;
	datocupon RECORD;      
      

BEGIN


		update cuponestado set cefechafin=now() 
		where  idcupon=$1 and idcentrocupon=$2  and nullvalue(cefechafin);

		insert into cuponestado(idcupon,idestadotipo,cefechaini,idcentrocupon,idcentrocuponestado) 
		values ($1,$3,now(),$2,centro());




RETURN 'true';
END;
$function$
