CREATE OR REPLACE FUNCTION public.amplancobertura()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza un Plan de Cobertura, ya se debe haber intresado el tipo de plan de cobertura */
/*amplancobertura()*/
DECLARE
	alta CURSOR FOR SELECT * FROM tempplancobertura WHERE nullvalue(tempplancobertura.error);
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado boolean;
BEGIN
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
SELECT INTO aux * FROM tipoplancob where tipoplancob.idtipoplancob = elem.idtipoplan;
IF NOT FOUND THEN
   UPDATE tempplancobertura SET error = 'NOTIPOPLAN' WHERE tempplancobertura.idtipoplan = elem.idtipoplan;
ELSE /*Si existe el Tipo de Plan de Cobertura*/

    SELECT INTO anterior * FROM plancobertura WHERE plancobertura.descripcion = elem.descripcion;
    IF NOT FOUND THEN
       INSERT INTO plancobertura (idplancoberturas,idplancobertura,descripcion,nombreimprimir,requieretramite,
                                 vencimiento,vencimientopersona,idtipoplan,normalegal,tipoafiliado,
                                 estadoactivo,estadocompservicios)
            VALUES (nextval('plancobertura_idplancoberturas_seq'),trim(' ' from to_char(currval('plancobertura_idplancoberturas_seq'),'9999999999')),elem.descripcion,elem.nombreimprimir,elem.requieretramite,
                   elem.vencimiento,elem.vencimientopersona,aux.idtipoplancob,elem.normalegal,elem.tipoafiliado,
                   elem.estadoactivo,elem.estadocompservicios);
    ELSE
        UPDATE plancobertura SET nombreimprimir = elem.nombreimprimir
                                 ,requieretramite = elem.requieretramite
                                 ,vencimiento = elem.vencimiento
                                 ,vencimientopersona = elem.vencimientopersona
                                 ,idtipoplan = elem.idtipoplan
                                 ,normalegal = elem.normalegal
                                 ,tipoafiliado = elem.tipoafiliado
                                 ,estadoactivo = elem.estadoactivo
                                 ,estadocompservicios = elem.estadocompservicios
                                 WHERE descripcion = elem.descripcion;
    END IF;
    DELETE FROM tempplancobertura WHERE tempplancobertura.descripcion = elem.descripcion;
END IF;
FETCH alta INTO elem;
END LOOP;
CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
