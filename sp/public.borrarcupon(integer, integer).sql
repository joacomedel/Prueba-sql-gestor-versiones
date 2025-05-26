CREATE OR REPLACE FUNCTION public.borrarcupon(integer, integer)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$
DECLARE
	
	datocupon RECORD;
       
--busca las cupones 
BEGIN
        



        select into datocupon 
	* from   cupon natural join cuponestado 
	where idcupon=$1 and idcentrocupon=$2;
	
		if found then 
		     delete from cuponestado where idcupon=datocupon.idcupon 
		   and idcentrocupon=datocupon.idcentrocupon;
		   
                   delete from cupon where idcupon=datocupon.idcupon 
		   and idcentrocupon=datocupon.idcentrocupon;
    
		   
                else

		
		    RAISE NOTICE 'no se consiguieron datos ';
		end if;


  

RETURN 'true';
END;
$function$
