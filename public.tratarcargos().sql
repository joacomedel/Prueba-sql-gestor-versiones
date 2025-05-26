CREATE OR REPLACE FUNCTION public.tratarcargos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	rafiliado RECORD;
	rpersona RECORD;
 	cargo1 CURSOR FOR SELECT * FROM cargos1;
	rcargo RECORD;
	ultimo integer;
	siguiente integer;
	resultado boolean;
        contador integer;
        relcargo RECORD;
BEGIN

SELECT INTO rafiliado * FROM afil;
if NOT FOUND
  then
      return 'false';
  else
    OPEN cargo1;
    FETCH cargo1 INTO rcargo;
    WHILE  found LOOP
	if (rcargo.tipo = 30) OR (rcargo.tipo = 31)OR (rcargo.tipo = 33) OR (rcargo.tipo = 37)
	  then
	    SELECT INTO rpersona * FROM cargo WHERE /*idcargo = rcargo.idcargo AND*/ nrodoc = rcargo.nrodoc AND tipodoc = rcargo.tipodoc;

---KR 06-09-22 Arreglo pq hay casos donde quieren usar el mismo cargo para otro dni, aviso que no se puede y por que. Eje cuando quisiero dar de alta a julieta j
	    IF NOT FOUND THEN
               SELECT INTO relcargo * FROM cargo WHERE  idcargo = rcargo.idcargo AND  nrodoc<> rcargo.nrodoc;
               IF FOUND THEN
                  RAISE EXCEPTION 'No es posible dar de alta ese cargo, existe para otro afiliado!!   (%)',relcargo; 
               ELSE 
		      INSERT INTO cargo (idcargo,fechainilab,fechafinlab,idcateg,iddepen,tipodoc,nrodoc,legajosiu)
              VALUES(rcargo.idcargo,rcargo.fechaini,rcargo.fechafin,rcargo.categoria,rcargo.depuniv,rcargo.tipodoc,rcargo.nrodoc,rafiliado.legajosiu);
               END IF;
	    else
		      UPDATE cargo SET fechainilab = rcargo.fechaini, fechafinlab = rcargo.fechafin, idcateg = rcargo.categoria, iddepen = rcargo.depuniv, legajosiu = rafiliado.legajosiu WHERE idcargo = rcargo.idcargo;
	    end if;
	  else
	    if (rcargo.tipo = 32)
	       then
		     SELECT INTO rpersona * FROM cargo WHERE idcargo = rcargo.idcargo;
	     	  if NOT FOUND
	            then
		    	 INSERT INTO cargo (idcargo,fechainilab,fechafinlab,idcateg,iddepen,tipodoc,nrodoc,legajosiu)
                 VALUES(rcargo.idcargo,rcargo.fechaini,rcargo.fechafin,rcargo.categoria,rcargo.depuniv,rcargo.tipodoc,rcargo.nrodoc,rafiliado.legajosiu);
		        else
		    	 UPDATE cargo SET fechainilab = rcargo.fechaini, fechafinlab = rcargo.fechafin, idcateg = rcargo.categoria, iddepen = rcargo.depuniv,legajosiu = rafiliado.legajosiu
                        WHERE idcargo = rcargo.idcargo;
	          end if;
		else
	  	 if (rcargo.tipo = 34)
		    then
		      return 'true';
		    else
		     return 'false';
		end if;
	    end if;
	end if;
	fetch cargo1 into rcargo;
    END LOOP;
    CLOSE cargo1;

    return 'true';
end if;
END;
$function$
