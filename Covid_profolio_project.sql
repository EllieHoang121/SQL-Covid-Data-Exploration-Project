SELECT * FROM covid_death
WHERE continent IS NOT NULL
ORDER BY location, date

-- Select the data needed

SELECT location, date, population, total_cases, new_cases, total_deaths
FROM covid_death
WHERE continent IS NOT NULL
ORDER BY location, date

-- Calculating the likelihood of dying in the United States

SELECT location, date, total_cases, total_deaths, CONCAT((ROUND((total_deaths/total_cases)*100, 2)), '%') AS death_percentage
FROM covid_death
WHERE location LIKE '%States%'
AND continent IS NOT NULL
ORDER BY location, date

-- Countries with highest infected percentages compare to population

SELECT location, population, MAX(total_cases) AS maximum_infected_cases, CONCAT(MAX(ROUND((total_cases/population)*100, 5)), '%') AS highest_infected_percentage
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_infected_percentage desc

-- Countries with total deaths and its highest death rate

SELECT location, SUM(CAST(total_deaths AS int)) AS total_deaths, CONCAT(MAX(ROUND((total_deaths/total_cases)*100, 2)), '%') AS highest_death_rate
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_rate desc

-- Continents with total deaths 
SELECT continent, SUM(CAST(total_deaths AS int)) AS total_deaths
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths desc

--Global's total cases, and death
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths
From covid_death
where continent is not null 
order by total_cases, total_deaths

-- Global total cases, total deaths, and death rates by month
SELECT YEAR(date) AS year, MONTH(date) AS month, 
SUM(CAST(total_cases AS bigint))AS total_cases,
SUM(CAST(total_deaths AS bigint)) AS total_deaths, 
CONCAT((ROUND(((SUM(CAST(total_deaths AS bigint))/SUM(CAST(total_cases AS bigint)))*100),10)),'%') AS death_rates
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY YEAR(date), MONTH(date)
ORDER BY YEAR(date), MONTH(date) asc

-- Rolling vaccinated percentage (with cte)

WITH rolling_vacc AS 
(SELECT d.continent, d.location, d.date, d.population,
v.new_vaccinations, 
SUM(CONVERT(int, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM covid_death d
INNER JOIN covid_vaccine v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL)

SELECT continent, location, date, population,
CONCAT(FORMAT((((rolling_people_vaccinated/population)*100)), '0.000'), '%') AS percentage_of_vaccinated
FROM rolling_vacc
ORDER BY 1, 2, 3

-- Create table
DROP TABLE IF EXISTS percent_of_vaccinated
CREATE TABLE percent_of_vaccinated
(continent varchar(100),
location varchar(100),
date datetime,
population numeric, 
total_cases numeric,
total_deaths numeric, 
people_vaccinated numeric, 
people_fully_vaccinated numeric,
gdp_per_capita numeric)

INSERT INTO percent_of_vaccinated
SELECT d.continent, d.location, d.date, d.population, d.total_cases, d.total_deaths, 
v.people_vaccinated, v.people_fully_vaccinated, v.gdp_per_capita
FROM covid_death d
INNER JOIN covid_vaccine v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT * FROM percent_of_vaccinated

-- Percentage of fully vaccinated over vaccinated
SELECT location, population, 
MAX(ROUND(CAST(((people_fully_vaccinated/people_vaccinated)*100) AS bigint), 2)) AS fully_vaccinated_percentage
FROM percent_of_vaccinated
WHERE continent IS NOT NULL
AND population IS NOT NULL
GROUP BY location, population
ORDER BY fully_vaccinated_percentage desc

-- Relationship between vaccinated and gdp
SELECT location, gdp_per_capita, 
MAX(ROUND(CAST(((people_vaccinated/population)*100) AS bigint), 2)) AS vaccinated_percentage
FROM percent_of_vaccinated
WHERE continent IS NOT NULL
AND gdp_per_capita IS NOT NULL
GROUP BY location, gdp_per_capita
ORDER BY gdp_per_capita desc, vaccinated_percentage desc