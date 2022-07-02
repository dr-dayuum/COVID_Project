-- The dataset for this project was taken from OurWorldInData (https://ourworldindata.org/covid-deaths). The main goal was to establish how the virus has affected different areas
-- and to find a relationship between infection rate and vaccine rate.
-- After import, all the data was of type NVARCHAR so I had to cast or alter them to different 


--Viewing the data
SELECT *
FROM PortfolioProject..Covid_Death_Hospital


SELECT *
FROM PortfolioProject..Covid_Vaccines;


-- Select Data to use
SELECT location, CAST(date AS DATE) AS Date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..Covid_Death_Hospital
ORDER BY location, date;

--Total Cases vs Deaths
SELECT location, CAST(date AS DATE) AS Date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DeathPercent
FROM PortfolioProject..Covid_Death_Hospital
WHERE total_cases != 0 AND location NOT LIKE '%income'
ORDER BY location, date;

-- Looking at total cases versus population
-- Shows what percentage of population got covid
SELECT location, CAST(date AS DATE) AS Date, total_cases, CAST(population AS BIGINT) AS Population, population_density, (CAST(total_cases AS FLOAT)/Population)*100 AS InfectionRate
FROM PortfolioProject..Covid_Death_Hospital
WHERE CAST(population AS BIGINT) != 0 AND location NOT LIKE '%income%'
ORDER BY location, date;

-- Shows what percentage of population got covid by income class
SELECT location, CAST(date AS DATE) AS Date, total_cases, CAST(population AS BIGINT) AS Population, population_density, (CAST(total_cases AS FLOAT)/Population)*100 AS InfectionRate
FROM PortfolioProject..Covid_Death_Hospital
WHERE CAST(population AS BIGINT) != 0 AND location LIKE '%income%'
ORDER BY location, date;

--Looking at countries with highest infection rate compared to population
SELECT location, MAX(total_cases) AS HighestCases, CAST(population AS BIGINT) AS Population, (MAX(CAST(total_cases AS FLOAT))/Population)*100 AS InfectionRate
FROM PortfolioProject..Covid_Death_Hospital
WHERE CAST(population AS BIGINT) != 0 AND location NOT LIKE '%income%'
GROUP BY location, population
ORDER BY InfectionRate DESC;

--Showing Countries with highest death rate
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..Covid_Death_Hospital
WHERE location NOT LIKE '%income%' AND continent NOT LIKE ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Showing Continents with highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..Covid_Death_Hospital
WHERE location NOT LIKE '%income%' AND continent LIKE ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global Numbers
SELECT CAST(date AS DATE) AS Date, SUM(CAST(new_cases AS FLOAT)) AS Total_Cases, SUM(CAST(new_deaths AS INT)) Total_Deaths, (SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT)))*100 AS DeathPercent
FROM PortfolioProject..Covid_Death_Hospital
WHERE new_cases != 0 AND location NOT LIKE '%income' AND continent IS NOT NULL
GROUP BY date
ORDER BY date

SELECT MAX(CAST(total_cases AS INT)) AS Total_Cases, MAX(CAST(total_deaths AS INT)) AS Total_Deaths, (MAX(CAST(total_deaths AS FLOAT))/MAX(CAST(total_cases AS FLOAT)))*100 AS DeathRate
FROM PortfolioProject..Covid_Death_Hospital
WHERE new_cases != 0 AND location NOT LIKE '%income' AND continent IS NOT NULL;

--Altering the new_vaccinations column to be of type INT
ALTER TABLE PortfolioProject..Covid_Vaccines ALTER COLUMN new_vaccinations INT NULL;

--Looking at total population vs Vaccinations
WITH PopVsVac (Continent, Location, Date, Population, Total_Cases, New_Vaccinations, Rolling_Vaccines_Count)
AS
(
SELECT Deaths.continent, Deaths.location, CAST(Deaths.date AS date) AS Date, CAST(Deaths.population AS BIGINT) AS Population, Deaths.total_cases,
	Vaccines.new_vaccinations,
	SUM(CONVERT(BIGINT, Vaccines.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, CAST(Deaths.Date AS Date)) AS Rolling_Vaccines_Count
FROM PortfolioProject..Covid_Death_Hospital AS Deaths
JOIN PortfolioProject..Covid_Vaccines AS Vaccines
	ON Deaths.location = Vaccines.location
	AND Deaths.date = Vaccines.date
WHERE Deaths.continent != ''
)
SELECT *, (CAST(Total_Cases AS FLOAT)/Population)*100 AS InfectionRate, (CAST(Rolling_Vaccines_Count AS FLOAT)/Population)*100 AS VaccinationPercent
FROM PopVsVac
WHERE Population != 0
ORDER BY 2, 3;

-- Creating View to store data for visualisations

CREATE View TotalCasesVsVaccines AS
WITH PopVsVac (Continent, Location, Date, Population, Total_Cases, New_Vaccinations, Rolling_Vaccines_Count)
AS
(
SELECT Deaths.continent, Deaths.location, CAST(Deaths.date AS date) AS Date, CAST(Deaths.population AS BIGINT) AS Population, Deaths.total_cases,
	Vaccines.new_vaccinations,
	SUM(CONVERT(BIGINT, Vaccines.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, CAST(Deaths.Date AS Date)) AS Rolling_Vaccines_Count
FROM PortfolioProject..Covid_Death_Hospital AS Deaths
JOIN PortfolioProject..Covid_Vaccines AS Vaccines
	ON Deaths.location = Vaccines.location
	AND Deaths.date = Vaccines.date
WHERE Deaths.continent != ''
)
SELECT *, (CAST(Total_Cases AS FLOAT)/Population)*100 AS InfectionRate, (CAST(Rolling_Vaccines_Count AS FLOAT)/Population)*100 AS VaccinationPercent
FROM PopVsVac
WHERE Population != 0
--ORDER BY 2, 3;
