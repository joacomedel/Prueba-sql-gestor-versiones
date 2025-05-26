CREATE OR REPLACE FUNCTION public.gestionarcuponafiliadov2(character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	 elcupon RECORD;
uncuponbenef RECORD;
	 resp boolean;
	 elnrodoc character varying;
     eltipodoc integer;
     elidestadotipo integer;
 cuponbenef refcursor;




BEGIN
     elnrodoc =$1;
     eltipodoc =$2;
     elidestadotipo= $3;
     resp = true;
     
     -- Busco la tarjeta del afiliado que se encuentra en circulacion (que no fue dada de baja idestadotipo <> 4; )
     SELECT into elcupon *
     FROM  cupon
     NATURAL JOIN  tarjeta
     NATURAL JOIN cuponestado
     NATURAL JOIN persona
     WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and nullvalue(cefechafin) and idestadotipo <> 4;

--     1    solicitado
--     2    CONFECCIONADO
--     3    ENTREGADO
--     4    De BAJA
 IF FOUND THEN
              IF (elidestadotipo = 1 )THEN
                 -- Se crea un nuevo cupon
                 SELECT INTO resp crearcupon(elcupon.idtarjeta,elcupon.idcentrotarjeta);
              END IF;
              IF (elidestadotipo = 2 or  elidestadotipo = 3 or elidestadotipo = 4) THEN
                SELECT INTO resp cambiarestadocupon(elcupon.idcupon , elcupon.idcentrocupon,elidestadotipo);
                     IF (elcupon.barra=35 and   elidestadotipo = 3) then
                        --creo el cupon del mes siguiente del jubilado
			select into resp crearcupon(elcupon.idtarjeta,elcupon.idcentrotarjeta);                          
                       --le creo los cupones a los beneficiarios del jubilado			
                         open cuponbenef for SELECT  * 
     					FROM   benefsosunc
					natural join persona natural join tarjeta natural join cupon
					natural join cuponestado
	     				WHERE 		benefsosunc.nrodoctitu=elnrodoc
							and benefsosunc.tipodoctitu=eltipodoc
							and nullvalue(cefechafin) and idestadotipo <> 4;

 				fetch cuponbenef into uncuponbenef;
   				 while FOUND loop
				        select into resp crearcupon(uncuponbenef.idtarjeta,uncuponbenef.idcentrotarjeta);
					fetch cuponbenef into uncuponbenef;
				 end loop;


                      
                      END IF;
              END IF;
     ELSE resp = false;
    END IF;





RETURN resp;
END;
$function$
