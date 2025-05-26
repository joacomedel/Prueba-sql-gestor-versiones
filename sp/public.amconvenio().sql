CREATE OR REPLACE FUNCTION public.amconvenio()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza un convenio */
/*amconvenio()*/
DECLARE
	alta CURSOR FOR SELECT * FROM tempconvenio WHERE nullvalue(tempconvenio.error);
        curdire CURSOR FOR SELECT * FROM tempdireccion;
	elem RECORD;
        elemdire RECORD;
	anterior RECORD;
	dire RECORD;
	resultado boolean;
        direccionlegal integer;
        iddireccionref integer;
        ddireccion1 integer;
        ddireccion2 integer;
        ddireccion3 integer;
BEGIN
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP

OPEN curdire;
FETCH curdire INTO elemdire;
WHILE  found LOOP
 IF (elemdire.tipodire = 'direccionlegal') THEN
            SELECT INTO direccionlegal * FROM amdireccionconvenio();
 END IF;
 IF (elemdire.tipodire = 'direccionref') THEN
            SELECT INTO iddireccionref * FROM amdireccionconvenio();
 END IF;
 IF (elemdire.tipodire = 'direccion1') THEN
            SELECT INTO ddireccion1 * FROM amdireccionconvenio();
 END IF;
 IF (elemdire.tipodire = 'direccion2')  THEN
            SELECT INTO ddireccion2 * FROM amdireccionconvenio();
 END IF;
 IF (elemdire.tipodire = 'direccion3')  THEN
       SELECT INTO ddireccion3 * FROM amdireccionconvenio();
 END IF;
FETCH curdire INTO elemdire;
END LOOP;
CLOSE curdire;

resultado = 'true';
/*Temporalmente no se verifica la direccion*/
IF resultado = 'false' THEN
/*No esta la direccion*/
     UPDATE tempconvenio SET error = 'NODIRECCION' WHERE tempconvenio.idconvenio = elem.idconvenio;
ELSE
    SELECT INTO anterior * FROM convenio WHERE convenio.idconvenio = elem.idconvenio;
    IF NOT FOUND THEN
       INSERT INTO convenio (cestatuto,cactaautoridades,ciniciovigencia,cfinvigencia,crenovacionautomat,
                            cdiaspreavisoresicion,cfechafirma,cpathestatuto,cdenominacion,cplazofacturacion,
                            cdiazplazodebito,cdiasplazorefact,cdiasplazopago,telefono,cuitini,cuitmedio,cuitfin,cnrosss,
                            iddireccion,iddireccionlegal,iddireccion1,iddireccion2,iddireccion3,cpathdesigautoridades,
                            nropersonajuridica,cplazopresentacion)
            VALUES (elem.cestatuto,elem.cactaautoridades,elem.ciniciovigencia,elem.cfinvigencia,elem.crenovacionautomat,
                   elem.cdiaspreavisoresicion,elem.cfechafirma,elem.cpathestatuto,elem.cdenominacion,elem.cplazofacturacion,
                   elem.cdiazplazodebito,elem.cdiasplazorefact,elem.cdiasplazopago,elem.telefono,elem.cuitini,elem.cuitmedio,elem.cuitfin,elem.cnrosss,
                   iddireccionref,direccionlegal,ddireccion1,ddireccion2,ddireccion3,elem.cpathdesigautoridades,
                   elem.nropersonajuridica,elem.cplazopresentacion);
    ELSE
       UPDATE convenio SET cestatuto = elem.cestatuto,
                       cactaautoridades = elem.cactaautoridades,ciniciovigencia= elem.ciniciovigencia,
                       cfinvigencia= elem.cfinvigencia,crenovacionautomat = elem.crenovacionautomat,
                   cdiaspreavisoresicion = elem.cdiaspreavisoresicion, cfechafirma = elem.cfechafirma,
                   cpathestatuto = elem.cpathestatuto,cdenominacion = elem.cdenominacion,
                   cplazofacturacion = elem.cplazofacturacion, cdiazplazodebito = elem.cdiazplazodebito,
                   cdiasplazorefact = elem.cdiasplazorefact,cdiasplazopago = elem.cdiasplazopago,
                   telefono = elem.telefono,cuitini = elem.cuitini,
                   cuitmedio = elem.cuitmedio,cuitfin = elem.cuitfin,
                   cnrosss = elem.cnrosss, iddireccion = elem.iddireccion,
                   iddireccionlegal = elem.iddireccionlegal,iddireccion1 = elem.iddireccion1,
                   iddireccion2= elem.iddireccion2,iddireccion3 = elem.iddireccion3,
                   cpathdesigautoridades = elem.cpathdesigautoridades,nropersonajuridica = elem.nropersonajuridica,
                   cplazopresentacion = elem.cplazopresentacion
            WHERE idconvenio = elem.idconvenio;
    END IF;
    DELETE FROM tempconvenio WHERE tempconvenio.idconvenio = elem.idconvenio;
END IF;
FETCH alta INTO elem;
END LOOP;
CLOSE alta;
resultado = 'true';
RETURN resultado;
END;$function$
