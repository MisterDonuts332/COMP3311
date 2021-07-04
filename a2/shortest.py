
import sys
import sqlite3
from collections import deque
import pandas as pd

con = sqlite3.connect('a2.db')

cur = con.cursor()

actor_1 = sys.argv[1]
actor_2 =  sys.argv[2]
df_movie = pd.read_sql_query("SELECT * from movie", con)
df_acting = pd.read_sql_query("SELECT * from acting", con)
df_actor = pd.read_sql_query("SELECT * from actor", con)

actor_dict = {}
paths_all = []
dicter = {}

#convert string to actor id:
get_id = """
    select a.id 
    from Actor as a
    where name like "%{}%"
    """


cur.execute(get_id.format(actor_1))

res = cur.fetchall()
a1_id = res[0][0]

cur.execute(get_id.format(actor_2))

res = cur.fetchall()
a2_id = res[0][0]

#print(a1_id)
#print(a2_id)


## Helper
def intersection(lst1, lst2):
    return list(set(lst1) & set(lst2))


def bfs(graph, start, goal):
    if start == goal:
        return

    queue = deque([start])

    # dict which holds parents, later helpful to retreive path.
    # Also useful to keep track of visited node
    parent = {}
    parent[start] = start

    while queue:
        currNode = queue.popleft()
        for neighbor in graph[currNode]:
            # goal found
            if neighbor == goal:
                parent[neighbor] = currNode
                curr_path = print_path(parent, neighbor, start)
                paths_all.append(curr_path)
                #return print_path(parent, neighbor, start)
            # check if neighbor already seen
            if neighbor not in parent:
                parent[neighbor] = currNode
                queue.append(neighbor)
    #return ("No path found.")


def print_path(parent, goal, start):
    path = [goal]
    # trace the path back till we reach start
    while goal != start:
        goal = parent[goal]
        path.insert(0, goal)
    return (path)


## This code matches 2 ids and gives all the movies common between them. 

def make_dict(id_1, id_2):
    ## Get the common movies
    lst_1 = df_acting[df_acting['actor_id'] == id_1]['movie_id'].values.tolist()
    lst_2 = df_acting[df_acting['actor_id'] == id_2]['movie_id'].values.tolist()

    ## Get the actor names
    actor_1_name = df_actor[df_actor["id"] == id_1].values[0][1]
    actor_2_name = df_actor[df_actor["id"] == id_2].values[0][1]

    movies_worked_in = intersection(lst_1,lst_2)

    movie_strings = []
    for i in movies_worked_in:
        movie_name,date = df_movie[df_movie['id'] == i].values[0][1], int(df_movie[df_movie['id'] == i].values[0][2])
        string = actor_1_name + " was in "+ movie_name + " ("+str(int(date)) + ") with " + actor_2_name 
        movie_strings.append(string)
  
    dicter[str([id_1, id_2])] = movie_strings




for i in df_actor["id"]:
    #print(i)
    actings = df_acting[df_acting["actor_id"] == i]["movie_id"].values
    #print(actings)

    actors = list(set(df_acting[df_acting["movie_id"].isin(actings)]["actor_id"].values.tolist()))
    actors.remove(i)
    #print(actors)

    actor_dict[i] = actors

bfs(actor_dict, a1_id ,a2_id)

## Minimum lengths path in paths_final
paths_final = []
for i in paths_all:
    if len(i) == len(paths_all[0]):
        paths_final.append(i)

#print(paths_final)


l = []
for paths in paths_final:
    dicter.clear()
    for i in range(0,len(paths)-1):
        make_dict(paths[i],paths[i+1])
    l.append(dicter.copy())

i = 1
for dic in l:
    #print(dic)
    for n in dic:
        '''
        print(f'{i}. ', end = "") 
        print(*dic[n], sep = "; ")
        '''
        i += 1


'''
i = 1
for n in dicter:
  print(f'{i}. ', end = "") 
  print(*dicter[n], sep = "; ")
  i += 1
'''