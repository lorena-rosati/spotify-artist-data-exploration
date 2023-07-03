# Spotify Artist Data Exploration

With this data exploration, I aimed to practice my SQL data cleaning and analysis skills by analyzing trends in the popularity of Taylor Swift's songs and albums. More specifically, I focused on analyzing which factors contribute to an album/song's popularity, from the release date to metrics on a song's energy, acousticness, and more.

# Cleaning
I started by checking if there were any null values throughout the table with the following query:
```
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
```

I noticed a column called "col" which did not have an obvious purpose from its title. It seemed like it began at 0 and was in increasing order of song release, so to make this more clear, I renamed the column to "release_order" and added 1 to each value so the most recent release has a value "1" rather than "0" in this column.
```
SELECT * from taylor_swift_spotify ORDER BY col;
ALTER TABLE taylor_swift_spotify RENAME COLUMN col TO release_order;
UPDATE taylor_swift_spotify SET release_order = release_order + 1;
```

Next, I wanted to ensure that popularity is a value ranging from 0 to 100 and other metrics relating to the "sound" of the song were values ranging from 0 to 1 for all data (in accordance with the dataset documentation).
```
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
```

Some songs were of the format [song name] - [note regarding its production]. For example, "Last Kiss - Live/2011". I sought to remove the note and add this to a separate column so that the song name column contains solely song names for easier analysis. I created a column called "comment" and added these notes to that column.
```
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
```

Similarly, some song names included the name of a feature artist on the song. I also wanted to remove this from the song name and create a separate column with this artists' name in order to only have actual song titles in the "name" column. One song, "Snow on the Beach (feat. More Lana Del Ray)", had the word "More" as part of the collaborator's "name", so I ensured that that was removed as well.
```
ALTER TABLE taylor_swift_spotify ADD collab text;

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

UPDATE taylor_swift_spotify
SET
	collab =
		CASE
			WHEN collab LIKE '%More%'
				THEN SUBSTRING(collab, 6)
			ELSE collab
		END;
```

Finally, I removed all possible whitespace before and after text columns:
```
UPDATE taylor_swift_spotify SET name = TRIM(name), collab = TRIM(collab), comment = TRIM(comment);
```

# Analysis
I wanted to begin by figuring out metrics that contribute to an album's popularity, so I ran a query that returned a table with descending popularity of an album and its average "sound" metrics and release date.
```
SELECT 
album, 
ROUND(AVG(popularity),2) AS popularity_avg, 
ROUND(AVG(acousticness), 2) AS acousticness_avg,
ROUND(AVG(danceability), 2) AS danceability_avg,
ROUND(AVG(energy), 2) AS energy_avg,
ROUND(AVG(liveness), 2) AS liveness_avg,
ROUND(AVG(loudness), 2) AS loudness_avg,
ROUND(AVG(speechiness), 2) AS speechiness_avg,
ROUND(AVG(tempo), 2) AS tempo_avg,
ROUND(AVG(valence), 2) AS valence_avg
FROM taylor_swift_spotify GROUP BY album ORDER BY popularity_avg DESC;
```
![1_Most_Popular_Songs](https://github.com/lorena-rosati/spotify-artist-data-exploration/assets/122554042/7526572e-f19d-4858-b85d-eaca7c2ba59a)
![Popularity_vs_Time](https://github.com/lorena-rosati/spotify-artist-data-exploration/assets/122554042/cf8ed1ee-65c9-440d-9173-fa29f005d732)

The factors influencing the albums's popularity seem to be very correlated to release date, as all of the newest albums are towards the top of the popularity list. However, reputation and Lover are older than folklore and evermore, yet they rank higher. To examine this, I ran a similar query but wanted to compare Lover and reputation with folklore and evermore.
```
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
```
![2_Comparing_Top_Albums](https://github.com/lorena-rosati/spotify-artist-data-exploration/assets/122554042/ddc21a7f-8bad-4fcf-b3c5-b4af00eb0289)
This table shows that folklore and evermore are, on average, much more acoustic than Lover and reputation, as their average "acoustic score" is 75% (vs. 25% for Lover/reputation). Other metrics don't seem to be as major of factors, but the table does show that the energy and danceability are more prominent in songs off of the Lover and reputation albums and these songs have quicker tempos. Lover and reputation are Taylor Swift's pop albums and folklore are evermore are her more folk/indie albums, so even though all four albums are widely loved by fans according to these stats, it seems as though her pop albums are preferred. This makes sense as well because she is more widely recognized by the public as a pop/country singer, rather than an indie/folk singer. 

Similarly, folklore and evermore are widely regarded by fans as sister albums and evermore is newer, yet folklore is higher in popularity. I wanted to compare their "sound" metrics to understand any factors that may contribute to this.
```
SELECT album, 
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
GROUP BY album;
```
![3_Comparing_Folklore_and_Evermore](https://github.com/lorena-rosati/spotify-artist-data-exploration/assets/122554042/fb96cc9c-52ca-4ccd-bc05-1bc3b1553cc4)
According this table, most sound metrics are quite similar. The largest discrepancy between the two albums seems to be the level of acousticness, with evermore having a score of 80% while folklore has a score of 71%. The only other contributor seems to be the release date, with folklore being released first. While with other albums, newer albums seem to perform better than older albums of similar genres according to previous analysis, it is the opposite for folklore and evermore. The only difference is that folklore and evermore are quite different genres from the rest of Taylor Swift's albums, so it can be speculated that folklore had the novelty of a different sound, whereas evermore wasn't as much of a genre shift since it came after folklore. 

Next, I analyzed the factors contributing to the popularity of songs. I started by trying to get a better understanding of the differences between the ten most popular and least popular songs. 
```
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
```
![4_Comparing_Most_and_Least_Popular_Songs](https://github.com/lorena-rosati/spotify-artist-data-exploration/assets/122554042/253bce28-1f88-4831-a446-3879cb7cac47)
The 10 least popular songs are about 23 seconds longer than the 10 most popular songs (on average), meaning that her shorter songs perform better. Similarly, her most popular songs have a 29% acousticness rating, whereas her least popular song have a 19% acousticness rating. This means that, generally speaking, songs perform better when they are less acoustic. 


----------
Source of the dataset: https://www.kaggle.com/datasets/jarredpriester/taylor-swift-spotify-dataset

