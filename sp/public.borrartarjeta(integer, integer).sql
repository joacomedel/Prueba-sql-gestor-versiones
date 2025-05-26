CREATE OR REPLACE FUNCTION public.borrartarjeta(integer, integer)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$
DECLARE
	
	datotarjeta RECORD;
       
--busca las tarjetas/cupones 
BEGIN
        



        select into datotarjeta 
	* from  tarjeta  natural join cupon natural join tarjetaestado 
	where idtarjeta=$1 and idcentrotarjeta=$2;
	
		if found then 
		   delete from tarjetaestado where idtarjeta=datotarjeta.idtarjeta 
		   and idcentrotarjeta=datotarjeta.idcentrotarjeta;

                   delete from tarjetalogin where idtarjeta=datotarjeta.idtarjeta 
		   and idcentrotarjeta=datotarjeta.idcentrotarjeta;
                
                
                   delete from cuponestado where idcupon=datotarjeta.idcupon 
		   and idcentrocupon=datotarjeta.idcentrocupon;
		   
                   delete from cupon where idcupon=datotarjeta.idcupon 
		   and idcentrocupon=datotarjeta.idcentrocupon;

                   delete from tarjeta where idtarjeta=datotarjeta.idtarjeta 
		   and idcentrotarjeta=datotarjeta.idcentrotarjeta;
                
		   
                else

		
		    RAISE NOTICE 'no se consiguieron datos ';
		end if;


  

RETURN 'true';
END;
$function$
