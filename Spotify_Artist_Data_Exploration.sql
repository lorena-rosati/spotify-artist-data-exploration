--Loading the data into PostgreSQL from csv file
COPY taylor_swift_spotify
FROM 'C:\Users\lrosa\OneDrive\Desktop\Coding\ts_discography\taylor_swift_spotify.csv' 
DELIMITER ','
CSV Header;

--Initially looking through the data
SELECT * FROM taylor_swift_spotify;

--------DATA CLEANING--------

--First, making sure that there are no null values throughout the table
SELECT
    *
FROM
    taylor_swift_spotify
WHERE
    number IS NULL
    OR name IS NULL
    OR album IS NULL
    OR release_date IS NULL
    OR track_number IS NULL
    OR id IS NULL
    OR uri IS NULL
    OR acousticness IS NULL
    OR danceability IS NULL
    OR energy IS NULL
    OR instrumentalness IS NULL
    OR liveness IS NULL
    OR loudness IS NULL
    OR speechiness IS NULL
    OR tempo IS NULL
    OR valence IS NULL
    OR popularity IS NULL
    OR duration_ms IS NULL
ORDER BY
    name;

--Confirming the purpose of the "col" column by ordering it
SELECT * from taylor_swift_spotify ORDER BY col;

--Adjusting first column to better reflect its purpose - made column name release_order and started values at 1 instead of 0
ALTER TABLE taylor_swift_spotify RENAME COLUMN col TO release_order;
UPDATE taylor_swift_spotify SET release_order = release_order + 1;

--Checking that the values are in the right ranges provided in the data set documentation
SELECT
    GREATEST(acousticness,
        danceability,
        energy,
        instrumentalness,
        liveness,
        loudness,
        speechiness,
        valence)
    AS max_value,
	LEAST(acousticness,
        danceability,
        energy,
        instrumentalness,
        liveness,
        loudness,
        speechiness,
        valence)
    AS min_value
FROM
    taylor_swift_spotify;
SELECT
    MAX(popularity)
    AS max_value,
	MIN(popularity)
    AS min_value
FROM    taylor_swift_spotify;

--Removing notes beside song names and adding them to a new column titled "comment"
SELECT name FROM taylor_swift_spotify WHERE name SIMILAR TO '%[A-Za-z]-[A-Za-z]%';

ALTER TABLE taylor_swift_spotify ADD comment text;

UPDATE
    taylor_swift_spotify
SET
    name =
        CASE
            WHEN name = 'Anti-Hero'
                THEN name
            WHEN name LIKE '%-%'
                THEN
                    SUBSTRING(name, 1, POSITION('-' in name) - 2)
            ELSE name
        END,
    comment =
        CASE
            WHEN name = 'Anti-Hero'
                THEN '-'
            WHEN name LIKE '%-%'
                THEN
                    SUBSTRING(name, POSITION('-' in name) + 2, LENGTH(name))
            ELSE '-'
        END;

--Removing featured artists from a song's name and adding that to a new column titled "collab"
ALTER TABLE taylor_swift_spotify ADD collab text;
	
SELECT
	CASE
		WHEN name LIKE '%(feat.%)'
			THEN SUBSTRING(name, 1, POSITION('(' in name)-2)
		ELSE name
	END AS name2,
	CASE
		WHEN name LIKE '%(feat.%)'
			THEN SUBSTRING(name, POSITION('(' in name)+7, POSITION(')' in name) - POSITION('(' in name)-7)
		ELSE '-'
	END AS collab2
FROM taylor_swift_spotify;

UPDATE taylor_swift_spotify 
SET 
	name = 
		CASE
			WHEN name LIKE '%(feat.%)'
				THEN SUBSTRING(name, 1, POSITION('(' in name)-2)
			ELSE name
		END,
	collab = 
		CASE
			WHEN name LIKE '%(feat.%)'
				THEN SUBSTRING(name, POSITION('(' in name)+7, POSITION(')' in name) - POSITION('(' in name)-7)
			ELSE '-'
		END;

SELECT 
	CASE
		WHEN collab LIKE '%More%'
			THEN SUBSTRING(collab, 6)
		ELSE collab
	END as collab2
FROM taylor_swift_spotify;

UPDATE taylor_swift_spotify
SET
	collab =
		CASE
			WHEN collab LIKE '%More%'
				THEN SUBSTRING(collab, 6)
			ELSE collab
		END;

--Ensuring no whitespace in the name and collab column values
UPDATE taylor_swift_spotify SET name = TRIM(name), collab = TRIM(collab), comment = TRIM(comment);



--------DATA ANALYSIS--------


SELECT album, release_date, ROUND(AVG(popularity),2) AS popularity_avg FROM taylor_swift_spotify GROUP BY album, release_date ORDER BY popularity_avg DESC;

