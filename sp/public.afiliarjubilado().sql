CREATE OR REPLACE FUNCTION public.afiliarjubilado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rafiliado RECORD;
       persona RECORD;
       cargo2 CURSOR FOR SELECT * FROM cargos2;
       rcargo RECORD;
       siguiente integer;
       encontro  boolean;
   resultado boolean;
   contador integer;
   existetbarras RECORD;
       respuesta varchar;
BEGIN

SELECT INTO rafiliado * FROM afil;
if NOT FOUND
 then
     return 'false';
 else
   encontro = 'false';
   SELECT INTO persona * FROM afiljub WHERE nrodoc = rafiliado.nrodoc
AND tipodoc = rafiliado.tipodoc;
   if NOT FOUND
      then
       OPEN cargo2;
       FETCH cargo2 into rcargo;
       WHILE  found LOOP
        if (rcargo.tipo = 35)
                 then
                   SELECT INTO contador count(*) FROM certpersonal;
                   if contador > 0
                    then
                           SELECT INTO siguiente MAX(idcertpers) FROM
certpersonal;
                           siguiente=siguiente+1;
                           INSERT INTO certpersonal (idcertpers,cantaport,idcateg) VALUES(rafiliado.nrodoc::BigInt,rcargo.cantaport,rcargo.categoria);
                           INSERT INTO afiljub (nrodoc,	idcertpers,trabaja,trabajaunc,tipodoc,ingreso)  VALUES(rafiliado.nrodoc,rafiliado.nrodoc::BigInt,rcargo.trabaja,rcargo.trabajaunc,rafiliado.tipodoc,rcargo.ingreso);
                           INSERT INTO aporteconfiguracion(idcentroaporteconfiguracion,nrodoc,tipodoc,acporcentaje,acimportebruto,acimporteaporte,acfechafin,acfechainicio,descripcion)
VALUES(centro(),rafiliado.nrodoc,rafiliado.tipodoc,rcargo.acporcentaje,rcargo.acimportebruto,rcargo.acimporteaporte,null,now()::date,rcargo.descripcion);
                             -- 25-02-22 llamo al SP que da de alta en clientectacte, luego esto se usa para las novedades
                           SELECT INTO respuesta  FROM sys_abmctactecliente(concat('{nrocliente =' , rafiliado.nrodoc, ',barra =',rafiliado.tipodoc,' , cccdtohaberes = ',false,' , idestadotipo = ',8,', idformapagoctacte= ', NULL,' }'));

                           encontro = 'true';
                      else
                           INSERT INTO certpersonal (idcertpers,cantaport,idcateg)VALUES(1,rcargo.cantaport,rcargo.categoria);
                            INSERT INTO afiljub (nrodoc,idcertpers,trabaja,trabajaunc,tipodoc,ingreso) VALUES(rafiliado.nrodoc,rafiliado.nrodoc::BigInt,rcargo.trabaja,rcargo.trabajaunc,rafiliado.tipodoc,rcargo.ingreso);
                           INSERT INTO aporteconfiguracion(idcentroaporteconfiguracion,nrodoc,tipodoc,acporcentaje,acimportebruto,acimporteaporte,acfechafin,acfechainicio,descripcion)
VALUES(centro(),rafiliado.nrodoc,rafiliado.tipodoc,rcargo.acporcentaje,rcargo.acimportebruto,rcargo.acimporteaporte,null,now()::date, rcargo.descripcion);
                           encontro = 'true';
                            -- 25-02-22 llamo al SP que da de alta en clientectacte, luego esto se usa para las novedades
                           SELECT INTO respuesta  FROM sys_abmctactecliente(concat('{nrocliente =' , rafiliado.nrodoc, ',barra =',rafiliado.tipodoc,' , cccdtohaberes = ',false,' , idestadotipo = ',8,', idformapagoctacte= ', NULL,' }'));

            end if;
                end if;
       fetch cargo2 into rcargo;
       END LOOP;
       CLOSE cargo2;
     else
       OPEN cargo2;
       FETCH cargo2 into rcargo;
       WHILE  found LOOP
        if (rcargo.tipo = 35)
                 then
                  UPDATE afiljub SET idcertpers = rcargo.idcert::BigInt, trabaja =
rcargo.trabaja, trabajaunc = rcargo.trabajaunc, ingreso =
rcargo.ingreso  WHERE tipodoc = rafiliado.tipodoc AND nrodoc =
rafiliado.nrodoc;
                  UPDATE certpersonal SET cantaport = rcargo.cantaport,
idcateg=rcargo.categoria WHERE idcertpers = rcargo.idcert;

                  UPDATE aporteconfiguracion SET acfechafin =
(now()::date) WHERE nrodoc = rafiliado.nrodoc and tipodoc =
rafiliado.tipodoc and  nullvalue(acfechafin)  ;


                 INSERT INTO aporteconfiguracion(idcentroaporteconfiguracion,nrodoc,tipodoc,acporcentaje,acimportebruto,acimporteaporte,acfechafin,acfechainicio,descripcion)
VALUES(centro(),rafiliado.nrodoc,rafiliado.tipodoc,rcargo.acporcentaje,rcargo.acimportebruto,rcargo.acimporteaporte,null,now()::date,rcargo.descripcion);
                  encontro = 'true';

                end if;
       fetch cargo2 into rcargo;
       END LOOP;
       CLOSE cargo2;
   end if;
   if encontro
      then
         SELECT INTO resultado * FROM
incorporarbarra(35,rafiliado.nrodoc,rafiliado.tipodoc);
          else
             resultado = 'false';
   end if;
    SELECT INTO existetbarras * FROM tbarras WHERE nrodoctitu =
rafiliado.nrodoc AND tipodoctitu = rafiliado.tipodoc;
   if NOT FOUND
       then
                 INSERT INTO tbarras VALUES (rafiliado.nrodoc,rafiliado.tipodoc,2);
                 resultado = 'true';
   end if;
   return resultado;
end if;
END;$function$
