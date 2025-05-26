CREATE OR REPLACE FUNCTION public.anularfacturaventaorden(bigint, integer, character varying, smallint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
elem RECORD;
tipoorden INTEGER;
resp BOOLEAN;

--temporal que tiene los datos de la factura a anular
sitems CURSOR FOR SELECT *
            FROM importesorden
            WHERE nroorden=$1 AND centro=$2
            AND (idformapagotipos=2 or idformapagotipos=3 or idformapagotipos=4 or idformapagotipos=5);
regsitems RECORD;

/*
sitemsval CURSOR FOR
   SELECT DISTINCT *
        FROM (SELECT sum(cantidad) as cant from
		(SELECT nrocuentac,desccuenta,importesorden.importe,cantidad FROM orden NATURAL JOIN itemvalorizada
        	 NATURAL JOIN importesorden JOIN item using(iditem,centro) NATURAL JOIN practica NATURAL JOIN cuentascontables
		 WHERE nroorden = $1 AND orden.centro = $2
		 AND idformapagotipos=$5 ) as a) AS a NATURAL JOIN (SELECT * from
		(SELECT nrocuentac,desccuenta,importesorden.importe,cantidad FROM orden NATURAL JOIN itemvalorizada
		 NATURAL JOIN importesorden JOIN item using(iditem,centro) NATURAL JOIN practica NATURAL JOIN cuentascontables
		 WHERE nroorden = $1 AND orden.centro = $2 AND idformapagotipos = $5) as a) AS b;
*/
	
sitemsval CURSOR FOR  SELECT  nrocuentac,	desccuenta,SUM(importe)as importe,SUM(cantidad) as cantidad
         FROM (
                 SELECT nrocuentac,desccuenta,importesorden.importe as importe,cantidad
                 FROM orden
                 NATURAL JOIN itemvalorizada
        	     NATURAL JOIN importesorden
                 JOIN item using(iditem,centro)
                 NATURAL JOIN practica
                 NATURAL JOIN cuentascontables
		         WHERE nroorden = $1
                       AND orden.centro = $2
                        AND idformapagotipos = $5
           ) as t
           group by nrocuentac,	desccuenta;
		 
		-- anularfacturaventaorden
regsitemsval RECORD;

BEGIN



       INSERT INTO ordenessinfacturas(nroorden,centro,tpoexpendio,nrodoc,tipodoc)
       VALUES($1,$2,CURRENT_TIMESTAMP,$3,$4);
			
      open sitems;
      fetch sitems into regsitems;
      WHILE FOUND LOOP

            SELECT INTO tipoorden tipo FROM orden WHERE nroorden= $1 and centro=$2;
   		
            IF (tipoorden=4) THEN
		                     INSERT INTO itemordenessinfactura(nroorden,centro,idconcepto,cantidad,importe,descripcion)
		                     VALUES($1,$2,'50340',1,regsitems.importe,'Consultas');
            ELSE if (tipoorden=37) then
                    INSERT INTO itemordenessinfactura(nroorden,centro,idconcepto,cantidad,importe,descripcion)
		                   select $1,$2,nrocuentac as idconcepto,1 as cantidad,importesorden.importe,desccuenta as descripcion
                           from orden
                           NATURAL JOIN importesorden
                           join cuentascontables on(nrocuentac='40316')
                           where nroorden=$1 and centro=$2 AND idformapagotipos = $5 ;
                    else
                         -- Se trata de una oren valorizada
	                     open sitemsval;
                         fetch sitemsval into regsitemsval;	
	                     IF FOUND THEN
		                      INSERT INTO itemordenessinfactura(nroorden,centro,idconcepto,cantidad,importe,descripcion)
		                      VALUES($1,$2,regsitemsval.nrocuentac,regsitemsval.cantidad,regsitemsval.importe,regsitemsval.desccuenta);
                        END IF;
                        close sitemsval;
                  END IF;					
             end if;
             fetch sitems into regsitems;
 END LOOP;
close sitems;
			
				
return true;
END;
$function$
