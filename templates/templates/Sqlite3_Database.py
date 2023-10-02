from flask import Flask, render_template, request, redirect
import sqlite3
app = Flask(__name__)
app.config['DATABASE'] = 'code.db'  # SQLite database file

def get_db():
    db = getattr(app, '_database', None)
    if db is None:
        db = sqlite3.connect(app.config['DATABASE'])
        app._database = db
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(app, '_database', None)
    if db is not None:
        db.close()
        
@app.route('/indexdb')
def indexdb():
    return render_template('indexdb.html')
        
@app.route('/search_database')
def search_database():
    return render_template('search_database.html')

@app.route('/search_db', methods=['POST'])
def search():
    search_term = request.form['search_term']
    search_area = request.form['search_area']

    db = get_db()
    cursor = db.cursor()
    if search_area == 'description':
        cursor.execute("SELECT * FROM snippets WHERE description LIKE ?", ('%' + search_term + '%',))
    elif search_area == 'code':
        cursor.execute("SELECT * FROM snippets WHERE code LIKE ?", ('%' + search_term + '%',))
    elif search_area == 'keywords':
        cursor.execute("SELECT * FROM snippets WHERE keywords LIKE ?", ('%' + search_term + '%',))
    else:
        return redirect('/search_database')

    results = cursor.fetchall()
    return render_template('db_results.html', results=results)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5200)
