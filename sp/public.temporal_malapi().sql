CREATE OR REPLACE FUNCTION public.temporal_malapi()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
    cractacte refcursor;
    cursorpagoctacte refcursor;

--RECORD
    rractacte RECORD;
    rusuario RECORD;
    regctactepago RECORD;
    rpagoctacte  RECORD;

--VARIABLES
    nrorecibo bigint;
    resp boolean;
    elidorigen bigint;
    ridpago bigint;
    an_integer bigint;

BEGIN


    -- Raise a debug level message.
an_integer = 0;
   RAISE DEBUG 'The raise_test() function began.';
an_integer = an_integer + 1;
    RAISE NOTICE 'Variable an_integer was changed. 1 ';
    RAISE NOTICE 'Variable an_integer value is 2  now %.',an_integer;
    RAISE NOTICE 'Variable an_integer was changed. 3 ';
    RAISE NOTICE 'Variable an_integer was changed. 4 ';


--  RAISE EXCEPTION ''Variable % changed.  Aborting transaction.'',an_integer;


RETURN TRUE;


END;
    $function$
