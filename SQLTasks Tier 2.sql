/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name
FROM Facilities 
WHERE membercost > 0;


/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(*)
FROM Facilities
WHERE membercost = 0;


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost < monthlymaintenance * .2;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE 1 = CASE
			WHEN facid = 1 THEN 1
			WHEN facid = 5 THEN 1
			ELSE 0
		END;

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, 
	CASE WHEN monthlymaintenance > 100
		THEN 'expensive'
		ELSE 'cheap' END AS cost_label
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate = (SELECT MAX(joindate) FROM Members);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT f.name AS court_name, CONCAT(c.firstname, ' ', c.surname) AS full_name
FROM Facilities AS f
LEFT JOIN (SELECT firstname, surname, m.memid, b.facid
FROM Members AS m
LEFT JOIN (SELECT DISTINCT(memid), facid
	FROM Bookings
	WHERE facid = 0 OR facid = 1) AS b ON m.memid = b.memid
WHERE m.memid = b.memid) AS c ON f.facid = c.facid
WHERE f.name = 'Tennis Court 1' OR f.name = 'Tennis Court 2'
ORDER BY full_name;



/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT f.name AS facility, CONCAT(firstname, ' ', surname) AS full_name, 
(CASE
 	WHEN b.memid = 0 THEN guestcost * slots
	ELSE membercost * slots
	END) AS total_cost
FROM Bookings AS b
LEFT JOIN Facilities AS f
	ON b.facid = f.facid
LEFT JOIN Members AS m
	ON b.memid = m.memid
WHERE b.starttime LIKE '2012-09-14%' AND ((b.memid = 0 AND slots * guestcost > 30) OR (b.memid != 0 AND slots * membercost > 30))
ORDER BY total_cost DESC;



/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT name AS facility, full_name, total_cost
FROM (SELECT bookid, b.facid, b.memid, starttime, slots, f.name, membercost, guestcost, CONCAT(firstname, ' ', surname) AS full_name, 
(CASE
 	WHEN b.memid = 0 THEN guestcost * slots
	ELSE membercost * slots
	END) AS total_cost
FROM Bookings AS b
LEFT JOIN Facilities AS f
	ON b.facid = f.facids
LEFT JOIN Members AS m
	ON b.memid = m.memid
WHERE b.starttime LIKE '2012-09-14%') AS sub
WHERE total_cost > 30
ORDER BY total_cost DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT *
FROM (SELECT name, SUM(amt_paid) AS total_revenue
FROM (SELECT f.name, b.facid, b.bookid,
(CASE
 	WHEN b.memid = 0 THEN b.slots * f.guestcost
 	ELSE b.slots * f.membercost
 	END) AS amt_paid
FROM Facilities AS f
LEFT JOIN Bookings AS b
	ON f.facid = b.facid) AS bf
GROUP BY name) AS rev
WHERE total_revenue < 1000
ORDER BY total_revenue;

or for python and pandas

q10 = pd.read_sql_query('''SELECT *
FROM (SELECT name, SUM(amt_paid) AS total_revenue
FROM (SELECT f.name, b.facid, b.bookid,
(CASE
 	WHEN b.memid = 0 THEN b.slots * f.guestcost
 	ELSE b.slots * f.membercost
 	END) AS amt_paid
FROM Facilities AS f
LEFT JOIN Bookings AS b
	ON f.facid = b.facid) AS bf
GROUP BY name) AS rev
WHERE total_revenue < 1000
ORDER BY total_revenue;''', engine)

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT m1.surname AS mem_surname, m1.firstname AS mem_firstname, m1.recommendedby AS recommended_by_ID, (CASE WHEN m1.recommendedby > 0 THEN m2.surname END) AS recommendedby_surname, (CASE WHEN m1.recommendedby > 0 THEN m2.firstname END) AS recommendedby_firstname
FROM Members AS m1
LEFT JOIN Members AS m2
	ON m1.recommendedby = m2.memid
ORDER BY m1.surname, m2.firstname;

or for python and pandas

q11 = pd.read_sql_query('''SELECT m1.surname AS mem_surname, m1.firstname AS mem_firstname, m1.recommendedby AS recommended_by_ID, (CASE WHEN m1.recommendedby > 0 THEN m2.surname END) AS recommendedby_surname, (CASE WHEN m1.recommendedby > 0 THEN m2.firstname END) AS recommendedby_firstname
FROM Members AS m1
LEFT JOIN Members AS m2
	ON m1.recommendedby = m2.memid
ORDER BY m1.surname, m2.firstname;''', engine)


/* Q12: Find the facilities with their usage by member, but not guests */

SELECT b.facid, f.name, COUNT(b.memid) AS mem_usage
FROM (
SELECT facid, memid
FROM Bookings
WHERE memid !=0
) AS b
LEFT JOIN Facilities AS f ON b.facid = f.facid
GROUP BY b.facid;

for python and pandas

q12 = pd.read_sql_query('''SELECT b.facid, f.name, COUNT(b.memid) AS mem_usage
FROM (
SELECT facid, memid
FROM Bookings
WHERE memid !=0
) AS b
LEFT JOIN Facilities AS f ON b.facid = f.facid
GROUP BY b.facid;''', engine)


/* Q13: Find the facilities usage by month, but not guests */

SELECT b.months, COUNT( b.memid ) AS mem_usage
FROM (
SELECT MONTH( starttime ) AS months, memid
FROM Bookings
WHERE memid !=0
) AS b
GROUP BY b.months;

for python and pandas * no MONTH function so strftime() used instead

q13 = pd.read_sql_query('''SELECT b.months, COUNT( b.memid ) AS mem_usage
FROM (
SELECT strftime('%m', starttime ) AS months, memid
FROM Bookings
WHERE memid !=0
) AS b
GROUP BY b.months;''', engine)


