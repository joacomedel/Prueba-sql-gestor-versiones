CREATE OR REPLACE FUNCTION public.agregardescuentosconceptos(pmes integer, panio integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Carga los conceptos 387 y 372 de la liquidacion para ser usada en la imputacion de
cuentas corrientes.
Utiliza la informacion de las tablas dh49 para la liquidacion y dh21 para los datos de
los aportes
*/
DECLARE
alta refcursor;
    cursorauxi refcursor;
    elemcursor record;
    elem RECORD;
    rinforme RECORD;
resultado boolean;
BEGIN
/*Verifico las personas que deben ser informadas*/
DELETE FROM infomeerrordescuentosplanilla;
OPEN cursorauxi FOR SELECT
                personas.legajosiu,nroliquidacion,personas.nrocargo,importe::numeric,mesingreso,anioingreso
                    FROM
                    (
                    SELECT max(dh21.mesingreso) as mesingreso,max(dh21.anioingreso) as anioingreso,nrolegajo as legajosiu,max(nroliquidacion) as nroliquidacion ,max(nrocargo) as nrocargo,sum(importe) as importe
                    FROM dh21
                    WHERE  dh21.mesingreso = pmes
                     AND dh21.anioingreso = panio
                     AND (dh21.nroconcepto = 372
                     OR dh21.nroconcepto = 387 )
                          GROUP BY nrolegajo
                    ) as personas
                    LEFT JOIN (
                      SELECT legajosiu,nrodoc,tipodoc FROM afilidoc
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afilinodoc
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afiliauto
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afilirecurprop
                      ) as t USING(legajosiu)
                      LEFT JOIN (SELECT idcargo as nrocargo,legajosiu,tipodesig as tipoempleado FROM cargo ) as cargo using(nrocargo)
                      
                     WHERE nullvalue(t.legajosiu) or nullvalue(tipoempleado) ;
FETCH cursorauxi INTO elemcursor;
WHILE found Loop
       --Reportarlo como que no existe en sosunc, o no esta bien cargado
       RAISE NOTICE 'elemcursor (%)',elemcursor;
       INSERT INTO infomeerrordescuentosplanilla (legajosiu,importe,mesingreso,anioingreso,nroliquidacion,nrocargo)
       VALUES(elemcursor.legajosiu,elemcursor.importe,elemcursor.mesingreso,elemcursor.anioingreso,elemcursor.nroliquidacion,elemcursor.nrocargo);
FETCH cursorauxi INTO elemcursor;
END LOOP;
CLOSE cursorauxi;
resultado = true;
/*Ingreso los aportes de las personas que no fueron reportadas en el informe*/
OPEN alta FOR 

-- CS y DM 2016-12-22
--SELECT dh21.*,nrodoc,tipodoc,tipoempleado,nrodoc::integer * 10 + tipodoc as idctacte

SELECT sum(dh21.importe) as importe, dh21.nrolegajo,dh21.nroliquidacion,dh21.nrocargo,dh21.mesingreso,dh21.anioingreso,dh21.nroconcepto,nrodoc,tipodoc,tipoempleado,nrodoc::integer * 10 + tipodoc as idctacte
    FROM dh21
    NATURAL JOIN (
         SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afilidoc
         UNION
         SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afilinodoc
         UNION
         SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afiliauto
         UNION
         SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afilirecurprop
          ) as t
    NATURAL JOIN (SELECT idcargo as nrocargo,legajosiu,tipodesig as tipoempleado FROM cargo ) as cargo
    LEFT JOIN infomeerrordescuentosplanilla USING(legajosiu,mesingreso,anioingreso)
    WHERE dh21.mesingreso = pmes
     AND dh21.anioingreso = panio
    AND  (dh21.nroconcepto = 372
    OR dh21.nroconcepto = 387 )
    AND nullvalue(infomeerrordescuentosplanilla.legajosiu)
   

-- CS y DM 2016-12-22
group by 
dh21.nrolegajo,dh21.nroliquidacion,dh21.nrocargo,dh21.mesingreso,dh21.anioingreso,dh21.nroconcepto,nrodoc,tipodoc,tipoempleado,nrodoc,tipodoc
-- //////////////////
    ;

FETCH alta INTO elem;
WHILE  found LOOP
       SELECT INTO rinforme * FROM informedescuentoplanillav2
                   WHERE nroliquidacion = elem.nroliquidacion
                            AND idcargo = elem.nrocargo
                            AND importe = elem.importe
                            AND mes = elem.mesingreso
                            AND concepto = elem.nroconcepto
                            AND anio = elem.anioingreso;

       IF NOT FOUND THEN
            INSERT INTO informedescuentoplanillav2
                     (idinforme,informedescuentoplanillatipo,nroliquidacion,legajosiu,concepto,idcargo,importe,fechaingreso,mes,anio,tipoempleado,importeimputado,nrodoc,tipodoc)
                     VALUES (nextval('informedescuentoplanilla_idinforme_seq'),1,elem.nroliquidacion,elem.nrolegajo,elem.nroconcepto,elem.nrocargo,elem.importe,CURRENT_DATE,elem.mesingreso,elem.anioingreso,elem.tipoempleado,elem.importe,elem.nrodoc,elem.tipodoc);
            INSERT INTO cuentacorrientepagos(idcomprobantetipos,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,tipodoc,idctacte,idcentropago)
                     VALUES (13,CURRENT_DATE,concat ( 'Descuento UNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' , elem.mesingreso , '/' , elem.anioingreso),10311,elem.importe*-1,currval('informedescuentoplanilla_idinforme_seq'),elem.importe*-1,elem.nroconcepto,elem.nrodoc,elem.tipodoc,elem.idctacte,centro());
      END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;
/*Paso tambien ahora por parametro 2 si es descuento concepto de unc*/
PERFORM asentarreciboenctactepagos(pmes,panio,2);

return resultado;

END;

$function$
