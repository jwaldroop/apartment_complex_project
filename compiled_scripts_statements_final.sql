#### TEAM 17 SQL SCRIPTS ####

use rentwithus;


# ----------------- #
# SELECT STATEMENTS #
# ----------------- #

## Jack Beck ##

-- Q1: What is the average SqFt for apartments in building 1? Customers would like this information to compare their units to the other units in the same building. 
SELECT 
AVG(SpaceSqFt) as Average_SqFt_All_Units
FROM apartment
WHERE BuildingID = 1;

-- Q2: What is the average number of rooms in each unit where SqFt > 1000? Management would like this done to inform rent adjustments for the next leasing season.
# The 'FLOOR' fucntion is used to round down the average, as in practice there is no fractional rooms.
SELECT 
FLOOR(AVG(NoRooms)) as Average_No_Rooms 
FROM apartment
WHERE SpaceSqFt > 1000; 

-- Q3: Which apartments have the highest average Sqft per unit? Rank all apartment buildings by their average SqFt per unit. This information will be compared to other local apartment leasing options to inform rent adjustments for the next leasing season.
SELECT 
RANK() OVER( ORDER BY AVG(SpaceSqFt) DESC) as 'Rank' , BuildingID, AVG(SpaceSqFt) as Avg_SqFt
FROM apartment
GROUP BY BuildingID;

-- Q4: What are the construction years of the buildings with the top 3 highest average Sqft per unit? The marketing team would like this information to appropriately advertise the buildings. 
SELECT 
RANK() OVER( ORDER BY AVG(a.SpaceSqFt) DESC) as 'Rank', AVG(a.SpaceSqFt) as Avg_SqFt, a.BuildingID, YEAR(b.DateBuilt) as 'Year Built'
FROM apartment as a
INNER JOIN building as b ON a.BuildingID = b.BuildingID
GROUP BY BuildingID 
LIMIT 3;

-- Q5: List the length of time between each maintencance expendtiures assigned date and due date. Show the ApartmentID associated with each maintenance expense. Management would like this information queried so that they can plan future expenses more efficiently. 
SELECT 
a.ApartmentID, e.Date as 'Maintenance Expense Date', e.DueDate, DATEDIFF(e.DueDate , e.Date) as 'Days Until Due'
FROM expenditure as e
INNER JOIN maintenance as m ON e.MaintenanceID = m.MaintenanceID
INNER JOIN apartment as a ON m.ApartmentID = a.ApartmentID
WHERE e.Type = 'Maintenance'
ORDER BY e.Date;

## Jordan Waldroop ## 

# which buildings have apartments with both parking lots and pools and how many bedrooms?
# potential residents may be looking to be close to both

select BuildingID, NoRooms, HasParkingLot, HasPool, count(distinct ApartmentID) as `# of Apartments`
from building
join apartment using (BuildingID)
where HasParkingLot = 1 AND HasPool = 1
group by BuildingID, NoRooms
order by BuildingID, NoRooms;




# what is the average credit score of the residents for each apartment size? 
# this could be important to owners/property managers looking to screen applicants.

select NoRooms, FLOOR(avg(CreditScore)) as Average_Credit_Score
from resident
join apartment using (ApartmentID)
group by NoRooms;




# how many of each lease types (length) by number of rooms in each apartment?
# this is important to management for advertising/lease management purposes.

select NoRooms, LeaseType, count(distinct LeaseID) as `# of Leases`
from lease
join rent using (LeaseID)
join apartment using (ApartmentID)
group by NoRooms, LeaseType
order by NoRooms, `# of Leases` desc;




# which apartments have new furniture? used furniture? per room number count?  
# this is important for audits of when new furniture will be need to be purchase to replace the used furniture

select furniture.Condition as `Condition`, 
	count(distinct ApartmentID) as `No of Apartments`,
    (select round(avg(amount),2) 
    from furniture join expenditure using (FurnitureID) 
    where expenditure.type = 'Furniture') as `Average Cost`
from furniture
join expenditure using (FurnitureID)
group by `Condition`;

# what is the average rent for each bedroom and bathroom size?
# this is important for leasing information

select NoRooms, NoBathrooms, round(avg(amount),2) as `Avg Payment`
from rent
join apartment using (ApartmentID)
group by NoRooms, NoBathrooms
order by NoRooms, NoBathrooms;


