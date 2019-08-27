PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT,
  lname TEXT
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT,
  body TEXT,
  associated_author INTEGER,

  FOREIGN KEY(associated_author) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  follower_id INTEGER,
  question_id INTEGER,

  FOREIGN KEY(follower_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)

);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body TEXT,
  question_id INTEGER,
  parent_reply_id INTEGER,
  author_id INTEGER,


  FOREIGN KEY(parent_reply_id) REFERENCES replies(id),
  FOREIGN KEY(author_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)

);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  liker_id INTEGER,
  question_id INTEGER,

  FOREIGN KEY (liker_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)

);

INSERT INTO
  users (fname, lname)
VALUES
('Jesse', 'Conway'),
('Asher', 'Schectman');

INSERT INTO
  questions (title, body, associated_author)
VALUES
('sql', 'how do you write an insert statement', (SELECT users.id FROM users WHERE users.fname = 'Jesse')),
('html', 'how do you add a body', (SELECT users.id FROM users WHERE users.fname = 'Asher'));

INSERT INTO
  question_follows (question_id , follower_id)
VALUES
  (1, 1),
  (2, 2),
  (2, 1),
  (1, 2);

INSERT INTO
  replies (body, question_id, parent_reply_id, author_id)
VALUES
  ("create a body element", 2, null, 2),
  ("Insert into", 1, null, 1);

INSERT INTO
  question_likes (liker_id, question_id)
VALUES
  (1, 1),
  (2, 2),
  (2, 1),
  (1, 2);