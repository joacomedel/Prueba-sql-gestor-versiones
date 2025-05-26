CREATE OR REPLACE FUNCTION public.w_cargarafiliaciondatos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	cursortitu CURSOR FOR SELECT * FROM persona
                              LEFT JOIN afilsosunc USING(nrodoc,tipodoc)
                              LEFT JOIN w_afiliaciondatos ON (persona.nrodoc = w_afiliaciondatos.nrodoc AND w_afiliaciondatos.idtiposdoc = persona.tipodoc) 
                              WHERE not nullvalue(afilsosunc.nrodoc)  AND fechafinos >= CURRENT_DATE AND nullvalue(w_afiliaciondatos.nrodoc) and (persona.barra >=  30 AND persona.barra < 100  )
-- and persona.nrodoc='22400866'
;
	titu RECORD;
        benef RECORD; 
	elidafiliaciondatos integer;
        cbenef refcursor;  
BEGIN 

CREATE TEMP TABLE afiliado ( nrodoc varchar(8) NOT NULL,nrodocreal varchar,apellido varchar NOT NULL,nombres varchar NOT NULL,fechanac date NOT NULL,sexo varchar(1) NOT NULL,estcivil varchar NOT NULL,telefono varchar,email varchar,fechainios date ,fechafinos date ,iddireccion int8,idcentrodireccion integer,barrio varchar,calle varchar,nro int4,tira varchar,piso varchar,dpto varchar,idprovincia int8,idlocalidad int8, tipodoc int2,carct varchar,barra int2,fechavtoreci date,idosreci int2,osreci varchar,idestado int2,estado varchar,idreci int2, reciprocidades varchar,nrocuilini varchar(2),nrocuildni varchar(8),nrocuilfin varchar(1),nroosexterna int8,idosexterna varchar,osexterna varchar,idctacte int8,ctacteexpendio boolean,mutu bool,nromutu int8,legajosiu int8,idcertpers int8,trabaja bool,trabajaunc bool,ingreso float4,nrodocjub varchar(8),tipodocjub int2,tipodocjubides varchar,idresolbec int8,textoalerta varchar) WITHOUT OIDS;

	CREATE TEMP TABLE beneficiarios ( nrodoc varchar(8) NOT NULL,apellido varchar(40) NOT NULL,nombres varchar NOT NULL,fechanac date NOT NULL,sexo varchar(1) NOT NULL,estcivil varchar NOT NULL,telefono varchar,email varchar,fechainios date,fechafinos date,iddireccion int8,idcentrodireccion integer,barrio varchar,calle varchar NOT NULL,nro int4 NOT NULL,tira varchar,piso varchar,dpto varchar,idprovincia int8 NOT NULL,idlocalidad int8 NOT NULL, tipodoc int2 NOT NULL,carct varchar,barra int2,fechavtoreci date,idestado int2,estado varchar,idreci int2, reciprocidades varchar,nrodoctitu varchar(8),tipodoctitu int2,idvin int2,barraTitu int2,nroosexterna int8,idosexterna varchar,osexterna varchar,mutual bool,barraMutu int2,nrodocreal varchar,nromututitu int8) WITHOUT OIDS;

	
	OPEN cursortitu;
	FETCH cursortitu into titu;
	WHILE found LOOP



			/** BUSCO LOS DATOS DEL TITULAR **/
			PERFORM datosafiliadov2(titu.nrodoc,titu.tipodoc);

			INSERT INTO w_afiliaciondatos ( adnombre,adapellido,adfechanac, adsexo , nrodoc ,
					idtiposdoc ,idtestadocivil ,adcalle , adnumero ,idlocalidad ,
					ademail , adtelfijo , adcel , adotraos, adamuc ,barra,idosexterna,adbarrio,adpiso,addepartamento,idprovincia)
			(
				SELECT nombres,apellido,fechanac, sexo , nrodoc ,afiliado.tipodoc ,estcivil::integer ,calle  , nro  ,idlocalidad ::integer	 , email ,concat(case when carct = 0 then '' ELSE carct::text END,' ',telefono) , '' as celular , nroosexterna, mutu, barra,idosexterna,barrio,piso,dpto,idprovincia
				FROM afiliado
                                NATURAL JOIN (SELECT descrip as tipodocdes,tipodoc FROM  tiposdoc ) as tipodoc
				NATURAL JOIN (SELECT descrip as localidaddescrip,idlocalidad FROM localidad) as localidad
                               
			);

			elidafiliaciondatos = currval('w_afiliaciondatos_idafiliaciondatos_seq');

			/** BUSCO LOS DATOS DEL BENEFICIARIO **/
