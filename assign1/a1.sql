---Q1
create or replace view Q1(pid, firstname, lastname) as
    select pid,firstname, lastname from person
    where pid not in (select pid from client) 
    and   pid not in (select pid from staff)
    order by pid;

---Q2
create or replace view Q2(pid, firstname, lastname) as
    select person.pid,person.firstname, person.lastname from person     
    except
    select person.pid,person.firstname, person.lastname from person 
    join client on client.pid = person.pid
    join insured_by on insured_by.cid = client.cid
    join policy on policy.pno = insured_by.pno where policy.status = 'E'
    order by pid;

---Q3

create or replace view Q3(brand,vid,pno,premium) as
    select t1.brand, t1.vid, t1.pno1, t3.pr FROM (select brand, pol.id as vid , cov.pno as pno1, sum(rate) as premium
    from insured_item
    join policy as pol on pol.id = insured_item.id
    join coverage as cov on cov.pno = pol.pno
    join rating_record on rating_record.coid = cov.coid
    group by brand,pol.id, cov.pno, pol.status, rating_record.status
    having pol.status = 'E' and rating_record.status <> 'R') t1, 
    
    (select t2.brand, MAX(t2.premium) as pr FROM (select brand, pol.id as vid , cov.pno as pno1, sum(rate) as premium
    from insured_item
    join policy as pol on pol.id = insured_item.id
    join coverage as cov on cov.pno = pol.pno
    join rating_record on rating_record.coid = cov.coid
    group by brand,pol.id, cov.pno, pol.status, rating_record.status
    having pol.status = 'E' and rating_record.status <> 'R') t2
    GROUP BY t2.brand) t3
    
    WHERE t3.pr = t1.premium
    ORDER BY t1.brand, t1.vid, t1.pno1, t3.pr;


---Q4
create or replace view Q4(pid, firstname, lastname) as
    (select pid, firstname, lastname from person
    where pid in (select pid from staff))
    except
    (select pid, firstname, lastname from person
    where pid in (select pid from staff
    where sid in (select sid from policy where policy.status = 'E')))
    except
    (select pid, firstname, lastname from person
    where pid in (select pid from staff
    where sid in (select sid from underwritten_by where underwritten_by.comments = 'rate is appropriate')))
    except
    (select pid, firstname, lastname from person
    where pid in (select pid from staff
    where sid in (select sid from rated_by where rated_by.comments = 'approved')))
    order by pid;

---Q5


create or replace view Q5(suburb, npolicies) as
    select suburb, count(policy.pno) as npolicies
    from person
    join client on client.pid = person.pid 
    join insured_by on insured_by.cid = client.cid 
    join policy on policy.pno = insured_by.pno   
    Where policy.status = 'E'
    group by suburb
    order by npolicies;


---Q6

create or replace view Q6(pno, ptype, pid, firstname, lastname) as
select pol.pno, pol.ptype, p.pid, p.firstname, p.lastname 
    from person as p
    join staff on staff.pid = p.pid
    join policy as pol on pol.sid = staff.sid
    where pol.status = 'E'
    group by pol.pno, pol.ptype,p.pid
intersect
select ur.pno, pol.ptype, p.pid, p.firstname, p.lastname
    from person as p
    join staff on staff.pid = p.pid  
    join underwritten_by as  ub on ub.sid = staff.sid
    join underwriting_record as ur on ur.urid = ub.urid
    join policy as pol on pol.pno = ur.pno
    where pol.status = 'E'
    group by ur.pno, pol.ptype,p.pid
    having count(ur.pno) <> 1
intersect
select co.pno, pol.ptype, p.pid, p.firstname, p.lastname
    from person as p
    join staff on staff.pid = p.pid 
    join rated_by as rb on rb.sid = staff.sid
    join rating_record as rr on rr.rid = rb.rid  
    join coverage as co on co.coid = rr.coid
    join policy as pol on pol.pno = co.pno
    where pol.status = 'E'
    group by co.pno, pol.ptype,p.pid
    having count(co.pno) <> 1
