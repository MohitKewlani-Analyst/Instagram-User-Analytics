use instagram_analytics;

-- Data Cleaning

-- finding Duplicates

with duplicatecomments as (
select * ,
row_number() over(partition by id,comment_text,user_id,photo_id,created_at) as rn
from comments )
select * from duplicatecomments 
where rn > 1;

with duplicatefollows as (
select * ,
row_number() over(partition by follower_id,followee_id,created_at) as rn 
from follows)
select * from duplicatefollows where rn > 1;

with duplicatelikes as 
(
select *,
row_number() over(partition by user_id,photo_id,created_at) as rn 
from likes)
select * from duplicatelikes where rn >1;

with duplicatephoto_tags as(
select * ,
row_number() over (partition by photo_id,tag_id) as rn 
from photo_tags)
select * from duplicatephoto_tags where rn >1; 

with duplicatephotos as (
select *,
row_number() over(partition by id,image_url,user_id,created_dat) as rn
from photos)
select * from duplicatephotos where rn >1;

with duplicatetags as(
select * ,
row_number() over (partition by id,tag_name,created_at) as rn
from tags)
select * from duplicatetags where rn > 1;

with duplicateusers as (
select *,
row_number() over (partition by id,username,created_at) as rn 
from users)
select * from duplicateusers where rn >1;

-- Finding Null values

SELECT 'id' as ColumnName, COUNT(*) AS NullCount 
FROM comments
WHERE id IS NULL 
UNION
SELECT 'comment_text' as ColumnName, COUNT(*) AS NullCount 
FROM comments
WHERE comment_text IS NULL 
UNION
SELECT 'user_id' as ColumnName, COUNT(*) AS NullCount 
FROM comments
WHERE user_id IS NULL
UNION
SELECT 'photo_id' as ColumnName, COUNT(*) AS NullCount 
FROM comments
WHERE photo_id IS NULL 
UNION
SELECT 'created_at' as ColumnName, COUNT(*) AS NullCount 
FROM comments
WHERE created_at IS NULL ;


-- Replace NULL comments with a placeholder using COALESCE
UPDATE comments
SET comment_text = COALESCE(NULLIF(TRIM(comment_text), ''), 'No comment provided')
WHERE comment_text IS NULL OR TRIM(comment_text) = '';
delete from comments where comment_text = 'No comment provided';


-- Trimming Whitespace & Normalizing Username Casing

UPDATE users
SET username = LOWER(TRIM(username));

-- Cleaning Broken URLs Using CASE WHENS

update photos 
set image_url = case 
when image_url not like 'http://%' and image_url not like 'https://%'
then concat('https://',trim(image_url))
else trim(image_url) end 
where image_url is not null;

-- Converting String Dates to Proper datetime value

UPDATE photos
SET created_dat = STR_TO_DATE(created_dat, '%Y-%m-%d %H:%i:%s')
WHERE created_dat IS NOT NULL;

-- detecting and deleting anamolies

select created_at from users 
where created_at > now();
DELETE FROM users
WHERE created_at > NOW();

select follower_id from follows
where follower_id = followee_id;
DELETE FROM follows
WHERE follower_id = followee_id;

-- Normalizes hashtag strings

UPDATE tags
SET tag_name = LOWER(TRIM(REPLACE(tag_name, '#', '')))
WHERE tag_name LIKE '#%' OR tag_name != LOWER(TRIM(tag_name));

-- Enforcing Schema Constraints & Correct Data Types

-- Modify columns to ensure data typing and avoid NULL anomalies
ALTER TABLE users 
    MODIFY COLUMN username VARCHAR(255) NOT NULL,
    MODIFY COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;


-- Data Analysis


-- 1 Who are the five oldest users on Instagram? 

select * from users;
select id,username ,min(created_at) as oldest_user from users
group by id,username
order by oldest_user
limit 5;

-- 2  Find the users who have never posted a single photo? 

select u.id,u.username 
from users u
left join photos p on u.id=p.user_id
where p.user_id is null;

-- 3  Which photo has the highest number of likes? 