begin
			PERFORM datosbeneficiarios(titu.nrodoc,titu.tipodoc,titu.barra);


			INSERT INTO w_afiliaciondatos ( adnombre,adapellido,adfechanac, adsexo , nrodoc ,
					idtiposdoc ,idtestadocivil ,adcalle , adnumero ,idlocalidad ,
					ademail , adtelfijo , adcel , adotraos, adamuc ,adidtitular,nrodoctitu ,idvin ,barra,idosexterna,adbarrio,adpiso,addepartamento,idprovincia )
			(
			SELECT nombres,apellido,fechanac, sexo , nrodoc ,beneficiarios.tipodoc ,estcivil::integer ,calle  , nro  ,idlocalidad ::integer , email , concat(case when carct = 0 then '' ELSE carct::text END,' ',telefono) , '' as celular , nroosexterna, mutual,elidafiliaciondatos,nrodoctitu,idvin,barra,idosexterna,barrio,piso,dpto,idprovincia
			FROM beneficiarios
			NATURAL JOIN (SELECT descrip as tipodocdes,tipodoc FROM  tiposdoc ) as tipodoc
			NATURAL JOIN (SELECT descrip as localidaddescrip,idlocalidad FROM localidad) as localidad
                        WHERE fechafinos >= current_date
			);
exception when others then 
  raise notice '% %', SQLERRM, SQLSTATE;
END;
	DELETE FROM  afiliado;		
		DELETE FROM  beneficiarios;
fetch cursortitu into titu;
END LOOP;
close cursortitu;

-- MaLapi 22-11-2018 Ahora agrego a todos los beneficiarios que no estan, que tienen fechafinos mayor a hoy y que ademas sus padres si estan en la ficha. 

OPEN cbenef FOR SELECT * FROM benefsosunc
                NATURAL JOIN persona 
                JOIN w_afiliaciondatos as padre  ON (benefsosunc.nrodoctitu = padre.nrodoc AND padre.idtiposdoc = benefsosunc.tipodoctitu) 
                LEFT JOIN w_afiliaciondatos ON (benefsosunc.nrodoc = w_afiliaciondatos.nrodoc AND w_afiliaciondatos.idtiposdoc = benefsosunc.tipodoc) 
                WHERE  fechafinos >= CURRENT_DATE AND nullvalue(w_afiliaciondatos.nrodoc);
	FETCH cbenef into benef;
	WHILE found LOOP
          
       DELETE FROM  beneficiarios;

       PERFORM datosbeneficiarios(benef.nrodoctitu,benef.tipodoctitu,benef.barratitu);


			INSERT INTO w_afiliaciondatos ( adnombre,adapellido,adfechanac, adsexo , nrodoc ,
					idtiposdoc ,idtestadocivil ,adcalle , adnumero ,idlocalidad ,
					ademail , adtelfijo , adcel , adotraos, adamuc ,adidtitular,nrodoctitu ,idvin ,barra,idosexterna,adbarrio,adpiso,addepartamento,idprovincia )
			(
			SELECT nombres,apellido,fechanac, sexo , nrodoc ,beneficiarios.tipodoc ,estcivil::integer ,calle  , nro  ,idlocalidad ::integer , email , concat(case when carct = 0 then '' ELSE carct::text END,' ',telefono) , '' as celular , nroosexterna, mutual,elidafiliaciondatos,nrodoctitu,idvin,barra,idosexterna,barrio,piso,dpto,idprovincia
			FROM beneficiarios
			NATURAL JOIN (SELECT descrip as tipodocdes,tipodoc FROM  tiposdoc ) as tipodoc
			NATURAL JOIN (SELECT descrip as localidaddescrip,idlocalidad FROM localidad) as localidad
                        LEFT JOIN w_afiliaciondatos ON (beneficiarios.nrodoc = w_afiliaciondatos.nrodoc AND w_afiliaciondatos.idtiposdoc = beneficiarios.tipodoc) 
                        WHERE fechafinos >= current_date AND nullvalue(w_afiliaciondatos.nrodoc)
			);




FETCH cbenef into benef;
END LOOP;
close cbenef;


return 'true';
END;
$function$
