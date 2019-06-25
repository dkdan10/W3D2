PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)

);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  parent_id INTEGER,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id)

);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
  users(fname, lname)
VALUES 
  ('Daniel', 'Keinan'),
  ('Ram', 'Bhattarai'),
  ('tom', 'cruise'),
  ('john', 'lenon');

INSERT INTO
  questions(title, body, author_id)
VALUES 
  ('SQl-HELP?!', 'NOne of these make sense',(SELECT id FROM users WHERE fname = 'Daniel' AND lname = 'Keinan')),
  ('SQl-HELPPPPPPHELP?!', 'None of these is making any sense its all abstract',(SELECT id FROM users WHERE fname = 'Daniel' AND lname = 'Keinan'));
 
INSERT INTO
  question_follows(question_id, user_id)
VALUES 
  ((SELECT id FROM questions WHERE title = 'SQl-HELP?!'),(SELECT id FROM users WHERE fname = 'Daniel' AND lname = 'Keinan'));

INSERT INTO
  replies
  (question_id, user_id, body, parent_id)
VALUES
  ((SELECT id
    FROM questions
    WHERE title = 'SQl-HELP?!'),
    (SELECT id
    FROM users
    WHERE fname = 'Ram' AND lname = 'Bhattarai'),
    "I can help with your SQL issues",
    NULL);

INSERT INTO
  replies
  (question_id, user_id, body, parent_id)
VALUES
  ((SELECT id
    FROM questions
    WHERE title = 'SQl-HELP?!'),
    (SELECT id
    FROM users
    WHERE fname = 'Daniel' AND lname = 'Keinan'),
    "Thank you for heling me!",
    (SELECT id FROM replies WHERE body = "I can help with your SQL issues"));


INSERT INTO
  question_likes
  (user_id, question_id)
VALUES
  ((SELECT id
  FROM users
  WHERE fname = 'Daniel' AND lname = 'Keinan'),
  (SELECT id
  FROM questions
  WHERE title = 'SQl-HELP?!')
  ),
  ((SELECT id
  FROM users
  WHERE fname = 'Ram' AND lname = 'Bhattarai')
  ,
  (SELECT id
  FROM questions
  WHERE title = 'SQl-HELP?!')
  );