## Sam Al Qarzi ##

-- select statements 
/* 1. what type of lease is most contracted? show lease type and number of residents per leasetype. 
This query is valuable to the management to forecast future rent revenues and to see which of their contracts is more popular among residents */

select l.LeaseType, count(res.residentID) as Numberofresidents from resident res 
join Apartment ap on res.ApartmentID = ap.ApartmentID 
join Rent r on ap.ApartmentID = r.ApartmentID 
join Lease l on r.LeaseID = l.LeaseID
group by l.leaseType
order by Numberofresidents desc;
    
/* 2. What is the average rent across all Lease types? 
 This query would be most useful for evaluating contracts and make them more appealing for new applicants*/
 
select l.LeaseType, round(avg(p.Amount),2) as AvgPerLease from Payment p
join Rent r on p.RentID = r.RentID 
join Lease l on r.LeaseID = l.LeaseID
group by LeaseType
order by LeaseType;

/* 3. Does average rent likely fluctuate based on how old the building is? 
 This query would expose any changes in rent across all buildings. Also, it will help the management adjust the rent based on the building's condition*/
 
select b.BuildingID,
	   b.DateBuilt,
	   round((DATEDIFF(curDate(),b.DateBuilt)/365),0) as BuildingAgeYears,
       round(avg(r.Amount),2) as AvgRent
       from building b
 join Apartment p on b.BuildingID = p.BuildingID
 join Rent r on p.ApartmentID = r.ApartmentID
 group by b.BuildingID
 order by DateBuilt desc;


/* 4. How many Maintenance Jobs were carried each Year per apartment? and what are their total costs? what is the average cost across all jobs?
 This will help the manaement monitor cost of maintenance jobs across apartments and try to implement permenant solutions. */
 
select  m.ApartmentID, 
        year(E.Date) as JobYear, 
        count(m.MaintenanceID) as MatJobs,
        sum(E.amount) as totalcost, 
        round((select sum(E.amount)/count(m.MaintenanceID) from Maintenance m 
		 join Expenditure E on m.MaintenanceID = E.MaintenanceID),2) as AvgCost
from Maintenance m 
join Expenditure E on m.MaintenanceID = E.MaintenanceID
group by m.ApartmentID, JobYear
order by m.ApartmentID, JobYear; 
 
/* 5. Were most of those Maintenance Jobs done in new or old buildings? what are the total number and cost of maintenance jobs in each buliding?
 This will help the management allocate maintenance cost on a building scale and determine if those expense are most likely associated with a building's condition. */
 
select b.BuildingID,
       b.DateBuilt,
       round((DATEDIFF(curDate(),b.DateBuilt)/365),0) as BuildingAgeYears,
       count(m.MaintenanceID) as NoMatJobs, 
       sum(E.amount) as totalcost
from  building b
join apartment p on b.BuildingID = p.BuildingID
join Maintenance m on p.ApartmentID = m.ApartmentID
join Expenditure E  on m.MaintenanceID = E.MaintenanceID
group by b.BuildingID
order by b.DateBuilt desc;

## Cody Rogers ##

# Cody Select

begin;
#Q1
#there has been a manufacturer recall on the new lamps that you have been installing, which states that the lamps are prone to overheating leading to fire.
#obtain a list of all apartments with new lamps, so they can be replaced, and so current residents can be warned

select residentID, FirstName, LastName, Email, f.ApartmentId, f.type, f.condition
from furniture as f 
join apartment as a on a.apartmentID = f.ApartmentID
join Resident as r on  r.ApartmentID = a.ApartmentID
where f.type = 'lamps' and f.condition = 'New';
 
#Q2
#########need to change rent amount to decimal (11, 2), not varchar, to match type with payment   
 
alter table rent 
change Amount Amount decimal (11, 2);

#accounting wants to know if there have been any underpayments by residents, to make sure their collection books are correct and current

select r.rentID, apartmentID, r.amount as rent_amount, p.amount as payment, r.amount-p.amount as amount_owed, paymentdate, type  from rent r
join payment p
on r.rentID = p.rentID 
where r.amount-p.amount > 0;
#this should return no rows, as all accounts are fully paid
   
