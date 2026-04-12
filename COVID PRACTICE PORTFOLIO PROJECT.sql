SELECT * 
FROM PortfolioProject.dbo.CovidDeaths
-- SOME CONTINENTS HAVE NULL VALUES IN THE CONTINENTS COLUMN & CONTINENT AS LOCATION, SO I AM USING IS NOT NULL TO DISPLAY ONLY THE COUNTRIES WITH CONTINENT DATA
WHERE continent IS NOT NULL	
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4

--SELECT THE DATA TO BE USED IN THE ANALYSIS
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL	
ORDER BY 1,2


--ANALYSING THE DATA OF TOTAL CASES AND DEATHS 
--death_ratePercentage = (total_deaths/total_cases)*100 shows the percentage of people who died from the total cases
SELECT location, date, total_cases,  total_deaths, (total_deaths/total_cases)*100 AS death_ratePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location IN ('United States', 'India', 'Brazil', 'Russia', 'United Kingdom')
ORDER BY 1,2

-- ANALYSING THE DATA OF TOTAL CASES AND DEATHS IN NIGERIA
SELECT location, date, total_cases,  total_deaths, (total_deaths/total_cases)*100 AS death_ratePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE 'Nigeria'
ORDER BY 1,2


-- ANALYSING THE DATA OF TOTAL CASES vs POPULATION IN NIGERIA
--cases_per_populationPercentage = (total_cases/population)*100 shows the percentage of people who got infected from the total population

SELECT location, date, population, total_cases,  (total_cases/population)*100 AS cases_per_populationPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE 'Nigeria'
ORDER BY 1,2


-- ANALYSING COUNTRIES WITH HIGHEST COVID CASE RATES COMPARED TO POPULATION
SELECT location, population,  MAX(total_cases) AS HighestCovidCount , MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL	
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC


-- ANALYSING COUNTRIES WITH HIGHEST COVID DEATH RATES 
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCountPerCountry 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL	
GROUP BY location
ORDER BY TotalDeathCountPerCountry DESC

-- ANALYSING CONTINENT WITH HIGHEST COVID DEATH RATES

SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeathCountPerContinent
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL	
GROUP BY continent
ORDER BY TotalDeathCountPerContinent DESC

SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCountPerContinent
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL	
GROUP BY location
ORDER BY TotalDeathCountPerContinent DESC


-- GLOBAL COVID BREAKDOWN 
SELECT SUM(new_cases) as total_new_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS global_death_ratePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- JOINS
-- INNER JOIN
SELECT * 
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL

-- JOINS TO ANALYSE TOTAL POPULATION VS  VACCINATIONS PER DAY
SELECT CD.continent, CD.location, CD.date, CD.population,CV.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY CD.location, CD.date

-- PARTITIONING BY  TO ANALYSE THE TREND OF NEW VACCINATIONS PER DAY IN EACH COUNTRY
-- BY DATE
SELECT CD.continent, CD.location, CD.date, CD.population,CV.new_vaccinations, SUM(CONVERT(int, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.date) AS cumulative_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY CD.location, CD.date

-- BY LOCATION
-- commenting out the percentage_vaccinated column because it is giving an error of invalid column name cumulative_vaccinations, even though I have defined it in the select statement, I think it is because I am trying to use a column alias in the same select statement which is not allowed in SQL Server, so I will have to use a CTE to be able to use the cumulative_vaccinations column in the calculation of percentage_vaccinated
SELECT CD.continent, CD.location, CD.date, CD.population,CV.new_vaccinations, SUM(CONVERT(int, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location) AS cumulative_vaccinations --, (cumulative_vaccinations/population)*100 AS percentage_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY CD.location, CD.date

-- CTE - ANALYSING THE TREND OF NEW VACCINATIONS PER DAY IN EACH COUNTRY
WITH POPULATION_VACCINATION  (continent, location, date, population, new_vaccinations,cumulative_vaccinations)
AS
(
SELECT CD.continent, CD.location, CD.date, CD.population,CV.new_vaccinations, SUM(CONVERT(int, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location) AS cumulative_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT *, (cumulative_vaccinations/population)*100 AS percentage_vaccinated
FROM POPULATION_VACCINATION


-- TEMPORAL ANALYSIS OF COVID VACCINATIONS 
-- CREATE A TEMPORARY TABLE TO ANALYSE THE TREND OF NEW VACCINATIONS PER DAY IN EACH COUNTRY
DROP TABLE IF EXISTS #Population_Vaccination_Percentage
CREATE TABLE #Population_Vaccination_Percentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population float,
new_vaccinations numeric,
cumulative_vaccinations numeric
)
INSERT INTO #Population_Vaccination_Percentage
SELECT CD.continent, CD.location, CD.date, CD.population,CV.new_vaccinations, SUM(CONVERT(int, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location) AS cumulative_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
ON CD.location = CV.location AND CD.date = CV.date
--WHERE CD.continent IS NOT NULL

SELECT *, (cumulative_vaccinations/population)*100 AS percentage_vaccinated
FROM #Population_Vaccination_Percentage


-- DATA VIEWS CREATION FOR VISUALIZATION PURPOSES
CREATE VIEW vw_CovidPopulation_Vaccination AS
SELECT CD.continent, CD.location, CD.date, CD.population,CV.new_vaccinations, SUM(CONVERT(int, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location) AS cumulative_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL

SELECT *
FROM PortfolioProject.dbo.vw_CovidPopulation_Vaccination