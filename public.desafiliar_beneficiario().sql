CREATE OR REPLACE FUNCTION public.desafiliar_beneficiario()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rbeneficiario record;
        rbeneficiarioborrado record;
        rbenefreciborrado record;
        barrapersona  record;
       
        resp boolean;
      

BEGIN



SELECT INTO rbeneficiario *  FROM tDeBeneficiarioSosunc;

SELECT INTO barrapersona *  from persona where nrodoc = rbeneficiario.nrodoc AND tipodoc= rbeneficiario.tipodoc ;
	


IF FOUND THEN 
		

           update persona set fechafinos=(CURRENT_DATE - INTERVAL '1 day')::date  
              WHERE nrodoc = rbeneficiario.nrodoc AND tipodoc= rbeneficiario.tipodoc;
     
           /*borrar al desafiliar un beneficiario.*/
/*Dani agrego el 21042022 para que tambien actualize de benefreci */
--KR 09-01-20 NO elimino mas a los beneficiarios. GA pidio seguir viendo la info pero que esten en estado pasivo. 
--	   delete from  benefsosunc WHERE nrodoc = rbeneficiario.nrodoc AND tipodoc= rbeneficiario.tipodoc;
  	   UPDATE benefsosunc SET estaactivo= FALSE WHERE nrodoc = rbeneficiario.nrodoc AND tipodoc= rbeneficiario.tipodoc;   
           UPDATE benefreci SET idestado=4, fechavtoreci=now()  WHERE nrodoc = rbeneficiario.nrodoc AND tipodoc= rbeneficiario.tipodoc;   
       
          /*ver si esta en tabla borrados si no insertar*/
            	if (barrapersona.barra<100) then 
                      SELECT INTO rbeneficiarioborrado *  from beneficiariosborrados where nrodoc = rbeneficiario.nrodoc AND tipodoc= rbeneficiario.tipodoc and
                      nrodoctitu = rbeneficiario.nrodoctitu AND tipodoctitu= rbeneficiario.tipodoctitu;
		   
		      IF not FOUND THEN 

                        insert into beneficiariosborrados(barramutu,nroosexterna,idosexterna,nrodoc,mutual,
                        nrodoctitu,nromututitu,idestado,tipodoc,tipodoctitu,idvin,barratitu)
                        values  (rbeneficiario.barramutu,rbeneficiario.nroosexterna,rbeneficiario.idosexterna,rbeneficiario.nrodoc,rbeneficiario.mutual,
                        rbeneficiario.nrodoctitu,rbeneficiario.nromututitu,rbeneficiario.idestado,rbeneficiario.tipodoc,rbeneficiario.tipodoctitu,
                        rbeneficiario.idvin,rbeneficiario.barratitu);
                       END IF;
               else /*barrapersona.barra>=100*/
                 SELECT INTO rbenefreciborrado *  from beneficiariosreciborrados where nrodoc = rbeneficiario.nrodoc AND tipodoc= rbeneficiario.tipodoc and
                      nrodoctitu = rbeneficiario.nrodoctitu AND tipodoctitu= rbeneficiario.tipodoctitu;
		   
		      IF not FOUND THEN 
--KR 06-07-22 DABA error pq tenia 2 veces el tipodoc en el insert
                        insert into beneficiariosreciborrados(idreci,nrodoctitu,tipodoctitu,nrodoc,tipodoc,idestado, idvin,barratitu,fechavtoreci)
                        values  (rbeneficiario.idosexterna::integer,rbeneficiario.nrodoctitu,rbeneficiario.tipodoctitu,rbeneficiario.nrodoc,rbeneficiario.tipodoc,rbeneficiario.idestado,rbeneficiario.idvin,rbeneficiario.barratitu,now());

  
                       END IF;
                END IF;/*barrapersona.barra>=100*/

 END IF;

return 'true';
END;$function$
