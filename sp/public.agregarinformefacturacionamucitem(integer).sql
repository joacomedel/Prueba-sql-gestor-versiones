CREATE OR REPLACE FUNCTION public.agregarinformefacturacionamucitem(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Se guarda la informacion de los items del informe de facturacion cuyo numero se pasa por parametro
* Este SP es usado para insertar items de los informes de AMUC
* Tablas que se modifican: Informefacturacion,informefacturacionestado,informefacturacionitem
*/

DECLARE
	--PARAMETROS
        idnroinforme alias for $1;
	
	--RECORDS
	elem RECORD;

        --VARIABLES
	resultado boolean;


       --CURSORES
	cursoritem CURSOR FOR
	              SELECT
                        sum(t.importe) as importe,t.nrocuentac,t.desccuenta as desccuenta from 
                               ((select DISTINCT  informefacturacionamuc.nroorden,importesorden.importe,min(cuentascontables.nrocuentac) as nrocuentac ,text_concatenarsinrepetir(desccuenta) as desccuenta
			        from informefacturacionamuc join orden using(nroorden,centro)
				join itemvalorizada on(itemvalorizada.nroorden=informefacturacionamuc.nroorden and itemvalorizada.centro=informefacturacionamuc.centro) 
				join item on (item.iditem=itemvalorizada.iditem and item.centro=itemvalorizada.centro)
				join practica using (idnomenclador,idcapitulo,idsubcapitulo,idpractica)
				join cuentascontables on(practica.nrocuentac=cuentascontables.nrocuentac)
				join importesorden on(informefacturacionamuc.nroorden=importesorden.nroorden and informefacturacionamuc.centro=importesorden.centro) 
				where informefacturacionamuc.origen='asistencial' 
and informefacturacionamuc.nroinforme = idnroinforme 
AND informefacturacionamuc.idcentroinformefacturacion= centro()
				and (orden.tipo <>4) AND importesorden.idformapagotipos=1 
GROUP BY informefacturacionamuc.nroorden,informefacturacionamuc.centro,importesorden.importe )
				UNION
				(SELECT  DISTINCT  informefacturacionamuc.nroorden,importesorden.importe,'40311' as nrocuentac,'Consulta' as desccuenta 
				from informefacturacionamuc join orden using(nroorden,centro) 
				join importesorden on(informefacturacionamuc.nroorden=importesorden.nroorden and informefacturacionamuc.centro=importesorden.centro) 
				where informefacturacionamuc.origen='asistencial' and informefacturacionamuc.nroinforme = idnroinforme  AND informefacturacionamuc.idcentroinformefacturacion=centro()
				AND (orden.tipo =4) and importesorden.idformapagotipos=1)

-- AMUC DE FARMACIA (Cristian, 21-11-2013)
union
--Items Farmacia
select DISTINCT  
	informefacturacionamuc.nroorden,
	far_ordenventaitemimportes.oviimonto as importe,
	'40362' as nrocuentac,
	'Consumos Farmacia Afiliados' as desccuenta
     from informefacturacionamuc 
	join far_ordenventa on informefacturacionamuc.nroorden= far_ordenventa.idordenventa and informefacturacionamuc.centro=far_ordenventa.idcentroordenventa
	natural join far_ordenventaitem
	natural join far_ordenventaitemimportes
	join facturaorden on (far_ordenventa.idordenventa=facturaorden.nroorden)
	join facturaventa using(nrosucursal,nrofactura,tipocomprobante,tipofactura)
where informefacturacionamuc.origen='farmacia' and informefacturacionamuc.nroinforme = idnroinforme 
AND informefacturacionamuc.idcentroinformefacturacion=centro() and nullvalue(facturaventa.anulada) and far_ordenventaitemimportes.idvalorescaja=61
----------------------------------------------------




) as t
				Group By t.nrocuentac,t.desccuenta;
	

		
BEGIN

resultado = true;

-- Creo los item del informe de facturacion, para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);

open cursoritem;
FETCH cursoritem INTO elem;

WHILE FOUND LOOP

   
             INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
             VALUES (idnroinforme,elem.nrocuentac,1,elem.importe,elem.desccuenta);
         
             FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;
    
             SELECT INTO resultado * FROM insertarinformefacturacionitem();

return resultado;
end;$function$
