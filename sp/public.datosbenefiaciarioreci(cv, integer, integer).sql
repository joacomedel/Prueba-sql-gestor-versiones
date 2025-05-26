CREATE OR REPLACE FUNCTION public.datosbenefiaciarioreci(character varying, integer, integer)
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
select INTO rtemporal column_name from information_schema.columns where table_name='beneficiarios' AND column_name = 'nrodocreal';
IF NOT FOUND THEN 
   ALTER TABLE beneficiarios ADD COLUMN nrodocreal text;
END IF;

    bandera='false';
	FOR rec IN SELECT * 
                FROM persona INNER JOIN benefreci  
                    ON (persona.nrodoc = benefreci.nrodoc  
                      AND persona.tipodoc = benefreci.tipodoc)
                WHERE benefreci.nrodoctitu=$1 
                --Malapi 25-03-2015 Ya no uso mas el tipodoc o la barra, para evitar una doble consulta en java
                --AND benefreci.tipodoctitu=$2 
                --AND benefreci.barratitu=$3
    LOOP
    bandera = 'true';
    select into aux * from estados where estados.idestado=rec.idestado;
    select into aux2 * from reciprocidades where reciprocidades.idreci = rec.idreci;
    select into aux3 * from direccion where rec.iddireccion=direccion.iddireccion and rec.idcentrodireccion = direccion.idcentrodireccion;
   
	
	INSERT INTO beneficiarios (nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos,iddireccion,idcentrodireccion,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad,tipodoc,carct,barra,fechavtoreci,idestado,estado,idreci,reciprocidades,nrodoctitu,tipodoctitu,idvin,barratitu,nroosexterna,idosexterna,osexterna,mutual,barramutu,nromututitu,nrodocreal)
VALUES (rec.nrodoc,rec.apellido,rec.nombres,rec.fechanac,rec.sexo,rec.estcivil,rec.telefono,rec.email,rec.fechainios,rec.fechafinos,rec.iddireccion,rec.idcentrodireccion,aux3.barrio,aux3.calle,aux3.nro,aux3.tira,aux3.piso,aux3.dpto,aux3.idprovincia,aux3.idlocalidad,rec.tipodoc,rec.carct,rec.barra,rec.fechavtoreci,rec.idestado,aux.descrip,rec.idreci,aux2.descrip,rec.nrodoctitu,rec.tipodoctitu,rec.idvin,rec.barraTitu,0,0,'',false,0,0,rec.nrodocreal);

   END LOOP ;
	
	IF NOT bandera THEN
            FOR rec IN SELECT * 
                    FROM persona INNER JOIN benefreci  
                    ON (persona.nrodoc = benefreci.nrodoc  
                      AND persona.tipodoc = benefreci.tipodoc)
                WHERE benefreci.nrodoctitu=$1 
                AND benefreci.tipodoctitu=$2 
               
        LOOP
        bandera = 'true';
        select into aux * from estados where estados.idestado=rec.idestado;
        select into aux2 * from reciprocidades where reciprocidades.idreci = rec.idreci;
        select into aux3 * from direccion where rec.iddireccion=direccion.iddireccion;
               
        INSERT INTO beneficiarios VALUES (rec.nrodoc,rec.apellido,rec.nombres,rec.fechanac,rec.sexo,rec.estcivil,rec.telefono,rec.email,rec.fechainios,rec.fechafinos,rec.iddireccion,aux3.barrio,aux3.calle,aux3.nro,aux3.tira,aux3.piso,aux3.dpto,aux3.idprovincia,aux3.idlocalidad,rec.tipodoc,rec.carct,rec.barra,rec.fechavtoreci,rec.idestado,aux.descrip,rec.idreci,aux2.descrip,rec.nrodoctitu,rec.tipodoctitu,rec.idvin,rec.barraTitu,0,0,'',false,0,0);
    
       END LOOP ;
    END IF;
    
    IF NOT bandera THEN
        RAISE EXCEPTION 'Error 1';
    END IF;
   RETURN 'true';
END;$function$
