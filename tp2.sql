select max(trunc((f.date_etabli - c.date_nais) / 365.25)) from client c, facture f where c.num = 1;

-- Vue Client
create materialized view client_vm 
BUILD IMMEDIATE
as select c.num as id, c.sexe, SUBSTR(REGEXP_SUBSTR(c.adresse, '[^,]+', INSTR(c.adresse, ',', 1, 1) + 1, 3), 1, 2) as lieu,
case
  when trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) < 30 then '<30 ans'
  when trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) >= 30 and trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) <= 45 then '30-45 ans' 
  when trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) > 45 and trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) <= 60 then '46-60 ans'
  else '>60 ans'
end as tranche_age
from client c
join facture f on c.num = f.client;

-- Vue produit_vm
create materialized view produit_vm
BUILD IMMEDIATE
REFRESH FORCE
ON COMMIT
as select NUM as id, 
  REGEXP_SUBSTR(designation, '[^.]+', 1) as nom,
  REGEXP_SUBSTR(designation, '[^.]+', INSTR(designation, '.', 1, 1) + 1) as categorie,
  case
    when INSTR(designation, '.', 1, 2) > 0 then REGEXP_SUBSTR(designation, '[^.]+', INSTR(designation, '.', 1, 2) + 1) 
    else null
  end 
  as sous_categorie
from produit;

-- vue lieu
create materialized view lieu_vm
BUILD IMMEDIATE
REFRESH FORCE
ON COMMIT
as select SUBSTR(REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 3), 1, 2) as code_etat,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 3) as pays,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 2) as ville,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 1) as code_postal
from client;

--select (level + to_date('01-01-2015','DD-MM-YYYY') - 1) as datee
--from dual
--connect by level < (to_date('01-01-2016','DD-MM-YYYY') - to_date('01-01-2015','DD-MM-YYYY') + 2);

-- vue Temps
create materialized view temps_vm
BUILD IMMEDIATE
as select date_ as id,
to_number(to_char(date_, 'DDD')) as jour_annee,
to_number(to_char(date_, 'MM')) as mois,
to_number(to_char(date_, 'YYYY')) as annee,
to_number(to_char(date_, 'Q')) as trimestre,
to_number(to_char(date_, 'WW')) as semaine,
to_char(date_, 'DAY') as label
from
(select (level + date_minimum - 1) as date_
from
  (select 
  min(date_etabli) as date_minimum,
  max(date_etabli) as date_maximum
  from facture)
connect by level < (date_maximum - date_minimum + 2));

-- Vue vente
create materialized view ventes_vm
BUILD IMMEDIATE
as select distinct c.id as client, p.id as produit, l.CODE_ETAT as lieu, 
  f.date_etabli as temps,
  (lf.qte * (pud.prix * (1 - pud.remise / 100))) as prix_vente,
  lf.qte as quantite,
  pud.prix as prix_unitaire,
  pud.remise as remise,
  trunc((f.date_etabli - c2.date_nais) / 365.25) as age
from ligne_facture lf
join facture f on lf.facture = f.num
join temps_vm t on f.DATE_ETABLI = t.id
join client_vm c on f.client = c.id
join client c2 on f.client = c2.num
join lieu_vm l on c.lieu = l.code_etat
join produit_vm p on lf.produit = p.id
join prix_date pud on lf.id_prix = pud.num;

select * from facture;
select * from ligne_facture;
select * from prix_date;

commit;