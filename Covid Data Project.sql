-- This project conducts exploratory data analysis on covid deaths and vaccinations dataset 
-- containing 85,000+ records of deaths annd vaccinations for each country grouped by date
-- The analysis calculates variables like death percentage, infection rate, total death count and rolling totals
-- It incorporates advanced SQL concepts like CTEs, window functions, temp tables and subqueries
-- The analysis has been done at a global level but can be done for a single country as well

--USE master;
--ALTER DATABASE Portfolio_Project SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--DROP DATABASE Portfolio_Project;

--Create database portfolio_project;

use portfolio_project;

SELECT *
FROM dbo.CovidDeaths
order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from dbo.CovidDeaths
order by 1, 2;

-- Calculating death percentage as total deaths divided by the total no. of cases. It tells us how fatal covid was
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from dbo.CovidDeaths
--where location like '%states%'
order by 1, 2;

-- Calculating infection rate as total cases divided by total poulation. It tells us how much the infection has spread
select location, date, population, total_cases, (total_cases/population)*100 as InfectionRate
from dbo.CovidDeaths
--where location like '%states%'
order by 1, 2;

-- List countries according to infection rate in descending order
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as InfectionRate
from dbo.CovidDeaths
--where location like '%states%'
group by location, population
order by InfectionRate desc;


select location, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
--where location like '%states%'
group by location
order by TotalDeathCount desc;
-- There are some data inconsistencies in location

--SELECT *
--FROM dbo.CovidDeaths
--where continent is not null
--order by 3,4;

-- Returns total death count for each country and excludes values like World, North America which came up in previous query
select location, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc;

-- Returns total death count for each continent
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc;


select location, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is null
group by location
order by TotalDeathCount desc;
-- European Union is included in Europe's total death count

-- Calculates death percentage as total deaths divided by total cases for each date
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths 
, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
group by date
order by 1, 2;

-- Returns global death percentage
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths
, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
--group by date
order by 1, 2;


--select * 
--from dbo.CovidDeaths as dea
--join dbo.CovidVaccinations as vac
--on dea.location = vac.location
--and dea.date = vac.date;

select dea.continent, dea.location, dea.date, vac.date, dea.population, vac.new_vaccinations 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
order by 2, 3;


-- Rolling count using window function
select dea.continent, dea.location, dea.date, vac.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location order by dea.location,
	dea.date) as RollingPeopleVaccinated 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
order by 2, 3;


-- Using CTE to calculate % of population that has been vaccinated
with PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location order by dea.location,
	dea.date) as RollingPeopleVaccinated 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100 as PercentPeopleVaccinated
from PopvsVac
order by 2, 3;


-- Using Temp Table
-- In Microsoft SQL Server, a table name starting with # is a local temporary table
DROP TABLE IF EXISTS #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
continent nvarchar(255), location nvarchar(255), date datetime, population numeric,
New_Vaccinations numeric, RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location order by dea.location,
	dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null

select *, (RollingPeopleVaccinated/population)*100 as PercentPeopleVaccinated
from #PercentPopVaccinated
order by 2, 3;


-- Using Views

--select continent, max(cast(total_deaths as int)) as TotalDeathCount
--from dbo.CovidDeaths
--where continent is not null
--group by continent
--order by TotalDeathCount desc;


CREATE VIEW PercentPopVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location order by dea.location,
	dea.date) as RollingPeopleVaccinated 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
;


select * from dbo.PercentPopVaccinated
order by 2,3;