#Q3
#the office staff need to know which apartments leases will be ending next month, so they can prepare renewal paperwork or advertize the units for new tenants    
	#assume current date is may 2019
	#to find apartments that will be renewing in the current month (resign, find new tenants)
    
select l.LeaseID, l.EndDate, res.ResidentID, res.ApartmentID from Lease l
join rent r on r.LeaseID = l.LeaseID
join Apartment a on a.ApartmentID = r.ApartmentID
join Resident res on res.ApartmentID = a.apartmentID
where MONTH(EndDate) = 6 and YEAR(EndDate) = 2019; 
select * from lease;

#Q4
#the maintanance operating manager wants to know which apartments had water damage repaired, and when, so the apartments can be tested for standing mold/failed repairs

select m.MaintenanceID, m.type as maintenance_type, m.ApartmentID, ex.Date, ex.Amount from maintenance m
join expenditure ex on ex.MaintenanceID = m.MaintenanceID
where m.type like 'leaks%' 
order by ApartmentID, date desc;
#########noticed for data normalization, "Pest control" vs "Pest Control" and ""leaks and water damage" vs "Leaks and Water Damage" in maintenance table

#Q5
#find all the residents who have a lower than average credit score, so office staff and accounting can keep an eye on risky individuals (late payments, etc)
select residentID, firstname, lastname, creditscore
from resident
where creditscore < (select avg(CreditScore) from resident);
end;

## Isaac Everitt ##

## Q1: What is the count of each type of role within the company?  Our HR team would like to know if we are understaffed for a company of our size.  This could dictate if members of that department deserve a raise or if more people need to be hired.

SELECT DISTINCT(role), COUNT(role)
FROM office
GROUP BY role;

## Q2: Which apartment buildings have the highest average square footage?  Return in descending order.

SELECT BuildingID, ROUND(avg(SpaceSqFt), 2) AS 'Apt Avg Square Footage'
FROM apartment
GROUP BY BuildingID
ORDER BY avg(SpaceSqFt) DESC;

## Q3: What are the residents name, their address, and rent amount that have a credit score below 600?  These tennats should be watched to ensure they are not late on consectutive months of rent.

SELECT res.FirstName, res.LastName, b.Address, res.CreditScore, rent.Amount
FROM resident AS res
JOIN rent 
	ON res.ApartmentID = rent.ApartmentID
JOIN apartment AS a 
	ON res.ApartmentID = a.ApartmentID
JOIN building AS b
	ON a.BuildingID = b.BuildingID
WHERE res.CreditScore < 600
ORDER BY res.CreditScore DESC;

## Q4: Identify the leases that are 1 year/12 months in length, the tennants in those leases, and when the lease ends.  The marketing team would like to know these customers so they can target them to resign

SELECT l.LeaseType, r.FirstName, r.LastName, l.EndDate
FROM lease AS l
JOIN rent USING (LeaseID)
JOIN resident AS r
	ON rent.ApartmentID = r.ApartmentID
WHERE LeaseType = '12 Month';

## Q5: What building year requires the most maintenance?  Our maintenance team would like to identify if there is a construction defect in a specific building year.

SELECT YEAR(b.DateBuilt), SUM(e.amount)
FROM expenditure AS e
JOIN maintenance m 
	ON e.MaintenanceID = m.MaintenanceID
JOIN apartment AS a
	ON m.ApartmentID = a.ApartmentID
JOIN building AS b
	ON a.BuildingID = b.BuildingID
GROUP BY YEAR(b.DateBuilt)
ORDER BY SUM(e.amount) DESC;


# ----------------- #
# STORED FUNCTIONS  #
# ----------------- #


/* Management has requested that we be able to write queries that break each buildings address apart into each buildings respective housing number and street name. 
I'll create a couple of functions to do this so it can be easily reused in the future if this query is requested again. 
These two functions are intended to be used together in one SELECT statment, in the future I will make a procedure which combines them. */

DELIMITER // 

CREATE FUNCTION breakAddressPart1 ( input_address varchar(45)) RETURNS varchar(45)
DETERMINISTIC
BEGIN
	RETURN SUBSTRING_INDEX (input_address,' ',1);
END // 

CREATE FUNCTION breakAddressPart2 ( input_address varchar(45)) RETURNS varchar(45)
DETERMINISTIC
BEGIN
    RETURN SUBSTRING_INDEX (input_address,' ',-2);
