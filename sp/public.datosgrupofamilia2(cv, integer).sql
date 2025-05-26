CREATE OR REPLACE FUNCTION public.datosgrupofamilia2(character varying, integer)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$
DECLARE
	datosafil REFCURSOR;
	datotitu RECORD;
        undatoafil RECORD;
	barraafi int4;
existe boolean;
	

BEGIN
 select into existe * from public.iftableexistsparasp('tmpafiliado');


 if not (existe)then 
    
     CREATE TEMP TABLE tmpafiliado (  nrodoc varchar(8) NOT NULL,
					apellido varchar(40) NOT NULL,
					nombres varchar(50) NOT NULL,
					fechanac date NOT NULL, 
					fechafinos date NOT NULL,
					 tipodoc int2, 
					descrip varchar(10) NOT NULL,
					barra int2,fechavtoreci date, 
					nrodoctitu varchar(8), 
					tipodoctitu int2,
                                         tetdescripcion varchar
					) ; 

   end if;
   barraafi = $2;
--recupero los datos del titular 

 select into datotitu nrodoctitu,tipodoctitu
	from benefsosunc natural join persona  
		where nrodoc=$1 and barra=$2;
		

if not found then 

select into datotitu nrodoc as nrodoctitu,tipodoc as tipodoctitu
	from  afilsosunc natural join persona 
		where nrodoc=$1 and barra=$2;
		if not found then 
		    RAISE NOTICE 'no se consiguieron datos ';
		end if;
end if;

  
	 OPEN datosafil FOR select *  from
		(
		select 
		nrodoc,apellido,nombres,
		barra,tipodoc,tiposdoc.descrip,fechanac,fechafinos,nrodoc as nrodoctitu, tipodoc as tipodoctitu
		from persona 
		natural join tiposdoc
		where nrodoc = datotitu.nrodoctitu  and tipodoc=datotitu.tipodoctitu

		union

		select nrodoc,apellido,nombres,barra,tipodoc,tiposdoc.descrip,fechanac,fechafinos,nrodoctitu,tipodoctitu
		from benefsosunc natural join persona  natural join tiposdoc
		where nrodoctitu=datotitu.nrodoctitu and tipodoctitu=datotitu.tipodoctitu
		)as d
	left join tarjeta using(nrodoc,tipodoc)
	left join tarjetaestado using(idtarjeta,idcentrotarjeta)
	left join tarjetaestadotipo using(idestadotipo)
	where nullvalue(tefechafin);
	

 FETCH datosafil into undatoafil;
 WHILE found LOOP
       IF nullvalue (undatoafil.tetdescripcion)THEN undatoafil.tetdescripcion =''; END IF;
			                
		INSERT INTO tmpafiliado(nrodoc,apellido,nombres,barra,tipodoc,descrip,fechanac,fechafinos,nrodoctitu,tipodoctitu,tetdescripcion)
		VALUES (undatoafil.nrodoc,undatoafil.apellido,undatoafil.nombres,undatoafil.barra,undatoafil.tipodoc,
		undatoafil.descrip,undatoafil.fechanac,undatoafil.fechafinos,undatoafil.nrodoctitu,undatoafil.tipodoctitu,undatoafil.tetdescripcion);

 FETCH datosafil into undatoafil;
 end loop;
close datosafil;	




RETURN 'true';
END;
$function$
