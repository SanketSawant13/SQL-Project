create database Digital_music_store;

--1)Who is the most senior employee based on job title.
--Write a query to return first ,last name,level and job title of employee?
SELECT top 1 first_name,last_name,title,levels FROM [dbo].[employee]
order by levels desc;


--2)Which  countries have the most invoices?
SELECT billing_country,count(*) as invoice_count FROM invoice
group by billing_country 
order by count(*) desc;


--3)What are top 3 values of total invices?
select top 3 total from invoice 
order by total desc;


--4)Which city has best customer? We would like to throw music festival in the city
--we made most money.Write a query that return one city that has highest sum of invoice totals 
--return both the city name and sum of all invoices total.
select top 1 billing_city, sum(total)as total_invoice from invoice 
group by billing_city
order by sum(total) desc;


--5)Who is the best customer?The customer who has spent the most money declare the best customer.
--write a query that return the person who spent the most money.
select top 1 c.customer_id, c.first_name, c.last_name,round(sum(total),2)as total_spent from customer as c 
join invoice as i  on c.customer_id=i.customer_id 
group by c.customer_id, c.first_name, c.last_name
order by sum(total) desc;


--6)Write a query to return email,first name,last name and genre of all rock music listners.
--return list  ordered alphabetically by email starting A
select  distinct first_name,last_name,c.email from customer c join invoice i on c.customer_id=i.customer_id 
join invoice_line il on i.invoice_id=il.invoice_id
where track_id in (
select track_id from track t join genre g on t.genre_id=g.genre_id
where g.name like 'rock') 
order by c.email;


--7)Write a query that return artist name and total track count of top 10 rock bands.
SELECT top 10  artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC;



--8)Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. 
select name,milliseconds
from track where milliseconds >
(select avg(milliseconds)
from track)
order by milliseconds desc


--9)Find how much amount spent by each customer on artists? 
--Write a query to return customer name, artist name and total spent 
WITH best_selling_artist AS (
	SELECT top 1 artist.artist_id AS artist_id, artist.name AS artist_name, 
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY artist.artist_id,artist.name
	ORDER BY 3 DESC
)
SELECT c.customer_id, c.first_name, c.last_name, 
SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY  c.customer_id, c.first_name, c.last_name
ORDER BY SUM(il.unit_price*il.quantity) DESC;


--10) We want to find out the most popular music Genre for each country. We determine the most popular genre as 
--the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. 
--For countries where the maximum number of purchases is shared return all Genres. 
WITH popular_genre AS 
	(SELECT COUNT(invoice_line.quantity) AS purchases, 
	 	customer.country, genre.name AS genre_name,
		ROW_NUMBER() 
	 	OVER(PARTITION BY customer.country 
	 ORDER BY COUNT(invoice_line.quantity) DESC)AS row_num 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY customer.country, genre.name)
SELECT country, genre_name, purchases 
FROM popular_genre 
WHERE row_num <= 1
ORDER BY genre_name ASC, country DESC;

-- Q11. Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH customer_with_country AS
	(SELECT customer.customer_id, first_name, last_name, billing_country, round(SUM(total),2) AS total_spent,
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS row_num
	FROM invoice
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY customer.customer_id, first_name, last_name, billing_country)
SELECT customer_id, first_name, last_name, billing_country, total_spent
FROM customer_with_country
WHERE row_num = 1
ORDER BY billing_country , total_spent DESC;

---Q12. Who are the most popular artists?

SELECT COUNT(invoice_line.quantity) AS purchases, artist.name AS artist_name
FROM invoice_line 
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
GROUP BY artist.name
ORDER BY COUNT(invoice_line.quantity) DESC;

-- Q13. Which is the most popular song?

SELECT COUNT(invoice_line.quantity) AS purchases, track.name AS song_name
FROM invoice_line 
JOIN track ON track.track_id = invoice_line.track_id
GROUP BY track.name
ORDER BY COUNT(invoice_line.quantity) DESC;

--Q14. What are the average prices of different types of music?

WITH purchases AS
	(SELECT genre.name AS genre, SUM(total) AS total_spent
	FROM invoice
	JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY genre.name)
	
SELECT genre, CONCAT('$',ROUND(AVG(total_spent),2)) AS total_spent
FROM purchases
GROUP BY genre
ORDER BY CONCAT('$',ROUND(AVG(total_spent),2));

-- Q15. What are the most popular countries for music purchases?

SELECT COUNT(invoice_line.quantity) AS purchases, customer.country
FROM invoice_line 
JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
GROUP BY country
ORDER BY purchases DESC;