END // 


DELIMITER ;

# Example usage of the 2 part function created above

SELECT
breakAddressPart1(address) 'Housing Number', breakAddressPart2(address) as 'Street Name'
FROM building
ORDER BY buildingID;


/* Management would like us to create a stored function which provides a string output to describe the relative size of an apartment unit when comparing 
its SqFt to other apartments */

SELECT MAX(SpaceSqFt) From apartment; # What is highest SqFt?

DELIMITER //

CREATE FUNCTION apartmentSize (SpaceSqFt bigint) RETURNS varchar(50)
DETERMINISTIC
BEGIN
	DECLARE AptSize varchar(50);
    CASE WHEN SpaceSqFt <= 400 
			THEN SET AptSize = 'Extremely Small';
		WHEN SpaceSqFt >= 400 AND SpaceSqFt < 600
			THEN SET AptSize = 'Very Small' ;
		WHEN SpaceSqFt >= 600 AND SpaceSqFt < 800
			THEN SET AptSize = 'Small';
		WHEN SpaceSqFt >= 800 AND SpaceSqFt < 1100
			THEN SET AptSize = 'Average';
		WHEN SpaceSqFt >= 1100 AND SpaceSqFt < 1400
			THEN SET AptSize = 'Large';
		WHEN SpaceSqFt >= 1400 AND SpaceSqFt < 1800
			THEN SET AptSize = 'Very Large';
		WHEN SpaceSqft >= 1800 AND SpaceSqFt < 2200
			THEN SET AptSize = 'Extremely Large';
		ELSE SET AptSize = 'You Are Spoiled';
	END CASE;
RETURN AptSize;
END //
	
DELIMITER ;

SELECT ApartmentID, SpaceSqFt, apartmentSize(SpaceSqFt)
FROM apartment;

# ----------------- #
# STORED PROCEDURE  #
# ----------------- #

DELIMITER // 

CREATE PROCEDURE creditRating (IN inputCreditScore int, OUT rating character)
BEGIN
	SELECT 
		CASE WHEN CreditScore <= 579 THEN 'Very Poor'
        WHEN CreditScore > 579 AND CreditScore <= 669 THEN 'Fair'
        WHEN CreditScore > 669 AND CreditScore <= 739 THEN 'Good'
        WHEN CreditScore > 739 AND CreditScore <= 799 THEN 'Very Good'
        WHEN CreditScore > 800 THEN 'Exceptional'
        ELSE NULL END AS credit_rate
	FROM resident
    where CreditScore = inputCreditScore;
END //

DELIMITER ;


CALL creditRating (850, @rating);

CALL creditRating (720, @rating);


# ----------------- #
#      TRIGGER      #
# ----------------- #

# Going to make an audit table that will catalog changes in the resident's information.

CREATE TABLE resident_Info_Audit(
residentID int,
ApartmentID int,
Email varchar(45),
Age varchar(45),
CreditScore varchar(45),
lastUpdate timestamp,
rowValue char(20)
);

# Time for the trigger which will store the data in the table I just created

DELIMITER //

CREATE TRIGGER storeOldInfo
AFTER UPDATE ON resident
FOR EACH ROW
BEGIN

	IF NEW.residentID != OLD.residentID OR NEW.ApartmentID != OLD.ApartmentID OR NEW.Email != OLD.Email OR NEW.Age != OLD.Age OR NEW.CreditScore != OLD.CreditScore THEN 
    
    INSERT INTO resident_Info_Audit (residentID, ApartmentID, Email, Age, CreditScore, lastUpdate, rowValue)
    VALUES (OLD.residentID, OLD.ApartmentID, OLD.Email, OLD.Age, OLD.CreditScore, current_timestamp(), 'Before Update');
    
    INSERT INTO resident_Info_Audit (residentID, ApartmentID, Email, Age, CreditScore, lastUpdate, rowValue)
    VALUES (NEW.residentID, NEW.ApartmentID, NEW.Email, NEW.Age, NEW.CreditScore, current_timestamp(), 'After Update');
    END IF;
    
END //

DELIMITER ;

# Time to update some data to try it out.
UPDATE resident
SET Email = 'Email@email.com'
WHERE residentID = 1;

# Did it work? 
SELECT * FROM resident;
SELECT * FROM resident_info_audit; -- Yes