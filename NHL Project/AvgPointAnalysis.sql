
Select *
From stats2020_2021
order by 1, 9
;
--Using this CTE to calculate league average point total, could modify this to exclude players skewing data
--Useful for identifying the number of players on a team who contribute higher than league average scoring
--This is a strong indicator of offensive depth
With LeaguePointAVG1920 as
(
Select distinct Round(AVG(s1920.P), 2, 2) as AvgPts From HockeyStats..stats2019_2020 as s1920
), LeaguePointAVG2021 as
(
Select distinct Round(AVG(s2021.P), 2, 2) as AvgPts From HockeyStats..stats2020_2021 as s2021
)

--This is used to figure out how many players have higher point total than the average and counts them according to team
Select distinct s2021.Team as Team, avg2021.*, (Count(s2021.Name) Over (Partition by s2021.Team)) as OverAverageScoring From LeaguePointAVG2021 as avg2021
Join HockeyStats..stats2020_2021 as s2021
	On avg2021.AvgPts < s2021.P
	And s2021.Pos != 'G'
Order by OverAverageScoring desc
;


--Looking at totals by Position, Useful for generating a more detailed analysis of each team
--Using a temp table to calculate point total averages by position
Drop Table if exists #PointsByPosition
Create Table #PointsByPosition
(
Position nvarchar(255),
AvgPosPts1920 Numeric,
AvgPosPts2021 Numeric
)
Insert into #PointsByPosition
Select distinct s1920.Pos as Pos, Round((AVG(s1920.P) OVER (Partition by s1920.Pos)),2 , 2) as AvgPositionPts1920, Round((AVG(s2021.P) OVER (Partition by s2021.Pos)), 2, 2) as AvgPositionPts2021 
From HockeyStats..stats2019_2020 as s1920
Right Join HockeyStats..stats2020_2021 as s2021
	On s1920.Pos = s2021.Pos
	Where s1920.Pos != 'G'

--These average numbers help account for the difference in scoring ability and availabilty between Forwards and Defensemen
Select Distinct s2021.Team as Team, s2021.Pos as Pos, #PointsByPosition.AvgPosPts2021 as AvgPts, (Count(s2021.Name) Over (Partition by s2021.Team, s2021.Pos)) as OverPosAVG2021
From HockeyStats..stats2020_2021 as s2021
Right Join #PointsByPosition
	On s2021.P > #PointsByPosition.AvgPosPts2021
	and s2021.Pos = #PointsByPosition.Position
Order By OverPosAVG2021 Desc, Team



