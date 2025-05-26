CREATE OR REPLACE FUNCTION public.setearctacteparatodos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*actualiza el campo cta cte, determinando si le corresponde o no tener cta cte para el expendio de ordenes
o solo para reciprocidado pago de aportes
*/
DECLARE
    alta CURSOR FOR SELECT * FROM afilsosunc;
    per RECORD;
    elem RECORD;
    rcargo RECORD;
    fechafin DATE;
    fechafinactivo DATE;
BEGIN
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP

        SELECT INTO per * FROM persona WHERE nrodoc = elem.nrodoc  AND tipodoc = elem.tipodoc;
        IF FOUND THEN
        IF per.barra = 31 OR per.barra = 32 OR per.barra = 37 THEN
           /*Les corresponde tener cuenta corriente para expendio sin importar los cargos que tengan.*/
           UPDATE afilsosunc SET ctacteexpendio = TRUE WHERE nrodoc = elem.nrodoc  AND tipodoc = elem.tipodoc;
        ELSE
            /*Hay que verificar la categoria de sus cargos vigentes, para determinar si tiene ctacte para expendio*/
            SELECT INTO rcargo * FROM cargo WHERE nrodoc = elem.nrodoc  AND tipodoc = elem.tipodoc AND cargo.fechafinlab > CURRENT_DATE AND
                                              (idcateg = 'TITE' OR idcateg = 'CITE' OR idcateg = 'ASOE' OR idcateg = 'ADJH'
                                              OR idcateg = 'CSOE' OR idcateg = 'ADJE' OR idcateg = 'CDJE' OR idcateg = 'JTPE'
                                              OR idcateg = 'AY1E');
            IF FOUND THEN
               UPDATE afilsosunc SET ctacteexpendio = TRUE WHERE nrodoc = elem.nrodoc  AND tipodoc = elem.tipodoc;
            ELSE
            /*El resto no tienen cta cte para expendio*/
                UPDATE afilsosunc SET ctacteexpendio = FALSE WHERE nrodoc = elem.nrodoc  AND tipodoc = elem.tipodoc;
            END IF;
        END IF;
         /*Todos tienen cta cte para reciprocidad y pago de aportes*/
        UPDATE afilsosunc SET idctacte = to_number(nrodoc,'99999999')*10 + tipodoc WHERE nrodoc = elem.nrodoc  AND tipodoc = elem.tipodoc;
        END IF;

fetch alta into elem;
END LOOP;
CLOSE alta;

return TRUE;
end;
$function$
