CREATE OR REPLACE FUNCTION public.amtipoplancob()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza un Tipo de Plan de Cobertura */
/*amtipoplancob()*/
DECLARE
	alta CURSOR FOR SELECT * FROM temptipoplancob WHERE nullvalue(temptipoplancob.error);
	elem RECORD;
	anterior RECORD;
	resultado boolean;
BEGIN
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
    SELECT INTO anterior * FROM tipoplancob WHERE tipoplancob.tpnombre = elem.tpnombre;
    IF NOT FOUND THEN

       INSERT INTO tipoplancob (tpnombre,tpdescripcion,tppresentadiagnostico,tplugarinternacion
                               ,tpprestador,tpfechaalta,tpdetalleinforme,tppresinfrome,tpedad,tpsexo
                               ,tptipointernacion,tpcantdiasinternacion)
            VALUES (elem.tpnombre,elem.tpdescripcion,elem.tppresentadiagnostico,elem.tplugarinternacion
            ,elem.tpprestador,elem.tpfechaalta,elem.tpdetalleinforme,elem.tppresinfrome,elem.tpedad,elem.tpsexo
            ,elem.tptipointernacion,elem.tpcantdiasinternacion);
    ELSE
        UPDATE tipoplancob SET tpdescripcion = elem.tpdescripcion
                                 ,tppresentadiagnostico = elem.tppresentadiagnostico
                                 ,tplugarinternacion = elem.tplugarinternacion
                                 ,tpprestador = elem.tpprestador
                                 ,tpfechaalta = elem.tpfechaalta
                                 ,tpdetalleinforme = elem.tpdetalleinforme
                                 ,tppresinfrome = elem.tppresinfrome
                                 ,tpedad = elem.tpedad
                                 ,tpsexo = elem.tpsexo
                                 ,tptipointernacion = elem.tptipointernacion
                                 ,tpcantdiasinternacion = elem.tpcantdiasinternacion
                                 WHERE tpnombre = elem.tpnombre;
    END IF;
    DELETE FROM temptipoplancob WHERE temptipoplancob.tpnombre = elem.tpnombre;
FETCH alta INTO elem;
END LOOP;
CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
