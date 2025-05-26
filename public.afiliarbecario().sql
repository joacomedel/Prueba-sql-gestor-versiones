CREATE OR REPLACE FUNCTION public.afiliarbecario()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	afiliado RECORD;
	persona RECORD;
	cargo1 CURSOR FOR SELECT * FROM cargos1;
	encontro boolean;
	resultado boolean;
	cargo RECORD;
	existetbarras RECORD;
	contador integer;
	siguiente integer;
BEGIN

SELECT INTO afiliado * FROM afil;
if NOT FOUND
  then
      return 'false';
  else
    encontro = 'false';
    SELECT INTO persona * FROM afilibec WHERE nrodoc = afiliado.nrodoc AND tipodoc = afiliado.tipodoc;
    if NOT FOUND
       then
        OPEN cargo1;
        FETCH cargo1 INTO cargo;
        WHILE  found LOOP
	      	if (cargo.tipo = 34)
	    		then
	    		SELECT INTO persona * FROM resolbec WHERE idresolbe = cargo.idresol;
	     	      if NOT FOUND
	              	then
	              	   SELECT INTO contador count(*) FROM resolbec;
                       if contador > 0
                          then
                           siguiente = 0;
				           SELECT INTO siguiente MAX(idresolbe)+1 FROM resolbec;
	 		    	       INSERT INTO resolbec (idresolbe,fechainilab,fechafinlab,idcateg,iddepen) VALUES(siguiente,cargo.fechaini,cargo.fechafin,cargo.categoria,cargo.depuniv);
	 		    	       INSERT INTO afilibec VALUES(afiliado.nrodoc,siguiente,afiliado.tipodoc);
	      			       encontro = 'true';
	 		    	      else 
	 		    	       INSERT INTO resolbec (idresolbe,fechainilab,fechafinlab,idcateg,iddepen) VALUES(1,cargo.fechaini,cargo.fechafin,cargo.categoria,cargo.depuniv);
	 		    	       INSERT INTO afilibec VALUES(afiliado.nrodoc,1,afiliado.tipodoc);
	      			       encontro = 'true';
	 		    	      
		    	       end if;
		            else
		    	       UPDATE resolbec SET  fechainilab = cargo.fechaini, fechafinlab = cargo.fechafin, idcateg = cargo.categoria, iddepen = cargo.depuniv WHERE idresolbe = cargo.idresol;
		    	       INSERT INTO afilibec VALUES(afiliado.nrodoc,cargo.idresol,afiliado.tipodoc);
	      			   encontro = 'true';  
	              end if;
	  		end if;
	  	fetch cargo1 into cargo;
        END LOOP;
        CLOSE cargo1;
     else
        OPEN cargo1;
        FETCH cargo1 INTO cargo;
        WHILE  found LOOP
	 		 if (cargo.tipo = 34)
	    		then
	    		SELECT INTO persona * FROM resolbec WHERE idresolbe = cargo.idresol;
	     	      if NOT FOUND
	              	then
	              	   SELECT INTO contador count(*) FROM resolbec;
                       if contador > 0
                          then
                           siguiente = 0;
				           SELECT INTO siguiente MAX(idresolbe)+1 FROM resolbec;
	 		    	       INSERT INTO resolbec (idresolbe,fechainilab,fechafinlab,idcateg,iddepen) VALUES(siguiente,cargo.fechaini,cargo.fechafin,cargo.categoria,cargo.depuniv);
       	     	           UPDATE afilibec SET idresolbe = siguiente WHERE tipodoc = afiliado.tipodoc AND nrodoc = afiliado.nrodoc;
	     			       encontro = 'true';
	 		    	      else 
	 		    	       INSERT INTO resolbec (idresolbe,fechainilab,fechafinlab,idcateg,iddepen) VALUES(1,cargo.fechaini,cargo.fechafin,cargo.categoria,cargo.depuniv);
       	     	 	       UPDATE afilibec SET idresolbe = 1 WHERE tipodoc = afiliado.tipodoc AND nrodoc = afiliado.nrodoc;
	     			       encontro = 'true';
		    	       end if;
		            else
		    	       UPDATE resolbec SET  fechainilab = cargo.fechaini, fechafinlab = cargo.fechafin, idcateg = cargo.categoria, iddepen = cargo.depuniv WHERE idresolbe = cargo.idresol;
       	     		   UPDATE afilibec SET idresolbe = cargo.idresol WHERE tipodoc = afiliado.tipodoc AND nrodoc = afiliado.nrodoc;
	     			   encontro = 'true';
	              end if;	    		
	  		 end if;
	  	fetch cargo1 into cargo;
        END LOOP;
        CLOSE cargo1;
    end if;
    if encontro
       then
          SELECT INTO resultado * FROM incorporarbarra(34,afiliado.nrodoc,afiliado.tipodoc);
	   else
	      resultado = 'false';
    end if;
     SELECT INTO existetbarras * FROM tbarras WHERE nrodoctitu = afiliado.nrodoc AND tipodoctitu = afiliado.tipodoc;
    if NOT FOUND
        then
		  INSERT INTO tbarras VALUES (afiliado.nrodoc,afiliado.tipodoc,2);
		  resultado = 'true';
    end if;
    return resultado;
end if;
END;
$function$
