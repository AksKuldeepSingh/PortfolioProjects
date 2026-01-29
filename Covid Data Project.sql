--USE master;
--ALTER DATABASE Portfolio_Project SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--DROP DATABASE Portfolio_Project;

--Create database portfolio_project;

use portfolio_project;

--SELECT *
--FROM dbo.CovidDeaths
--order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from dbo.CovidDeaths
order by 1, 2;

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where location like '%states%'
order by 1, 2;


select location, date, population, total_cases, (total_cases/population)*100 as InfectionRate
from dbo.CovidDeaths
where location like '%states%'
order by 1, 2;


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


SELECT *
FROM dbo.CovidDeaths
where continent is not null
order by 3,4;


select location, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc;


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


select continent, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc;


select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
group by date
order by 1, 2;


select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
--group by date
order by 1, 2;


select * 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date;


select dea.continent, dea.location, dea.date, vac.date, dea.population, vac.new_vaccinations 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
order by 2, 3;


-- Rolling count
select dea.continent, dea.location, dea.date, vac.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location order by dea.location,
	dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
order by 2, 3;


-- CTE
with PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location order by dea.location,
	dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100 as PercentPeopleVaccinated
from PopvsVac
order by 2, 3;


-- Temp Table
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


-- Views

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc;


CREATE VIEW PercentPopVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location order by dea.location,
	dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
-- order by 2, 3
;


select * from dbo.PercentPopVaccinated
order by 2,3;
