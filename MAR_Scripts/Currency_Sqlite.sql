INSERT INTO currency(guid, name, fraction) 
SELECT {guid}, {currencyName}, 1.0
WHERE NOT EXISTS(
select name from currency where name={currencyName}
)
;

select name from currency where name={currencyName};
