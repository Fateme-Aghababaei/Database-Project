use proj_2;
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
-- ............................................................................................

-- Question1
with goals_num(Player_Id, goals_number)
AS (select  Player_Id,count(Player_Id) as goals_number
from goal
group by Player_Id  )

select Player_Id,Name,max(goals_number) as number_of_goals
from goals_num  join human  on goals_num.Player_Id=human.Id
where goals_num.goals_number=
      (
          select max(goals_number)
          from goals_num
          );
-- ............................................................................................

-- Question2

WITH Refs_Team (Id, Ref_Id) AS (
	SELECT Id, Head_Id AS Ref_Id FROM referee_team
    UNION ALL
    SELECT Id, Assistant1_Id AS Ref_Id FROM referee_team
    UNION ALL
    SELECT Id, Assistant2_Id AS Ref_Id FROM referee_team
    UNION ALL
    SELECT Id, Fourth_Id AS Ref_Id FROM referee_team
    UNION ALL
    SELECT Id, Var_Id AS Ref_Id FROM referee_team
),
Ref_Match_Count (Name, Match_Count) AS (
	SELECT human.Name, COUNT(Refs_Team.Ref_Id) AS Match_Count
	FROM game
	JOIN Refs_Team ON game.Referee_Team_Id = Refs_Team.Id
	JOIN human ON Refs_Team.Ref_Id = human.Id
	GROUP BY Refs_Team.Ref_Id
)
SELECT Name, Match_Count
FROM Ref_Match_Count
WHERE Match_Count = (
	SELECT Max(Match_Count) FROM Ref_Match_Count
);


-- ................................................................................................

-- Question3
WITH goals_time(player_id,time)
AS(SELECT distinct player_id , time
FROM goal
WHERE time>80)
SELECT player_id,name
FROM goals_time JOIN Human ON goals_time.player_id = Human.id;
-- ............................................................................................

-- Question4
WITH Penalty(Match_id, Stadium_id, Goals_num) AS (
	SELECT Match_id, Stadium_id, COUNT(Stadium_id) AS Goals_num
    FROM Goal JOIN Game On Goal.Match_id = Game.Id
    WHERE Goal.is_penalty = 1
    GROUP BY Stadium_id
)

SELECT Stadium_id, Name 
FROM Penalty JOIN stadium On Penalty.Stadium_id = stadium.Id
WHERE Goals_num = (
	SELECT MIN(Goals_num) FROM Penalty
);
-- .............................................................................................

-- Question5
select Name , age,Player_Id
from human join goal on human.Id=goal.Player_Id
where  human.Age =
       (
           select   max(Age)
           from human join goal on human.Id=goal.Player_Id
           );
-- ..............................................................................................

-- Question6
WITH Subs(sub_nums) AS (
	SELECT COUNT(Match_Id) AS sub_nums
	FROM substitute
	GROUP BY Match_Id
	HAVING sub_nums < 5
)
SELECT COUNT(sub_nums) AS count
FROM Subs;

-- ..............................................................................................

-- Question7
SELECT DISTINCT Name, Capacity
FROM game JOIN Stadium ON game.Stadium_Id = Stadium.Id
WHERE (Team1_Id = 'T-03' OR Team2_Id = 'T-03' OR Team1_Id = 'T-28' OR Team2_Id = 'T-28') AND (Stage != 'group stage');

-- ..............................................................................................

-- Question8
WITH First_Half_Goals(Match_Id, First_Goals) AS (
	SELECT Match_Id, COUNT(Match_Id) AS First_Goals
    FROM goal
    WHERE Time <= 45
    GROUP BY Match_Id
),
Second_Half_Goals(Match_Id, Second_Goals) AS (
	SELECT Match_Id, COUNT(Match_Id) AS Second_Goals
    FROM goal
    WHERE Time > 45
    GROUP BY Match_Id
)
SELECT First_Half_Goals.Match_Id, First_Goals, Second_Goals
FROM First_Half_Goals LEFT JOIN Second_Half_Goals ON First_Half_Goals.Match_Id = Second_Half_Goals.Match_Id
WHERE First_Goals > Second_Goals;

-- ..............................................................................................