select l.photo_id,u.username,p.image_url,count(l.user_id) as total_likes
from likes l 
inner join photos p
on l.photo_id = p.id
inner join users u
on p.user_id = u.id
group by 1,2,3
order by total_likes desc
limit 5;

-- 4 Which are the top 5 most commonly used hashtags?

select photo_tags.tag_id,tags.tag_name,count(*) as total_tags
from photo_tags 
join tags
on photo_tags.tag_id = tags.id
group by 1,2
order by total_tags desc
limit 5;

select * from users;

-- 5 On which day, the highest number of accounts were created? 

with cte as (select *,dayofweek(created_at) as day_week,dayname(created_at) as day_name
from users)
select day_name , count(day_week) as total_appearance
from cte
group by day_name;

-- 6 Find the account which has the highest number of followers? 
WITH FollowerCounts AS (
    SELECT 
        u.id AS user_id,
        u.username,
        COUNT(f.follower_id) AS total_followers,
        DENSE_RANK() OVER (ORDER BY COUNT(f.follower_id) DESC) AS rank_pos
    FROM users u
    JOIN follows f ON u.id = f.followee_id
    GROUP BY u.id, u.username
)
SELECT 
    user_id,
    username
FROM FollowerCounts
WHERE rank_pos = 1
ORDER BY user_id ASC;

-- Q7 Some users are dormant. Find out from how long these users have been dormant? 

with dormantusers as (
select u.id,u.username,u.created_at,
datediff((select max(created_at) from users),u.created_at) as day_diff
from users u
LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON u.id = l.user_id
    LEFT JOIN comments c ON u.id = c.user_id
    LEFT JOIN `follows` f ON u.id = f.follower_id
   WHERE p.id IS NULL AND l.user_id IS NULL AND c.user_id IS NULL AND f.follower_id IS NULL )
   select case 
   when day_diff <= 90 then 'recent_drop'
   when day_diff >90 and day_diff <= 180 then 'mid_drop'
   else 'long_drop'
   end as dormant_cohort,
   count(id) as total_users,
   round(100* count(id)/(select count(id) from dormantusers),2) as percent_dormant
   from dormantusers group by dormant_cohort;
   
 -- Q8  Find the top 3 Inactive/dormant users? 
 
with dormantusers as (
select u.id,u.username,date(u.created_at) as signup_date,
dense_rank() over(order by u.created_at) as priority 
FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON u.id = l.user_id
    LEFT JOIN comments c ON u.id = c.user_id
    LEFT JOIN follows f ON u.id = f.follower_id
    WHERE p.id IS NULL AND l.user_id IS NULL AND c.user_id IS NULL AND f.follower_id IS NULL )
    SELECT 
    priority,
    id,
    username,
    signup_date
FROM DormantUsers
WHERE priority <= 3
ORDER BY priority ASC;


-- PART B

-- 1
 -- avg no. of photo per user for active users (removed users who does not post)
 
with cte as (select u.id,u.username,count(p.id) as total_photos
from users u 
inner join photos p on 
u.id = p.user_id
group by 1,2)
select sum(total_photos) / count(id) as av from cte;


-- avg. no. of photos per user (consider all users)

SELECT 
    COUNT(p.id) AS total_photos,
    COUNT(DISTINCT u.id) AS total_users,
    ROUND(COUNT(p.id) * 1.0 / COUNT(DISTINCT u.id), 2) AS avg_posts_per_user
FROM users u
LEFT JOIN photos p ON u.id = p.user_id;

-- 2
-- What percentage of total platform content was contributed by each user 

SELECT 
    u.id,
    u.username,
    COUNT(p.id) AS user_posts,
    ROUND(100.0 * COUNT(p.id) / (SELECT COUNT(*) FROM photos), 2) AS pct_of_total_platform_posts
FROM users u
INNER JOIN photos p ON u.id = p.user_id
GROUP BY u.id, u.username
ORDER BY pct_of_total_platform_posts DESC;

-- 3
-- identify the users who have liked every photo (bot accounts)

select u.id,u.username,
count(l.photo_id) as total_likes_given 
from users u 
join likes l
on u.id = l.user_id
group by 1,2
having total_likes_given = (select count(*) from photos);

