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
ORDER BY 1,2 asc;

-- Looking at Total Cases vs Total Deaths

EXEC sp_columns 'CovidDeaths';

SELECT 
    CAST(CASE 
            WHEN total_deaths is null THEN 0 
            ELSE total_deaths 
         END AS FLOAT) / 
    CAST(CASE 
            WHEN total_cases is null THEN 1 -- Avoid division by zero if cases are NULL
            ELSE total_cases 
         END AS FLOAT) AS case_fatality_rate
FROM 
    CovidDeaths
	;

-- Shows the likelihood of dying if infected (in your country of choice)

SELECT Location, DateOnly, total_cases, total_deaths, (SELECT 
    CAST(CASE 
            WHEN total_deaths is null THEN 0 
            ELSE total_deaths 
         END AS FLOAT) / 
    CAST(CASE 
            WHEN total_cases is null THEN 1 -- Avoids division by zero if cases are NULL
            ELSE total_cases 
         END AS FLOAT))*100 AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

--SELECT COUNT(*) AS null_count
--FROM CovidDeaths
--WHERE total_cases IS NULL;


--SELECT *, 
    --CAST(CASE 
            --WHEN total_deaths IS NULL THEN 0 
            --ELSE total_deaths 
         --END AS FLOAT) / 
    --CAST(CASE 
           --WHEN total_cases IS NULL THEN 1 
            --ELSE total_cases 
         --END AS FLOAT) AS case_fatality_rate
--FROM CovidDeaths
--WHERE total_cases IS NULL;


-- Looking at Total Cases vs Population

-- Shows percentage infected (in your country of choice)


SELECT Location, 
       DateOnly, 
       total_cases, 
       population, 
       (SELECT 
           CAST(CASE 
                   WHEN total_cases IS NULL THEN 0 
                   ELSE total_cases 
                END AS FLOAT) / 
           NULLIF(CAST(population AS FLOAT), 0) -- Returns NULL if population is NULL
        ) * 100 AS percentage_infected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;


-- Looking at countries with the highest infection rate (i.e. percentage_infected)

EXEC sp_columns 'CovidDeaths';

SELECT 
    Location,  
    MAX(CAST(total_cases AS BIGINT)) AS highest_infection_count, 
    population, 
    MAX((CAST(CASE 
                   WHEN total_cases IS NULL THEN 0 
                   ELSE total_cases 
                END AS FLOAT) / 
           NULLIF(CAST(population AS FLOAT), 0))) * 100 AS percentage_infected
FROM 
    PortfolioProject..CovidDeaths
	WHERE Location !='International'
	GROUP BY Location, population
ORDER BY 
    percentage_infected DESC;


-- Showing countries with the highest total death count

-- Breakdown by country

SELECT 
    Location,  
    max(COALESCE(CAST(total_deaths AS INT), 0)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent is not null
	GROUP BY Location
ORDER BY 
    total_death_count DESC;


-- Breakdown by continent

SELECT 
    location,  
    max(COALESCE(CAST(total_deaths AS INT), 0)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent is null
	GROUP BY location
ORDER BY 
    total_death_count DESC;

-- Since the data includes overlapping regions like EU, Europe and International...
-- The World total deaths and the sum of all other regions does not add up but this approach has been verified


--Showing the continents with the highest death count

SELECT DISTINCT continent FROM PortfolioProject..CovidDeaths;


SELECT 
    continent,  
    MAX(COALESCE(CAST(total_deaths AS INT), 0)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent is not null
	GROUP BY continent
ORDER BY 
    total_death_count DESC;


--SELECT continent, SUM(latest_deaths) AS sum_of_countries
--FROM (
    --SELECT continent, location, MAX(COALESCE(CAST(total_deaths AS INT), 0)) AS latest_deaths
    --FROM PortfolioProject..CovidDeaths
    --WHERE continent IS NOT NULL
    --GROUP BY continent, location
--) country_totals
--GROUP BY continent
--ORDER BY sum_of_countries DESC;


-- Global Numbers

SELECT DateOnly, SUM(CAST(new_cases AS INT)) as total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths,
CASE 
        WHEN SUM(CAST(new_cases AS INT)) > 0 
        THEN (SUM(CAST(new_deaths AS INT)) * 1.0 / NULLIF(SUM(CAST(new_cases AS INT)), 0)) * 100 
        ELSE 0
END AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY DateOnly
ORDER BY 1,2;

-- Global aggregate numbers

SELECT SUM(CAST(new_cases AS INT)) as total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths,
CASE 
        WHEN SUM(CAST(new_cases AS INT)) > 0 
        THEN (SUM(CAST(new_deaths AS INT)) * 1.0 / NULLIF(SUM(CAST(new_cases AS INT)), 0)) * 100 
        ELSE 0
END AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY DateOnly
ORDER BY 1,2;


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


-- Using CTE

With pop_vs_vac (continent, location,DateOnly,population,new_vaccinations, rolling_ppl_vaccinated)
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
Select *, (CAST(CASE 
            WHEN rolling_ppl_vaccinated is null THEN 0 
            ELSE rolling_ppl_vaccinated
         END AS FLOAT) / 
    CAST(CASE 
            WHEN population is null THEN 1 -- Avoids division by zero if cases are blank
            ELSE population 
         END AS FLOAT))*100
from pop_vs_vac
ORDER BY 2,3;


-- Temp table

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

select *, (CAST(CASE 
            WHEN rolling_ppl_vaccinated is null THEN 0 
            ELSE rolling_ppl_vaccinated
         END AS FLOAT) / 
    CAST(CASE 
            WHEN population is null THEN 1 -- Avoids division by zero if cases are blank
            ELSE population 
         END AS FLOAT))*100
from #percent_population_vaccinated
order by 2,3;


-- Calculate percentage of population vaccinated

Select *,
       (CAST(CASE 
                WHEN rolling_ppl_vaccinated IS NULL THEN 0 
                ELSE rolling_ppl_vaccinated
             END AS FLOAT) / 
        CAST(CASE 
                WHEN population IS NULL THEN 1 -- Avoids division by zero
                ELSE population 
             END AS FLOAT)) * 100 as percent_vaccinated
From #percent_population_vaccinated
Order By 2, 3;


-- Creating a view to store data for visualizations later

Create view percent_population_vaccinated as 
Select dea.continent,dea.location,dea.DateOnly,dea.population,vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.DateOnly) as rolling_ppl_vaccinated
From CovidDeaths dea
Join CovidVaccinations vac
on dea.location=vac.location
and dea.DateOnly=vac.DateOnly
WHERE dea.continent is not null

select *
from percent_population_vaccinated
order by 2,3
