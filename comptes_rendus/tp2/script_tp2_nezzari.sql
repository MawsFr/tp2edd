drop MATERIALIZED VIEW client_vm;
drop MATERIALIZED VIEW produit_vm;
drop MATERIALIZED VIEW lieu_vm;
drop MATERIALIZED VIEW temps_vm;
drop MATERIALIZED VIEW vente_vm;

-- Vue client_vm
create materialized view client_vm
REFRESH FORCE
ON DEMAND
Enable query rewrite 
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
REFRESH FORCE
ON DEMAND
Enable query rewrite 
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
REFRESH FORCE
ON DEMAND
Enable query rewrite 
as select SUBSTR(REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 3), 1, 2) as code_etat,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 3) as pays,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 2) as ville,
  REGEXP_SUBSTR(adresse, '[^,]+', INSTR(adresse, ',', 1, 1) + 1, 1) as code_postal
from client;

-- vue Temps
create materialized view temps_vm
REFRESH FORCE
ON DEMAND
Enable query rewrite 
as select concat(to_char(to_number(to_char(date_, 'DDD'))), concat('-', to_char(to_number(to_char(date_, 'YYYY'))))) as id,
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
REFRESH FORCE
ON DEMAND
Enable query rewrite 
as select distinct 
  c.id as id_client, 
  p.id as id_produit, 
  l.CODE_ETAT as id_lieu, 
  concat(to_char(t.jour_annee), concat('-', to_char(t.annee))) as id_temps,
  (lf.qte * (pud.prix * (1 - pud.remise / 100))) as prix_vente,
  lf.qte as quantite,
  pud.prix as prix_unitaire,
  pud.remise as remise,
  trunc((f.date_etabli - c2.date_nais) / 365.25) as age
from ligne_facture lf
join facture f on lf.facture = f.num
join temps_vm t on concat(to_char(to_number(to_char(f.DATE_ETABLI, 'DDD'))), concat('-', to_char(to_number(to_char(f.DATE_ETABLI, 'YYYY'))))) = t.id
join client_vm c on f.client = c.id
join client c2 on f.client = c2.num
join lieu_vm l on SUBSTR(REGEXP_SUBSTR(c2.adresse, '[^,]+', INSTR(c2.adresse, ',', 1, 1) + 1, 3), 1, 2) = l.code_etat
join produit_vm p on lf.produit = p.id
join prix_date pud on lf.id_prix = pud.num;

select * from facture;
select * from ligne_facture;
select * from prix_date;

exec INSERER_DONNEES;

execute dbms_mview.refresh('CLIENT_VM');
execute dbms_mview.refresh('LIEU_VM');
execute dbms_mview.refresh('PRODUIT_VM');
execute dbms_mview.refresh('VENTE_VM');
execute dbms_mview.refresh('TEMPS_VM');

create unique index client_vm_index on client_vm (id);
create bitmap index CLIENT_VM_INDEX_TRANCHE_AGE ON client_vm (tranche_age);
create bitmap index CLIENT_VM_INDEX_SEXE ON client_vm (sexe);
--create unique index produit_vm_index on produit_vm (id);
create index lieu_vm_index on lieu_vm (code_etat, ville, code_postal);
create unique index temps_vm_index on temps_vm (id);
create unique index vente_vm_index on vente_vm (id_produit, id_temps, id_lieu, id_client);

create dimension produit_dim
  level nom is (produit_vm.nom)
  level categorie is (produit_vm.categorie)
  level sous_categorie is (produit_vm.sous_categorie)
  
  hierarchy prod_rollup (
    nom 
    child of sous_categorie 
    child of categorie
  )
  ATTRIBUTE nom DETERMINES (PRODUIT_VM.NOM)
  attribute sous_categorie DETERMINES (PRODUIT_VM.SOUS_CATEGORIE)
  ATTRIBUTE categorie DETERMINES (PRODUIT_VM.CATEGORIE);

execute SYS.DBMS_DIMENSION.VALIDATE_DIMENSION('produit_dim', false, true, 'test dim prod');

select * from produit where rowid in (select bad_rowid from dimension_exceptions where statement_id = 'test dim prod');

set SERVEROUTPUT ON;

EXECUTE DBMS_DIMENSION.DESCRIBE_DIMENSION('produit_dim');

select * from produit_dim;

-- Requetes
-- 1
select p.id, p.nom, sum(v.prix_vente) as CA
from vente_vm v
join produit_vm p on v.id_produit = p.id
group by p.id, p.nom;

-- 2
select p.categorie, t.mois, sum(v.prix_vente) as CA
from vente_vm v
join produit_vm p on v.id_produit = p.id
join temps_vm t on v.id_temps = t.id
group by rollup (p.categorie, t.mois);

-- 3
select c.tranche_age, sum(v.prix_vente) as CA, rank() over (order by sum(v.prix_vente) DESC) as RANG
from vente_vm v
join client_vm c on v.ID_CLIENT = c.ID
group by c.tranche_age;

-- 4
select id, nom, CA 
from (
  select p.id, p.nom, sum(v.prix_vente) as CA, rank() over (order by sum(v.prix_vente) DESC) as RANG
  from vente_vm v
  join produit_vm p on v.id_produit = p.id
  group by p.id, p.nom
)
where rang between 1 and 3;

ROLLBACK;
commit;