CREATE OR REPLACE FUNCTION public.ingresardesignaciones()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	alta CURSOR FOR SELECT mesingreso,anioingreso,dependencia,nrolegajo,nrocargo,categoria,codcaracteristica,unidadacademica,fechaalta,CASE WHEN nullvalue(fechabaja) THEN to_date(concat('31/01/', date_part('year', current_date+365)), 'DD/MM/YYYY') ELSE fechabaja END as fechabaja
    FROM dh49
    WHERE dh49.mesingreso >= date_part('month', current_date -30)
	AND dh49.anioingreso >= date_part('year', current_date - 30)
	--AND nrolegajo =102344
      ORDER BY nrolegajo,fechabaja ASC;
	elem RECORD;
	per RECORD;
	aux RECORD;
	verif RECORD;
	resultado BOOLEAN;
	fechafin DATE;
	
BEGIN

/*ALTER TABLE cargo disable trigger aicargo;
ALTER TABLE cargo disable trigger amcargo;
ALTER TABLE persona disable trigger aipersona;
ALTER TABLE persona disable trigger ampersona;*/
--08/04/2015 Malapi, limpio los datos de las designaciones
DELETE FROM tdesignaciones;

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
/*01/04/2006 M.L.P Se modifica para que verifique la existencia del afiliado, si no existe se informa.
                   Tambien se actualizan todos los campos de la designacion al realizar un Update*/
/*23/04/2006 M.L.P Se modifica para que se actualice la fechafinos al ingresar las designaciones*/
/*05/03/2009 M.L.P Se modifica para que no busque por nrodoc sino que por legajo */
/*05/03/2009 M.L.P Se modifica para tomar directamente de la tabla dh49 en lugar de la temporal cargada por java*/
/*18/05/2009 M.L.P Se modifica para que si existe el cargo, se actualice la informacion de la designacion*/
    --SELECT INTO per * FROM afilsosunc where afilsosunc.nrodoc = elem.nrodoc /*AND afilsosunc.tipodoc = elem.tipodoc*/;
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
	      --UPDATE tdesignaciones SET tipoinforme = 'No existe Dependencia Universitaria' WHERE tdesignaciones.idcargo = elem.idcargo;
       ELSE
           /*Verifico que exista la categoria*/
           SELECT INTO verif * FROM categoria where categoria.idcateg = elem.categoria;
	        IF NOT FOUND THEN
	               INSERT INTO tdesignaciones (idcargo,fechainilab,fechafinlab,idcateg,iddepen,tipodoc,nrodoc,legajosiu,tipoinforme,tipodesig)
                   VALUES(elem.nrocargo,elem.fechaalta,elem.fechabaja,elem.categoria,elem.unidadacademica,per.tipodoc,per.nrodoc,elem.nrolegajo,'No existe categoria',elem.codcaracteristica);
	
	               --UPDATE tdesignaciones SET tipoinforme = 'No existe categoria' WHERE tdesignaciones.idcargo = elem.idcargo;
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
                          -- La idea que los que no existen quedan en la tabla para ser reportados.
                  /*Actualizo la fechafinos en persona, como estan ordenasdas en forma decreciente, la ultima que se inserta es la que tiene la fechafinlab
                  que determina la fechadinos y el estado valido*/
                  /*06-03-2009 MaLaPi lo saco de aca para ponerlo en la carga de aportes*/
                  --fechafin = elem.fechabaja + INTEGER '90';
                  --UPDATE persona SET fechafinos = fechafin WHERE nrodoc = per.nrodoc and tipodoc = per.tipodoc;
                  --DELETE FROM tdesignaciones WHERE tdesignaciones.idcargo = elem.idcargo;
            END IF;
       END IF;
    END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;

--MaLaPi 09-11-2015 Se dan de baja todos los cargos que no son de SOS que no se informaron en el DH49.

UPDATE cargo SET fechafinlab = CURRENT_DATE -1
WHERE fechafinlab >= current_date and (idcargo) not in (select  idcargo from licsinhab where fechafinlic>=CURRENT_DATE)


 AND (idcargo,legajosiu) IN (
  select idcargo,legajosiu 
  FROM cargo  
   where cargo.fechafinlab>=CURRENT_DATE AND iddepen <> 'SOS'
  AND (idcargo,legajosiu) NOT IN (
     SELECT nrocargo,nrolegajo 
     FROM dh49 
     WHERE dh49.mesingreso >= date_part('month', current_date -30)
	AND dh49.anioingreso >= date_part('year', current_date - 30)
    ) 
);




return 'true';

/*ALTER TABLE cargo enable trigger aicargo;
ALTER TABLE cargo enable trigger amcargo;
ALTER TABLE persona enable trigger aipersona;
ALTER TABLE persona enable trigger ampersona;*/

END;
$function$
