CREATE OR REPLACE FUNCTION multivac.agregarcuentacontable()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
    rpres RECORD;
    idprest bigint;
    nroctac varchar;
    presnombre varchar;
    rprestador CURSOR FOR
               select * from  tempcuentascontables;
BEGIN
     OPEN rprestador;
     FETCH rprestador INTO rpres;
     WHILE  found LOOP
        nroctac = rpres.nrocuentac;
        if (rpres.idcuenta=0) then --Inserta un Nuevo
           begin
             presnombre = rpres.descripcionsiges;
             
             insert into cuentascontables(orden,nrocuentac,desccuenta)
             values (1000,nroctac,presnombre);

             INSERT INTO multivac.mapeocuentascontables(nrocuentac,descripcionsiges,saldohabitual,imputable,asignaccosto,jerarquia,activo)
             VALUES (rpres.nrocuentac,rpres.descripcionsiges,rpres.saldohabitual,rpres.imputable,rpres.asignaccosto,rpres.jerarquia,rpres.activo);
             idprest = currval('"multivac"."mapeocuentascontables_idcuenta_seq"');

           end;
        else--Actualiza
          begin
             idprest = rpres.idcuenta;

             UPDATE cuentascontables
                    set desccuenta = rpres.descripcionsiges
                    where nrocuentac= nroctac;
             
             UPDATE multivac.mapeocuentascontables
                 SET descripcionsiges=rpres.descripcionsiges,
                 nrocuentac=rpres.nrocuentac,
                 saldohabitual = rpres.saldohabitual,
                 asignaccosto = rpres.asignaccosto,
                 imputable = rpres.imputable,
                 jerarquia = rpres.jerarquia,
                 activo = rpres.activo,
                 update = true,
                 fechaupdate = now(),
                 tipomov='U'
                 where nrocuentac = nroctac;

          end;
        end if;
          FETCH rprestador INTO rpres;
     END LOOP;
     CLOSE rprestador;

     RETURN TRUE;
END;
$function$
