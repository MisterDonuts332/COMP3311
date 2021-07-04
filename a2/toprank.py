import sqlite3
import pandas as pd
import sys 


def toprank(genres_inp, min_rating):

    con = sqlite3.connect("a2.db")
    df_movie = pd.read_sql_query("SELECT * from movie", con)
    df_genre = pd.read_sql_query("SELECT * from genre", con)
    df_rating = pd.read_sql_query("SELECT * from rating", con)
    con.close()


    
    df_genre2 = df_genre.groupby(['movie_id']).apply(lambda x: [list(x['genre'])]).apply(pd.Series)

    
    df_genre2['movie_id'] = df_genre2.index

    df_genre2.columns = ['genre_list', 'movie_id']


    ## Join movie and genre
    df_movie_genre = df_movie.join(df_genre2.set_index('movie_id'), on = 'id')

    ## Join movie and rating
    df_movie_genre = df_movie_genre.join(df_rating.set_index('movie_id'), on = 'id')

    ## COnvert the genre list 
    genre_list = genres_inp.split("&")
    min_rating = min_rating
    important_mov = []

    
 
    ## Go through the movies to get the important ones. 
    for index, row in df_movie_genre.iterrows():
        if (all(item in row['genre_list'] for item in genre_list) or genre_list == [""]) and row['imdb_score'] >= min_rating:
          important_mov.append(row)

    newlist = sorted(important_mov, key=lambda k: (k['imdb_score'], k['num_voted_users']), reverse = True) 

    count = 1
    for i in newlist:
      if str(i['year']) != 'nan':
        print(f"{count}. {i['title']} ({int(i['year'])} {i['content_rating']} {i['lang']}) [{i['imdb_score']} {i['num_voted_users']}]")
      else:
        print(f"{count}. {i['title']} ({i['content_rating']} {i['lang']}) [{i['imdb_score']} {i['num_voted_users']}]")
      count += 1

##Usage. 
toprank(sys.argv[1], float(sys.argv[2]))

