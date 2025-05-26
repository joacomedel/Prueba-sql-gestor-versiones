CREATE OR REPLACE FUNCTION public.paraborrar_dani()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	baja CURSOR FOR SELECT   table_schema,table_name
FROM information_schema.tables
WHERE
 (
table_name='far_ordenventa' or
table_name='far_ordenventaestado' or
table_name='far_ordenventaitem' or
table_name='far_ordenventaitemimportes' or

table_name='far_ordenventaitemitemfacturaventa' or
table_name='far_ordenventareceta' or
table_name='facturaventausuario' or
table_name='far_afiliado' or
table_name='far_validacion' or
table_name='far_validacionitems' or
table_name='far_validacionitemsestado' or
table_name='far_validacionxml' or



table_name='far_movimientostockitem' or
table_name='far_movimientostock' or

table_name='far_movimientostockitemfactventa' or
table_name='far_movimientostockitemordenventa' or
table_name='far_movimientostockitemstockajuste'

)

AND table_schema ilike 'public'

ORDER BY table_schema,table_name;


	elem RECORD;
	rtablas RECORD;
	resultado boolean;
	
BEGIN


OPEN baja;
FETCH baja INTO elem;


WHILE  found LOOP

SELECT INTO rtablas * FROM tablasasincronizar where nombre=elem.table_name;
if not found then

 	select into  resultado * from agregarsincronizable(elem.table_name);

end if;

fetch baja into elem;
END LOOP;
CLOSE baja;
return 'true';

END;
$function$
