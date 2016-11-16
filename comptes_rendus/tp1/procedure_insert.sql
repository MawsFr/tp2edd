	create or replace procedure inserer_donnees as

	num_client1 client.num%type;
  num_client2 client.num%type;
  num_client3 client.num%type;
  num_client4 client.num%type;
  
  num_produit1 produit.num%type;
  num_produit2 produit.num%type;
  num_produit3 produit.num%type;
  num_produit4 produit.num%type;
  
	num_facture1 facture.num%type;
  num_facture2 facture.num%type;
  num_facture3 facture.num%type;
  num_facture4 facture.num%type;
  
  date_facture1 facture.date_etabli%type;
  date_facture2 facture.date_etabli%type;
  date_facture3 facture.date_etabli%type;
  date_facture4 facture.date_etabli%type;
  
  prix1_1 prix_date.num%type;
  prix1_3 prix_date.num%type;
  prix2_2 prix_date.num%type;
  prix2_4 prix_date.num%type;
  prix3_1 prix_date.num%type;
  prix3_2 prix_date.num%type;
  prix4_3 prix_date.num%type;
  prix4_4 prix_date.num%type;
  
	begin
    num_client1 := client_seq.nextval;
    num_client2 := client_seq.nextval;
    num_client3 := client_seq.nextval;
    num_client4 := client_seq.nextval;
    
    num_produit1 := produit_seq.nextval;
    num_produit2 := produit_seq.nextval;
    num_produit3 := produit_seq.nextval;
    num_produit4 := produit_seq.nextval;
    
    num_facture1 := facture_seq.nextval;
    num_facture2 := facture_seq.nextval;
    num_facture3 := facture_seq.nextval;
    num_facture4 := facture_seq.nextval;
    
    date_facture1 := TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2453372,2453372+3*364)),'J');
    date_facture2 := TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2453372,2453372+3*364)),'J');
    date_facture3 := TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2453372,2453372+3*364)),'J');
    date_facture4 := TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2453372,2453372+3*364)),'J');
    
    prix1_1 := prix_seq.nextval;
    prix1_3 := prix_seq.nextval;
    prix2_2 := prix_seq.nextval;
    prix2_4 := prix_seq.nextval;
    prix3_1 := prix_seq.nextval;
    prix3_2 := prix_seq.nextval;
    prix4_3 := prix_seq.nextval;
    prix4_4 := prix_seq.nextval;
    
    INSERT INTO CLIENT VALUES(num_client1,'Balquet','Marie','107 rue du general bonnaud,59200,Tourcoing,France',	TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2433283,2433283+40*364)),'J')	,'femme');
    INSERT INTO CLIENT VALUES(num_client2,'Nezzari','Mustapha','46 rue du capitaine Guynemer,59200,Tourcoing,France',	TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2433283,2433283+40*364)),'J')	,'homme');
    INSERT INTO CLIENT VALUES(num_client3,'Merkel','Angela','Chancellerie federale,12209,Berlin,Allemagne',	TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2433283,2433283+40*364)),'J')	,'femme');
    INSERT INTO CLIENT VALUES(num_client4,'Poutine','Vladimir','78 rue du albator,789555,Tokyo,Japon',	TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2433283,2433283+40*364)),'J')	,'homme');
    
    INSERT INTO PRODUIT VALUES(num_produit1,'CocaCola.Boissons.Soda',			1024	);
    INSERT INTO PRODUIT VALUES(num_produit2,'Panzani.Pâtes et céréales.Pâtes',			2048	);
    INSERT INTO PRODUIT VALUES(num_produit3,'Côte d or.Dessert.Chocolat',			256	);
    INSERT INTO PRODUIT VALUES(num_produit4,'Pringles Piment.Dessert',			512	);
    
    INSERT INTO FACTURE VALUES(num_facture1,	num_client1	,	date_facture1	);
    INSERT INTO FACTURE VALUES(num_facture2,	num_client2	,	date_facture2	);
    INSERT INTO FACTURE VALUES(num_facture3,	num_client3	,	date_facture3	);
    INSERT INTO FACTURE VALUES(num_facture4,	num_client4	,	date_facture4	);
    
    INSERT INTO prix_date VALUES(prix1_1,	num_produit1,	date_facture1,	12	,	0	);
    INSERT INTO prix_date VALUES(prix1_3,	num_produit1,	date_facture3,	2	,	0	);
    INSERT INTO prix_date VALUES(prix2_2,	num_produit2,	date_facture2,	4	,	0	);
    INSERT INTO prix_date VALUES(prix2_4,	num_produit2,	date_facture4,	77	,	0	);
    INSERT INTO prix_date VALUES(prix3_1,	num_produit3,	date_facture1,	45	,	0	);
    INSERT INTO prix_date VALUES(prix3_2,	num_produit3,	date_facture2,	8	,	0	);
    INSERT INTO prix_date VALUES(prix4_3,	num_produit4,	date_facture3,	32	,	0	);
    INSERT INTO prix_date VALUES(prix4_4,	num_produit4,	date_facture4,	1	,	0	);
            
    
    INSERT INTO LiGNE_FACTURE VALUES(	num_facture1	,	num_produit1	,	3	,	prix1_1	);
    INSERT INTO LiGNE_FACTURE VALUES(	num_facture1	,	num_produit3	,	4	,	prix1_3	);
    INSERT INTO LiGNE_FACTURE VALUES(	num_facture2	,	num_produit2	,	6	,	prix2_2	);
    INSERT INTO LiGNE_FACTURE VALUES(	num_facture2	,	num_produit4	,	9	,	prix2_4	);
    INSERT INTO LiGNE_FACTURE VALUES(	num_facture3	,	num_produit1	,	6	,	prix3_1	);
    INSERT INTO LiGNE_FACTURE VALUES(	num_facture3	,	num_produit2	,	4	,	prix3_2	);
    INSERT INTO LiGNE_FACTURE VALUES(	num_facture4	,	num_produit3	,	12	,	prix4_3	);
    INSERT INTO LiGNE_FACTURE VALUES(	num_facture4	,	num_produit4	,	2	,	prix4_4	);

end inserer_donnees;