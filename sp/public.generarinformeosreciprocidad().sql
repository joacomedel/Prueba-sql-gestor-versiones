CREATE OR REPLACE FUNCTION public.generarinformeosreciprocidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Datos entrada: tempordreci (
*			       prestador INTEGER,
*                              fechauso varchar NOT NULL,
*                              obrasocial varchar NOT NULL,
*                              idosreci  varchar NOT NULL,
*                              tipoorden INTEGER,
*                              nroorden INTEGER NOT NULL,
*                              barra INTEGER NOT NULL,
*                              nombres varchar,
*                              apellido varchar,
*                              importe DOUBLE PRECISION,
*                              centro  INTEGER NOT NULL)
*
* Se guarda la informacion de las ordenes expendidas a afiliados por reciprocidad
* Se crea el informe de facturacion de reciprocidad
* Tablas que se modifican: Informefacturacion,informefacturacionestado,informefacturacionitem,informefacturacionreciprocidad
*/



DECLARE
    informes refcursor;
    uninforme RECORD;
    resultado BOOLEAN;
    regorden RECORD;
    idinforme INTEGER;
    nroinfo INTEGER;
    rinformefacturacionreciprocidad RECORD;
    cursororden CURSOR FOR 
            SELECT CASE
            WHEN nullvalue(tempordreci.nrodoc) THEN 
            CASE  WHEN nullvalue(ou.nrodocuso) THEN r.nrodoc ELSE ou.nrodocuso END
            ELSE tempordreci.nrodoc
            END AS nrodoc, 
            CASE
            WHEN nullvalue(tempordreci.tipodoc) THEN 
            CASE  WHEN nullvalue(ou.tipodocuso) THEN r.tipodoc ELSE ou.tipodocuso END
            ELSE tempordreci.tipodoc
            END AS tipodoc, 
            CASE
            WHEN nullvalue(tempordreci.idprestadortemp) THEN 
            CASE  WHEN nullvalue(ou.idprestador) THEN r.idfarmacia ELSE ou.idprestador END
            ELSE tempordreci.idprestadortemp
            END AS idprestador, 
            CASE
            WHEN nullvalue(tempordreci.nroorden) THEN 
            CASE  WHEN nullvalue(ou.nroorden) THEN r.nrorecetario ELSE ou.nroorden END
            ELSE tempordreci.nroorden
            END AS nroorden, 
            CASE
            WHEN nullvalue(tempordreci.centro) THEN 
            CASE  WHEN nullvalue(ou.centro) THEN r.centro::bigint ELSE ou.centro END
            ELSE tempordreci.centro
            END AS centro, 
            CASE
            WHEN nullvalue(tempordreci.fechausotemp) THEN 
            CASE  WHEN nullvalue(ou.fechauso) THEN r.fechauso ELSE ou.fechauso END
            ELSE tempordreci.fechausotemp
            END AS fechauso
           ,importetemp as importe
           ,tempordreci.idosreci
           ,tempordreci.barra
           ,tempordreci.tipo
FROM tempordreci LEFT JOIN ordenesutilizadas ou USING (nroorden, centro, tipo)
LEFT JOIN recetario as r ON (tempordreci.nroorden=r.nrorecetario AND tempordreci.centro=r.centro AND (tempordreci.tipo=14 or tempordreci.tipo=37));

 
	
BEGIN
   -- Creo una tabla temporal para guardar los numeros de informes que utilizo y luego insertar los items de los mismos
    CREATE TEMP TABLE ttnroinforme (nroinforme INTEGER);



    OPEN cursororden;
    FETCH cursororden INTO regorden;

    WHILE FOUND LOOP

      -- Busco si existe algun informe en estado pendiente de la obra social por reciprocidad
      SELECT into idinforme nroinforme from informefacturacionreciprocidad natural join 
             informefacturacion natural join informefacturacionestado 
             where nullvalue(fechafin) and idinformefacturacionestadotipo = 1  and nrocliente =regorden.idosreci and barra =regorden.barra;
	 
      IF NOT FOUND THEN-- Si no existe ningun informe en estado pendiente de dicho obra social
      
        --creo el informe de facturacion, 2 es el numero que corresponde al tipo de informe de RECIPROCIDAD (ver tabla informefacturaciontipo) 
         SELECT INTO idinforme * FROM crearinformefacturacion(regorden.idosreci,regorden.barra,2);
     
      END IF;
      -- Ma.La.Pi 14-03-2012 Modifico para que se pueda modificar la informacion de una orden auditada
-- Dani 03-04-2013 Modifico para que la modificacion anterior solo se haga sobre un informe que no este cancelado
	 
  SELECT INTO rinformefacturacionreciprocidad * 
       		FROM informefacturacionreciprocidad 
natural join 
             informefacturacionestado

            WHERE nroinforme = idinforme 
            AND centro = regorden.centro
            AND nroorden = regorden.nroorden
            AND idcomprobantetipos = regorden.tipo
and (idinformefacturacionestadotipo<>5);
      IF FOUND THEN 
         UPDATE informefacturacionreciprocidad 
         SET fechauso =  regorden.fechauso 
            ,importe =  regorden.importe 
            ,nrodoc = regorden.nrodoc
            ,tipodoc= regorden.tipodoc
            ,idprestador = regorden.idprestador 
          WHERE nroinforme = idinforme 
            AND centro = regorden.centro
            AND nroorden = regorden.nroorden
            AND idcomprobantetipos = regorden.tipo;
       
            
      ELSE 
      

      INSERT INTO informefacturacionreciprocidad(nroinforme,idcentroinformefacturacion,centro,nroorden,idosreci,idprestador,fechauso,importe,nrodoc,tipodoc,idcomprobantetipos,barra) 
      VALUES(idinforme,centro(),regorden.centro, regorden.nroorden,regorden.idosreci::INTEGER
         ,regorden.idprestador 
         ,regorden.fechauso
         ,regorden.importe  
         ,regorden.nrodoc
         ,regorden.tipodoc
        ,regorden.tipo,regorden.barra);
     
      END IF;
      
     SELECT INTO nroinfo nroinforme from ttnroinforme WHERE ttnroinforme.nroinforme= idinforme;
     IF NOT FOUND THEN-- si el informe no existe en la temporal que cree 
             INSERT INTO ttnroinforme values(idinforme);
  END IF;
     FETCH cursororden INTO regorden;

    END LOOP;

    CLOSE cursororden;

 /*  OPEN informes FOR SELECT * FROM ttnroinforme;
   FETCH informes INTO uninforme;
   WHILE FOUND LOOP
        
        SELECT INTO resultado * FROM agregarinformefacturacionreciprocidaditem(uninforme.nroinforme);
  
        FETCH informes INTO uninforme;

    END LOOP;

    CLOSE informes;
*/

return resultado;
END;
$function$