-- Question9
WITH Team_Match_Goals AS (
	SELECT player.Team_Id, goal.Match_Id, COUNT(*) AS Goals
    FROM goal JOIN player ON goal.Player_Id = player.Id
    GROUP BY player.Team_Id, goal.Match_Id
)
SELECT Team_Id, AVG(Goals) AS Average_Goals
FROM Team_Match_Goals
GROUP BY Team_Id
ORDER BY Average_Goals DESC;

-- ..............................................................................................

-- Question10
WITH Refs_Team (Id, Ref_Id) AS (
	SELECT Id, Head_Id AS Ref_Id FROM referee_team
    UNION ALL
    SELECT Id, Assistant1_Id AS Ref_Id FROM referee_team
    UNION ALL
    SELECT Id, Assistant2_Id AS Ref_Id FROM referee_team
    UNION ALL
    SELECT Id, Fourth_Id AS Ref_Id FROM referee_team
    UNION ALL
    SELECT Id, Var_Id AS Ref_Id FROM referee_team
)
SELECT human.Name, COUNT(Refs_Team.Ref_Id) AS Penalty_Goals
FROM goal
JOIN game ON goal.Match_Id = game.Id
JOIN Refs_Team ON game.Referee_Team_Id = Refs_Team.Id
JOIN human ON Refs_Team.Ref_Id = human.Id
WHERE goal.Is_Penalty = 1
GROUP BY Refs_Team.Ref_Id;

-- ..............................................................................................

-- Question11
SELECT team.Name
FROM coach JOIN human ON coach.Id = human.Id JOIN team ON coach.Team_id = team.Id
WHERE human.Nationality = team.Nationality;

-- ..............................................................................................

-- Question12
WITH Best_Players(Name, Best_Player_Count) AS (
	SELECT human.Name, COUNT(game.Best_Player_Id) AS Best_Player_Count
	FROM game JOIN human ON game.Best_Player_Id = human.Id
    GROUP BY game.Best_Player_Id
)
SELECT Name
FROM Best_Players
WHERE Best_Player_Count = (
	SELECT Max(Best_Player_Count) FROM Best_Players
);

-- ..............................................................................................

-- Question13
WITH Next_Stage_Teams AS (
	SELECT DISTINCT team.Name
	FROM team JOIN game ON team.Id = game.Team1_Id OR team.Id = game.Team2_Id
	WHERE game.Stage != 'group stage'
)
SELECT human.Name
FROM team LEFT JOIN Next_Stage_Teams ON team.Name = Next_Stage_Teams.Name
JOIN coach ON team.Id = coach.team_Id
JOIN human ON coach.Id = human.Id
WHERE Next_Stage_Teams.Name IS NULL;

-- ..............................................................................................

-- Question14
WITH Team_Cards AS (
	SELECT team.Name, COUNT(player.Team_Id) AS Card_Count
	FROM card JOIN player ON card.Player_Id = player.Id JOIN team ON player.Team_Id = team.Id
	GROUP BY player.Team_Id
)
SELECT Name, Card_Count
FROM Team_Cards
WHERE Card_Count = (
	SELECT MAX(Card_Count) FROM Team_Cards
);

-- ..............................................................................................

-- Question15
SELECT DISTINCT human.Name
FROM substitute JOIN goal ON substitute.Match_Id = goal.Match_Id JOIN human ON goal.Player_Id = human.Id
WHERE substitute.Player_Id_In = goal.Player_Id AND substitute.Time < goal.Time;

-- ..............................................................................................

-- Question16
SELECT team.Name
FROM card
JOIN game ON card.Match_Id = game.Id
JOIN player ON card.Player_Id = player.Id
JOIN team ON player.Team_Id = team.Id
WHERE card.Color = 'red' AND player.Team_Id = (CASE 
	WHEN game.Team1_Goals > game.Team2_Goals THEN game.Team1_Id
    WHEN game.Team1_Goals < game.Team2_Goals THEN game.Team2_Id
END);

-- ..............................................................................................

-- Question17
WITH Non_Native_Coach AS (
	SELECT human.Name AS Coach_Name, human.Nationality AS Coach_Nationality
    FROM coach
    JOIN human ON coach.Id = human.Id
    JOIN team ON coach.Team_id = team.Id
    WHERE human.Nationality != team.Nationality
)
SELECT Coach_Name, Coach_Nationality
FROM Non_Native_Coach JOIN team ON Non_Native_Coach.Coach_Nationality = team.Nationality