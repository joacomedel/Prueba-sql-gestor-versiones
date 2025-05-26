CREATE OR REPLACE FUNCTION public.insertarinformefacturacionitem()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$--Se crea una nueva instancia de informefacturacionitem

--CREATE TEMP TABLE ttinformefacturacionitem ( 
--				
--				nroinforme INTEGER,
--				nrocuentac VARCHAR,
--				cantidad INTEGER,
--				importe DOUBLE PRECISION,
--				descripcion VARCHAR);

DECLARE
	
 items CURSOR FOR SELECT * FROM ttinformefacturacionitem;
 unitem RECORD;
 idnroitem INTEGER;
elidiva INTEGER;
BEGIN


     



open items;
fetch items into  unitem;	
while found loop
        elidiva = null;
        IF  existecolumtemp('ttinformefacturacionitem', 'idiva') THEN 
              elidiva =  unitem.idiva;
                        
        END IF; 

	INSERT INTO informefacturacionitem(idcentroinformefacturacionitem,idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion,idiva)
        VALUES(centro(),centro(),unitem.nroinforme,unitem.nrocuentac,unitem.cantidad,unitem.importe,unitem.descripcion,elidiva);
        fetch items into unitem;

end loop;
close items;
return 'true';
END;
$function$
