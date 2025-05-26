CREATE OR REPLACE FUNCTION public.gestionaruncuponmasivo(integer, integer, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	

	datocupon RECORD;
	infoafiliado record;
    resp boolean;
    elidtarjeta INTEGER;
	elidcentrotarjeta INTEGER;
	elidcuponnuevo INTEGER;
    lafechafin date;
	lafechahasta date;
	lafechacreacion varchar(15);
    lafechavalidez varchar(15);
    uncupon RECORD;
       

BEGIN
	elidtarjeta =$1;
	elidcentrotarjeta =$2;
	lafechahasta=$3;

	    SELECT INTO infoafiliado *,
            CASE WHEN nullvalue (eltitu ) THEN '' ELSE concat('Titular ',upper(eltitu)) END as eltitular ,
            tiposdoc.descrip as descriptipodoc
	    FROM persona
	    NATURAL JOIN tarjeta
        LEFT JOIN ( SELECT benefsosunc.nrodoc as nrodoc , benefsosunc.tipodoc  as tipodoc,concat(apellido ,', ',nombres) as eltitu
				    FROM benefsosunc
				    JOIN persona ON ( nrodoctitu = persona.nrodoc
                                 and tipodoctitu=persona.tipodoc)
	                )as T  ON (T.nrodoc= persona.nrodoc and T.tipodoc = persona.tipodoc)
		JOIN tiposdoc	on (tiposdoc.tipodoc=persona.tipodoc)
	    WHERE idtarjeta=elidtarjeta and idcentrotarjeta=elidcentrotarjeta;

	    if found then 
			lafechafin=infoafiliado.fechafinos;
	    else
---			RAISE NOTICE 'no se consiguieron datos ';
	    end if;
---        RAISE NOTICE 'ENTRO ';
        --ver como hacer la comparacion de fechas
        while (lafechafin<lafechahasta) loop
                
                 
                   lafechafin= case when (EXTRACT(MONTH FROM (lafechafin))=12 ) then
	                           to_date(concat(EXTRACT(YEAR FROM (lafechafin)::timestamp)+1 ,'-',01,'-10'),'YYYY-MM-DD')
                               else  to_date(concat(EXTRACT(YEAR FROM (lafechafin)::timestamp) ,'-',EXTRACT(MONTH FROM
                               (lafechafin))+1,'-10') ,'YYYY-MM-DD')   end  ;		


                   lafechacreacion=to_char(infoafiliado.fechanac::timestamp,'dd-MM-YYYY');
                   lafechavalidez=to_char(infoafiliado.fechafinos::timestamp,'dd-MM-YYYY');

                   -- corrobor la existencia del cupon
                   SELECT INTO uncupon * FROM cupon
                   WHERE idtarjeta = elidtarjeta
                         and idcentrotarjeta =  elidcentrotarjeta 
                         and cfechavto = lafechafin;
                   IF not found THEN
                      INSERT INTO cupon (idtarjeta,idcentrotarjeta,cfechavto )VALUES (elidtarjeta,elidcentrotarjeta,lafechafin);
                      --- recupero el id del cupon
                      elidcuponnuevo =  currval('cupon_idcupon_seq');
                       SELECT INTO resp cambiarestadocupon(elidcuponnuevo,elidcentrotarjeta,1);
                       SELECT INTO resp cambiarestadocupon(elidcuponnuevo,elidcentrotarjeta,2);
                   else
                       elidcuponnuevo =uncupon.idcupon;
                   END IF ;
                   INSERT INTO  temporalcupones(idcupon , apellido,nombre,titulodelempleo,departamento,telefono,fax,email,fechadecreacion,id,fechadevalidez,foto)
                   values (elidcuponnuevo , upper(infoafiliado.apellido),upper(infoafiliado.nombres),infoafiliado.eltitular,'',
                          infoafiliado.nrodoc,infoafiliado.tipodoc,concat(upper(infoafiliado.descriptipodoc),' ' ,infoafiliado.nrodoc),lafechacreacion,concat(infoafiliado.nrodoc,' ',infoafiliado.barra),lafechafin,concat(infoafiliado.nrodoc,'-',infoafiliado.barra));

                  
      end loop;
     
RETURN 'true';
END;
$function$
