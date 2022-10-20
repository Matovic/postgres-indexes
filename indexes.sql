-- 1.
EXPLAIN ANALYSE
SELECT username FROM authors WHERE username='mfa_russia';

-- 2. 
-- pozrieme parametre
SHOW max_parallel_workers_per_gather;

SHOW max_worker_processes;
SHOW max_parallel_workers;

-- zmenime nastavenia parametra
SET max_parallel_workers_per_gather = 4;
SET max_parallel_workers_per_gather = 8;

-- 3.
--DROP INDEX idx_authors_username;
CREATE INDEX idx_authors_username ON authors USING BTREE(username);

-- 4.
-- podmienka 1
EXPLAIN ANALYSE
SELECT username FROM authors 
WHERE 
	followers_count >= 100 AND 
	followers_count <= 200;
	
-- podmienka 2
EXPLAIN ANALYSE
SELECT username FROM authors 
WHERE 
	followers_count >= 100 AND 
	followers_count <= 120;

-- parameter parallel_tuple_cost može za nepoužitie paralelizácie pri podmienke 1
SHOW parallel_tuple_cost;

SET parallel_tuple_cost = 0;

SET parallel_tuple_cost = 0.1;

-- 5.
CREATE INDEX idx_authors_followers_count ON authors USING BTREE(followers_count);

-- 6.
CREATE INDEX idx_authors_name_insert ON authors USING BTREE(name);
CREATE INDEX idx_authors_followers_count_insert ON authors USING BTREE(followers_count);
CREATE INDEX idx_authors_description_insert ON authors USING BTREE(description);

SELECT max(id) FROM authors;

SELECT * FROM authors WHERE id=1;

DELETE FROM authors WHERE id=1; 

EXPLAIN ANALYSE
INSERT INTO authors(
	id, name, username, description, followers_count, following_count, 
	tweet_count, listed_count
) VALUES(1, 'Erik', 'clever_username', 'txt', 0, 89, 74, 56);

DROP INDEX idx_authors_name_insert;
DROP INDEX idx_authors_followers_count_insert;
DROP INDEX idx_authors_description_insert;

-- 7.
CREATE INDEX idx_conversations_retweet_count ON conversations USING BTREE(retweet_count);

CREATE INDEX idx_conversations_content ON conversations USING BTREE(content);

-- 8.

-- get all indexes in schema to get names of indexes
SELECT tablename, indexname, indexdef FROM pg_indexes WHERE schemaname = 'public'
ORDER BY tablename, indexname;
	
-- extension for inspecting indexes
CREATE EXTENSION pageinspect;

SELECT * FROM bt_metap('idx_authors_followers_count');

SELECT * FROM bt_page_stats('idx_authors_followers_count', 1);

SELECT * FROM bt_metap('idx_authors_username');

SELECT * FROM bt_page_stats('idx_authors_username', 1);

SELECT * FROM bt_metap('idx_conversations_content');

SELECT * FROM bt_page_stats('idx_conversations_content', 1);

SELECT * FROM bt_metap('idx_authors_name_insert');

SELECT * FROM bt_page_stats('idx_authors_name_insert', 1);

SELECT * FROM bt_metap('idx_conversations_retweet_count');

SELECT * FROM bt_page_stats('idx_conversations_retweet_count', 1);


-- 9.
-- Vyhľadajte v conversations content meno „Gates“ na ľubovoľnom mieste a porovnajte
-- výsledok po tom, ako content naindexujete pomocou btree. V čom je rozdiel a prečo?

EXPLAIN ANALYSE
SELECT content FROM conversations 
WHERE content LIKE '%Gates%';

DROP INDEX idx_conversations_content;
CREATE INDEX idx_conversations_content ON conversations USING BTREE(content);

-- 10.
-- Vyhľadajte tweet, ktorý začína “There are no excuses” a zároveň je obsah potenciálne
-- senzitívny (possibly_sensitive). Použil sa index? Prečo? Ako query zefektívniť?

EXPLAIN ANALYSE
SELECT content FROM conversations 
WHERE possibly_sensitive = TRUE AND content LIKE 'There are no excuses%';

