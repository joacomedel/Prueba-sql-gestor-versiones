CREATE OR REPLACE FUNCTION public.actualizarctacte(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*actualiza el campo cta cte, determinando si le corresponde o no tener cta cte para el expendio de ordenes
o solo para reciprocidado pago de aportes
*/
DECLARE
    tipodocumento alias for $2;
    nrodocumento alias for $1;
    per RECORD;
    rcargo RECORD;
    fechafin DATE;
    fechafinactivo DATE;
    raux RECORD;

--RECORD
   rmontodisponible RECORD;
BEGIN
        SELECT INTO rcargo * FROM cargo NATURAL JOIN categoriactacte 
                                                  WHERE nrodoc = nrodocumento
                                                  AND tipodoc = tipodocumento
                                                  AND cargo.fechafinlab >= CURRENT_DATE;
         IF FOUND THEN
           /*Les corresponde tener cuenta corriente por su categoria.*/
                  UPDATE afilsosunc SET ctacteexpendio = TRUE
                  WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento;
           ELSE
                  UPDATE afilsosunc SET ctacteexpendio = FALSE
                  WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento;
         END IF;
      
         /*Todos tienen cta cte para reciprocidad y pago de aportes*/
/*select to_char(to_number(nrodocumento,'99999999')*10 + tipodocumento,'000000000') modificar para cuando podamos poner el campo idctacte como varchar*/
        UPDATE afilsosunc SET idctacte = to_number(nrodoc,'99999999')*10 + tipodoc WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento AND nullvalue(idctacte);
       /*Ma.La.Pi 11-06-2013 Modifico para verificar que si tiene ctacte expendio no tiene que estar en la tabla de ctacteexentos */
       SELECT INTO raux * FROM afilsosunc WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento AND ctacteexpendio = TRUE;
       IF FOUND THEN
              SELECT INTO raux * FROM ctacteexentos WHERE nullvalue(ccefechafin) AND nrodoc = nrodocumento AND tipodoc = tipodocumento;
              IF FOUND THEN
                UPDATE afilsosunc SET ctacteexpendio = FALSE
                       WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento AND ctacteexpendio = TRUE;
              END IF;
       END IF;

--KR 20-03-19 Si tiene cuenta corriente pero ya consumio lo permitido, se le deshabilita la cta cte SINO se le habilita. Esto se informa en el DH 357
       
       SELECT INTO rmontodisponible * FROM ctasctesmontosdescuento 
                                WHERE nrodoc  =nrodocumento  AND ccmdvigenciainicio<=current_date 
and current_date<= ccmdvigenciafin;
     
       IF FOUND THEN
            UPDATE afilsosunc SET ctacteexpendio = ((rmontodisponible.ccmdimporte - rmontodisponible.ccmdmontoconsumido)>0)
                       WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento ;
       END IF;

return TRUE;
end;
$function$