-- 4
-- find the percentage of active users who are engaging with all the features such as likes,comments,photo_post

with activeusers as (
select u.id,u.username
from users u
inner JOIN photos p ON u.id = p.user_id
    inner JOIN likes l ON u.id = l.user_id
    inner JOIN comments c ON u.id = c.user_id
   WHERE p.id IS not NULL AND l.user_id IS not NULL AND c.user_id IS not NULL 
   group by 1,2)
   select 
   count(id) as total_activeusers,
   100 * count(*)/(select count(*) from users) as pct_of_total_activeusers
   from activeusers;
   
-- To achieve the exact same result while eliminating the costly Cartesian product, use EXISTS clauses:
SELECT 
    COUNT(*) AS total_activeusers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM users), 2) AS pct_of_total_activeusers
FROM users u
WHERE EXISTS (SELECT 1 FROM photos p WHERE p.user_id = u.id)
  AND EXISTS (SELECT 1 FROM likes l WHERE l.user_id = u.id)
  AND EXISTS (SELECT 1 FROM comments c WHERE c.user_id = u.id);
  
  
 -- 5 

SELECT 
    DATE_FORMAT(u.created_at, '%Y') AS registration_year,
    COUNT(DISTINCT u.id) AS cohort_signups,
    COUNT(DISTINCT p.id) AS total_posts_produced,
    ROUND(COUNT(DISTINCT p.id) / COUNT(DISTINCT u.id), 2) AS posts_per_registered_user,
    ROUND(COUNT(DISTINCT p.id) / COUNT(DISTINCT p.user_id), 2) AS posts_per_active_creator
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
GROUP BY DATE_FORMAT(u.created_at, '%Y')
ORDER BY registration_year ASC;

-- 6.
-- Find the percentage increase in users in comparison to previous year.
WITH YearlyRegistrations AS (
    SELECT 
        YEAR(created_at) AS registration_year,
        COUNT(id) AS total_users
    FROM users
    GROUP BY YEAR(created_at)
)
SELECT 
    registration_year,
    total_users,
    LAG(total_users, 1) OVER (ORDER BY registration_year ASC) AS prev_year_users,
    ROUND(
        (total_users - LAG(total_users, 1) OVER (ORDER BY registration_year ASC)) * 100.0 / 
        LAG(total_users, 1) OVER (ORDER BY registration_year ASC), 
        2
    ) AS pct_change_vs_prev_year
FROM YearlyRegistrations
ORDER BY registration_year ASC;

/* with monthly_registration as (
select date_format(created_at,"%Y-%m") as registered_month,
count(id) as total_users from users 
group by date_format(created_at,"%Y-%m")
),
 cte2 as (select registered_month,total_users,
sum(total_users) over(order by registered_month) as cumulative_users,
round(( sum(total_users) over(order by registered_month) - total_users) * 100/sum(total_users) over(order by registered_month),2) as pct_change_over_month
from monthly_registration
order by registered_month)
select registered_month,total_users,
pct_change_over_month,
abs(pct_change_over_month - lag(pct_change_over_month) over(order by registered_month))
as pct_change_prev_month
from cte2
order by registered_month; */


/* with monthly_registration as (
select date_format(created_at,"%Y-%m") as registered_month,
count(id) as total_users from users 
group by date_format(created_at,"%Y-%m")
)
select registered_month,total_users,
avg(total_users) over(order by registered_month)
from  monthly_registration
order by registered_month; */




-- 7
-- what is the platforms core user conversion funnel
SELECT 
    COUNT(DISTINCT u.id) AS total_registered_users,
    COUNT(DISTINCT p.user_id) AS active_creators,
    COUNT(DISTINCT l.user_id) AS active_likers,
    COUNT(DISTINCT c.user_id) AS active_commenters,
    ROUND(COUNT(DISTINCT p.user_id) * 100.0 / COUNT(DISTINCT u.id), 2) AS creator_activation_rate_pct,
    ROUND(COUNT(DISTINCT l.user_id) * 100.0 / COUNT(DISTINCT u.id), 2) AS engager_activation_rate_pct
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id;