-- 11.
-- Vytvorte nový btree index, tak aby ste pomocou neho vedeli vyhľadať tweet, ktorý končí
-- reťazcom „https://t.co/pkFwLXZlEm“ kde nezáleží na tom ako to napíšete. Popíšte čo
-- jednotlivé funkcie robia.

CREATE INDEX idx_conversations_content_tweet ON conversations USING BTREE(content)
WHERE LOWER(content) LIKE LOWER('%https://t.co/pkFwLXZlEm');

EXPLAIN ANALYSE
SELECT content FROM conversations 
WHERE LOWER(content) LIKE LOWER('%https://t.co/pkFwLXZlEm');

-- *'https://t.co/pkFwLXZlEm'

-- 12.
-- Nájdite conversations, ktoré majú reply_count väčší ako 150, retweet_count väčší rovný
-- ako 5000 a výsledok zoraďte podľa quote_count. Následne spravte jednoduché indexy a
-- popíšte ktoré má a ktoré nemá zmysel robiť a prečo. Popíšte a vysvetlite query plan, ktorý sa
-- aplikuje v prípade použitia jednoduchých indexov.

EXPLAIN ANALYSE
SELECT content FROM conversations
WHERE reply_count > 150 AND retweet_count >= 500
ORDER BY quote_count;

DROP INDEX idx_conversations_reply_count;
DROP INDEX idx_conversations_retweet_count;
DROP INDEX idx_conversations_quote_count;
DROP INDEX idx_covnersations_content;

CREATE INDEX idx_conversations_reply_count ON conversations USING BTREE(reply_count);
CREATE INDEX idx_conversations_retweet_count ON conversations USING BTREE(retweet_count);
CREATE INDEX idx_conversations_quote_count ON conversations USING BTREE(quote_count);
CREATE INDEX idx_conversations_content ON conversations USING BTREE(content);


-- 13.
-- Na predošlú query spravte zložený index a porovnajte výsledok s tým, kedy sú indexy
-- separátne. Výsledok zdôvodnite. Popíšte použitý query plan. Aký je v nich rozdiel?


CREATE INDEX idx_conversations ON conversations USING BTREE(
	content,
	reply_count, 
	retweet_count, 
	quote_count
);


-- 14.
-- Napíšte dotaz tak, aby sa v obsahu konverzácie našlo slovo „Putin“ a zároveň spojenie
-- „New World Order“, kde slová idú po sebe a zároveň obsah je senzitívny. Vyhľadávanie má
-- byť indexe. Popíšte použitý query plan pre GiST aj pre GIN. Ktorý je efektívnejší?


CREATE INDEX idx_conversations_gin ON conversations USING GIN(content);
CREATE INDEX idx_conversations_gist ON conversations USING GIST(content);


EXPLAIN ANALYSE
SELECT content FROM conversations
--WHERE possibly_sensitive = TRUE AND content LIKE 'Putin' AND content LIKE 'New World Order';
WHERE 
	possibly_sensitive = TRUE AND 
	to_tsvector('simple', content) @@ to_tsquery('simple', 'Putin:*') @@ to_tsquery('simple', 'New World Order:*');
-- 15.
-- Vytvorte vhodný index pre vyhľadávanie v links.url tak aby ste našli kampane z
-- ‘darujme.sk’. Ukážte dotaz a použitý query plan. Vysvetlite prečo sa použil tento index.


-- 16.
-- Vytvorte query pre slová "Володимир" a "Президент" pomocou FTS (tsvector a
-- tsquery) v angličtine v stĺpcoch conversations.content, authors.decription a
-- authors.username, kde slová sa môžu nachádzať̌ v prvom, druhom ALEBO treťom stĺpci.
-- Teda vyhovujúci záznam je ak aspoň jeden stĺpec má „match“. Výsledky zoradíte podľa
-- retweet_count zostupne. Pre túto query vytvorte vhodné indexy tak, aby sa nepoužil ani raz
-- sekvenčný scan (správna query dobehne rádovo v milisekundách, max sekundách na super
-- starých PC). Zdôvodnite čo je problém s OR podmienkou a prečo AND je v poriadku pri joine.

DROP INDEX idx_;
CREATE INDEX idx_authors_fts ON authors USING GIN(
	username,
	description
);