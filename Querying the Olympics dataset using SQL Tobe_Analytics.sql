drop table if exists Olympics_History;
Create table if not exists Olympics_History
(
	id int,
	name varchar,
	sex varchar,
	age varchar,
	height varchar,
	weight varchar,
	team varchar,
	noc varchar,
	games varchar,
	year int,
	season varchar,
	city varchar,
	sport varchar,
	event varchar,
	medal varchar	
);


drop table if exists Olympics_History_Noc_Regions;
create table if not exists Olympics_History_Noc_Regions
(
	noc varchar,
	region varchar,
	notes varchar
);


--Question 1. How many olympics games have been held?

select count (distinct games) as Total_games
from Olympics_History;

--Question 2. List down all Olympics games held so far with respect to the year, season, and city.?

select distinct year, season, city 
from Olympics_History
order by year;

--Question 3. Mention the total number of nations who participated in each olympics game?

select oh.games, count (distinct nr.region)
from Olympics_History as oh
join Olympics_History_noc_regions as nr 
on oh.noc=nr.noc
group by games
order by games 

--Question 3. Alternative Solution

with all_countries as
			(select oh.games, nr.region
			from Olympics_History as oh
			inner join Olympics_history_noc_regions as nr
			on oh.noc=nr.noc
			group by games, nr.region)
select games, count(*) as total_countries 
from all_countries 
group by games
order by games;

--Question 4. Which year saw the highest and lowest number of countries participating in Olympics

with all_countries as
		(select oh.games, nr.region
		from Olympics_History as oh
		join Olympics_History_noc_regions as nr
		on oh.noc=nr.noc
		group by games, region),
	total_countries as
		(select games, count(*) as total_countries
		from all_countries
		group by games)
select distinct 
	concat(min(games) over(order by total_countries asc), 
		   ' - ',
			min(total_countries) over(order by total_countries asc)) as Lowest_Countires,
	concat(max(games) over (order by total_countries desc),
			' - ',
			max(total_countries) over (order by total_countries desc)) as Highest_Countries	
from total_countries

--Question 5. Which nation has participated in all of the olympic games?

select oh.noc, nr.region, count (distinct oh.games) as Total_Games_Participated
from Olympics_History as oh
join Olympics_History_noc_regions as nr
on oh.noc=nr.noc
group by oh.noc, nr.region
having count(distinct oh.games) = (select count (distinct games) from Olympics_History)
order by Total_Games_Participated desc;

--Question 6. Identify the sport which was played in all summer olympics.

select Sport, count(distinct year) as "Total Summer Olympics"
from Olympics_History
where season ='Summer'
group by sport
having count(distinct year)= (select count(distinct year) from Olympics_History where season = 'Summer');

--Question 6 Alternative Solution 

with t1 as
	(select count( distinct games) as total_summer_games
	 from Olympics_history
	 where season ='Summer' ),
t2 as 
	(select distinct sport,games
	   from Olympics_history
		where season = 'Summer' order by games),
t3 as
		(select sport, count(games) as no_of_games
		from t2
		group by sport)
select * 
from t3
join t1
on t1.total_summer_games = t3.no_of_games; 

--Question 7. Which Sports were just played only once in the olympics.

select distinct sport, count(distinct games) as No_of_games
from Olympics_History 
group by sport
having count(distinct games)= 1;

--Question 8. Fetch the total no of sports played in each olympic games.

select games, count (distinct sport) as Total_number_of_sport_played
from Olympics_History
group by games
order by games desc;

--Question 8 Alternative Solution 

with t1 as
      	(select distinct games, sport
      	from olympics_history),
      t2 as
      	(select games, count (distinct sport) as no_of_sports
      	from t1
      	group by games)
select * from t2
order by games desc;

--Question 9. Fetch oldest athletes to win a gold medal

select name, sex, age, team, sport, event, medal
from Olympics_History
where medal ='Gold' and age <> 'NA' and age <> ' '
order by age desc
limit 2;

--Question 9 Alternative Solution

with t1 as
		(select name, sex, cast(case when age = 'NA' then '0' else age end as integer) as age,team,
		sport,event, medal
		from Olympics_History),
	ranking as
		(select *,
		 rank() over (order by age desc ) as rnk
		from t1
		where medal = 'Gold')
select *
from ranking
where rnk =1;

--Question 10. Find the Ratio of male and female athletes participated in all olympic games.

with t1 as 
		(select sex, count(sex) as cnt
		from Olympics_History
		group by sex),
	t2 as 
		(select *, row_number() over(order by cnt asc) as ranking
		 from t1 ),
	min_cnt as 
		(select cnt from t2 where ranking =1),
	max_cnt as
		(select cnt from t2 where ranking =2)
select concat(' 1 : ', round(max_cnt.cnt::decimal/min_cnt.cnt, 2 )) as ratio
from min_cnt, max_cnt

--Question 10 Alternative Solution

