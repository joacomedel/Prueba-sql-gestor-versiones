CREATE OR REPLACE FUNCTION multivac.agregarcuentafondos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
*/
DECLARE
    rpres RECORD;
    idprest bigint;
    presnombre varchar;
    rprestador CURSOR FOR
               select * from  tempcuentasfondos;
BEGIN
     OPEN rprestador;
     FETCH rprestador INTO rpres;
     WHILE  found LOOP
        if (rpres.idcuentafondos=0) then --Inserta un Nuevo Prestador
           begin
             INSERT INTO multivac.mapeocuentasfondos(nombrecuentafondos,nrocuentac,tipocuenta,update,fechaupdate,tipomov)
             VALUES (rpres.descripcion,rpres.nrocuentac,rpres.tipocuenta,true,now(),'I');
             idprest = currval('"multivac"."mapeocuentasfondos_idcuentafondos_seq"');
             presnombre = rpres.descripcion;
           end;
        else--Actualiza un Prestador
          begin
             idprest = rpres.idcuentafondos;
             UPDATE multivac.mapeocuentasfondos
             SET nombrecuentafondos=rpres.descripcion,
                 nrocuentac=rpres.nrocuentac,
                 tipocuenta = rpres.tipocuenta,
                 update = true,
                 fechaupdate = now(),
                 tipomov='U'
                 WHERE idcuentafondos=idprest;
          end;
        end if;
          FETCH rprestador INTO rpres;
     END LOOP;
     CLOSE rprestador;

     RETURN TRUE;
END;
$function$
