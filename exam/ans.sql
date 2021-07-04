-- COMP3311 21T1 Exam SQL Answer Template
--
-- * Don't change view/function names and view/function arguments;
-- * Only change the SQL code for view/function bodies as commented below;
-- * and do not remove the ending semicolon of course.
--
-- * You may create additional views, if you wish;
-- * but you are NOT allowed to create tables.
--




create or replace view Q4_helper(name, year) as
    select a.name as name, min(m.year) as year
    from actor as a
    join acting as act on act.actor_id = a.id
    join movie as m on m.id = act.movie_id
    group by a.name
    intersect 
    (select d.name, m.year
    from director as d
    join movie as m on m.director_id = d.id)
;

-- Q1. 

create or replace view Q1(name, total) as
    select a.name as name, count(act.movie_id) as total
    from actor as a
    left join acting as act on act.actor_id = a.id
    group by a.name
    order by total desc, a.name asc;


-- Q2. 

create or replace view Q2(year, name) as
    select m.year as year, d.name as name
    from movie as m 
    join rating as rat on rat.movie_id = m.id
    join director as d on m.director_id = d.id
    where rat.num_voted_users >= 100000
    order by year;





-- Q3. 

create or replace view Q3 (title, name) as
    select m.title as title, a.name as name
    from movie as m
    join acting as act on act.movie_id = m.id
    join actor as a on a.id = act.actor_id
    join director as dic on m.director_id = dic.id
    where a.name = dic.name
    order by m.title asc, dic.name asc;


-- Q4. 

create or replace view Q4 (name) as
    select a.name as name
    from actor as a
    intersect
    (select dic.name 
    from director as dic)
    except
    (
    select name from Q4_helper
    )
    order by name asc;


-- Q5. 

create or replace view Q5(actor1, actor2) as
select 'ABC', 'DEF'
;


-- Q6. 


create or replace function
    experiencedActor(_m int, _n int) returns setof actor
as $$ 
declare
r record;
_a actor;
begin
    for r in 
        select a.id, a.name, a.facebook_likes 
        from movie as m 
        join acting as act on act.movie_id = m.id
        join actor as a on a.id = act.actor_id
        group by a.id, a.name
        having max(m.year) - min(m.year) + 1 <= _n
        and
        max(m.year) - min(m.year) + 1 >= _m
    loop
        _a.id := r.id;
        _a.name := r.name;
        _a.facebook_likes := r.facebook_likes;
    return next _a;
    end loop;
end;
$$ language plpgsql;


-- Q7.
-- Define your trigger (or triggers) below




