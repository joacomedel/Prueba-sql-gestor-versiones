CREATE OR REPLACE FUNCTION public.afiliarpensionado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	rafiliado RECORD;
	rpersona RECORD;
	cargo2 CURSOR FOR SELECT * FROM cargos2;
	rcargo RECORD;
	encontro  boolean;
    resultado boolean;
    existetbarras RECORD;
    contador integer;
    siguiente integer;
        respuesta varchar;
BEGIN

SELECT INTO rafiliado * FROM afil;
if NOT FOUND
  then
      return 'false';
  else
    encontro = 'false';
    SELECT INTO rpersona * FROM afilpen WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;
    if NOT FOUND then
    	OPEN cargo2;
    	FETCH cargo2 into rcargo;
    	WHILE  found LOOP
    	if (rcargo.tipo = 36)  then
    	   SELECT INTO siguiente CASE WHEN nullvalue(MAX(idcertpers)) then 0
                                     ELSE MAX(idcertpers)
                                END
                                FROM certpersonal;
		        siguiente=siguiente+1;
                         delete from benefsosunc where  nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;
			   /* UPDATE benefsosunc SET idestado = 4 WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;*/
			    INSERT INTO certpersonal (idcertpers,cantaport,idcateg) VALUES(rafiliado.nrodoc::bigint,rcargo.cantaport,rcargo.categoria);
				INSERT INTO afilpen (nrodoc,nrodoctitu,trabaja,tipodoc,tipodoctitu,ingreso,idcert)
                            VALUES(rafiliado.nrodoc,rcargo.nrotitu,rcargo.trabaja,rafiliado.tipodoc,rcargo.tipodoctitu,rcargo.ingreso,rafiliado.nrodoc::BigInt);
                    INSERT INTO aporteconfiguracion(idcentroaporteconfiguracion,nrodoc,tipodoc,acporcentaje,acimportebruto,acimporteaporte,acfechafin,acfechainicio,descripcion)
VALUES(centro(),rafiliado.nrodoc,rafiliado.tipodoc,rcargo.acporcentaje,rcargo.acimportebruto,rcargo.acimporteaporte,null,now()::date,rcargo.descripcion);
			    encontro = 'true';
	   	end if;
    	fetch cargo2 into rcargo;
    	END LOOP;
    	CLOSE cargo2;
       else
		OPEN cargo2;
    	FETCH cargo2 into rcargo;
    	WHILE  found LOOP
    	 if (rcargo.tipo = 36)
	  	  then
		    UPDATE afilpen SET nrodoctitu = rcargo.nrotitu, trabaja = rcargo.trabaja, tipodoctitu = rcargo.tipodoctitu, ingreso = rcargo.ingreso WHERE tipodoc = rafiliado.tipodoc AND nrodoc = rafiliado.nrodoc;
   	  	    UPDATE certpersonal SET cantaport = rcargo.cantaport, idcateg=rcargo.categoria WHERE idcertpers = rcargo.idcert;
                   UPDATE aporteconfiguracion SET acfechafin =(now()::date) WHERE nrodoc = rafiliado.nrodoc and tipodoc =rafiliado.tipodoc and  nullvalue(acfechafin)  ;


                 INSERT INTO
aporteconfiguracion(idcentroaporteconfiguracion,nrodoc,tipodoc,acporcentaje,acimportebruto,acimporteaporte,acfechafin,acfechainicio,descripcion)
VALUES(centro(),rafiliado.nrodoc,rafiliado.tipodoc,rcargo.acporcentaje,rcargo.acimportebruto,rcargo.acimporteaporte,null,now()::date,rcargo.descripcion);
-- 25-02-22 llamo al SP que da de alta en clientectacte, luego esto se usa para las novedades
                SELECT INTO respuesta  FROM sys_abmctactecliente(concat('{nrocliente =' , rafiliado.nrodoc, ',barra =',rafiliado.tipodoc,' , cccdtohaberes = ',false,' , idestadotipo = ',8,', idformapagoctacte= ', NULL,' }'));

		    encontro = 'true';
	   	 end if;
    	fetch cargo2 into rcargo;
    	END LOOP;
    	CLOSE cargo2;
    end if;
    if encontro
       then
          SELECT INTO resultado * FROM incorporarbarra(36,rafiliado.nrodoc,rafiliado.tipodoc);
	   else
	      resultado = 'false';
    end if;
     SELECT INTO existetbarras * FROM tbarras WHERE nrodoctitu = rafiliado.nrodoc AND tipodoctitu = rafiliado.tipodoc;
    if NOT FOUND
        then
		  INSERT INTO tbarras VALUES (rafiliado.nrodoc,rafiliado.tipodoc,2);
		  resultado = 'true';
    end if;
    return resultado;
end if;
END;
$function$
