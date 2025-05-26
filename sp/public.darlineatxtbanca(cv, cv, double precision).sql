CREATE OR REPLACE FUNCTION public.darlineatxtbanca(character varying, character varying, double precision)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       lineatxt character varying;
       infocuenta record;
       cdueno refcursor;
       rdueno record;
       importe double precision;
       infodueno character varying;
       textoadicional character varying;
       elcuit character varying;
       laclave  integer;
        razonsocial  character varying;
        elnrodoc character varying ;
        eltipodoc  integer;
BEGIN
     -- $1 = clave
     -- $2 = tabla del dueno de la cuenta
     -- $3 = monto a transferir

     importe = round($3::numeric,2);
     importe = importe * 100;

    
     /* Por cada tabla que se envie por parametro se deben setear la info necesaria para armar la linea*/
     if (trim($1) = 'ca.persona')THEN  -- busco en persona la razon social
        laclave = split_part($2, '|',1);
        SELECT INTO rdueno *  FROM ca.persona NATURAL JOIN ca.empleado WHERE idpersona = laclave;
        textoadicional = rdueno.emlegajo;
        elcuit =  replace(replace(replace(rdueno.penrocuil,'/',''),'-',''),' ','');
        elnrodoc = elcuit;
        eltipodoc= 12 ;
        razonsocial = concat(concat(rdueno.penombre,' '), rdueno.peapellido) ;
       -- RAISE NOTICE 'nrodoc=(%) and tipodoc = (%);',elnrodoc,eltipodoc;
     END IF;

     SELECT INTO infocuenta * FROM cuentas WHERE nrodoc=elnrodoc and tipodoc = eltipodoc;
     IF infocuenta.nrobanco = '191' THEN -- es una cuenta del banco credicoop
     /*
     fila = respuesta.getString("tipocuenta")+
              rellenar(respuesta.getString("nrobanco"), 3)+
              rellenar(respuesta.getString("nrosucursal"), 3)+
              rellenar(respuesta.getString("nrocuenta"), 7)
	    	+respuesta.getString("digitoverificador")
			+rellenar(aux1, 15)
		    +this.rellenarConBlancos(unaOrden.get("razonsocial").toString(), 40)
			+respuesta.getString("nrocuit")
			+this.rellenarConBlancos(unaOrden.get("emlegajo").toString(), 10)+
            this.rellenarConBlancos("Generado Automaticamente", 60);
				
     */
          lineatxt ='C'||infocuenta.tipocuenta ::character varying
                     || rpad(infocuenta.nrobanco::character varying,3,'0')
                     || lpad(infocuenta.nrosucursal::character varying,3,'0')
                     || lpad(infocuenta.nrocuenta::character varying,7,'0')
                     ||infocuenta.digitoverificador::character varying
                     || lpad(importe,15,'0')
                     || rpad(razonsocial,40,' ')
                     || elcuit
                     || rpad(textoadicional,10,' ')
                     || rpad('Generado Automaticamente SIGES',60,' ');
     ELSE -- NO  es una cuenta del banco credicoop
     /*
	fila = rellenar(respuesta.getString("cbuini"),8)+
									rellenar(respuesta.getString("cbufin"),14)+
									rellenar(aux1, 10)+
                                    nrocuit+
                                    rellenarConBlancos("",11)+
									rellenarConBlancos(prestador, 40)+
                                    rellenar(emlegajo,9)+" "
									+rellenarConBlancos("Archivo generado por SIGES", 60)+"VAR";
							ListaTXT.add(fila);
     */
        lineatxt ='O'|| rpad(infocuenta.cbuini,8,'0')
                     || rpad(infocuenta.cbufin,14,'0')
                  ||  lpad(importe,10,'0')
                     ||  elcuit
                     ||  rpad('',11)
                     || rpad(razonsocial,40,' ')
                     || lpad(textoadicional,9,'0')
                     || rpad(' Generado Automaticamente SIGES',60,' ')
                     || ' VAR' ;

     END IF;




return  lineatxt;
END;
$function$