--Query to observe metrics that contribute to an album's popularity
SELECT 
album, 
release_date,
ROUND(AVG(popularity),2) AS popularity_avg, 
ROUND(AVG(acousticness), 2) AS acousticness_avg,
ROUND(AVG(danceability), 2) AS danceability_avg,
ROUND(AVG(energy), 2) AS energy_avg,
ROUND(AVG(liveness), 2) AS liveness_avg,
ROUND(AVG(loudness), 2) AS loudness_avg,
ROUND(AVG(speechiness), 2) AS speechiness_avg,
ROUND(AVG(tempo), 2) AS tempo_avg,
ROUND(AVG(valence), 2) AS valence_avg
FROM taylor_swift_spotify GROUP BY album, release_date ORDER BY popularity_avg DESC;

--Analyze the reasons for which older albums (Lover and reputation) are more popular than newer albums (folklore and evermore)
SELECT 'Lover/reputation' AS albums, 
ROUND(AVG(acousticness), 2) AS acousticness_avg,
ROUND(AVG(danceability), 2) AS danceability_avg,
ROUND(AVG(energy), 2) AS energy_avg,
ROUND(AVG(instrumentalness), 2) AS instrumentalness_avg,
ROUND(AVG(liveness), 2) AS liveness_avg,
ROUND(AVG(loudness), 2) AS loudness_avg,
ROUND(AVG(speechiness), 2) AS speechiness_avg,
ROUND(AVG(tempo), 2) AS tempo_avg,
ROUND(AVG(valence), 2) AS valence_avg
FROM taylor_swift_spotify
WHERE album IN ('Lover', 'reputation')
UNION ALL
SELECT 'folklore/evermore' AS albums, 
ROUND(AVG(acousticness), 2) AS acousticness_avg,
ROUND(AVG(danceability), 2) AS danceability_avg,
ROUND(AVG(energy), 2) AS energy_avg,
ROUND(AVG(instrumentalness), 2) AS instrumentalness_avg,
ROUND(AVG(liveness), 2) AS liveness_avg,
ROUND(AVG(loudness), 2) AS loudness_avg,
ROUND(AVG(speechiness), 2) AS speechiness_avg,
ROUND(AVG(tempo), 2) AS tempo_avg,
ROUND(AVG(valence), 2) AS valence_avg
FROM taylor_swift_spotify
WHERE album IN ('folklore', 'evermore');

--Analyzing the different metrics influencing the popularity of folklore and evermore
SELECT album, release_date,
ROUND(AVG(acousticness), 2) AS acousticness_avg,
ROUND(AVG(danceability), 2) AS danceability_avg,
ROUND(AVG(energy), 2) AS energy_avg,
ROUND(AVG(instrumentalness), 2) AS instrumentalness_avg,
ROUND(AVG(liveness), 2) AS liveness_avg,
ROUND(AVG(loudness), 2) AS loudness_avg,
ROUND(AVG(speechiness), 2) AS speechiness_avg,
ROUND(AVG(tempo), 2) AS tempo_avg,
ROUND(AVG(valence), 2) AS valence_avg
FROM taylor_swift_spotify
WHERE album IN ('folklore', 'evermore')
GROUP BY album, release_date;

--Analyzing the differences between the top and bottom 10 songs, in terms of popularity
SELECT 'Top 10 Songs' AS song_name,
ROUND(AVG(CAST(duration_ms as numeric)), 2) AS duration_avg,
ROUND(AVG(acousticness), 2) AS acousticness_avg,
ROUND(AVG(danceability), 2) AS danceability_avg,
ROUND(AVG(energy), 2) AS energy_avg,
ROUND(AVG(instrumentalness), 2) AS instrumentalness_avg,
ROUND(AVG(liveness), 2) AS liveness_avg,
ROUND(AVG(loudness), 2) AS loudness_avg,
ROUND(AVG(speechiness), 2) AS speechiness_avg,
ROUND(AVG(tempo), 2) AS tempo_avg,
ROUND(AVG(valence), 2) AS valence_avg
FROM (
SELECT name, duration_ms, acousticness, danceability, energy, instrumentalness, liveness, loudness, speechiness, tempo, valence
FROM taylor_swift_spotify
WHERE comment = '-'
ORDER BY popularity DESC
LIMIT 10
) AS top_songs
UNION ALL
SELECT 'Lowest 10 Songs' AS song_name,
ROUND(AVG(CAST(duration_ms as numeric)), 2) AS duration_avg,
ROUND(AVG(acousticness), 2) AS acousticness_avg,
ROUND(AVG(danceability), 2) AS danceability_avg,
ROUND(AVG(energy), 2) AS energy_avg,
ROUND(AVG(instrumentalness), 2) AS instrumentalness_avg,
ROUND(AVG(liveness), 2) AS liveness_avg,
ROUND(AVG(loudness), 2) AS loudness_avg,
ROUND(AVG(speechiness), 2) AS speechiness_avg,
ROUND(AVG(tempo), 2) AS tempo_avg,
ROUND(AVG(valence), 2) AS valence_avg
FROM (
SELECT name, duration_ms, acousticness, danceability, energy, instrumentalness, liveness, loudness, speechiness, tempo, valence
FROM taylor_swift_spotify
WHERE comment = '-'
ORDER BY popularity
LIMIT 10
) AS low_songs;
