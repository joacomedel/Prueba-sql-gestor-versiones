CREATE OR REPLACE FUNCTION public.cambiarcentrotarjeta(character varying, integer, integer)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$DECLARE
	
	datotarjeta RECORD;
        nuevocentro integer;
       
--busca las tarjetas/cupones 
BEGIN
       
 nuevocentro=$3;
select into datotarjeta 
	* from  tarjeta natural join tarjetaestado
	where nrodoc=$1 and tipodoc=$2 and nullvalue(tefechafin) and idestadotipo<>4;


      
	
		if found then 
		   update  tarjetaestado set idcentrotarjeta=nuevocentro
                   where idtarjeta=datotarjeta.idtarjeta 
		   and idcentrotarjeta=datotarjeta.idcentrotarjeta;

                  
                   update  tarjeta set idcentrotarjeta=nuevocentro
                   where idtarjeta=datotarjeta.idtarjeta 
		   and idcentrotarjeta=datotarjeta.idcentrotarjeta;

                
               /*    update  tarjetalogin set idcentrotarjeta=nuevocentro
                   where idtarjeta=datotarjeta.idtarjeta 
		   and idcentrotarjeta=datotarjeta.idcentrotarjeta;

                */
		   
                else

		
		    RAISE NOTICE 'no se consiguieron datos ';
		end if;


  

RETURN 'true';
END;
$function$
