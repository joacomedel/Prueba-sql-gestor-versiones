CREATE OR REPLACE FUNCTION public.gestionarcuponesmasivos(integer, integer, date, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	cursordatosafil REFCURSOR;
	
	datotitu RECORD;
    registrodatosafil RECORD;
    
    cursordatosbenef  REFCURSOR;
     recorddatosbenef RECORD;
    
        lala RECORD;
	barraafi int4;
	fechahasta date;
       fechadesde date;
        lafechacreacion varchar(50);
       lafechavalidez varchar(50);
	respuesta boolean;
	elcentro integer;
        eltitu varchar(50);
       respa   boolean;

BEGIN
     barraafi=$1;
     fechahasta=$4;
     fechadesde=$3;
     elcentro=$2;
     --creo la temporal
      CREATE TEMP TABLE temporalcupones (
				  apellido varchar,
			      nombre varchar,
			      titulodelempleo varchar,
			      departamento varchar,
			      telefono varchar,
                              fax varchar,
				  email varchar,
				  fechadecreacion varchar,
				  id varchar,				
				  fechadevalidez varchar,				
				  foto varchar,
				  idcupon integer,
				  idtarjeta integer
				  ) ;

           OPEN cursordatosafil FOR SELECT *
           FROM persona
           LEFT JOIN actasdefun USING(nrodoc,tipodoc)
           NATURAL JOIN tarjeta
           NATURAL JOIN tarjetaestado
           WHERE persona.barra=barraafi and idcentrotarjeta=elcentro
                 and fechafinos >= CURRENT_DATE-180
                 and nullvalue(actasdefun.nrodoc)
                 and nullvalue(tefechafin)
                 and idestadotipo<>4    ;
        
     
           FETCH cursordatosafil into registrodatosafil;
	       WHILE found LOOP
	             ---- se crea el cupon del titular
                 perform gestionaruncuponmasivo(registrodatosafil.idtarjeta,registrodatosafil.idcentrotarjeta,fechadesde,fechahasta);
                 -- por cada beneficiario
                 OPEN cursordatosbenef FOR  SELECT *
                 FROM  persona
                 NATURAL JOIN benefsosunc
                  NATURAL JOIN tarjeta
                  NATURAL JOIN tarjetaestado
                 WHERE nrodoctitu =registrodatosafil.nrodoc and tipodoctitu =registrodatosafil.tipodoc        and nullvalue(tefechafin) and idestadotipo<>4 ;
                 FETCH cursordatosbenef into recorddatosbenef;
                 WHILE found LOOP
                        -- por cada beneficiario
                        perform gestionaruncuponmasivo(recorddatosbenef.idtarjeta,recorddatosbenef.idcentrotarjeta,fechadesde,fechahasta);

                        FETCH cursordatosbenef into recorddatosbenef;
                 end loop;
                 CLOSE cursordatosbenef;
                 FETCH cursordatosafil into registrodatosafil;
           END LOOP;
	       CLOSE cursordatosafil;


RETURN 'true';
END;
$function$
