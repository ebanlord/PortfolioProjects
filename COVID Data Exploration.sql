# -----FIXING DATE OF COVIDDEATHS-----
select * from coviddeaths;

# add new column
alter table coviddeaths add column date_formatted date;
# Convert Dates and Populate New Column
update coviddeaths
set date_formatted = str_to_date(date_death, '%d/%m/%Y');
# Drop Old Column
alter table coviddeaths drop column date_death;
# Rename New Column
alter table coviddeaths change column date_formatted date_death DATE;

SHOW COLUMNS FROM coviddeaths;

# move date to after location
ALTER TABLE coviddeaths
MODIFY COLUMN date_death DATE AFTER location;

# -----FIXING DATE OF COVIDVACINES-----
select * from covidvacines;

# add new column
alter table covidvacines add column date_formatted date;
# Convert Dates and Populate New Column
update covidvacines
set date_formatted = str_to_date(date_vacine, '%d/%m/%Y');
# Drop Old Column
alter table covidvacines drop column date_vacine;
# Rename New Column
alter table covidvacines change column date_formatted date_vacine DATE;

SHOW COLUMNS FROM covidvacines;

# move date to after location
ALTER TABLE covidvacines
MODIFY COLUMN date_vacine DATE AFTER location;

# -------------START OF PROJECT-------------
select * from project_covid19.coviddeaths
where continent != ''
order by 3,4;

select location, date_death, total_cases, new_cases, total_deaths, population
from project_covid19.coviddeaths
where continent != ''
order by 1,2;

# total cases vs total deaths in PH
select location, date_death, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from project_covid19.coviddeaths
where location = 'Philippines' 
and continent != ''
order by 1,2;

# total cases vs population in PH
select location, date_death, population, total_cases, (total_cases/population)*100 as infected_percentage
from project_covid19.coviddeaths
where location = 'Philippines' 
and continent != ''
order by 1,2;

# countries with highest infection rate compared to population
select location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population)*100) as infected_percentage
from project_covid19.coviddeaths
where continent != ''
group by location, population
order by infected_percentage desc;

# countries with highest death count per population
select location, MAX(total_deaths) as Total_Death_Count
from project_covid19.coviddeaths
where iso_code not like 'OWID_%' # not include continents for location
group by location
order by Total_Death_Count desc;

# total death count by continent
select continent, MAX(total_deaths) as Total_Death_Count
from project_covid19.coviddeaths
-- where iso_code like 'OWID_%' 
where continent != ''
group by continent
order by Total_Death_Count desc;

# deaths by global nuumbers
select date_death, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	(SUM(new_deaths)/SUM(new_cases))*100 as Death_Percentage
from project_covid19.coviddeaths 
where continent != ''
group by date_death
order by 1,2;

# total deaths overall
select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	(SUM(new_deaths)/SUM(new_cases))*100 as Death_Percentage
from project_covid19.coviddeaths 
where continent != ''
order by 1,2;


ALTER TABLE project_covid19.coviddeaths RENAME COLUMN `date` TO `date_death`;
ALTER TABLE project_covid19.covidvacines RENAME COLUMN `date` TO `date_vacine`;

# --- JOIN BOTH TABLES IN TERMS OF LOCATION AND DATE ---
SELECT * 
FROM project_covid19.coviddeaths AS dea
JOIN project_covid19.covidvacines AS vacc
	ON dea.location = vacc.location
AND dea.date_death = vacc.date_vacine;

# --- population vs vaccinations ---
SELECT dea.continent, dea.location, dea.date_death, dea.population, vacc.new_vaccinations,
	SUM(vacc.new_vaccinations) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date_death) 
    as Running_Vacc_Count # ,(Running_Vacc_Count/population)*100
FROM project_covid19.coviddeaths AS dea
JOIN project_covid19.covidvacines AS vacc
	ON dea.location = vacc.location
    AND dea.date_death = vacc.date_vacine
where dea.continent != ''
order by 2,3;

# use CTE since Running_Vacc_Count is a new column, functions cant be used on it
with PopvsVac (continent, location, `date`, population, new_vaccinations, Running_Vacc_Count) as (
SELECT dea.continent, dea.location, dea.date_death, dea.population, vacc.new_vaccinations,
	SUM(vacc.new_vaccinations) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date_death) 
    as Running_Vacc_Count 
FROM project_covid19.coviddeaths AS dea
JOIN project_covid19.covidvacines AS vacc
	ON dea.location = vacc.location
    AND dea.date_death = vacc.date_vacine
where dea.continent != ''
order by 2,3 )
SELECT *, (Running_Vacc_Count/population)*100 as Percent_Running_Vacc_Count
FROM PopvsVac;

-- temp table option to do the running vacc count
-- Step 1: Create the table
DROP TABLE if exists PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
    continent VARCHAR(50),
    location VARCHAR(50),
    `date` DATETIME,
    population bigint,
    new_vaccinations bigint,
    Running_Vacc_Count bigint
);
-- Step 2: Insert data into the table, handling empty strings
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date_death, dea.population, 
    IFNULL(NULLIF(vacc.new_vaccinations, ''), 0) AS new_vaccinations,
    SUM(IFNULL(NULLIF(vacc.new_vaccinations, ''), 0)) OVER (PARTITION BY dea.location ORDER BY dea.date_death) AS Running_Vacc_Count
FROM project_covid19.coviddeaths AS dea
JOIN project_covid19.covidvacines AS vacc
    ON dea.location = vacc.location
    AND dea.date_death = vacc.date_vacine;
-- Step 3: Select data and calculate the percentage of the population vaccinated
SELECT *, (Running_Vacc_Count/population)*100 AS Percent_Running_Vacc_Count
FROM PercentPopulationVaccinated;

# ------ VIEW to store data for later visualizations
create view PercentPopulationVaccinatedView as
SELECT dea.continent, dea.location, dea.date_death, dea.population, 
    IFNULL(NULLIF(vacc.new_vaccinations, ''), 0) AS new_vaccinations,
    SUM(IFNULL(NULLIF(vacc.new_vaccinations, ''), 0)) OVER (PARTITION BY dea.location ORDER BY dea.date_death) AS Running_Vacc_Count
FROM project_covid19.coviddeaths AS dea
JOIN project_covid19.covidvacines AS vacc
    ON dea.location = vacc.location
    AND dea.date_death = vacc.date_vacine
where dea.continent != '';

# can query off the view
select * from PercentPopulationVaccinatedView;