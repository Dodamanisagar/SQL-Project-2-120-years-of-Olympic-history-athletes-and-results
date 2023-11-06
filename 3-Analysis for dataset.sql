-- STEP-1: Creating tables to import data
-- 1) OLYMPICS_HISTORY table:
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY
(
	ID		INT,
	NAME	VARCHAR,
	SEX		VARCHAR,
	AGE		VARCHAR,
	HEIGHT 	VARCHAR,
	WEIGHT  VARCHAR,
	TEAM	VARCHAR,
	NOC		VARCHAR,
	GAMES	VARCHAR,
	YEAR 	INT,
	SEASON	VARCHAR,
	CITY	VARCHAR,
	SPORT 	VARCHAR,
	EVENT	VARCHAR,
	MEDAL	VARCHAR
);

-- 2) NOC_REGIONS table:
CREATE TABLE IF NOT EXISTS NOC_REGIONS
(
	NOC		VARCHAR,
	REGION 	VARCHAR,
	NOTES	VARCHAR
);

-- STEP-2: Import data from csv files

-- STEP-3: Check data is imported correctly or not
SELECT * FROM OLYMPICS_HISTORY;
SELECT * FROM NOC_REGIONS;

-- Total number of rows in OLYMPICS_HISTORY table:
SELECT COUNT(1) FROM OLYMPICS_HISTORY;

-- Total number of rows in NOC_REGIONS table:
SELECT COUNT(1) FROM NOC_REGIONS;

-- Questions-
-- 1) How many olympics games have been held?
-- Expected output: single number having total count
SELECT COUNT(DISTINCT GAMES) FROM OLYMPICS_HISTORY;
 
 
-- 2) List down all Olympics games held so far.
-- Expected output: year,season,city
SELECT DISTINCT YEAR,SEASON,CITY
FROM OLYMPICS_HISTORY
ORDER BY 1;


-- 3) Mention the total no of nations who participated in each olympics game?
-- Expected output:- games, total number of countries
WITH ALL_COUNTRIES AS
        (
			SELECT GAMES, NR.REGION
         	FROM OLYMPICS_HISTORY OH
        	JOIN NOC_REGIONS NR USING(NOC)
        	GROUP BY GAMES, NR.REGION
		)
    SELECT GAMES, COUNT(1) AS TOTAL_COUNTRIES
    FROM ALL_COUNTRIES
    GROUP BY GAMES
    ORDER BY GAMES;

-- 4) Which year saw the highest and lowest no of countries participating in olympics?
WITH ALL_COUNTRIES AS
              (
				  SELECT GAMES, NR.REGION
              	  FROM OLYMPICS_HISTORY OH
              	  JOIN NOC_REGIONS NR USING(NOC)
                  GROUP BY GAMES, NR.REGION
			  ),
          TOT_COUNTRIES AS
              (
				  SELECT GAMES, COUNT(1) AS TOTAL_COUNTRIES
              	  FROM ALL_COUNTRIES
                  GROUP BY GAMES
			  )
      SELECT DISTINCT
      CONCAT(FIRST_VALUE(GAMES) OVER(ORDER BY TOTAL_COUNTRIES)
      , ' - '
      , FIRST_VALUE(TOTAL_COUNTRIES) OVER(ORDER BY TOTAL_COUNTRIES)) AS LOWEST_COUNTRIES,
      CONCAT(FIRST_VALUE(GAMES) OVER(ORDER BY TOTAL_COUNTRIES DESC)
      , ' - '
      , FIRST_VALUE(TOTAL_COUNTRIES) OVER(ORDER BY TOTAL_COUNTRIES DESC)) AS HIGHEST_COUNTRIES
      FROM TOT_COUNTRIES
      ORDER BY 1;

-- 5) Which nation has participated in all of the olympic games?
 WITH TOT_GAMES AS
              (
				  SELECT COUNT(DISTINCT GAMES) AS TOTAL_GAMES
              	  FROM OLYMPICS_HISTORY
			  ),
          COUNTRIES AS
              (
				  SELECT GAMES, NR.REGION AS COUNTRY
               	  FROM OLYMPICS_HISTORY OH
                  JOIN NOC_REGIONS NR USING(NOC)
                  GROUP BY GAMES, NR.REGION
			  ),
          COUNTRIES_PARTICIPATED AS
              (
				  SELECT COUNTRY, COUNT(1) AS TOTAL_PARTICIPATED_GAMES
                  FROM COUNTRIES
                  GROUP BY COUNTRY
			  )
      SELECT CP.*
      FROM COUNTRIES_PARTICIPATED CP
      JOIN TOT_GAMES TG ON TG.TOTAL_GAMES = CP.TOTAL_PARTICIPATED_GAMES
      ORDER BY 1;
	  
-- 6) Identify the sport which was played in all summer olympics.
 WITH TABLE1 AS
          	(SELECT COUNT(DISTINCT GAMES) AS TOTAL_GAMES
          	FROM OLYMPICS_HISTORY WHERE SEASON = 'summer'),
          TABLE2 AS
          	(SELECT DISTINCT GAMES, SPORT
          	FROM OLYMPICS_HISTORY WHERE SEASON = 'summer'),
          TABLE3 AS
          	(SELECT SPORT, COUNT(1) AS NO_OF_GAMES
          	FROM TABLE2
          	GROUP BY SPORT)
      SELECT *
      FROM TABLE3
      JOIN TABLE1 ON TABLE1.TOTAL_GAMES = TABLE3.NO_OF_GAMES;
	  
