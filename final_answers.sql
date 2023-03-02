
None selected 

Skip to content
Using Gmail with screen readers
answer key 
Conversations
Some messages in Trash or Spam match your search. View messages
9.68 GB of 15 GB used
Terms · Privacy · Program Policies
Last account activity: 0 minutes ago
Open in 1 other location · Details
-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count) AS claims
FROM prescription
GROUP BY npi
ORDER BY claims DESC;
--1881634483: 99,707

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT 
	p2.nppes_provider_first_name AS first_name, 
	p2.nppes_provider_last_org_name AS last_name, 
	p2.specialty_description, 
	SUM(p1.total_claim_count) AS claims, 
	p1.npi
FROM prescription as p1
LEFT JOIN prescriber as p2
ON p1.npi = p2.npi
GROUP BY p1.npi, first_name, last_name, specialty_description
ORDER BY claims DESC;
--Left join on prescription because we are only interested in the prescribers who have claims. This allows us to start with the prescription entries (all of which have claims), and link only the relevant prescribers.
--Bruce Pendley with 99,707 claims (20592 total rows)

--Alternatively, it is possible to use a full join, which will give us nulls in the claims column for prescribers with no claims. To remedy this, we can add "WHERE total_claim_count IS NOT NULL". 
--To see for yourself what the difference here is, try commenting out the WHERE clause and running it again.
SELECT p2.nppes_provider_first_name AS first_name, p2.nppes_provider_last_org_name AS last_name, p2.specialty_description, SUM(p1.total_claim_count) AS claims, p1.npi
FROM prescription as p1
FULL JOIN prescriber as p2
ON p1.npi = p2.npi
WHERE total_claim_count IS NOT NULL
GROUP BY p1.npi, first_name, last_name, specialty_description
ORDER BY claims DESC;



-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT 
	p2.specialty_description, 
	SUM(p1.total_claim_count) AS claims
FROM prescription as p1
INNER JOIN prescriber as p2
ON p1.npi = p2.npi
GROUP BY specialty_description
ORDER BY claims DESC;
--Family Practice: 9,752,347

--     b. Which specialty had the most total number of claims for opioids?
SELECT 
	p2.specialty_description, 
	SUM(p1.total_claim_count) AS claims
FROM prescription as p1
LEFT JOIN prescriber as p2
ON p1.npi = p2.npi
LEFT JOIN drug as d
ON p1.drug_name = d.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY claims DESC;
--Nurse Practitioner: 900,845

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT p2.specialty_description, SUM(p1.total_claim_count) AS claims
FROM prescriber as p2
FULL JOIN prescription as p1
ON p1.npi = p2.npi
GROUP BY specialty_description
HAVING SUM(p1.total_claim_count) IS NULL;
--15
--If you used 'WHERE p1.total_claim_count IS NULL' instead of this HAVING, you'll get 92 rows (all distinct specialties). This is because of the order of operations - WHERE runs before GROUP BY, so WHERE is filtering down to just the rows that have nulls, then GROUP BY is putting specialties together, so assuming each specialty has at least one null, all rows will be represented. No sum is actually occuring because everything is null now. In contrast, HAVING lets the GROUP BY run and sum everything up, then tells it to drop the rows where this newly-created row is NULL. Tricky, tricky

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
--SEE SEPARATE SCRIPT: "PRESCRIBERS_DIFFICULT_BONUS.SQL"




-- 3. a. Which drug (generic_name) had the highest total drug cost?
--Good:
SELECT d.generic_name, SUM(p.total_drug_cost) AS total_cost
FROM drug AS d
LEFT JOIN prescription AS p
ON d.drug_name = p.drug_name
GROUP BY d.generic_name
HAVING SUM(p.total_drug_cost) IS NOT NULL
ORDER BY total_cost DESC;
--Insulin Glargine, Hum.Rec.Anlog: $104,264,066.35

--Better:
SELECT d.generic_name, MONEY(SUM(p.total_drug_cost)) AS total_cost
FROM drug AS d
INNER JOIN prescription AS p
ON d.drug_name = p.drug_name
GROUP BY d.generic_name
ORDER BY total_cost DESC;

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT d.generic_name, ROUND(sum(p.total_drug_cost)/sum(p.total_day_supply),2) as daily_cost
FROM drug as d
INNER JOIN prescription as p
ON d.drug_name = p.drug_name
GROUP BY generic_name
ORDER BY daily_cost DESC;
--C1 Esterase Inhibitor: $3495.22




-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name, opioid_drug_flag, antibiotic_drug_flag,
CASE
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM drug;

--or for generic drugs:
SELECT
	generic_name,
	CASE
		WHEN opioid_drug_flag = 'Y' then 'opioid'
		WHEN antibiotic_drug_flag = 'Y' then 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT MONEY(SUM(total_drug_cost)),
CASE
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM drug
LEFT JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug_type;
--(neither), then opiods, then antibiotics




-- 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%, TN%'
	OR cbsaname LIKE '%-TN%';
--10
--DISTINCT is needed because a cbsa can be in multiple counties, so there is a row for each csba for each county, creating duplicates; 
--also some states have extra states tacked on to the end of the state name so I added the extra '%-TN' in case it ever didn't come first in a list, however in this case it doesn't

--could have joined to county table instead of using LIKE (probably a better method, less room for error)
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
LEFT JOIN fips_county
USING(fipscounty)
WHERE fips_county.state = 'TN';

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, sum(population) AS total_population
FROM cbsa 
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
--HAVING sum(population) IS NOT NULL: for use with LEFT JOIN, although INNER makes more sense here
ORDER BY total_population DESC;
--Nashville-Davidson_Murphreesboro-Franklin: 1,830,410
--this question threw me because for some reason there is only population data for TN

SELECT cbsaname, sum(population) AS total_population
FROM cbsa 
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
--HAVING sum(population) IS NOT NULL: for use with LEFT JOIN
ORDER BY total_population;
--Morristown: 116,352

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT f.county, f.state, p.population
FROM fips_county as f
INNER JOIN population as p
USING(fipscounty)
LEFT JOIN cbsa as c
USING(fipscounty)
WHERE c.cbsa IS NULL
ORDER BY population DESC;
--Sevier: 95,523




-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
LEFT JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
	drug_name, 
	total_claim_count, 
	opioid_drug_flag, 
	nppes_provider_first_name, 
	nppes_provider_last_org_name
FROM prescription
LEFT JOIN drug
USING(drug_name)
LEFT JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000;





-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';
--Cross join - tricky, tricky

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT prescriber.npi, drug_name, total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY drug_name;
--Joining on two keys - tricky, tricky

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT prescriber.npi, drug_name, COALESCE(total_claim_count,0)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY drug_name;
