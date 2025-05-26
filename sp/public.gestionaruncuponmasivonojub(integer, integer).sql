CREATE OR REPLACE FUNCTION public.gestionaruncuponmasivonojub(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	

	datocupon RECORD;
	uncupon record;
	infoafiliado record;
    resp boolean;
    elidtarjeta INTEGER;
	elidcentrotarjeta INTEGER;
	elidcuponnuevo INTEGER;
    lafechafin date;
	lafechahasta date;
lafechadesde date;
	lafechacreacion varchar(15);
    lafechavalidez varchar(15);
       

BEGIN
	elidtarjeta =$1;
	elidcentrotarjeta =$2;
	
IF NOT  iftableexists('temporalcupones') THEN
--Dani agrego el apellidodeltitular para ordenar por ese campo
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
				  idtarjeta integer,
                                  idcentrotarjeta integer,
                                  nrodoctitu varchar ,
                                  barra integer  ,
                                  apellidotitular  varchar
				 );
END IF;
	    SELECT INTO infoafiliado *,
            CASE WHEN nullvalue (eltitu ) THEN '' ELSE concat('Titular ',upper(eltitu)) END as eltitular ,
  CASE WHEN nullvalue (eltitu ) THEN apellido ELSE upper(eltitu) END as apellidotitular ,
            tiposdoc.descrip as descriptipodoc,T.nrodoctitu
	    FROM persona
	    NATURAL JOIN tarjeta
        LEFT JOIN ( SELECT benefsosunc.nrodoc as nrodoc , benefsosunc.tipodoc  as tipodoc,concat(apellido ,', ',nombres) as eltitu,case when nullvalue(nrodoctitu) then '' else nrodoctitu end as nrodoctitu
				    FROM benefsosunc
				    JOIN persona ON ( nrodoctitu = persona.nrodoc
                                 and tipodoctitu=persona.tipodoc)
	                )as T  ON (T.nrodoc= persona.nrodoc and T.tipodoc = persona.tipodoc)
		JOIN tiposdoc	on (tiposdoc.tipodoc=persona.tipodoc)
	    WHERE idtarjeta=elidtarjeta and idcentrotarjeta=elidcentrotarjeta and fechafinos>=current_date;

	    if found then 
			lafechafin=infoafiliado.fechafinos;
	    else
---			RAISE NOTICE 'no se consiguieron datos ';
	    end if;
---        RAISE NOTICE 'ENTRO ';
        
     
                 
         lafechacreacion=to_char(infoafiliado.fechanac::timestamp,'dd-MM-YYYY');

                   --- corroboro que no exista el cupon
                   --- VAS 02-10-2014 falta estado de cupon <>4
                   SELECT INTO uncupon *
                   FROM cupon
                   NATURAL JOIN cuponestado
                   WHERE idtarjeta = elidtarjeta
                         and idcentrotarjeta =  elidcentrotarjeta
                         and cfechavto = lafechafin
                         and idestadotipo<>4
                         and nullvalue(cefechafin);
                  IF not found THEN
                       INSERT INTO cupon (idtarjeta,idcentrotarjeta,idcentrocupon,cfechavto )VALUES (elidtarjeta,elidcentrotarjeta,elidcentrotarjeta,lafechafin);
                       --- recupero el id del cupon
                       elidcuponnuevo =  currval('cupon_idcupon_seq');
                      SELECT INTO resp cambiarestadocupon(elidcuponnuevo,elidcentrotarjeta,1);
                      SELECT INTO resp cambiarestadocupon(elidcuponnuevo,elidcentrotarjeta,2);
                  ELSE
                      elidcuponnuevo =uncupon.idcupon;
                  END IF ;
                 
                   --Dani 2014-08-12 puede ser q el cupon ya este generado para esa fechafin
                   -- pero igualmente puede q se quiera reimprimir el cupon de esa fecha.
                   --Por esto  inserto en la temporal , por fuera del IF

                   INSERT INTO  temporalcupones(idtarjeta,idcupon , apellido,nombre,titulodelempleo,departamento,telefono,fax,email,fechadecreacion,id,fechadevalidez,foto,idcentrotarjeta,nrodoctitu,barra,apellidotitular)
                   values (elidtarjeta,elidcuponnuevo , upper(infoafiliado.apellido),upper(infoafiliado.nombres),infoafiliado.eltitular,concat(infoafiliado.nrodoc,' ',infoafiliado.barra),
                          infoafiliado.nrodoc,infoafiliado.tipodoc,concat(upper(infoafiliado.descriptipodoc),' ',infoafiliado.nrodoc),lafechacreacion,concat(infoafiliado.nrodoc,'-',infoafiliado.barra),lafechafin,concat(infoafiliado.nrodoc,'-',infoafiliado.barra),elidcentrotarjeta,infoafiliado.nrodoctitu,infoafiliado.barra,infoafiliado.apellidotitular);
     
     
RETURN 'true';
END;
$function$
