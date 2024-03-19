
--Covid 19 Data Exploration 
--skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Select *
From portfolioProject..CovidDeaths

Select *
From portfolioProject..CovidVaccinations

-- Identify variables to use for exploration

Select Location, Date, Total_cases, new_cases, total_deaths, population
From portfolioProject..CovidDeaths
Order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country (USA & Ghana)

Select Location, Date, Total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
From portfolioProject..CovidDeaths
Where Location like '%states%'
Order by 1,2

Select Location, Date, Total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
From portfolioProject..CovidDeaths
Where Location like '%Ghana%'
Order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, Date, population, Total_cases, (total_cases/population) * 100 as PercentageInfected
From portfolioProject..CovidDeaths
Where Location like '%states%'
Order by 1,2

Select Location, Date, population, Total_cases, (total_cases/population) * 100 as PercentageInfected
From portfolioProject..CovidDeaths
Where Location like '%Ghana%'
Order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, population, Max(Total_cases) as HighestInfectionCount, Max((total_cases/population)) * 100 as PercentagePopulationInfected
From portfolioProject..CovidDeaths
Group by Location, population
Order by PercentagePopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, Max(cast(Total_deaths as int)) as TotalDeathCount
From portfolioProject..CovidDeaths
Where continent is not null
Group by Location
Order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
From portfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc


Select Location, Max(cast(Total_deaths as int)) as TotalDeathCount
From portfolioProject..CovidDeaths
Where continent is null
Group by Location
Order by TotalDeathCount desc


---GLOBAL NUMBERS

Select date, SUM(new_cases)
From portfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2

Select date, SUM(new_cases), SUM(cast(new_deaths as int))
From portfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
From portfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
From portfolioProject..CovidDeaths
Where continent is not null
Order by 1,2




-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select *
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 1,2,3

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location)
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingCountofPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3


-- CTE
-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, RollingCountofPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingCountofPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *
From PopvsVac


With PopvsVac (continent, location, date, population, new_vaccinations, RollingCountofPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingCountofPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingCountofPeopleVaccinated / Population) * 100
From PopvsVac


--TEMP TABLE
-- Using Temp Table to perform Calculation on Partition By in previous query

Drop Table if exists #PercentagePopulationVaccinated
Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingCountofPeopleVaccinated numeric,
)
insert into #PercentagePopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingCountofPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingCountofPeopleVaccinated / Population) * 100
From #PercentagePopulationVaccinated



-- Creating view to store for later visualization

Create view PercentagePopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingCountofPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *
From PercentagePopulationVaccinated