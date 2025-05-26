CREATE OR REPLACE FUNCTION public.actualizarmasivoafilrecihistorico()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
		afillista refcursor;
                benefrecilista refcursor;

  
	elem RECORD;
        elembenef RECORD;
	pers RECORD;
	resultado boolean;
BEGIN
resultado=false;
RAISE NOTICE 'entro a masivo'; 
OPEN afillista FOR SELECT * FROM afilreci;

        FETCH afillista INTO elem;
		WHILE  found LOOP
                   RAISE NOTICE 'entro a masivo %',elem.nrodoc; 
                           
		   UPDATE cambioestafilreci SET fechafin = '2012-09-01' WHERE tipodoc = elem.tipodoc AND nrodoc = elem.nrodoc  AND fechafin = '9999-12-31';
		     
                   INSERT INTO cambioestafilreci(tipodoc,nrodoc,idestado,fechaini,fechafin) VALUES(elem.tipodoc,elem.nrodoc,elem.idestado,'2012-09-01', '9999-12-31');

                    resultado=true;
     
                    OPEN benefrecilista FOR SELECT * FROM benefreci where nrodoctitu=elem.nrodoc and tipodoctitu=elem.tipodoc;

                     FETCH benefrecilista INTO elembenef;
		     WHILE  found LOOP
   
                          UPDATE benefreci SET idestado = elem.idestado WHERE tipodoc = elembenef.tipodoc AND nrodoc = elembenef.nrodoc;

                          UPDATE cambioestbenefreci SET fechafin = '2012-09-01' WHERE tipodoc = elembenef.tipodoc AND nrodoc = elembenef.nrodoc  AND fechafin = '9999-12-31';
		     
                           INSERT INTO cambioestbenefreci(tipodoc,nrodoc,idestado,fechaini,fechafin) VALUES(elembenef.tipodoc,elembenef.nrodoc,elem.idestado,'2012-09-01','9999-12-31');

                      fetch benefrecilista into elembenef;
		      END LOOP;
	              CLOSE benefrecilista;

     
 fetch afillista into elem;
		END LOOP;
	CLOSE afillista;

return resultado;
End;$function$
