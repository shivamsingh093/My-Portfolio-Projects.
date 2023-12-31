--SELECT *
--FROM PortfolioProject.dbo.CovidDeaths
--WHERE continent IS NOT NULL

SELECT location, 
       date,
	   total_cases,
	   new_cases,
	   total_deaths,
	   population
FROM   
       PortfolioProject..CovidDeaths
ORDER BY 
       location,
	   date


--Looking at Total Cases vs Total Deaths
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    CASE
        WHEN TRY_CAST(total_cases AS float) = 0 THEN NULL  -- Handle division by zero
        ELSE (TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float)) * 100
    END AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE location LIKE '%India%'
ORDER BY
    1, 2;


--Looking at Total Cases vs Population
--Shows What Percentage Of Population Got COVID
SELECT
    location,
    date,
    total_cases,
    population,
    (total_cases/population)*100 AS PercentPopulationInfected
FROM
    PortfolioProject..CovidDeaths
--WHERE location LIKE '%India%'
ORDER BY
    1, 2;


--Looking At Countries With Highest Infection Rate Compared To Population
SELECT
    location,
	population,
    MAX(total_cases) AS HighestInfectionCount,
    population,
    MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM
    PortfolioProject..CovidDeaths
--WHERE location LIKE '%India%'
GROUP BY 
    location,
    population
ORDER BY
    PercentPopulationInfected DESC



--Showing Countries With Highest Death Count Per Population
SELECT
    location,
	MAX(total_deaths) AS TotalDeathCount
FROM
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC


--Showing Countries With Highest Death Count Per Population
SELECT 
    continent,
	MAX(total_deaths) AS TotalDeathCount
FROM
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    continent
ORDER BY 
    TotalDeathCount DESC


--Global Numbers
SELECT 
    SUM(new_cases) AS TotalCases,
	SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100
	AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
ORDER BY 
    TotalCases, TotalDeaths


--Looking at Total Population Vs Vaccinations
--USING CTE
WITH 
    PopulationVSVaccination 
    (continent,
	location,
	date,
	population,
	new_vaccinations,
	CumulativeVaccinations)
	AS 
	(
SELECT 
    Deaths.continent, 
    Deaths.location, 
    Deaths.date, 
    Deaths.population, 
    Vac.new_vaccinations,
    SUM(COALESCE(CAST(Vac.new_vaccinations AS bigint), 0)) 
        OVER (PARTITION BY Deaths.location ORDER BY Deaths.date) AS CumulativeVaccinations
FROM   
    PortfolioProject.dbo.CovidDeaths AS Deaths
JOIN   
    PortfolioProject.dbo.CovidVaccinations AS Vac
    ON   
    Deaths.location = Vac.location
    AND   
    Deaths.date = Vac.date
WHERE  
    Deaths.continent IS NOT NULL
    )
	SELECT *, (CumulativeVaccinations/population)*100
	FROM PopulationVSVaccination


--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
    (
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	CumulativeVaccinations numeric
	)
INSERT INTO
    #PercentPopulationVaccinated
     SELECT 
    Deaths.continent, 
    Deaths.location, 
    Deaths.date, 
    Deaths.population, 
    Vac.new_vaccinations,
    SUM(COALESCE(CAST(Vac.new_vaccinations AS bigint), 0)) 
        OVER (PARTITION BY Deaths.location ORDER BY Deaths.date) AS CumulativeVaccinations
FROM   
    PortfolioProject.dbo.CovidDeaths AS Deaths
JOIN   
    PortfolioProject.dbo.CovidVaccinations AS Vac
    ON   
    Deaths.location = Vac.location
    AND   
    Deaths.date = Vac.date
WHERE  
    Deaths.continent IS NOT NULL

SELECT *, (CumulativeVaccinations/population)*100
	FROM #PercentPopulationVaccinated



--Creating View to Store Data For Later Visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    Deaths.continent, 
    Deaths.location, 
    Deaths.date, 
    Deaths.population, 
    Vac.new_vaccinations,
    SUM(COALESCE(CAST(Vac.new_vaccinations AS bigint), 0)) 
        OVER (PARTITION BY Deaths.location ORDER BY Deaths.date) AS CumulativeVaccinations
FROM   
    PortfolioProject.dbo.CovidDeaths AS Deaths
JOIN   
    PortfolioProject.dbo.CovidVaccinations AS Vac
    ON   
    Deaths.location = Vac.location
    AND   
    Deaths.date = Vac.date
WHERE  
    Deaths.continent IS NOT NULL



SELECT * FROM PercentPopulationVaccinated;
