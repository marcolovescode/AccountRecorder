INSERT INTO accounts(guid, num, name) 
SELECT {guid}, {accountNum}, '{accountNum}'
WHERE NOT EXISTS(
select num from accounts where num={accountNum}
)
;

select guid from accounts where num={accountNum};
