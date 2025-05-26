CREATE OR REPLACE FUNCTION public.generarreintegroautomatico(idplancoberturaaux integer, idano integer, idmes integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   
    cursorplanes refcursor;

     rplancobpersona RECORD;

    rregistroaux RECORD;

 cursorreintegroex refcursor;


      salida  boolean;
      tempo  boolean;
      idcomprobantet integer=0; 
      idtiporecepciont integer =0;
      nombret VARCHAR='';
      apellidot VARCHAR='';
      localidadt  VARCHAR='';
      idcorreot  integer=0;

      idrecepciont integer=0; 

      nrodoct varchar;
      tipodoct integer=0;
      barrat integer;

      aux RECORD;
      rcuentas RECORD;

      rbeneficiario RECORD;

     reintegroexiste RECORD;

BEGIN
  salida='false';
   tempo='false';
 /*
 idplancoberturaAux=19;
idmes=01;*/



         OPEN cursorreintegroex for select * from plancobpersona natural join persona   join reintegro on(persona.nrodoc=reintegro.nrodoc       and persona.tipodoc=reintegro.tipodoc) join reintegroprestacion on(reintegro.nroreintegro=reintegroprestacion.nroreintegro)  where idplancobertura=19 and tipoprestacion =27 and date_part('year',rfechaingreso) =idano and date_part('month',rfechaingreso) =idmes;


FETCH cursorreintegroex into rregistroaux;

 if (nullvalue(rregistroaux.nrodoc)) then

          /* Por cada plan de cobertura activo o donde la fecha fin del plan es null */
            OPEN cursorplanes for SELECT * FROM plancobpersona natural join persona  WHERE  idplancobertura= idplancoberturaAux and ((pcpfechafin >  NOW())  or ( pcpfechafin is null  ));
                       -- OPEN cursorplanes for SELECT * FROM plancobpersona natural join persona  WHERE  persona.nrodoc ='06161100' and idplancobertura= idplancoberturaAux and ((pcpfechafin >  NOW())  or ( pcpfechafin is null  ));
         
          select  into localidadt  crdescripcion from centro() join  centroregional on   centro=centroregional.idcentroregional ;
          
--natural join direccion natural join localidad

    FETCH cursorplanes into rplancobpersona;

    WHILE  found LOOP
     
      /* Ingresar datos recepcion     */

           /* dar alta comprobante */ 

            	 INSERT INTO comprobante(fechahora) VALUES (now());

                 SELECT INTO idcomprobantet MAX(idcomprobante) FROM comprobante;


            /* datos recepcion */

              

		 idtiporecepciont= 5;
		nombret=rplancobpersona.nombres;
		apellidot=rplancobpersona.apellido;
		
		 idcorreot=0; 		
        
		
                INSERT INTO recepcion(idcomprobante,idtiporecepcion,fecha,nombre,apellido,idcorreo) 
               VALUES (idcomprobantet,idtiporecepciont,NOW(),nombret,apellidot,idcorreot);

              SELECT INTO idrecepciont MAX(idrecepcion) FROM recepcion;




		

            /*   recreintegro */


          INSERT INTO recreintegro(idrecepcion,nrodoc,barra,localidad,nombreaf,apellidoaf,idcentroreintegro)
          VALUES       (idrecepciont,rplancobpersona.nrodoc,rplancobpersona.barra,localidadt,nombret,apellidot,centro());


  
      /*     tipo reintegro */

      INSERT INTO reintegroestudio(idestudio,idrecepcion,cantidad) 
       VALUES (27,idrecepciont,1);

  /*      sp insetarreintegro3 */
              nrodoct= rplancobpersona.nrodoc;
              barrat = rplancobpersona.barra;
              tipodoct= rplancobpersona.tipodoc;
            SELECT into tempo  * from insertarreintegro3(idrecepciont,2,nrodoct,barrat);


        
   /* actualizacion de estado de reintegro a liquidable  */


 SELECT INTO aux * FROM reintegro where reintegro.idrecepcion = idrecepciont and reintegro.idcentrorecepcion = centro() and reintegro.anio=date_part('year', NOW());

      if (nullvalue(aux.rimporte)) then

      if (rplancobpersona.barra>=1 and rplancobpersona.barra<30) then

         SELECT INTO rbeneficiario * FROM benefsosunc  WHERE benefsosunc.nrodoc = nrodoct AND benefsosunc.tipodoc =    tipodoct;
         
       /* busco si la persona tiene  nro de cuenta ya insertado*/
         SELECT INTO rcuentas * FROM cuentas  WHERE rbeneficiario.nrodoc = cuentas.nrodoc AND rbeneficiario.tipodoc =    cuentas.tipodoc; 
          IF not  FOUND then    /* si no tiene insertada nro de cuenta */
                  SELECT INTO rcuentas * FROM cuentas  WHERE rbeneficiario.nrodoctitu = cuentas.nrodoc AND rbeneficiario.tipodoctitu =    cuentas.tipodoc;
                       IF   FOUND then
                            INSERT INTO cuentas(nrodoc,tipodoc,nrocuenta,tipocuenta,digitoverificador,nrobanco,nrosucursal)    VALUES 
                                (nrodoct,tipodoct,rcuentas.nrocuenta,rcuentas.tipocuenta,rcuentas.digitoverificador,rcuentas.nrobanco,rcuentas.nrosucursal);

 UPDATE reintegro SET nrocuenta = rcuentas.nrocuenta, tipocuenta=rcuentas.tipocuenta WHERE reintegro.idrecepcion = idrecepciont and reintegro.idcentrorecepcion = centro() and reintegro.anio=date_part('year', NOW());
                       end if;
           
           end if;
           
    --   UPDATE reintegro SET nrocuenta = rcuentas.nrocuenta, tipocuenta=rcuentas.tipocuenta WHERE reintegro.idrecepcion = idrecepciont and reintegro.idcentrorecepcion = centro() and reintegro.anio=date_part('year', NOW());

      end if;

         UPDATE reintegro SET rimporte = 1000 WHERE reintegro.idrecepcion = idrecepciont and reintegro.idcentrorecepcion = centro() and reintegro.anio=date_part('year', NOW());

        UPDATE reintegroprestacion SET importe = 1000 WHERE reintegroprestacion.nroreintegro = aux.nroreintegro and reintegroprestacion.idcentroregional = centro() and reintegroprestacion.tipoprestacion=27 and reintegroprestacion.anio=date_part('year', NOW());
 


      end if;

 
            UPDATE restados SET fechacambio = NOW() WHERE nroreintegro=aux.nroreintegro and tipoestadoreintegro=1 and idcentroregional=aux.idcentroregional and anio=date_part('year', NOW());

            INSERT INTO restados
                 (fechacambio,nroreintegro,tipoestadoreintegro,anio,observacion,idcentroregional)
                 VALUES(NOW(),aux.nroreintegro,2,date_part('year', NOW()),'Generados Automaticamente',aux.idcentroregional);

   


          salida='true';
    fetch cursorplanes into rplancobpersona;
   END LOOP;

CLOSE cursorplanes;


end if;

CLOSE cursorreintegroex;

return salida;   

END;
$function$
