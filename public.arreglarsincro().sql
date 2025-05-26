CREATE OR REPLACE FUNCTION public.arreglarsincro()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
   aux record;
begin

CREATE temp TABLE tablasasincronizarcopia (
    nombre character varying(40) NOT NULL,
    orden integer,
    sincronizada boolean
);


--ALTER TABLE public.tablasasincronizarcopia OWNER TO postgres;

--
-- Data for Name: tablasasincronizarcopia; Type: TABLE DATA; Schema: public; Owner: postgres
--

insert into tablasasincronizarcopia select * from tablasasincronizar;

select into aux eliminartablasincronizable(nombre) from tablasasincronizarcopia;
select into aux agregarsincronizable(nombre) from tablasasincronizarcopia;
return true;
end;$function$
