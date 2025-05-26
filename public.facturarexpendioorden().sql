CREATE OR REPLACE FUNCTION public.facturarexpendioorden()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
lasordenes refcursor;

--REGISTRO
unaorden record;
unitem record;
titularfactura record; 

--VARIABLES
esvalorizada boolean;
resp boolean;
importetotalapagar DOUBLE PRECISION;

BEGIN

   OPEN lasordenes FOR SELECT * FROM tempfacturaexpendio NATURAL JOIN orden;
          FETCH lasordenes INTO unaorden;
          WHILE  found LOOP
                
                   SELECT INTO titularfactura  CASE WHEN nullvalue(TT.nrodoctitu) THEN consumo.nrodoc ELSE nrodoctitu END as nrodoc,
                   CASE WHEN nullvalue(TT.tipodoctitu) THEN consumo.tipodoc ELSE tipodoctitu END as tipodoc
                   FROM consumo LEFT JOIN (
                   SELECT benefsosunc.nrodoc, benefsosunc.tipodoc,benefsosunc.nrodoctitu, benefsosunc.tipodoctitu FROM benefsosunc
--Dani agrego el 09/05/2019 
/*left join beneficiariosborrados
on (beneficiariosborrados.nrodoc=benefsosunc.nrodoc and
beneficiariosborrados.tipodoc=benefsosunc.tipodoc)
where  nullvalue(beneficiariosborrados.nrodoc)
*/

                   UNION 
                   SELECT benefreci.nrodoc, benefreci.tipodoc, benefreci.nrodoctitu, benefreci.tipodoctitu  FROM benefreci
--Dani agrego el 09/05/2019
/*left join
beneficiariosreciborrados on (beneficiariosreciborrados.nrodoc=benefreci.nrodoc and
beneficiariosreciborrados.tipodoc=benefreci.tipodoc)
where  nullvalue(beneficiariosreciborrados.nrodoc)*/
                   ) AS TT USING (nrodoc, tipodoc) 
                   WHERE nroorden=unaorden.nroorden and centro=unaorden.centro;

              INSERT INTO ordenessinfacturas(nroorden,centro,nrodoc,tipodoc)
              VALUES(unaorden.nroorden,unaorden.centro,titularfactura.nrodoc,titularfactura.tipodoc);
          
                     
               SELECT INTO unitem nrocuentac, importesorden.importe, nroorden,centro,cantidad,desccuenta
               FROM importesorden LEFT JOIN 
               (SELECT nrocuentac, cantidad,desccuenta,nroorden,centro
                FROM item JOIN itemvalorizada USING(iditem, centro)  JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica) 
                NATURAL JOIN cuentascontables  WHERE nroorden=unaorden.nroorden and centro=unaorden.centro
                UNION 
                SELECT '40311' as nrocuentac, 1,'Consulta' as desccuenta, nroorden,centro FROM orden NATURAL JOIN ordconsulta  WHERE nroorden=unaorden.nroorden and centro=unaorden.centro 
                UNION 
                SELECT '40316' as nrocuentac, 1,'Recetario TP' as desccuenta,nrorecetario as nroorden,centro FROM recetariotp  WHERE nrorecetario=unaorden.nroorden and centro=unaorden.centro
              ) as TT USING (nroorden, centro)
               WHERE nroorden=unaorden.nroorden and centro=unaorden.centro and (idformapagotipos =2 or idformapagotipos=3);
          

            IF FOUND THEN 
               INSERT INTO itemordenessinfactura(nroorden,centro,idconcepto,cantidad,importe,descripcion)
               VALUES (unitem.nroorden,unitem.centro,unitem.nrocuentac,unitem.cantidad,round(CAST(unitem.importe AS numeric),2),unitem.desccuenta);


            END IF; 
             SELECT INTO resp * FROM alta_modifica_ficha_medica_orden_expendio(unaorden.nroorden,unaorden.centro);
             FETCH lasordenes INTO unaorden;
          END LOOP;
          CLOSE lasordenes;


    return true;
END;

$function$
