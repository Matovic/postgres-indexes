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
CREATE INDEX idx_authors_username_insert ON authors USING BTREE(username);
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

DROP INDEX idx_authors_username_insert;
DROP INDEX idx_authors_followers_count_insert;
DROP INDEX idx_authors_description_insert;

-- 7.