-- 7) Which Sports were just played only once in the olympics?
 WITH T1 AS
          	(SELECT DISTINCT GAMES, SPORT
          	FROM OLYMPICS_HISTORY),
          T2 AS
          	(SELECT SPORT, COUNT(1) AS NO_OF_GAMES
          	FROM T1
          	GROUP BY SPORT)
      SELECT T2.*, T1.GAMES
      FROM T2
      JOIN T1 USING(SPORT)
      WHERE T2.NO_OF_GAMES = 1
      ORDER BY T1.SPORT;


-- 8) Fetch the total no of sports played in each olympic games.
WITH T1 AS(
			SELECT DISTINCT GAMES, SPORT
    		FROM OLYMPICS_HISTORY),
     T2 AS(
		 	SELECT GAMES, COUNT(1) AS NO_OF_SPORTS
      		FROM T1
      		GROUP BY GAMES)
      SELECT * FROM T2
      ORDER BY NO_OF_SPORTS DESC;

-- 9) Fetch details of the oldest athletes to win a gold medal.
 WITH TEMP AS
            (SELECT NAME,SEX,CAST(CASE WHEN AGE = 'NA' THEN '0' ELSE AGE END AS INT) AS AGE
              ,TEAM,GAMES,CITY,SPORT, EVENT, MEDAL
            FROM OLYMPICS_HISTORY),
        RANKING AS
            (SELECT *, RANK() OVER(ORDER BY AGE DESC) AS RNK
            FROM TEMP
            WHERE MEDAL='Gold')
    SELECT *
    FROM RANKING
    WHERE RNK = 1;


-- 10) Find the Ratio of male and female athletes participated in all olympic games.
 WITH T1 AS
        	(SELECT SEX, COUNT(1) AS CNT
        	FROM OLYMPICS_HISTORY
        	GROUP BY SEX),
        T2 AS
        	(SELECT *, ROW_NUMBER() OVER(ORDER BY CNT) AS RN
        	 FROM T1),
        MIN_CNT AS
        	(SELECT CNT FROM T2	WHERE RN = 1),
        MAX_CNT AS
        	(SELECT CNT FROM T2	WHERE RN = 2)
    SELECT CONCAT('1 : ', ROUND(MAX_CNT.CNT::DECIMAL/MIN_CNT.CNT, 2)) AS RATIO
    FROM MIN_CNT, MAX_CNT;


-- 11) Fetch the top 5 athletes who have won the most gold medals.
 WITH T1 AS
            (SELECT NAME, TEAM, COUNT(1) AS TOTAL_GOLD_MEDALS
            FROM OLYMPICS_HISTORY
            WHERE MEDAL = 'Gold'
            GROUP BY NAME, TEAM
            ORDER BY TOTAL_GOLD_MEDALS DESC),
        T2 AS
            (SELECT *, DENSE_RANK() OVER (ORDER BY TOTAL_GOLD_MEDALS DESC) AS RNK
            FROM T1)
    SELECT NAME, TEAM, TOTAL_GOLD_MEDALS
    FROM T2
    WHERE RNK <= 5;


-- 12) Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
WITH T1 AS
            (SELECT NAME, TEAM, COUNT(1) AS TOTAL_MEDALS
            FROM OLYMPICS_HISTORY
            WHERE MEDAL IN ('Gold', 'Silver', 'Bronze')
            GROUP BY NAME, TEAM
            ORDER BY TOTAL_MEDALS DESC),
        T2 AS
            (SELECT *, DENSE_RANK() OVER (ORDER BY TOTAL_MEDALS DESC) AS RNK
            FROM T1)
    SELECT NAME, TEAM, TOTAL_MEDALS
    FROM T2
    WHERE RNK <= 5;

-- 13) Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
  WITH T1 AS
            (SELECT NR.REGION, COUNT(1) AS TOTAL_MEDALS
            FROM OLYMPICS_HISTORY OH
            JOIN NOC_REGIONS NR ON NR.NOC = OH.NOC
            WHERE MEDAL <> 'NA'
            GROUP BY NR.REGION
            ORDER BY TOTAL_MEDALS DESC),
        T2 AS
            (SELECT *, DENSE_RANK() OVER(ORDER BY TOTAL_MEDALS DESC) AS RNK
            FROM T1)
    SELECT *
    FROM T2
    WHERE RNK <= 5;

-- 14) In which Sport/event, India has won highest medals.
 WITH T1 AS
        	(SELECT SPORT, COUNT(1) AS TOTAL_MEDALS
        	FROM OLYMPICS_HISTORY
        	WHERE MEDAL <> 'NA'
        	AND TEAM = 'India'
        	GROUP BY SPORT
        	ORDER BY TOTAL_MEDALS DESC),
        T2 AS
        	(SELECT *, RANK() OVER(ORDER BY TOTAL_MEDALS DESC) AS RNK
        	FROM T1)
    SELECT SPORT, TOTAL_MEDALS
    FROM T2
    WHERE RNK = 1;


-- 15) Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
SELECT TEAM, SPORT, GAMES, COUNT(1) AS TOTAL_MEDALS
    FROM OLYMPICS_HISTORY
    WHERE MEDAL <> 'NA'
    AND TEAM = 'India' AND SPORT = 'Hockey'
    GROUP BY TEAM, SPORT, GAMES
    ORDER BY TOTAL_MEDALS DESC;
