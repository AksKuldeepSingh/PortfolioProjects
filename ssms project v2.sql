SELECT*
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4
;

--SELECT*
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4
--;

-- Changing date format

EXEC sp_rename 'CovidDeaths.date','test_date','COLUMN';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths' AND COLUMN_NAME = 'test_date';

SELECT CONVERT(VARCHAR(10), CAST(test_date AS DATE), 111) AS formatted_date
FROM CovidDeaths;

UPDATE CovidDeaths
SET test_date = CONVERT(VARCHAR(10), CAST(test_date AS DATE), 111);

-- Using formatted date

SELECT Location, test_date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths

SELECT 
    CAST(CASE 
            WHEN total_deaths = '' THEN 0 
            ELSE total_deaths 
         END AS FLOAT) / 
    CAST(CASE 
            WHEN total_cases = '' THEN 1 -- Avoid division by zero if cases are blank
            ELSE total_cases 
         END AS FLOAT) AS case_fatality_rate
FROM 
    CovidDeaths

--Shows the likelihood of dying if infected in your country

SELECT Location, test_date, total_cases, total_deaths, (SELECT 
    CAST(CASE 
            WHEN total_deaths = '' THEN 0 
            ELSE total_deaths 
         END AS FLOAT) / 
    CAST(CASE 
            WHEN total_cases = '' THEN 1 -- Avoids division by zero if cases are blank
            ELSE total_cases 
         END AS FLOAT))*100 AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at the Total Cases vs Population

--Shows percentage infected in your country

SELECT Location, test_date, total_cases, population, (SELECT 
    CAST(CASE 
            WHEN total_cases = '' THEN 0 
            ELSE total_cases 
         END AS FLOAT) / 
    CAST(CASE 
            WHEN population = '' THEN 1 -- Avoids division by zero if cases are blank
            ELSE population 
         END AS FLOAT))*100 AS percentage_infected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

--Shows percentage infected in all countries

SELECT 
    Location, 
    test_date, 
    total_cases, 
    population, 
    (CAST(CASE 
            WHEN total_cases = '' THEN 0 
            ELSE CAST(total_cases AS BIGINT) -- Explicitly cast to BIGINT first
         END AS FLOAT) / 
    CAST(CASE 
            WHEN population = '' THEN 1 -- Avoid division by zero if population is blank
            ELSE CAST(population AS BIGINT)
         END AS FLOAT)) * 100 AS percentage_infected
FROM 
    PortfolioProject..CovidDeaths
ORDER BY 
    1, 2;

-- Looking at countries with the highest Infection rate (i.e. percentage_infected)

SELECT 
    Location,  
    MAX(CAST(total_cases AS BIGINT)) AS highest_infection_count, 
    population, 
    MAX((CAST(CASE 
            WHEN total_cases = '' THEN 0 
            ELSE CAST(total_cases AS BIGINT) -- Explicitly cast to BIGINT first
         END AS FLOAT) / 
    CAST(CASE 
            WHEN population = '' THEN 1 -- Avoid division by zero if population is blank
            ELSE CAST(population AS BIGINT)
         END AS FLOAT))) * 100 AS percentage_infected
FROM 
    PortfolioProject..CovidDeaths
	WHERE Location !='International'
	GROUP BY Location, population
ORDER BY 
    percentage_infected DESC;

-- Showing countries with the highest death count per population

--Breakdown by country

