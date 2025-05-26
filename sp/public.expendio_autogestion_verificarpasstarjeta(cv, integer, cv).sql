CREATE OR REPLACE FUNCTION public.expendio_autogestion_verificarpasstarjeta(character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
    datotarjeta RECORD;
    datotarjetalogin RECORD;
    infoctacte  RECORD;
    resp boolean;
    eltipodoc integer;
    elnrodoc varchar;
    elcodigo  varchar;
    eltexto  varchar;
    cambiarpass Boolean;
    bloqueada Boolean;
    


BEGIN
     elnrodoc = $1;
     eltipodoc = $2;
     elcodigo = $3;
     resp = false;
     -- creo la tabla temporal
     CREATE TEMP TABLE infotarjetalogin( idcentrotarjeta INTEGER ,tlcambiarpass BOOLEAN
       ,idtarjeta bigint, tlbloqueada boolean,passcorrecta boolean DEFAULT false
      , texto varchar,nrodoc varchar,tipodoc integer);


     -- Si la persona no tiene cta cte no se continua el analisis
     --Malapi 15-04-2016 Ya no importa si la persona tiene o no Cta.CTe. Se puede pagar por Caja
     --IF expendio_tiene_ctacte_sosunc(elnrodoc,eltipodoc) THEN
              -- busco la tarjeta activa para la persona
              SELECT into datotarjeta *
              FROM  tarjeta
              NATURAL JOIN tarjetaestado
              WHERE tipodoc = eltipodoc and  nrodoc=elnrodoc -- q se corresponda con la persona
                    and nullvalue(tefechafin) and idestadotipo = 3 ; -- que la tarjeta este activa
               -- Si tiene una tarjeta activa la retorno para posterior verificacion
               IF  found THEN
                   SELECT INTO datotarjetalogin *
                   FROM tarjetalogin
                   WHERE idtarjeta = datotarjeta.idtarjeta and idcentrotarjeta = datotarjeta.idcentrotarjeta;
                   -- si  encuentra los datos del login se verifica la pass ingresada
                   IF found  THEN 
                   	IF (datotarjetalogin.tlbloqueada) THEN -- Verifico si la tarjeta esta bloqueada
		            eltexto =  'La seguridad de su credencial fue comprometida. \n Se requiere su presencia en la Obra Social';
                            bloqueada = true;
                        ELSE 
                        --- Verifico si la tarjeta NO esta bloqueada y que la pass coincidan
                             IF(datotarjetalogin.tlcodigo = md5(elcodigo)) THEN
                                --Verifico si se tiene que cambiar la contraseña
                                  cambiarpass = datotarjetalogin.tlcambiarpass;
				  IF (datotarjetalogin.tlcambiarpass) THEN 
					eltexto =  'Se debe cambiar el codigo de acceso.';
				  END IF;
                                  resp = true;
				  
			     ELSE
                                eltexto =  'Contraseña invalida. Vuelva a intentarlo.';
                                
                             END IF;

			END IF; -- End -- Verifico si la tarjeta esta bloqueada
		   ELSE -- No tiene definido el codigo de acceso 
			eltexto =  'No se le asigno un codigo de acceso. \n Comuniquese con la OSU.';
                   END IF;

                   INSERT INTO infotarjetalogin(nrodoc,tipodoc, idcentrotarjeta  ,tlcambiarpass  ,idtarjeta , passcorrecta,tlbloqueada,texto)
                   VALUES (elnrodoc,eltipodoc,datotarjeta.idcentrotarjeta  ,cambiarpass ,datotarjeta.idtarjeta, resp ,bloqueada,eltexto) ; 		
                   ELSE --
			INSERT INTO infotarjetalogin(nrodoc,tipodoc,texto)
                   VALUES (elnrodoc,eltipodoc, 'No cuenta con una credencial habilitada. \n Consulte con la mesa de entrada \n de la OSU para realizar el trámite.') ; 		

		END IF;
         --ELSE
         --    INSERT INTO infotarjetalogin(nrodoc,tipodoc,texto)
         --          VALUES (elnrodoc,eltipodoc, 'No tiene habilitada la cta cte. \n Consulte con la mesa de entrada \n de la OSU para realizar el trámite.') ; 		


         --END IF;

RETURN resp;
END;
$function$
