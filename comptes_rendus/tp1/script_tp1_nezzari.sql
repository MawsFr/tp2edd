-- EXERCICE 1

-- a
SELECT deptno,
       ename,
       sal,
       Rank()
         OVER (
           partition BY deptno
           ORDER BY sal DESC) AS "RANG"
FROM   emp
WHERE  deptno = 10 OR deptno = 30;

-- b
SELECT deptno,
       ename,
       sal,
       Dense_rank()
         OVER (
           partition BY deptno
           ORDER BY sal DESC) AS "RANG"
FROM   emp
WHERE  deptno = 10 
	OR deptno = 30;
  
-- c
SELECT DISTINCT deptno,
                sal,
                Dense_rank()
                  over (
                    PARTITION BY deptno
                    ORDER BY sal DESC) AS "RANG"
FROM   emp
WHERE  deptno = 10 
	OR deptno = 20
ORDER  BY deptno;
      
-- d
SELECT job, 
       SUM(sal) AS "TOT_SAL_JOB" 
FROM   emp 
GROUP  BY job;

SELECT DISTINCT job, 
                SUM(sal) 
                  over ( 
                    PARTITION BY job) AS "TOT_SAL_JOB" 
FROM   emp;

SELECT DISTINCT job, 
                (SELECT SUM(sal) 
                 FROM   emp E2 
                 WHERE  E1.job = E2.job) AS "TOT_SAL_JOB" 
FROM   emp E1;
-- e
-- Le partition by est execute apres que le select soit fait

-- f
SELECT deptno, 
       job, 
       SUM(sal) 
FROM   emp 
GROUP  BY rollup ( deptno, job );

-- g
SELECT Nvl(To_char(deptno), 'TousDep')   AS DEPARTEMENT, 
       Nvl(To_char(job), 'TousEmployes') AS JOB, 
       SUM(sal) 
FROM   emp 
GROUP  BY rollup ( deptno, job ) 
ORDER  BY deptno, 
          SUM(sal) DESC;

-- Tous departement et job confondu => La somme totale tout en bas
-- Par departement => rollup avec la somme par departement tout les null apres chaque fin de departement
-- Par departement et job c'est les sommes a droit de chaque ligne de job

SELECT Decode(deptno, NULL, 'TousDep', deptno) AS DEPARTEMENT, 
       Decode(job, NULL, 'TousEmployes', job)  AS JOB, 
       SUM(sal) 
FROM   emp 
GROUP  BY rollup ( deptno, job ) 
ORDER  BY deptno, 
          SUM(sal) DESC;

-- EXERCICE 2
-- 1
SELECT annee,
       cl_r,
       category,
       Avg(qte * pu) AS CA_MOYEN
FROM   ventes
       join clients
         ON clients.cl_id = ventes.cid
       join produits
         ON ventes.pid = produits.pid
       join temps
         ON ventes.tid = temps.tid
WHERE  annee = 2009
    OR annee = 2010
GROUP  BY rollup ( annee, cl_r, category );


-- 2
SELECT annee, 
       cl_r, 
       category, 
       Avg(qte * pu) AS CA_MOYEN 
FROM   ventes 
       join clients 
         ON clients.cl_id = ventes.cid 
       join produits 
         ON ventes.pid = produits.pid 
       join temps 
         ON ventes.tid = temps.tid 
WHERE  annee = 2009 
        OR annee = 2010 
GROUP  BY cube ( annee, cl_r, category );


-- 3
SELECT annee, 
       category, 
       pname 
FROM   (SELECT t.annee, 
               p.category, 
               p.pname, 
               Rank() 
                 over ( 
                   PARTITION BY t.annee, p.category 
                   ORDER BY SUM(qte*pu) DESC) RANG 
        FROM   ventes v 
               join produits p 
                 ON v.pid = p.pid 
               join temps t 
                 ON v.tid = t.tid 
        GROUP  BY t.annee, 
                  p.category, 
                  p.pname) 
WHERE  rang = 1;


-- 4
SELECT t.annee, 
       p.category, 
       SUM(v.qte * v.pu) AS CA_TOTAL 
FROM   ventes v 
       join produits p 
         ON v.pid = p.pid 
       join temps t 
         ON v.tid = t.tid 
GROUP  BY rollup ( t.annee, p.category ) 
HAVING Grouping_id(t.annee, p.category) != 3 
ORDER  BY t.annee, 
          ca_total DESC;

-- 5
SELECT annee, 
       mois, 
       ca_total 
FROM   (SELECT t.annee, 
               t.mois, 
               p.pname, 
               SUM(qte * pu)                  AS CA_TOTAL, 
               Rank() 
                 over ( 
                   PARTITION BY t.annee 
                   ORDER BY SUM(qte*pu) DESC) AS RANG 
        FROM   ventes v 
               join produits p 
                 ON v.pid = p.pid 
               join temps t 
                 ON v.tid = t.tid 
        WHERE  p.pname LIKE 'Sirop d érable' 
        GROUP  BY t.annee, 
                  t.mois, 
                  p.pname 
        ORDER  BY t.annee, 
                  t.mois) 
WHERE  rang = 1;


-- 6
SELECT t.annee, 
       c.cl_name, 
       p.category, 
       SUM(qte * pu) AS CA_TOTAL 
FROM   ventes v 
       join clients c 
         ON c.cl_id = v.cid 
       join produits p 
         ON v.pid = p.pid 
       join temps t 
         ON v.tid = t.tid 
GROUP  BY grouping sets ( ( t.annee, c.cl_name ), ( t.annee, p.category ) );


-- 7
SELECT p.category,
       SUM(qte)                    AS QTE_VENDU_2010, 
       Ntile(3) 
         over ( 
           ORDER BY SUM(qte) DESC) AS TIERS 
FROM   ventes v 
       join produits p 
         ON v.pid = p.pid 
       join temps t 
         ON v.tid = t.tid 
WHERE  t.annee = 2010 
GROUP  BY p.category;


-- 8
SELECT category, 
       mois, 
       Min(tid)       AS JOUR1, 
       Max(tid)       AS JOUR5, 
       SUM(qte_jours) AS QTE_5_JOURS 
FROM   (SELECT p.category, 
               SUM(qte)             AS QTE_JOURS, 
               t.mois, 
               t.jour, 
               t.tid, 
               Dense_rank() 
                 over ( 
                   PARTITION BY p.category, t.mois 
                   ORDER BY t.jour) AS RANG 
        FROM   ventes v 
               join produits p 
                 ON v.pid = p.pid 
               join temps t 
                 ON v.tid = t.tid 
        WHERE  t.annee = 2010 
        GROUP  BY t.mois, 
                  p.category, 
                  t.jour, 
                  t.tid)
WHERE  rang BETWEEN 1 AND 5 
GROUP  BY category, 
          mois 
HAVING Count(rang) = 5 
ORDER  BY category, 
          mois;
