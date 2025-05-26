CREATE OR REPLACE FUNCTION multivac.agregarcategoriagasto()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
    rpres RECORD;
    idprest bigint;
    presnombre varchar;
    rprestador CURSOR FOR
               select * from  tempcategoriagasto;
BEGIN
     OPEN rprestador;
     FETCH rprestador INTO rpres;
     WHILE  found LOOP
        if (rpres.idcatgasto=0) then --Inserta un Nuevo Prestador
           begin
             INSERT INTO multivac.mapeocatgasto(descripcionsiges,nrocuentac,nrocuentacproveedor,activo,idtipocatgasto,update,fechaupdate,tipomov)
             VALUES (rpres.descripcion,rpres.nrocuentac,rpres.nrocuentacproveedor,rpres.activo,rpres.idtipocatgasto,true,now(),'I');
             idprest = currval('"multivac"."mapeocatgasto_idcategoriagastosiges_seq"');
             presnombre = rpres.descripcion;
           end;
        else--Actualiza un Prestador
          begin
             idprest = rpres.idcatgasto;
             UPDATE multivac.mapeocatgasto
             SET descripcionsiges=rpres.descripcion,
                 nrocuentac=rpres.nrocuentac,
                 nrocuentacproveedor=rpres.nrocuentacproveedor,
                 activo = rpres.activo,
                 idtipocatgasto=rpres.idtipocatgasto,
                 update = true,
                 fechaupdate = now(),
                 tipomov='U'
                 WHERE idcategoriagastosiges=idprest;
          end;
        end if;
          FETCH rprestador INTO rpres;
     END LOOP;
     CLOSE rprestador;

     RETURN TRUE;
END;
$function$
