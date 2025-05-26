CREATE OR REPLACE FUNCTION public.procesarpagosdedescuentosenctacte()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* 
	Dado un mes y año se procesan los descuentos de todos los empleados
*/
DECLARE
--RECORD	
	relosdtos RECORD;

--CURSOR
	closdtos REFCURSOR;
BEGIN
--llamo al sp que ingresa los datos de los montos maximos de descuentos en ctacte para los empleados de la unc
   PERFORM agregarmontosdedescuentos();

--llamo al sp que ingresa los datos de los descuentos de los empleados de SOSUNC
  -- PERFORM procesardescuentos_empleados_sosunc();
 PERFORM procesardescuentos_empleados_sosunc_test();

--llamo al sp que ingresa los datos de los descuentos de los empleados de UNCo
   PERFORM agregardescuentosconceptos();

--llamo al sp que genera los disponibles ( en particular se agrego el 21032025 par alos barra 149
    PERFORM ctacte_generar_disponible();


--llamo al sp que imputa los descuentos automaticos de todos los empleados
   PERFORM imputardescuentosautomaticos();


--llamo al sp que cancela los envios a descontar de cuenta corriente si ya se pagaron
  PERFORM liberardescuentos();


--llamo al sp que inserta en la tabla info_aporterte_unc la info de los ultimos paortes recibidos de la unc para luego consultarlos desde la panelera de reportes. 

PERFORM  actualiza_info_aporterte_unc(  concat('{mes=',date_part('month', current_date -30),',anio=',date_part('year', current_date -30),'}') );
return 'true';
END;
$function$
