CREATE OR REPLACE FUNCTION public.modificarfechafinosconcargoyaporte()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	alta CURSOR FOR SELECT * FROM tcargaaporte
			ORDER BY tcargaaporte.nrodoc
                           ,tcargaaporte.tipodoc;
			
                          
	elem RECORD;
	aux RECORD;
	td record;
	numcargo integer;
	resol integer;
	fechafin date;
	resultado boolean;
	tdoc integer;
	barraEmp smallint;

	
BEGIN

resultado = true;
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
       Select INTO tdoc tiposdoc.tipodoc  from tiposdoc where descrip = elem.tipodoc;
       SELECT INTO aux * FROM persona WHERE persona.nrodoc = elem.nrodoc AND persona.tipodoc = tdoc;
       IF NOT FOUND THEN
               /*Si no esta la persona no se puede hacer nada*/
  	   ELSE
         /*Si esxite buscar su fecha de inicio y fin laboral*/
          barraEmp = aux.barra;
          IF elem.tipoemp = 'BECARIO' THEN
                  SELECT INTO aux MAX(resolbec.fechafinlab)
                         FROM resolbec natural join afilibec
                         WHERE afilibec.nrodoc = elem.nrodoc AND afilibec.tipodoc = tdoc; 	   		
                      IF NOT FOUND THEN
                         /*Si no existe el la resolucion no le podemos cambiar la fecha fin os segun la resolucion*/
                      ELSE /* IF NOT FOUND FROM resolbec*/
                           fechafin = aux.fechafinlab;
                      END IF; /* IF NOT FOUND FROM resolbec*/
          ELSE /* IF elem.tipoemp = 'BECARIO' THEN */
                     SELECT MAX(cargo.fechafinlab) as fechafinlab into aux
                     FROM cargo
                      WHERE cargo.nrodoc = elem.nrodoc
                       AND cargo.tipodoc = tdoc;
                   IF NOT FOUND THEN
                       /*Si no encontramos un cargo, nada se puede modificar teniendo en cuanta la fechaginlab*/
                   ELSE /*IF NOT FOUND FROM cargo*/
                        fechafin = aux.fechafinlab + INTEGER '90';
                   END IF;
          END IF; /* IF elem.tipoemp = 'BECARIO'*/
		IF (fechafin is not null) THEN
		UPDATE persona SET fechafinos = fechafin
			WHERE persona.nrodoc = elem.nrodoc
		AND persona.tipodoc = tdoc;	
		end if;

    END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;
return resultado;

END;
$function$
