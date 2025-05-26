CREATE OR REPLACE FUNCTION public.datosbenefiaciariososunc(character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  
    aux RECORD;
    aux2 RECORD;
    aux3 RECORD;
    rec RECORD;
    rtemporal RECORD;
    bandera boolean;

BEGIN


--Malapi 25-03-2015 Verifico que exista el campo en la tabla temporal, para que no me de error mientras no se pone en producccion 
--la nueva version de afiliaciones. 
/*select INTO rtemporal column_name from information_schema.columns where table_name='beneficiarios' AND column_name = 'nrodocreal';
IF NOT FOUND THEN 
   ALTER TABLE beneficiarios ADD COLUMN nrodocreal text;
END IF;
*/
IF (iftableexistsparasp('beneficiarios')) THEN    
     DROP TABLE beneficiarios;
    CREATE TEMP TABLE beneficiarios ( nrodoc varchar(8) NOT NULL,apellido varchar(40) NOT NULL,nombres varchar(50) NOT NULL,fechanac date NOT NULL,sexo varchar(1) NOT NULL,estcivil varchar  NOT NULL,telefono varchar ,email varchar ,fechainios date NOT NULL,fechafinos date NOT NULL,iddireccion int8 NOT NULL,idcentrodireccion integer NOT NULL,barrio varchar,calle varchar  NOT NULL,nro int4 NOT NULL,tira varchar ,piso varchar ,dpto varchar ,idprovincia int8 NOT NULL,idlocalidad int8 NOT NULL, tipodoc int2 NOT NULL,carct varchar(6),barra int2,fechavtoreci date,idestado int2,estado varchar ,idreci int2, reciprocidades varchar ,nrodoctitu varchar(8),tipodoctitu int2,idvin int2,barraTitu int2,nroosexterna int8,idosexterna varchar(20),osexterna varchar ,mutual bool,barraMutu int2,nrodocreal text,nromututitu int8) WITHOUT OIDS;

END IF;




    bandera='false';
    IF NOT bandera THEN
            FOR rec IN SELECT CASE WHEN nullvalue(btrim(benef.idosexterna)) OR benef.idosexterna = 'null'  OR btrim(benef.idosexterna) = '' THEN '0' ELSE benef.idosexterna END as idosexterna,*  FROM persona 
                       NATURAL JOIN 
                       (SELECT  benefsosunc.* FROM benefsosunc 
                        LEFT JOIN beneficiariosborrados USING(nrodoc, tipodoc, nrodoctitu, tipodoctitu)
                        LEFT JOIN  afilsosunc ON benefsosunc.nrodoc = afilsosunc.nrodoc AND benefsosunc.tipodoc = afilsosunc.tipodoc 
                        WHERE  --Malapi 17-11-2017 Agrego para que muestre a los beneficiarios que no se volvieron a afiliar de otra formar.
                                (not NULLVALUE(beneficiariosborrados.nrodoc) 
                              AND NULLVALUE(afilsosunc.nrodoc))
OR (   NULLVALUE(beneficiariosborrados.nrodoc) 
                             AND    NULLVALUE(afilsosunc.nrodoc))
OR (   NULLVALUE(beneficiariosborrados.nrodoc) 
                             AND   NOT NULLVALUE(afilsosunc.nrodoc) AND (afilsosunc.barra>29 OR nullvalue(afilsosunc.barra)))

) as benef
                            WHERE benef.nrodoctitu=$1
                                 --Malapi 25-03-2015 Ya no uso mas el tipodoc o la barra, para evitar una doble consulta en java
                                 --AND benef.tipodoctitu=$2  
                                 --AND benef.barratitu=$3
                                  
                    
        LOOP
        bandera = 'true';
        select into aux * from estados where estados.idestado=rec.idestado;
        select into aux2 * from osexterna where osexterna.idosexterna = rec.idosexterna;
        select into aux3 * from direccion where rec.iddireccion=direccion.iddireccion and rec.idcentrodireccion = direccion.idcentrodireccion;
        
        INSERT INTO beneficiarios (nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos
,iddireccion,idcentrodireccion,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad,tipodoc,carct,barra,		fechavtoreci,idestado,estado,idreci,reciprocidades,nrodoctitu,tipodoctitu,idvin,barratitu,nroosexterna,idosexterna
,osexterna,mutual,barramutu,nromututitu,nrodocreal) VALUES (rec.nrodoc,rec.apellido,rec.nombres,rec.fechanac,rec.sexo,rec.estcivil,rec.telefono,rec.email,rec.fechainios,rec.fechafinos,rec.iddireccion,rec.idcentrodireccion,aux3.barrio,aux3.calle,aux3.nro,aux3.tira,aux3.piso,aux3.dpto,aux3.idprovincia,aux3.idlocalidad,rec.tipodoc,rec.carct,rec.barra,'9999-12-31',rec.idestado,aux.descrip,0,'',rec.nrodoctitu,rec.tipodoctitu,rec.idvin,rec.barratitu,rec.nroosexterna,rec.idosexterna,aux2.descrip,rec.mutual,rec.barramutu,rec.nromututitu,rec.nrodocreal);
    
       END LOOP ;
    END IF;
    
    IF NOT bandera THEN
        RAISE EXCEPTION 'Error 1';
    END IF;
   RETURN 'true';
END;$function$
