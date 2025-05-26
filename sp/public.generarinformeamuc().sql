CREATE OR REPLACE FUNCTION public.generarinformeamuc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
elinforme refcursor;

--REGISTRO
uninfo record;


--VARIABLES
idnroinforme INTEGER;
idcentroinforme INTEGER;
BEGIN

  SELECT INTO uninfo nroinforme, idcentroinformeamuc, fechamodificacion ,informeamucestadostipos.descripcion, crdescripcion  
             FROM informeamuc NATURAL JOIN informeamucestados NATURAL JOIN informeamucestadostipos  
             LEFT JOIN centroregional ON idcentroinformeamuc = idcentroregional 
             WHERE idestado = 1 and nullvalue(fechafin) ORDER BY informeamuc.nroinforme ;
   IF FOUND THEN
        idnroinforme = uninfo.nroinforme;
        idcentroinforme = uninfo.idcentroinformeamuc;
   ELSE
        INSERT INTO informeamuc(fechamodificacion,idcentroinformeamuc) VALUES (CURRENT_DATE,centro());
          --(*) Recupero el id de informeamuc
          idnroinforme =  currval('informeamuc_nroinforme_seq');
          idcentroinforme = centro();
        INSERT INTO informeamucestados (nroinforme,idcentroinformeamuc,idestado) values (idnroinforme,centro(),1);

   END IF; 
  


INSERT INTO ordenesconsultaauditadas(nroorden,centro,nrodoc,tipodoc, idprestador,fechauso,importe,fechaauditoria,nroinforme,idcentroinformeamuc) 
SELECT OU.nroorden, OU.centro, OU.nrodocuso, OU.tipodocuso, OU.idprestador, OU.fechauso, OU.importe, OU.fechaauditoria,idnroinforme, idcentroinforme
FROM orden NATURAL JOIN consumo NATURAL JOIN 
( SELECT nrodoc, tipodoc, TT.mutu 
  FROM afilsosunc LEFT JOIN (SELECT nrodoc, tipodoc, mutu FROM afiliauto 
				UNION SELECT nrodoc, tipodoc, mutu FROM afilidoc 
				UNION SELECT nrodoc, tipodoc, mutu FROM afilinodoc 
				UNION SELECT nrodoc, tipodoc, mutu FROM afilirecurprop 
				UNION SELECT nrodoc, tipodoc, mutu FROM afilisos) AS TT USING(nrodoc,tipodoc)	
  WHERE mutu
) AS AA
JOIN ordenesutilizadas as OU USING(nroorden, centro,tipo)
JOIN ( SELECT nrodoc, tipodoc, mutual
  FROM benefsosunc 
  WHERE not mutual
) AS TT 
ON(OU.nrodocuso=TT.nrodoc AND OU.tipodocuso=TT.tipodoc)
LEFT JOIN ordenesconsultaauditadas as oca  USING(nroorden, centro)
WHERE orden.tipo=4 AND nullvalue(oca.nroorden);


   return true;
END;

$function$
