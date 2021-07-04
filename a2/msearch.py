#!/usr/bin/python3

import sqlite3,sys

#need to fix null values and ordering

con = sqlite3.connect('a2.db')

cur = con.cursor()

query = """
    select m.title, m.year, m.content_rating, rat.imdb_score, group_concat(distinct(g.genre))
    from movie as m
    join Acting as act on act.movie_id = m.id
    join Actor as a on a.id = act.actor_id 
    join Director as d on d.id = m.director_id
    join Rating as rat on rat.movie_id = m.id
    join Genre as g on g.movie_id = m.id
    where m.title in 
        (select movie.title
        from Movie
        join Acting on acting.movie_id = Movie.id
        join Actor on actor.id = acting.actor_id
        where actor.name like "%{}%")
    or m.title like "%{}%"
    or d.name like "%{}%"
    group by m.title,m.year
    order by m.year desc, rat.imdb_score, m.title  asc 
"""

d = []

l = sys.argv[1:]

for i in l:
    cur.execute(query.format(i,i,i))
    res = cur.fetchall()
    l = set()
    for t in res:
        title,year,rating,score,genre = t
        l.add(t)
    d.append(l)

result = (d[0].intersection(*d))

a = 1
for i in result:
    print('{}. {} ({},{},{}) [{}]'.format(a,i[0],i[1],i[2],i[3],i[4]))
    a = a + 1


con.close()