order by pno;


---Q7
create or replace view Q7(pno,ptype, effectivedate, expirydate, agreedvalue) as
    select pno,ptype, effectivedate,expirydate,agreedvalue
    from policy
    where policy.status = 'E' 
    and
    expirydate - effectivedate >= ALL(select expirydate - effectivedate from policy)
    group by pno
    order by pno;

---Q8

create or replace view helper(pid, name, brand) as
    select p.pid, p.firstname || ' ' || p.lastname as name, it.brand
    from person as p
    join staff on staff.pid = p.pid
    join policy on policy.sid = staff.sid
    join insured_item as it on it.id = policy.id
    where policy.status = 'E'
    group by p.pid, it.brand
    order by pid;

create or replace view helper2(pid, name) as
    select pid, name from helper
    group by pid, name
    having count(pid) = 1;

create or replace view Q8(pid, name, brand) as
    select helper2.pid, helper2.name, insured_item.brand 
    from helper2
    join staff as s on s.pid = helper2.pid
    join policy on  policy.sid = s.sid
    join insured_item on insured_item.id = policy.id
    group by helper2.pid, helper2.name,insured_item.brand
    order by helper2.pid;

---Q9

create or replace view helper3(pid, name) as
    select p.pid, p.firstname || ' ' || p.lastname as name,it.brand
    from person as p
    join client as c on c.pid = p.pid
    join insured_by as ib on  ib.cid = c.cid
    join policy as pol on pol.pno = ib.pno
    join insured_item as it on it.id = pol.id
    group by p.pid, it.brand;

create or replace view Q9(pid,name) as
    select pid,name from helper3
    group by pid, name
    having count(pid) = 3
    order by pid;


---Q10

create or replace function staffcount(pno integer) returns integer
as $$
    declare
    result integer;
    begin
    select sum(total) into result from (
    select count(*) as total from (
        select p.pid, p.firstname
        from person as p
        join staff on staff.pid = p.pid
        join underwritten_by as ub on ub.sid = staff.sid
        join underwriting_record as ur on ur.urid = ub.urid
        where ur.pno = $1
        union
        select p.pid, p.firstname
        from person as p
        join staff on staff.pid = p.pid
        join policy as pol on pol.sid = staff.sid
        where pol.pno = $1
        union
        select p.pid, p.firstname
        from person as P
        join staff on staff.pid = p.pid
        join rated_by as rb on rb.sid = staff.sid
        join rating_record as rr on rr.rid = rb.rid
        join coverage as co on co.coid = rr.coid
        where co.pno = $1
        ) as s
        group by s
        )
    as x
    group by x; 
    return result;
    end;
$$ language plpgsql;

--Q11
create or replace procedure renew(pno integer) 
    language plpgsql
    as
    $$

    declare
        stat character;
        ptyp char;
        pnum integer; 
        ed date;
        expd date;
        av real;
        comm character;
        staffid integer;
        vid integer;
        maxnum integer;
    begin
        select pol.pno, pol.ptype,pol.status, pol.effectivedate, pol.expirydate, pol.agreedvalue, pol.comments, pol.sid, pol.id, pol.pno*100
        into
        pnum,ptyp,stat,ed,expd,av,comm,staffid,vid
        from policy as pol
        where $1 = pol.pno
        group by pol.pno;
        if (stat = 'E') then
        /*
            INSERT INTO policy VALUES (maxnum + 1, ptyp, 'D', current_date,current_date  + (expd - ed) ,av,comm,staffid,vid);
            UPDATE policy
            set  expirydate = current_date
            where policy.pno = $1;
        */
            INSERT INTO policy VALUES (maxnum + 1, ptyp, 'D', current_date,current_date  + (expd - ed) ,av,comm,staffid,vid);
            UPDATE policy
            set  expirydate = current_date
            where policy.pno = $1;
        end if;
    end;
    $$;