SELECT 
    Location,  
    MAX(CAST(total_deaths as INT)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent !='' -- Where continent is not blank
	GROUP BY Location
ORDER BY 
    total_death_count DESC;

-- Breakdown by continent

SELECT 
    location,  
    MAX(CAST(total_deaths as INT)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent ='' -- Where continent is blank
	GROUP BY location
ORDER BY 
    total_death_count DESC;

--Showing the continents with the highest death count

SELECT 
    continent,  
    MAX(CAST(total_deaths as INT)) AS total_death_count
FROM 
    PortfolioProject..CovidDeaths
	WHERE continent !='' -- Where continent is not blank
	GROUP BY continent
ORDER BY 
    total_death_count DESC;

--Global Numbers

SELECT test_date, SUM(CAST(new_cases AS INT)) as total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths,
CASE 
        WHEN SUM(CAST(new_cases AS INT)) > 0 
        THEN (SUM(CAST(new_deaths AS INT)) * 1.0 / NULLIF(SUM(CAST(new_cases AS INT)), 0)) * 100 
        ELSE 0
END AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent !=''
GROUP BY test_date
ORDER BY 1,2

--Global aggregate numbers

SELECT SUM(CAST(new_cases AS INT)) as total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths,
CASE 
        WHEN SUM(CAST(new_cases AS INT)) > 0 
        THEN (SUM(CAST(new_deaths AS INT)) * 1.0 / NULLIF(SUM(CAST(new_cases AS INT)), 0)) * 100 
        ELSE 0
END AS case_fatality_rate
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent !=''
--GROUP BY test_date
ORDER BY 1,2

--Covid Vaccinations
--Formatting date...again

EXEC sp_rename 'CovidVaccinations.date','test_date','COLUMN';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidVaccinations' AND COLUMN_NAME = 'test_date'; 

SELECT CONVERT(VARCHAR(10), CAST(test_date AS DATE), 111) AS formatted_date
FROM CovidVaccinations;

UPDATE CovidVaccinations
SET test_date = CONVERT(VARCHAR(10), CAST(test_date AS DATE), 111)

--Looking at total population vs vaccinations

Select dea.continent,dea.location,dea.test_date,dea.population,vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.test_date) as rolling_ppl_vaccinated
--,(rolling_ppl_vaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
on dea.location=vac.location
and dea.test_date=vac.test_date
WHERE dea.continent!=''
ORDER BY 2,3

--use CTE

With pop_vs_vac (continent, location,test_date,population,new_vaccinations, rolling_ppl_vaccinated)
as
(
Select dea.continent,dea.location,dea.test_date,dea.population,vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.test_date) as rolling_ppl_vaccinated
--,(rolling_ppl_vaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
on dea.location=vac.location
and dea.test_date=vac.test_date
WHERE dea.continent!=''
--ORDER BY 2,3
)
Select *, (CAST(CASE 
            WHEN rolling_ppl_vaccinated = '' THEN 0 
            ELSE rolling_ppl_vaccinated
         END AS FLOAT) / 
    CAST(CASE 
            WHEN population = '' THEN 1 -- Avoids division by zero if cases are blank
            ELSE population 
         END AS FLOAT))*100
from pop_vs_vac
ORDER BY 2,3

--Temp table

DROP TABLE IF EXISTS #percent_population_vaccinated;

Create Table #percent_population_vaccinated
(
    continent nvarchar(255), 
    location nvarchar(255),
    test_date datetime,
    population numeric,
    new_vaccinations numeric,
    rolling_ppl_vaccinated numeric
);

-- Insert data with conversions and handling non-numeric values
Insert into #percent_population_vaccinated
Select dea.continent,
       dea.location,
       dea.test_date,
       dea.population,
       TRY_CAST(vac.new_vaccinations AS numeric) as new_vaccinations,
       SUM(TRY_CAST(vac.new_vaccinations AS numeric)) 
           OVER (Partition by dea.location 
                 Order by dea.location, dea.test_date) as rolling_ppl_vaccinated
From CovidDeaths dea
Join CovidVaccinations vac
    on dea.location = vac.location
    and dea.test_date = vac.test_date
--Where dea.continent != ''
  AND TRY_CAST(vac.new_vaccinations AS numeric) IS NOT NULL -- Filter out non-numeric data

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

--Creating view to store data for visualizations later
Create view percent_population_vaccinated as 
Select dea.continent,dea.location,dea.test_date,dea.population,vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.test_date) as rolling_ppl_vaccinated
--,(rolling_ppl_vaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
on dea.location=vac.location
and dea.test_date=vac.test_date
WHERE dea.continent!=''
--ORDER BY 2,3

select *
from percent_population_vaccinated
order by 2,3