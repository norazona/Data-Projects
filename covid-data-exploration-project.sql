--SELECT * 
--FROM CovidProject..CovidDeaths
--ORDER BY 3,4

--SELECT * 
--FROM CovidProject..CovidVaccinations
--ORDER BY 3,4

-- NUMBERS BY COUNTRIES

--Select the data that is going to be used
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL -- Filters out the continents from the location column
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE Location = 'United States'
	AND continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of the population got covid
SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS PopulationPercentageInfected
FROM CovidProject..CovidDeaths
WHERE Location = 'United States'
ORDER BY 1,2

-- Showing Countries with Highest Infection Rate per Population
SELECT Location
	,Population
	,MAX(total_cases) AS HighInfectionCount
	,MAX((total_cases/population))*100 AS CovidPercentageInfected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY 4 DESC

-- Showing Countries with Highest Death Count per Population
SELECT Location
	,Population
	,MAX(total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY 3 DESC

-- CONTINENT NUMBERS

-- Showing continents with the highest death count per population
SELECT continent
	,MAX(total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

--Correct way to do the above - Use the location column instead of continent
	-- This rolls it up to do nested reporting in a BI tool
SELECT location
	,Population
	,MAX(total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
AND location NOT LIKE '%income' -- Remove high income, middle income, and low income
GROUP BY Location, Population
ORDER BY 3 DESC

-- GLOBAL NUMBERS
SELECT date
	,SUM(new_cases) AS NewCases
	,SUM(new_deaths) AS NewDeaths
	,(SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
	AND new_deaths IS NOT NULL
	AND new_cases IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total Cases and Total Deaths Global
SELECT SUM(cast(new_cases as int)) AS NewCases -- cast - transforms one data type into another
	,SUM(new_deaths) AS NewDeaths
	,(SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations
SELECT deaths.continent
	, deaths.location
	, deaths.date
	, deaths.population
	, vaccs.new_vaccinations
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccs
	-- Use two fields as joining keys when there is not 1 unique one for both tables
	ON deaths.location = vaccs.location
	AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL
ORDER BY 1,2,3

-- Rolling Count of new_vaccinations in a new column
SELECT deaths.continent
	, deaths.location
	, deaths.date
	, deaths.population
	, vaccs.new_vaccinations
	, SUM(new_vaccinations) OVER (Partition by deaths.location Order by deaths.location, deaths.date)  AS rolling_count_vaccinations
	-- ^ Aggregates by location first and then orders by location and date
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccs
	-- Use two fields as joining keys when there is not 1 unique one for both tables
	ON deaths.location = vaccs.location
	AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL
ORDER BY 1,2,3

-- USE CTE to do a calculation on the created column - rolling_count_vaccinations
WITH PopulationvsVac (continent, location, date, population, new_vaccinations, rolling_count_vaccinations)
AS
(
SELECT deaths.continent
	, deaths.location
	, deaths.date
	, deaths.population
	, vaccs.new_vaccinations
	, SUM(new_vaccinations) OVER (Partition by deaths.location Order by deaths.location, deaths.date)  AS rolling_count_vaccinations
	-- ^ Aggregates by location first and then orders by location and date
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccs
	-- Use two fields as joining keys when there is not 1 unique one for both tables
	ON deaths.location = vaccs.location
	AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL
)
SELECT *
	, (rolling_count_vaccinations/population)*100 AS population_vaccinated
FROM 
PopulationvsVac

-- USE TEMP TABLE to do a calculation on the created column - rolling_count_vaccinations
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_count_vaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent
	, deaths.location
	, deaths.date
	, deaths.population
	, vaccs.new_vaccinations
	, SUM(new_vaccinations) OVER (Partition by deaths.location Order by deaths.location, deaths.date)  AS rolling_count_vaccinations
	-- ^ Aggregates by location first and then orders by location and date
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccs
	-- Use two fields as joining keys when there is not 1 unique one for both tables
	ON deaths.location = vaccs.location
	AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL

SELECT *
	, (rolling_count_vaccinations/population)*100 AS population_vaccinated
FROM 
#PercentPopulationVaccinated
WHERE Location LIKE 'United%'



-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated AS
SELECT deaths.continent
	, deaths.location
	, deaths.date
	, deaths.population
	, vaccs.new_vaccinations
	, SUM(new_vaccinations) OVER (Partition by deaths.location Order by deaths.location, deaths.date)  AS rolling_count_vaccinations
	-- ^ Aggregates by location first and then orders by location and date
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccs
	-- Use two fields as joining keys when there is not 1 unique one for both tables
	ON deaths.location = vaccs.location
	AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated