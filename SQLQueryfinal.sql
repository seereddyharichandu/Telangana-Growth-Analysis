------ How does the revenue generated from document registration vary across districts in Telangana? 


select d.district , sum(documents_registered_rev)as totalrev 
from [dbo].[fact_stamps$] f
right join [dbo].[dim_districts$] d  on d.dist_code = f.dist_code
group by d.district
order by totalrev desc 

-----List down the top 5 districts that showed the highest document registration revenue growth between FY 2019 and 2022.
select top 5 
   sum(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 then documents_registered_rev ELSE 0 END) - sum(CASE WHEN DATEPART(YEAR, f.MONTH) = 2019 then documents_registered_rev ELSE 0 END)as totalrev ,d.district  
from [dbo].[fact_stamps$] f
left join [dbo].[dim_districts$] d  on d.dist_code = f.dist_code
WHERE YEAR(month) IN (2019, 2022)
group by d.district
order by totalrev desc 

------2 How does the revenue generated from document registration compare to the revenue generated from e-stamp challans across districts? 
select d.district, sum(documents_registered_rev)as totalrev , sum(estamps_challans_rev)as totalrevstamps
from [dbo].[fact_stamps$] f
right join [dbo].[dim_districts$] d  on d.dist_code = f.dist_code
group by d.district

-------2 List down the top 5 districts where e-stamps revenue contributes significantly more to the revenue than the documents in FY 2022?
select top 5  d.district, sum(f.documents_registered_rev)as totaldocument_rev , sum(f.estamps_challans_rev)as totalstamps_rev , 
 sum(f.estamps_challans_rev) - sum(f.documents_registered_rev) as estamp_more_revofdoc
from [dbo].[fact_stamps$] f
right join [dbo].[dim_districts$] d  on d.dist_code = f.dist_code
where year(month) = (2022) 
group by d.district
order by estamp_more_revofdoc desc


---- Is there any alteration of e-Stamp challan count and document registration count pattern since the implementation of e-Stamp challan? 
SELECT
    d.district,
    SUM(f.documents_registered_cnt) AS totaldocument_count,
    SUM(f.estamps_challans_cnt) AS totalstamps_cnt,
    SUM(f.estamps_challans_cnt) - SUM(f.documents_registered_cnt) AS count_dif_estamp_doc
FROM
    [dbo].[fact_stamps$] f
left JOIN
    [dbo].[dim_districts$] d ON d.dist_code = f.dist_code
WHERE
    DATEPART(YEAR, f.MONTH) IN ( 2022)
    AND DATEPART(MONTH, f.MONTH) IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
	
GROUP BY
    d.district
ORDER BY
    count_dif_estamp_doc DESC;
------4 Categorize districts into three segments based on their stamp registration revenue generation during the fiscal year 2021 to 2022.

WITH DistrictRevenue AS (
    SELECT
        d.district,
        SUM(CASE WHEN YEAR([month]) BETWEEN 2021 AND 2022 THEN f.documents_registered_rev ELSE 0 END) AS revenue_2021_to_2022
    FROM
        [dbo].[fact_stamps$] f
    left JOIN
        [dbo].[dim_districts$] d ON d.dist_code = f.dist_code
    GROUP BY
        d.district
)

SELECT
    district,
    revenue_2021_to_2022,
    CASE
        WHEN revenue_2021_to_2022 >= PERCENTILE_CONT(0.67) WITHIN GROUP (ORDER BY revenue_2021_to_2022) OVER () THEN 'High Revenue'
        WHEN revenue_2021_to_2022 >= PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY revenue_2021_to_2022) OVER () THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_segment
FROM
    DistrictRevenue
ORDER BY
    revenue_2021_to_2022 DESC;

------5 investigate whether there is any correlation between vehicle sales and specific months or seasons in different districts. Are there any months or seasons that consistently show higher or lower sales rate, and if yes, what could be the driving factors?
SELECT
    d.district,
    DATEPART(MONTH, f.MONTH) AS month,
    SUM(f.fuel_type_diesel) AS total_dies_vehi,
    SUM(f.fuel_type_electric) AS total_elect_vehi,
    SUM(f.fuel_type_others) AS total_other_vehi,
    SUM(f.fuel_type_petrol) AS total_pet_vehi,
    (SUM(f.fuel_type_electric) + SUM(f.fuel_type_others) + SUM(f.fuel_type_petrol) + SUM(f.fuel_type_diesel)) AS totalvehi
FROM
    [dbo].[fact_transport$] AS f
LEFT JOIN
    [dbo].[dim_districts$] AS d ON d.dist_code = f.dist_code
WHERE
    DATEPART(YEAR, f.MONTH) IN (2019, 2020, 2021, 2022)
    AND DATEPART(MONTH, f.MONTH) IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
GROUP BY
    DATEPART(MONTH, f.MONTH),
    d.district
ORDER BY
    DATEPART(MONTH, f.MONTH);

------6 How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different districts? Are there any districts with a predominant preference for a specific vehicle class? Consider FY 2022 for analysis


SELECT
    t.district,
       SUM(ISNULL(f.vehicleClass_MotorCycle, 0)) AS motorcycles,
    SUM(ISNULL(f.vehicleClass_MotorCar, 0)) AS motorcars,
    SUM(ISNULL(f.vehicleClass_AutoRickshaw, 0)) AS autorickshaws,
    SUM(ISNULL(f.vehicleClass_Agriculture, 0)) AS agriculture,
    SUM(ISNULL(f.vehicleClass_others, 0)) AS vehiclesothers
FROM [dbo].[fact_transport$] f
left JOIN [dbo].[dim_districts$] t ON f.dist_code = t.dist_code
WHERE DATEPART(YEAR, f.MONTH) = 2022
GROUP BY t.district
ORDER BY t.district;

------7. List down the top 3 and bottom 3 districts that have shown the highest and lowest vehicle sales growth during FY 2022 compared to FY 2021? (Consider and compare categories: Petrol, Diesel and Electric)
SELECT top 3 
    t.district,
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_petrol  ELSE 0 END)  -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_petrol ELSE 0 END) as petrol_vehicles,
	SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_diesel  ELSE 0 END)  -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_diesel ELSE 0 END) as diesel_vehicles,
	SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_electric  ELSE 0 END)  -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_electric ELSE 0 END) as electric_vehicles,

    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_petrol + f.fuel_type_diesel + f.fuel_type_electric + f.fuel_type_others ELSE 0 END) -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_petrol + f.fuel_type_diesel + f.fuel_type_electric + f.fuel_type_others ELSE 0 END) as sales_growth
FROM [dbo].[fact_transport$] f
LEFT JOIN [dbo].[dim_districts$] t ON f.dist_code = t.dist_code
WHERE DATEPART(YEAR, f.MONTH) IN (2021, 2022)
GROUP BY t.district
ORDER BY sales_growth DESC;

SELECT top 3 
    t.district,
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_petrol  ELSE 0 END)  -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_petrol ELSE 0 END) as petrol_vehicles,
	SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_diesel  ELSE 0 END)  -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_diesel ELSE 0 END) as diesel_vehicles,
	SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_electric  ELSE 0 END)  -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_electric ELSE 0 END) as electric_vehicles,
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_petrol + f.fuel_type_diesel + f.fuel_type_electric + f.fuel_type_others ELSE 0 END) -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_petrol + f.fuel_type_diesel + f.fuel_type_electric + f.fuel_type_others ELSE 0 END) as sales_growth
FROM [dbo].[fact_transport$] f
LEFT JOIN [dbo].[dim_districts$] t ON f.dist_code = t.dist_code
WHERE DATEPART(YEAR, f.MONTH) IN (2021, 2022)
GROUP BY t.district
ORDER BY sales_growth asc;

------8. List down the top 5 sectors that have witnessed the most significant investments in FY 2022.
select top 5
sector , sum ([investment in cr]) as total_inv  from [dbo].[fact_TS_iPASS$]
where DATEPART(YEAR, MONTH) IN ( 2022)
group by sector
order by total_inv desc

-------9. List down the top 3 districts that have attracted the most significant sector investments during FY 2019 to 2022? What factors could have led to the substantial investments in these particular districts?
select  
       top 3
        t.district,count(distinct sector)as no_of_sectors
      from [dbo].[fact_TS_iPASS$] f
	  left join [dbo].[dim_districts$] t ON f.dist_code = t.dist_code
	  GROUP BY t.district
	  order by no_of_sectors desc

