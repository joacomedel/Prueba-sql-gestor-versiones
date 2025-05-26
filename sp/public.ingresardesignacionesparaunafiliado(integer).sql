CREATE OR REPLACE FUNCTION public.ingresardesignacionesparaunafiliado(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	alta CURSOR FOR SELECT mesingreso,anioingreso,dependencia,nrolegajo,nrocargo,categoria,codcaracteristica,unidadacademica,fechaalta,CASE WHEN nullvalue(fechabaja) THEN to_date(concat('31/01/' , date_part('year', current_date+365)), 'DD/MM/YYYY') ELSE fechabaja END as fechabaja
    FROM dh49
    WHERE nrolegajo =$1
    -- AND mesingreso = 1
    --AND anioingreso = 2014

   ORDER BY nrolegajo,fechabaja ASC;
	elem RECORD;
	per RECORD;
	aux RECORD;
	verif RECORD;
	resultado BOOLEAN;
	fechafin DATE;
	
BEGIN


OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
/*01/04/2006 M.L.P Se modifica para que verifique la existencia del afiliado, si no existe se informa.
                   Tambien se actualizan todos los campos de la designacion al realizar un Update*/
/*23/04/2006 M.L.P Se modifica para que se actualice la fechafinos al ingresar las designaciones*/
/*05/03/2009 M.L.P Se modifica para que no busque por nrodoc sino que por legajo */
/*05/03/2009 M.L.P Se modifica para tomar directamente de la tabla dh49 en lugar de la temporal cargada por java*/
/*18/05/2009 M.L.P Se modifica para que si existe el cargo, se actualice la informacion de la designacion*/
/*08/04/2010 M.L.P Se genera un nuevo sp para que cargue las designaciones del afiliado que aun no se hayan cargado*/
SELECT INTO per *
    FROM afilsosunc
    NATURAL JOIN (
         SELECT legajosiu,nrodoc,tipodoc FROM afilidoc
         UNION
         SELECT legajosiu,nrodoc,tipodoc FROM afilinodoc
         UNION
         SELECT legajosiu,nrodoc,tipodoc FROM afiliauto
         UNION
         SELECT legajosiu,nrodoc,tipodoc FROM afilirecurprop
          ) as t
 where legajosiu = elem.nrolegajo;
    IF NOT FOUND THEN
     /*Verifico que exista la persona*/
       INSERT INTO tdesignaciones (idcargo,fechainilab,fechafinlab,idcateg,iddepen,tipodoc,nrodoc,legajosiu,tipoinforme,tipodesig)
       VALUES(elem.nrocargo,elem.fechaalta,elem.fechabaja,elem.categoria,elem.unidadacademica,0,'',elem.nrolegajo,'No existe persona',elem.codcaracteristica);
       --UPDATE tdesignaciones SET tipoinforme = 'No existe persona' WHERE tdesignaciones.nrodoc = elem.nrodoc AND tdesignaciones.tipodoc = elem.tipodoc;
    ELSE
     /*Verifico que Exista la Dep Universitaria*/
	   SELECT INTO verif * FROM depuniversitaria where depuniversitaria.iddepen = elem.unidadacademica;
	   IF NOT FOUND THEN
    	  INSERT INTO tdesignaciones (idcargo,fechainilab,fechafinlab,idcateg,iddepen,tipodoc,nrodoc,legajosiu,tipoinforme,tipodesig)
          VALUES(elem.nrocargo,elem.fechaalta,elem.fechabaja,elem.categoria,elem.unidadacademica,per.tipodoc,per.nrodoc,elem.nrolegajo,'No existe Dependencia Universitaria',elem.codcaracteristica);
	    ELSE
           /*Verifico que exista la categoria*/
           SELECT INTO verif * FROM categoria where categoria.idcateg ilike elem.categoria;
	        IF NOT FOUND THEN
	               INSERT INTO tdesignaciones (idcargo,fechainilab,fechafinlab,idcateg,iddepen,tipodoc,nrodoc,legajosiu,tipoinforme,tipodesig)
                   VALUES(elem.nrocargo,elem.fechaalta,elem.fechabaja,elem.categoria,elem.unidadacademica,per.tipodoc,per.nrodoc,elem.nrolegajo,'No existe categoria',elem.codcaracteristica);
	
	            ELSE
	               DELETE FROM tdesignaciones WHERE idcargo = elem.nrocargo;
	              SELECT INTO aux * FROM cargo where idcargo = elem.nrocargo;
                  IF NOT FOUND THEN
 		       	      INSERT INTO cargo (idcargo,fechainilab,fechafinlab,idcateg,iddepen,tipodoc,nrodoc,legajosiu,tipodesig)
                            VALUES(elem.nrocargo,to_date(elem.fechaalta,'YYYY-MM-DD'),to_date(elem.fechabaja,'YYYY-MM-DD'),elem.categoria,elem.unidadacademica,per.tipodoc,per.nrodoc,elem.nrolegajo,elem.codcaracteristica);
                   ELSE
 	   	      	       UPDATE cargo SET fechainilab = elem.fechaalta,
                                        fechafinlab = elem.fechabaja,
                                        idcateg = elem.categoria,
                                        iddepen = elem.unidadacademica,
                                        tipodesig = elem.codcaracteristica
                                        WHERE idcargo = elem.nrocargo;
                   END IF;
               END IF;
       END IF;
    END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;
return 'true';

END;
$function$
