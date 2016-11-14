drop MATERIALIZED VIEW client_vm;
drop MATERIALIZED VIEW produit_vm;
drop MATERIALIZED VIEW lieu_vm;
drop MATERIALIZED VIEW temps_vm;
drop MATERIALIZED VIEW vente_vm;

-- Vue client_vm
create materialized view client_vm
BUILD IMMEDIATE
as select distinct c.num as id, c.sexe,
case
  when trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) < 30 then '<30 ans'
  when trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) >= 30 and trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) <= 45 then '30-45 ans' 
  when trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) > 45 and trunc(((select max(f.date_etabli) from facture f where f.client = c.num) - c.date_nais) / 365.25) <= 60 then '46-60 ans'
  else '>60 ans'
end as tranche_age
from client c
join facture f on c.num = f.client;

--create materialized VIEW log on produit with rowid;

-- Vue produit_vm
create materialized view produit_vm
BUILD IMMEDIATE
REFRESH FAST
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

-- vue lieu_vm
create materialized view lieu_vm
as select SUBSTR(REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 3), 1, 2) as code_etat,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 3) as pays,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 2) as ville,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 1) as code_postal
from client;

-- vue Temps
create materialized view temps_vm
as select date_ as id,
to_number(to_char(date_, 'DDD')) as jour_annee,
to_number(to_char(date_, 'MM')) as mois,
to_number(to_char(date_, 'YYYY')) as annee,
to_number(to_char(date_, 'Q')) as trimestre,
to_number(to_char(date_, 'WW')) as semaine,
to_char(date_, 'DAY') as libelle
from
(select (level + date_minimum - 1) as date_
from
  (select 
  min(date_etabli) as date_minimum,
  max(date_etabli) as date_maximum
  from facture)
connect by level < (date_maximum - date_minimum + 2));

-- Vue vente
create materialized view vente_vm
as select distinct 
  c.id as id_client, 
  p.id as id_produit, 
  l.CODE_ETAT as id_lieu, 
  concat(to_char(t.jour_annee), concat(' ', to_char(t.annee))) as id_temps,
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