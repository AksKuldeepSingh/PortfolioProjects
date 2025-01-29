-- The dataset contains global Covid deaths and vaccinations data

SELECT*
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4
;

SELECT*
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4
;

-- Changing date format to YYYY-MM-DD

SELECT CAST(date AS DATE) AS DateOnly
FROM PortfolioProject.dbo.CovidDeaths;

ALTER TABLE PortfolioProject.dbo.CovidDeaths
ADD DateOnly DATE;

UPDATE PortfolioProject.dbo.CovidDeaths
SET DateOnly = CAST(date AS DATE);

SELECT date, DateOnly
FROM PortfolioProject.dbo.CovidDeaths;

-- Using formatted date

SELECT Location, DateOnly, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths (Case Fatality Rate)

EXEC sp_columns 'CovidDeaths';

SELECT 
    CAST(total_deaths AS FLOAT) / 
    CAST(total_cases AS FLOAT) AS case_fatality_rate
FROM 
    CovidDeaths
	;

-- Shows the likelihood of dying if infected (in your country of choice)

SELECT Location, DateOnly, total_cases, total_deaths, (SELECT 
    CAST(total_deaths AS FLOAT) / 
    CAST(total_cases AS FLOAT))*100 AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;


-- Looking at Total Cases vs Population (Infection Rate)

SELECT population, total_cases, 
    CAST(total_cases AS FLOAT) / 
    CAST(population AS FLOAT) AS percentage_infected
FROM 
    CovidDeaths
	order by 3 desc
	;

-- Shows percentage infected (in your country of choice)


SELECT Location, DateOnly, total_cases, population, 
       (SELECT 
           CAST(total_cases AS FLOAT) / 
           CAST(population AS FLOAT)
        )* 100 AS percentage_infected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;


-- Looking at countries with the highest infection rate (i.e. percentage_infected)

EXEC sp_columns 'CovidDeaths';

SELECT 
    Location, MAX(CAST(total_cases AS INT)) AS highest_infection_count, population, 
    MAX(CAST(total_cases AS FLOAT) / 
           CAST(population AS FLOAT))* 100 AS percentage_infected
FROM 
    PortfolioProject..CovidDeaths
	--WHERE Location !='International'
	GROUP BY Location, population
ORDER BY 4 DESC;


-- Showing countries with the highest total death count

-- Breakdown by country --

SELECT 
    Location,  
    max(CAST(total_deaths AS INT)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent is not null
	GROUP BY Location
ORDER BY 2 DESC;


-- Breakdown by continent --

SELECT 
    location,  
    max(CAST(total_deaths AS INT)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent is null
	GROUP BY location
ORDER BY 2 DESC;


-- Showing the continents with the highest death count

SELECT DISTINCT continent FROM PortfolioProject..CovidDeaths;


SELECT 
    continent,  
    MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent is not null
	GROUP BY continent
ORDER BY 2 DESC;


-- Global Numbers --

SELECT DateOnly, SUM(CAST(new_cases AS INT)) as total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths,
SUM(CAST(new_deaths AS FLOAT))/ SUM(CAST(new_cases AS FLOAT))* 100 AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY DateOnly
ORDER BY 1;

-- Global aggregate numbers --

SELECT SUM(CAST(new_cases AS INT)) as total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths,
SUM(CAST(new_deaths AS FLOAT))/ SUM(CAST(new_cases AS FLOAT))* 100 AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null


-- Covid Vaccinations

-- Formatting date to YYYY-MM-DD

SELECT CAST(date AS DATE) AS DateOnly
FROM PortfolioProject.dbo.CovidVaccinations;

ALTER TABLE PortfolioProject.dbo.CovidVaccinations
ADD DateOnly DATE;

UPDATE PortfolioProject.dbo.CovidVaccinations
SET DateOnly = CAST(date AS DATE);

SELECT date, DateOnly
FROM PortfolioProject.dbo.CovidVaccinations;


-- Looking at total population vs vaccinations

Select dea.continent,dea.location,dea.DateOnly,dea.population,vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.DateOnly) as rolling_ppl_vaccinated
From CovidDeaths dea
Join CovidVaccinations vac
on dea.location=vac.location
and dea.DateOnly=vac.DateOnly
WHERE dea.continent is not null
ORDER BY 2,3;


-- Using Common Table Expression (CTE)

With pop_vs_vac (continent, location, DateOnly, population, new_vaccinations, rolling_ppl_vaccinated)
as
(
Select dea.continent,dea.location,dea.DateOnly,dea.population,vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.DateOnly) as rolling_ppl_vaccinated
From CovidDeaths dea
Join CovidVaccinations vac
on dea.location=vac.location
and dea.DateOnly=vac.DateOnly
WHERE dea.continent is not null
)
Select *, (CAST(rolling_ppl_vaccinated AS FLOAT) / 
    CAST(population AS FLOAT))*100 AS percent_vaccinated
from pop_vs_vac
ORDER BY 2,3;


-- Temp table can be useful as it can be queried without having to touch the original table(s)

DROP TABLE IF EXISTS #percent_population_vaccinated;
Create Table #percent_population_vaccinated
(
    continent nvarchar(255), 
    location nvarchar(255),
    DateOnly datetime,
    population numeric,
    new_vaccinations numeric,
    rolling_ppl_vaccinated numeric
)
Insert into #percent_population_vaccinated
Select dea.continent, dea.location, dea.DateOnly, dea.population, vac.new_vaccinations
, SUM(Convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.DateOnly) as rolling_ppl_vaccinated
From CovidDeaths dea
Join CovidVaccinations vac
    on dea.location = vac.location
    and dea.DateOnly = vac.DateOnly

select *, (CAST(rolling_ppl_vaccinated AS FLOAT) / 
    CAST(population AS FLOAT))*100 AS percent_vaccinated
from #percent_population_vaccinated
where continent is not null
order by 2,3;


-- Calculate percentage of population that is vaccinated

Select *,
       (CAST(rolling_ppl_vaccinated AS FLOAT) / 
        CAST(population AS FLOAT)) * 100 as percent_vaccinated
From #percent_population_vaccinated
where continent is not null
Order By 2, 3;


-- Creating a view to store data for visualizations later

CREATE VIEW percent_population_vaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.DateOnly,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.DateOnly
    ) AS rolling_ppl_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.DateOnly = vac.DateOnly
WHERE dea.continent IS NOT NULL;

select *
from percent_population_vaccinated
order by 2,3;
