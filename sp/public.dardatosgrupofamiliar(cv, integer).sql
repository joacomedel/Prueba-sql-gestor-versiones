CREATE OR REPLACE FUNCTION public.dardatosgrupofamiliar(character varying, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE


DECLARE
dgfliar VARCHAR;
BEGIN


SELECT INTO dgfliar text_concatenar(nrodocb) FROM(

(SELECT  concat('',text_concatenar(concat(' ','nrodoc =','''',benefsosunc.nrodoc,''''))) as nrodocb
FROM benefsosunc LEFT JOIN (
SELECT DISTINCT nrodoctitu, tipodoctitu
FROM benefsosunc  
WHERE nrodoc= $1 OR nrodoctitu= $1) as bs USING (nrodoctitu, tipodoctitu)
WHERE benefsosunc.nrodoctitu=bs.nrodoctitu  )

UNION


(SELECT concat(' nrodoc =','''',afs.nrodoc,'''') as nrodocb
FROM afilsosunc AS afs LEFT JOIN benefsosunc AS bs ON(afs.nrodoc = bs.nrodoctitu AND afs.tipodoc=bs.tipodoctitu)
WHERE afs.nrodoc= $1 OR bs.nrodoc= $1
order by barra LIMIT 1)
UNION

SELECT  concat('',text_concatenar(concat(' ','nrodoc =','''',benefreci.nrodoc,''''))) as nrodocb
FROM benefreci LEFT JOIN (
SELECT DISTINCT nrodoctitu, tipodoctitu
FROM benefreci  
WHERE nrodoc=  $1 OR nrodoctitu=  $1  ) as bs USING (nrodoctitu, tipodoctitu)
WHERE benefreci.nrodoctitu=bs.nrodoctitu AND benefreci.fechavtoreci>=CURRENT_DATE
UNION
(SELECT concat('nrodoc =','''',afs.nrodoc,'''') as nrodocb
FROM afilreci AS afs
NATURAL JOIN persona
LEFT JOIN benefreci AS bs ON(afs.nrodoc = bs.nrodoctitu AND afs.tipodoc=bs.tipodoctitu)

WHERE afs.nrodoc= $1 OR bs.nrodoc= $1 AND barra > 100  AND afs.fechavtoreci>=CURRENT_DATE
LIMIT 1
)

order by nrodocb DESC) AS T;

dgfliar = REPLACE(dgfliar, 'nrodoc =', ' OR nrodoc =' );


--IF dgfliar ilike ' OR%' THEN
  dgfliar = regexp_replace(dgfliar, 'OR', ' ');
  if (length(trim(dgfliar))=0 )THEN
          dgfliar=' true ' ;
   END IF;


--END IF;
RETURN dgfliar;

END;$function$
