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
EXPLAIN ANALYSE
SELECT content FROM conversations 
WHERE content LIKE '%Gates%';

DROP INDEX idx_conversations_content;
CREATE INDEX idx_conversations_content ON conversations USING BTREE(content);

-- 10.
EXPLAIN ANALYSE
SELECT content FROM conversations 
WHERE possibly_sensitive = TRUE AND content LIKE 'There are no excuses%';

-- 11.
DROP INDEX idx_conversations_content_tweet;

CREATE INDEX idx_conversations_content_tweet ON conversations USING BTREE(content)
WHERE LOWER(REVERSE(content)) LIKE LOWER(REVERSE('%https://t.co/pkFwLXZlEm'));

EXPLAIN ANALYSE
SELECT content FROM conversations 
WHERE LOWER(REVERSE(content)) LIKE LOWER(REVERSE('%https://t.co/pkFwLXZlEm'));

-- 12.
EXPLAIN ANALYSE
SELECT content FROM conversations
WHERE reply_count > 150 AND retweet_count >= 5000
ORDER BY quote_count;

DROP INDEX idx_conversations_reply_count;
DROP INDEX idx_conversations_quote_count;
DROP INDEX idx_conversations_12;

CREATE INDEX idx_conversations_reply_count ON conversations USING BTREE(reply_count);
CREATE INDEX idx_conversations_quote_count ON conversations USING BTREE(quote_count);

CREATE INDEX idx_conversations_12 ON conversations USING BTREE(content)
WHERE reply_count > 150 AND retweet_count >= 5000;


-- 13.
CREATE INDEX idx_conversations_13 ON conversations USING BTREE(
	content,
	reply_count, 
	retweet_count, 
	quote_count
) WHERE reply_count > 150 AND retweet_count >= 5000;


-- 14.
DROP INDEX idx_conversations_gin;
CREATE INDEX idx_conversations_gin ON conversations USING GIN(to_tsvector('simple', content))
WHERE possibly_sensitive = TRUE AND content LIKE '%Putin%New World Order%';

DROP INDEX idx_conversations_gist;
CREATE INDEX idx_conversations_gist ON conversations USING GIST(to_tsvector('simple', content))
WHERE possibly_sensitive = TRUE AND content LIKE '%Putin%New World Order%';

EXPLAIN ANALYSE
SELECT content FROM conversations
WHERE 
	possibly_sensitive = TRUE AND 
	content LIKE '%Putin%New World Order%';
	--to_tsvector('simple', content) @@ to_tsquery('Putin & New & World & Order');

-- 15.
CREATE INDEX idx_url ON links USING GIN(to_tsvector('simple', url)) WHERE url LIKE '%darujme.sk%';

EXPLAIN ANALYSE
SELECT url FROM links WHERE url LIKE '%darujme.sk%';

-- 16.
-- Vytvorte query pre slová "Володимир" a "Президент" pomocou FTS (tsvector a
-- tsquery) v angličtine v stĺpcoch conversations.content, authors.decription a
-- authors.username, kde slová sa môžu nachádzať̌ v prvom, druhom ALEBO treťom stĺpci.
-- Teda vyhovujúci záznam je ak aspoň jeden stĺpec má „match“. Výsledky zoradíte podľa
-- retweet_count zostupne. Pre túto query vytvorte vhodné indexy tak, aby sa nepoužil ani raz
-- sekvenčný scan (správna query dobehne rádovo v milisekundách, max sekundách na super
-- starých PC). Zdôvodnite čo je problém s OR podmienkou a prečo AND je v poriadku pri joine.

DROP INDEX idx_authors_gist_16;
CREATE INDEX idx_authors_gist_16 ON authors USING GIST(
	to_tsvector('simple', username),
	to_tsvector('simple', description)
)
WHERE 
	to_tsvector('simple', authors.username) || 
	to_tsvector('simple', authors.description) @@
	to_tsquery('Володимир & Президент');
	
DROP INDEX idx_authors_gin_16;
CREATE INDEX idx_authors_gin_16 ON authors USING GIN(
	to_tsvector('english', username),
	to_tsvector('english', description)
)
WHERE
	to_tsvector('english', authors.username) || 
	to_tsvector('english', authors.description) @@
	to_tsquery('Володимир & Президент');


DROP INDEX idx_conversations_gin_16;
CREATE INDEX idx_conversations_gin_16 ON conversations USING GIN(
	to_tsvector('english', content)
)

DROP INDEX idx_authors_btree_16;
CREATE INDEX idx_authors_btree_16 ON authors USING BTREE(id);

DROP INDEX idx_conversations_btree_16;
CREATE INDEX idx_conversations_btree_16 ON conversations USING BTREE(
	author_id,
	retweet_count DESC
);

EXPLAIN ANALYSE
SELECT authors.username, authors.description, conversations.content 
FROM authors --CROSS JOIN conversations
JOIN conversations ON authors.id = conversations.author_id
WHERE
	to_tsvector('english', authors.username || authors.description || conversations.content) @@
	to_tsquery('Володимир & Президент')
ORDER BY conversations.retweet_count DESC;

"Володимир" a "Президент"

