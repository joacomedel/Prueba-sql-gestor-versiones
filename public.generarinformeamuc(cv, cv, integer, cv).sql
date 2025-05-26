CREATE OR REPLACE FUNCTION public.generarinformeamuc(character varying, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    elem RECORD;
    resultado BOOLEAN;
    regorden RECORD;
    idinforme integer;
    fechahasta alias for $1;
    fechadesde alias for $2;
    idcentro alias for $3;
    porigen alias for $4;

    cursororden CURSOR FOR

select tt.* from (
SELECT
	'asistencial' as origen,
	orden.nroorden,
	orden.centro
FROM orden
	left join informefacturacionamuc on(orden.nroorden=informefacturacionamuc.nroorden and 		orden.centro=informefacturacionamuc.centro and informefacturacionamuc.origen='asistencial')

left join informefacturacionestado USING(nroinforme, idcentroinformefacturacion)
	join importesorden on(orden.nroorden=importesorden.nroorden and  orden.centro=importesorden.centro)
	left  join ordenestados on(ordenestados.nroorden=orden.nroorden and ordenestados.centro=orden.centro)
left  join ordenesreemitidas on(ordenesreemitidas.nroorden=orden.nroorden and ordenesreemitidas.centro=orden.centro)

WHERE ((nullvalue(informefacturacionamuc.nroorden) and nullvalue(informefacturacionamuc.centro)) 
OR idinformefacturacionestadotipo=5 and nullvalue(fechafin)
)  and
	 orden.fechaemision <= $1 AND orden.fechaemision >= $2
and nullvalue(ordenesreemitidas.nroorden)
        -- En caso de Diferencias con la Facturación de AMUC, descomentar esta linea y comentar la siguiente
        /* AND importesorden.idformapagotipos=1 and (orden.centro=$3 or $3=0) */
	/*AND  (not(orden.tipo=24 AND orden.centro =1)) */ and importesorden.idformapagotipos=1 and (orden.centro=$3 or $3=0) 
        ----------------------------------------------------------------------------------------------------
	AND ((nullvalue(ordenestados.nroorden) and nullvalue(ordenestados.centro) OR  ( ordenestados.fechacambio >=$1)
))

union

select  distinct 'farmacia' as origen,
       	far_ordenventa.idordenventa as nroorden,
	far_ordenventa.idcentroordenventa as centro

from 	far_ordenventa
	natural join far_ordenventaitem
	natural join far_ordenventaitemimportes
	join facturaorden on (far_ordenventa.idordenventa=facturaorden.nroorden)
	natural join facturaventa
        left join informefacturacionamuc on(far_ordenventa.idordenventa=informefacturacionamuc.nroorden and 		far_ordenventa.idcentroordenventa=informefacturacionamuc.centro and informefacturacionamuc.origen='farmacia')

where nullvalue(facturaventa.anulada)
--controla q las ordenes no esten ya ingresadas en otro informe

and (nullvalue(informefacturacionamuc.nroorden) and nullvalue(informefacturacionamuc.centro))
and far_ordenventa.ovfechaemision <= $1 AND far_ordenventa.ovfechaemision >= $2
and (far_ordenventa.idcentroordenventa=$3 or $3=0)
and far_ordenventaitemimportes.idvalorescaja=61

ORDER By nroorden,centro) as tt
where tt.origen = porigen or porigen='todos';



	
BEGIN
    OPEN cursororden;
    FETCH cursororden INTO regorden;

  IF FOUND THEN


     SELECT into elem cliente.nrocliente, cliente.barra from cliente join osreci 
         on (cliente.nrocliente=osreci.idosreci and  cliente.barra=osreci.barra) where osreci.descrip='A.M.U.C';

    /*creo el informe de facturacion, 1 es el numero que corresponde al tipo de informe de AMUC (ver tabla informefacturaciontipo)
        le modifico el estado AUDITADO*/


     SELECT INTO idinforme * FROM crearinformefacturacion(elem.nrocliente,elem.barra,1);

   -- Cambio el estado del informe de facturacion 3=facturable
      UPDATE informefacturacionestado
      SET fechafin=NOW()
      WHERE nroinforme=idinforme and idcentroinformefacturacion=centro() and fechafin is null;

      INSERT INTO informefacturacionestado(idinformefacturacionestadotipo,nroinforme,idcentroinformefacturacion,fechaini) 
            VALUES(2,idinforme,centro(),now());

   /* coloco estas lineas mas arriba para que si no hay ordnes para agregar no cree ningun informe
      OPEN cursororden;
      FETCH cursororden INTO regorden;
    IF FOUND THEN
   */

    WHILE FOUND LOOP

     /*creo el informe de facturacion amuc */
    INSERT INTO informefacturacionamuc(nroinforme,idcentroinformefacturacion,centro,nroorden,origen) VALUES(idinforme,centro(),regorden.centro, regorden.nroorden,regorden.origen);

    FETCH cursororden INTO regorden;

    END LOOP;

    CLOSE cursororden;

   SELECT INTO resultado * FROM agregarinformefacturacionamucitem(idinforme);

   PERFORM generardeudaordenesinstitucion(idinforme);

END IF;
return resultado;
END;$function$
