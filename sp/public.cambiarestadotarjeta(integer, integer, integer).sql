CREATE OR REPLACE FUNCTION public.cambiarestadotarjeta(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	
	datotarjeta RECORD;
	datocupon RECORD;
        undatoafil RECORD;
        resp boolean;
     elidtarjeta integer;
     elidcentrotarjeta integer;
     elidestado integer;
	


BEGIN
   
--recupero los datos del titular 

		
    
--end if;

--si el estado nuevo de la tarjeta es entregado entonces entrego tambien lso cupones
--si el estado nuevo de la tarjeta es renovado tengo q ver si es por renovar tarjeta o cupon
--si es renovar cupon solo cambio el estado al cupon

     elidtarjeta =$1;
     elidcentrotarjeta =$2;
     elidestado =$3;
	
     SELECT into datotarjeta *
     FROM  tarjeta
     NATURAL JOIN tarjetaestado
     WHERE idtarjeta=elidtarjeta and idcentrotarjeta=elidcentrotarjeta;
	
     if  found then
		UPDATE tarjetaestado SET tefechafin=now()
		WHERE  idtarjeta=elidtarjeta and idcentrotarjeta=elidcentrotarjeta  and nullvalue(tefechafin);

	 END IF;
    INSERT INTO tarjetaestado(idtarjeta,idcentrotarjeta,idestadotipo,tefechaini)
		VALUES (elidtarjeta,elidcentrotarjeta,elidestado,now());


RETURN resp;
END;
$function$
