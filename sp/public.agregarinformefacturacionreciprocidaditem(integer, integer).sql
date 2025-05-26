CREATE OR REPLACE FUNCTION public.agregarinformefacturacionreciprocidaditem(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Se guarda la informacion de los items del informe de facturacion cuyo numero se pasa por parametro
* Este SP es usado para insertar items de los informes de reciprocidad
* Tablas que se modifican: Informefacturacion,informefacturacionestado,informefacturacionitem,informefacturacionreciprocidad
*/

DECLARE
	--PARAMETROS
        idnroinforme alias for $1;
	
	--RECORDS
	elem RECORD;
        itemsaborrar  RECORD;
        rgastoadm RECORD;
        rlacuenta RECORD;

        --VARIABLES
	resultado boolean;
        importeifi DOUBLE PRECISION DEFAULT 0;
        elimportetotal  DOUBLE PRECISION;

       --CURSORES
	cursoritem CURSOR FOR
	               SELECT
                        sum(t.importe) as importe,t.nrocuentac,t.desccuenta as desccuenta from 
                               (
select DISTINCT   concat ( informefacturacionreciprocidad.nroorden,'-',informefacturacionreciprocidad.centro) as nroorden,informefacturacionreciprocidad.importe
,case when ct.idcomprobantetipos=14 then '40362'
 when ct.idcomprobantetipos=4 then '40311' 
 when ct.idcomprobantetipos=3 then '40355'
 when ct.idcomprobantetipos=37 then '40316'
else cuentascontables.nrocuentac  
end  as nrocuentac 
,case when ct.idcomprobantetipos=14 then 'Farmacia' 
  when ct.idcomprobantetipos=4 then 'Consulta' 
  when ct.idcomprobantetipos=3 then 'Internacion' 
  when ct.idcomprobantetipos=37 then 'Recetario TP '
 else cuentascontables.desccuenta end as desccuenta

			        from informefacturacionreciprocidad natural join orden --using(nroorden,centro)
NATURAL JOIN comprobantestipos as ct
				left join itemvalorizada 
 on(itemvalorizada.nroorden=informefacturacionreciprocidad.nroorden and itemvalorizada.centro=informefacturacionreciprocidad.centro) 

				left join item on (item.iditem=itemvalorizada.iditem and item.centro=itemvalorizada.centro)
				left join practica using (idnomenclador,idcapitulo,idsubcapitulo,idpractica)
				left join cuentascontables on(practica.nrocuentac=cuentascontables.nrocuentac)
				where informefacturacionreciprocidad.nroinforme = idnroinforme AND informefacturacionreciprocidad.idcentroinformefacturacion= centro()
and expendio
) as t
				Group By t.nrocuentac,t.desccuenta;

		
BEGIN

resultado = true;
/*Dani agrega el 02062022 para q borre los posibles items de un informe. esto se necesitaba cuando informese volvia a un estado previo en forma manual y se acumulaban los items*/
select into itemsaborrar from informefacturacionitem
where informefacturacionitem.nroinforme = idnroinforme AND informefacturacionitem.idcentroinformefacturacion= centro();

if FOUND then 
delete from informefacturacionitem
where informefacturacionitem.nroinforme = idnroinforme AND informefacturacionitem.idcentroinformefacturacion= centro();
end if;


open cursoritem;
FETCH cursoritem INTO elem;

WHILE FOUND LOOP

          INSERT INTO informefacturacionitem(idcentroinformefacturacionitem,idcentroinformefacturacion,
                   nroinforme,nrocuentac,cantidad,importe,descripcion)
          VALUES(centro(),centro(),idnroinforme,elem.nrocuentac,1,elem.importe,elem.desccuenta);   
          importeifi = importeifi+elem.importe;
          FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;

/*Genero el gasto administrativo si esta*/
IF  iftableexists('temp_informefacturacion') THEN
 SELECT INTO rgastoadm * FROM temp_informefacturacion; 
 IF FOUND THEN 
         IF (rgastoadm.nrocliente ='24' AND rgastoadm.barra=999) THEN --es AMUC
                  SELECT INTO rlacuenta * FROM cuentascontables WHERE nrocuentac='40713';
         ELSE 
                  SELECT INTO rlacuenta * FROM cuentascontables WHERE nrocuentac='40358';
         END IF;
         INSERT INTO informefacturacionitem(idcentroinformefacturacionitem,idcentroinformefacturacion,
                   nroinforme,nrocuentac,cantidad,importe,descripcion)
          VALUES(centro(),centro(),idnroinforme,rlacuenta.nrocuentac,1,
                 round(CAST ((CASE WHEN rgastoadm.porcentaje THEN (importeifi* rgastoadm.montogtoadmi/100)  ELSE rgastoadm.montogtoadmi END) AS numeric),2)
                   
                  ,rlacuenta.desccuenta);   

  
  END IF; 
END IF;   

PERFORM cambiarestadoinformefacturacion(idnroinforme,centro(),
	3,'Se cambia el estado y se deja pendiente de facturacion. ');
           
return resultado;
end;
$function$