----------10. Is there any relationship between district investments, vehicles sales and stamps revenue within the same district between FY 2021 and 2022?
    SELECT
        t.district,
		SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN f.fuel_type_petrol + f.fuel_type_diesel + f.fuel_type_electric + f.fuel_type_others ELSE 0 END) -
        SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN f.fuel_type_petrol + f.fuel_type_diesel + f.fuel_type_electric + f.fuel_type_others ELSE 0 END) as sales_growth
    FROM [dbo].[fact_transport$] f
   left JOIN [dbo].[dim_districts$] t ON f.dist_code = t.dist_code
    WHERE DATEPART(YEAR, f.MONTH) IN (2021, 2022)
    GROUP BY t.district 
	order by t.district asc

    SELECT
        d.district,
        SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN [investment in cr] ELSE 0 END) - SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN [investment in cr] ELSE 0 END) as inc_invest_cr
    FROM [dbo].[fact_TS_iPASS$] f
    LEFT JOIN [dbo].[dim_districts$] d ON d.dist_code = f.dist_code
	    WHERE DATEPART(YEAR, f.MONTH) IN (2021, 2022)

    GROUP BY d.district
   order by d.district asc

    SELECT
        d.district,

        SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN documents_registered_rev ELSE 0 END) - SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2019 THEN documents_registered_rev ELSE 0 END) as inc_rev
    FROM [dbo].[fact_stamps$] f
    LEFT JOIN [dbo].[dim_districts$] d ON d.dist_code = f.dist_code
    GROUP BY d.district
    order by d.district asc
------11. Are there any particular sectors that have shown substantial  investment in multiple districts between FY 2021 and 2022
SELECT
    f.sector,
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN [investment in cr] ELSE 0 END) as total_invst2022,
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN [investment in cr] ELSE 0 END) as total_invst2021,
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN [investment in cr] ELSE 0 END) -
    SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN [investment in cr] ELSE 0 END) as inc_invest,
    COUNT(DISTINCT d.district) AS num_districts
FROM [dbo].[fact_TS_iPASS$] f
LEFT JOIN [dbo].[dim_districts$] d ON d.dist_code = f.dist_code
WHERE DATEPART(YEAR, f.MONTH) IN (2021, 2022)
GROUP BY f.sector
HAVING SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2022 THEN [investment in cr] ELSE 0 END) - SUM(CASE WHEN DATEPART(YEAR, f.MONTH) = 2021 THEN [investment in cr] ELSE 0 END) > 0
ORDER BY inc_invest DESC;

-----12. Can we identify any seasonal patterns or cyclicality in the  investment trends for specific sectors?
select  sum([investment in cr]) as totl_invst , f.sector , DATEPART(MONTH, f.MONTH) as smonth from [dbo].[fact_TS_iPASS$] f 
LEFT JOIN
    [dbo].[dim_districts$] AS d ON d.dist_code = f.dist_code
WHERE
    DATEPART(YEAR, f.MONTH) IN (2019, 2020, 2021, 2022)
    AND DATEPART(MONTH, f.MONTH) IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
GROUP BY
    DATEPART(MONTH, f.MONTH),
    f.sector
ORDER BY
    DATEPART(MONTH, f.MONTH);

-----12. Do certain sectors experience higher investments during particular months?
WITH MonthlySectorInvestments AS (
    SELECT
        SUM([investment in cr]) as total_investment,
        f.sector,
       
        DATEPART(MONTH, f.MONTH) as month
    FROM
        [dbo].[fact_TS_iPASS$] f
    WHERE
        DATEPART(YEAR, f.MONTH) IN (2019,2020,2021,2022)
    GROUP BY
  
        DATEPART(MONTH, f.MONTH),
        f.sector
)
SELECT
  
    month,
    sector,
    total_investment
FROM (
    SELECT
      
        month,
        sector,
        total_investment,
        ROW_NUMBER() OVER (PARTITION BY  month ORDER BY total_investment DESC) as rn
    FROM MonthlySectorInvestments
) RankedInvestments
WHERE rn = 1
ORDER BY  month;


------- What are the top 5 districts to buy commercial properties in Telangana? 
SELECT Top 5
    SUM([investment in cr]) as total_investment_cr,
	d.district
FROM
    [dbo].[fact_TS_iPASS$] f
LEFT JOIN
    [dbo].[dim_districts$] AS d ON d.dist_code = f.dist_code
WHERE
    DATEPART(YEAR, f.MONTH) IN (2019, 2020, 2021, 2022)
    AND DATEPART(MONTH, f.MONTH) IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
GROUP BY
    d.district
order by 
    total_investment_cr desc



