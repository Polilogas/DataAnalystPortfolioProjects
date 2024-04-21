/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Windows Functions, Aggregate Functions, Converting Data Types

*/

-- Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From [COVID19-PortfolioProject]..CovidDeaths
Where continent IS NOT NULL
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID-19 in your country
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS DECIMAL) / CAST(total_cases AS DECIMAL)) * 100 AS  death_percentage_of_cases
FROM [COVID19-PortfolioProject]..CovidDeaths
WHERE location = 'Greece' AND total_cases IS NOT NULL AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at the Total Cases vs Population
-- Shows what percentage of the population that got infected with COVID-19
SELECT location, date, total_cases, population, (total_cases / population) * 100 AS covid_infection_rate
FROM [COVID19-PortfolioProject]..CovidDeaths
WHERE location = 'Greece' AND total_cases IS NOT NULL AND continent IS NOT NULL
ORDER BY 1, 2


-- Countries with the highest infection rate compared to its population
WITH CTE_CovidCases AS (
	SELECT location, total_cases, population, (total_cases / population) * 100 AS covid_infection_rate
	FROM [COVID19-PortfolioProject]..CovidDeaths
	WHERE total_cases IS NOT NULL AND continent IS NOT NULL
)
SELECT location, MAX(covid_infection_rate) AS highest_infaction_rate
FROM CTE_CovidCases
GROUP BY location, population
ORDER BY highest_infaction_rate DESC


-- Showing countries with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathsCount
FROM [COVID19-PortfolioProject]..CovidDeaths
WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathsCount DESC

-- Showing the total deaths from each country compared to their population density
WITH LatestDatePerCountry AS (
    SELECT location, MAX(date) AS latest_date
    FROM [COVID19-PortfolioProject]..CovidVaccinations
    WHERE population_density IS NOT NULL
    GROUP BY location
)

SELECT vac.location, vac.date, vac.population_density, dea.total_deaths
FROM LatestDatePerCountry AS ldc
JOIN [COVID19-PortfolioProject]..CovidVaccinations AS vac
    ON ldc.location = vac.location
    AND ldc.latest_date = vac.date
JOIN [COVID19-PortfolioProject]..CovidDeaths AS dea
    ON ldc.location = dea.location
    AND ldc.latest_date = dea.date
ORDER BY vac.population_density DESC;


-- ~~~~~~~~~ BREAKDOWN BY CONTINENTS ~~~~~~~~~

-- Showing continent's total death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathsCount
FROM [COVID19-PortfolioProject]..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income'
GROUP BY location
ORDER BY TotalDeathsCount DESC


-- ~~~~~~~~~ GLOBAL NUMBERS ~~~~~~~~~

-- Total death percentage in the world
SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/ SUM(new_cases) * 100 AS DeathPercentage
FROM [COVID19-PortfolioProject]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- TEMP TABLE 
-- Countries with the highest infection rate compared to its population

DROP TABLE IF EXISTS #HighestInfectedCountries
CREATE TABLE #HighestInfectedCountries (
	location nvarchar(255),
	total_cases nvarchar(255),
	population float
)

INSERT INTO #HighestInfectedCountries (location, total_cases, population)
	SELECT location, 
	MAX(CONVERT(INT, total_cases)) AS total_cases,
	MAX((total_cases / population) * 100)  AS highest_infaction_rate
	FROM [COVID19-PortfolioProject]..CovidDeaths
	WHERE total_cases IS NOT NULL AND continent IS NOT NULL
	GROUP BY location, population

SELECT location, population AS highest_infaction_rate
FROM #HighestInfectedCountries
ORDER BY population DESC 



-- ~~~~~~~~~ CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATIONS ~~~~~~~~~

-- Showing countries with the highest death count per population
CREATE VIEW DeathCountPerCountry AS
	SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathsCount
	FROM [COVID19-PortfolioProject]..CovidDeaths
	WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
	GROUP BY location



-- Shows the likelihood of dying if you contract COVID-19 in your country
CREATE VIEW CaseFatalityRate AS
	SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS DECIMAL) / CAST(total_cases AS DECIMAL)) * 100 AS  death_percentage_of_cases
	FROM [COVID19-PortfolioProject]..CovidDeaths
	WHERE total_cases IS NOT NULL AND continent IS NOT NULL


-- Shows what percentage of the population that got infected with COVID-19
CREATE VIEW InfactionRate AS 
	SELECT location, date, total_cases, population, (total_cases / population) * 100 AS covid_infection_rate
	FROM [COVID19-PortfolioProject]..CovidDeaths
	WHERE total_cases IS NOT NULL AND continent IS NOT NULL

-- Showing continent's total death count
CREATE VIEW ContinentDeathCount AS
	SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathsCount
	FROM [COVID19-PortfolioProject]..CovidDeaths
	WHERE continent IS NULL AND location NOT LIKE '%income'
	GROUP BY location

-- Total death percentage in the world
CREATE VIEW WorldCovidData AS
	SELECT 
		SUM(new_cases) AS total_cases, 
		SUM(CAST(new_deaths AS INT)) AS total_deaths,
		SUM(CAST(new_deaths AS INT))/ SUM(new_cases) * 100 AS DeathPercentage
	FROM [COVID19-PortfolioProject]..CovidDeaths
	WHERE continent IS NOT NULL