select concat('1 :', round(max_cnt.cnt::decimal/min_cnt.cnt, 2)) as Ratio
from 
	(select cnt
	  from 
		  (select sex, count(sex) as cnt
		   from Olympics_History
		   group by sex
		   order by cnt asc) as t1
		   limit 1) as min_cnt,
	(select cnt 
	 from 
		 (select sex, count(sex) as cnt
		  from Olympics_History
		  group by sex
		  order by cnt desc) as t2
		  limit 1) as max_cnt;
		  
--Question 11. Fetch the top 5 athletes who have won the most gold medals

select name, gold_medals, rank
from 
	( select name, count(medal) as gold_medals, 
	  dense_rank() over(order by count(medal) desc ) as rank
	  from Olympics_History
	  where medal= 'Gold'
	  group by name) as Ranked_Athletics
where rank <=5;

--Question 11 Alternative Solution 

with t1 as
	(select name, count(medal) as total_medals
	from Olympics_History 
	where medal= 'Gold'
	group by name
	order by count(*) desc),
t2 as
	(select *, dense_rank() over(order by total_medals desc) as rnk
	  from t1)
select * 
from t2
where rnk <=5;

--Question 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)

select name, total_medals, ranking
from 
	(select name, count(medal) as total_medals,
	 dense_rank () over (order by count(medal) desc ) as ranking
	 from Olympics_history
	 where medal in ('Gold', 'Silver', 'Bronze')
	 group by name
	) as Ranked_Athletics
where ranking <=5;

--Question 12 Alternative Solution

with t1 as
         (select name, count(medal) as total_medals
           from olympics_history
           where medal in ('Gold', 'Silver', 'Bronze')
           group by name, team
           order by total_medals desc),
      t2 as
          (select *, dense_rank() over (order by total_medals desc) as ranking
           from t1)
select name, total_medals, ranking
from t2
where ranking <= 5;

--Question 13. Fetch the top 5 most successful countries in Olympics. Success is defined by no of medals won 

select nr.region as country,
	   count(distinct (oh.event, oh.year) ) as total_medals_in_all_events,
	 dense_rank() over (order by count(distinct oh.event) desc) as ranking
from Olympics_History as oh
join Olympics_History_noc_regions as nr
on oh.noc=nr.noc
where oh.medal in ('Gold', 'Silver', 'Bronze')
group by country
order by ranking
limit 5;

--Question 13 Alternative Solution 

with t1 as
            (select nr.region, count(distinct (oh.event, oh.year) ) as total_medals_in_all_events
            from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <> 'NA'
            group by nr.region
            order by total_medals_in_all_events desc),
       t2 as
            (select *, dense_rank() over(order by total_medals_in_all_events desc) as rnk
            from t1)
select *
from t2
where rnk <= 5;

--Question 14. List down total gold, silver, bronze medals won by each country  

select nr.region as country,
	   count(distinct case when medal= 'Gold' then (oh.event, oh.year) end) as gold_medals,
	   count(distinct case when medal= 'Silver' then (oh.event, oh.year) end) as silver_medals,
	   count(distinct case when medal= 'Bronze' then (oh.event, oh.year) end) as bronze_medals
from Olympics_History as oh
left join Olympics_History_noc_regions as nr
on oh.noc=nr.noc
group by country
order by gold_medals desc, silver_medals desc, bronze_medals desc;

--Question 15. List down total gold, silver and bronze medals won by each country corresponding to each Olympic game.

select oh.games,nr.region as country,
	   count(distinct case when medal= 'Gold' then (oh.event, oh.year) end) as gold_medals,
	   count(distinct case when medal= 'Silver' then (oh.event, oh.year) end) as silver_medals,
	   count(distinct case when medal= 'Bronze' then (oh.event, oh.year) end) as bronze_medals
from Olympics_History as oh
left join Olympics_History_noc_regions as nr
on oh.noc=nr.noc
group by oh.games, country
order by oh.games, country;

--Question 16. Which countries have never won gold medal but have won silver/bronze medals?

select nr.region as country,
	   count(distinct case when oh.medal='Gold' then (oh.event, oh.year) end) as Gold,
	   count(distinct case when oh.medal= 'Silver' then (oh.event, oh.year) end) as Silver,
	   count(distinct case when oh.medal= 'Bronze' then (oh.event, oh.year) end) as Bronze
from Olympics_History as oh
join Olympics_History_noc_regions as nr
on oh.noc=nr.noc
where oh.medal in ('Silver', 'Bronze') and nr.region not in (select nr.region
															from Olympics_History as oh
															right join Olympics_History_noc_regions as nr
															on oh.noc=nr.noc
															where oh.medal = 'Gold')
group by country
order by country;

--Question 17. In which Sport has team Nigeria won the highest medals?

select team, sport, count(distinct(event, year)) as total_medals
from Olympics_History
where medal <> 'NA' and team = 'Nigeria'
group by team, sport
order by total_medals desc
limit 1;

--Question 17 Alternative Solution

with t1 as
        (select team, sport, count(distinct(event, year)) as total_medals
        from olympics_history
        where medal <> 'NA'
        and team = 'Nigeria'
        group by team, sport
        order by total_medals desc),
     t2 as
        (select *, rank() over(order by total_medals desc) as rnk
         from t1)
select team, sport, total_medals
from t2
where rnk = 1;






