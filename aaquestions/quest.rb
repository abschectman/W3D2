require 'sqlite3'
require_relative 'modelbase.rb'



class User < ModelBase
  attr_accessor :id, :fname, :lname
  # def self.all
  #   data = QuestionsDatabase.instance.execute("SELECT * FROM users")
  #   data.map { |hash| User.new(hash) }
  # end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
       fname = ? AND lname = ?
    SQL

    return nil if user.length == 0
    User.new(user.first)
  end

  # def self.find_by_id(id)
  #   user = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       users
  #     WHERE
  #       id = ?
  #   SQL
  #   return nil if user.length == 0
  #   User.new(user.first)
  # end


  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
      Question.find_all_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_all_by_author_id(self.id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLikes.liked_questions_for_user_id(self.id)
  end

  def average_karma
    user = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT
     COUNT(question_likes.question_id) / CAST(COUNT(DISTINCT(questions.id)) AS FLOAT)
    FROM
      question_likes
    JOIN
      users ON users.id = question_likes.liker_id
    JOIN
     questions ON questions.id = question_likes.question_id
    WHERE
    questions.associated_author = ?
    GROUP BY
     questions.associated_author

    SQL
    return nil if user.length == 0
    user.first.values.first
  end

  def save
    if self.id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
        INSERT INTO
         users (fname, lname)
        VALUES
          (?, ?)
        SQL
        self.id = QuestionsDatabase.instance.last_insert_row_id
    else
        QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname, self.id)
        UPDATE
         users
         SET
         fname = ?, lname = ?
        WHERE
          id = ?
          SQL
    end
  end
  #update


end

class Question
  attr_accessor :id, :title, :body, :associated_author
   def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |hash| Question.new(hash) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil if question.length == 0
    Question.new(question.first)
  end

    def self.find_all_by_author_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        associated_author = ?
    SQL
    return nil if question.length == 0
    question.map { |hash| Question.new(hash) }
  end

  def self.most_followed(n)
    QuestionFollows.most_followed_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @associated_author = options['associated_author']


  end

  def followers
    QuestionFollows.followers_for_question_id(self.id)
  end

  def author
    question = QuestionsDatabase.instance.execute(<<-SQL, self.associated_author)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil if question.length == 0
    User.new(question.first)
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def likers
    QuestionLikes.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLikes.num_like_for_question_id(self.id)
  end

  def self.most_liked(n)
    QuestionLikes.most_liked_questions(n)
  end

   def save
    if self.id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.associated_author)
        INSERT INTO
         questions (title, body, associated_author)
        VALUES
          (?, ?, ?)
        SQL
        self.id = QuestionsDatabase.instance.last_insert_row_id
    else
        QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.associated_author, self.id)
        UPDATE
         questions
         SET
         title = ?, body = ?, associated_author = ?
        WHERE
          id = ?
          SQL
    end
  end
end

class QuestionFollows
  attr_accessor :id, :question_id, :follower_id

  def self.followers_for_question_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      users.*
    FROM
      users
    JOIN
      question_follows ON users.id = question_follows.follower_id
    JOIN
      questions ON questions.id = question_follows.question_id
    WHERE
      questions.id = ?


  SQL
  return nil if question.length == 0
  question.map { |hash| User.new(hash) }
end

def self.most_followed_questions(n)
    question = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      question_follows ON questions.id = question_follows.question_id
    GROUP BY
    questions.id
    ORDER BY
    COUNT(question_follows.follower_id) DESC

  SQL
  return nil if question.length == 0
  question[0...n].map { |hash| Question.new(hash) }
end

def self.followed_questions_for_user_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      question_follows ON questions.id = question_follows.question_id
    JOIN
      users ON users.id = question_follows.follower_id
    WHERE
      users.id = ?


  SQL
  return nil if question.length == 0
  question.map { |hash| Question.new(hash) }
end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map { |hash| QuestionFollows.new(hash) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL
    return nil if question.length == 0
    QuestionFollows.new(question.first)
  end

  def self.find_all_by_follower_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        follower_id = ?
    SQL
    return nil if question.length == 0
    question.map { |hash| QuestionFollows.new(hash) }
  end

    def self.find_all_by_question_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        question_id = ?
    SQL
    return nil if question.length == 0
    question.map { |hash| QuestionFollows.new(hash) }
  end


  def initialize(options)
    @id = options['id']
    @follower_id = options['follower_id']
    @question_id = options['question_id']
  end

end

class Reply
  attr_accessor :id, :question_id, :body, :parent_reply_id, :author_id
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |hash| Reply.new(hash) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil if question.length == 0
    Reply.new(question.first)
  end

  def self.find_by_question_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    return nil if question.length == 0
    Reply.new(question.first)
  end

  def self.find_all_by_author_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
    SQL
    return nil if question.length == 0
    question.map { |hash| Reply.new(hash) }
  end


  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @body = options['body']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
  end

  def author
     question = QuestionsDatabase.instance.execute(<<-SQL, self.author_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil if question.length == 0
    User.new(question.first)
  end

  def question
      question = QuestionsDatabase.instance.execute(<<-SQL, self.question_id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil if question.length == 0
    Question.new(question.first)
  end

  def parent_reply
      question = QuestionsDatabase.instance.execute(<<-SQL, self.parent_reply_id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil if question.length == 0
    Reply.new(question.first)
  end

  def child_replies
      question = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        *
      FROM
        replies
      WHERE
        ? IN (
          SELECT
           parent_reply_id
           FROM
           replies
        )
    SQL
    return nil if question.length == 0
     quesiton.map { |hash| Reply.new(hash) }
  end

   def save
    if !self.id
    QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.author_id, self.body, self.parent_reply_id)
        INSERT INTO
         replies (question_id, author_id, body, parent_reply_id)
        VALUES
          (?, ?, ?, ?)
SQL
        self.id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.author_id, self.body, self.parent_reply_id, self.id)
        UPDATE
         replies
         SET
         question_id = ?, author_id = ?, body = ?, parent_reply_id = ?
        WHERE
          id = ?
SQL
    end
  end

end

class QuestionLikes
attr_accessor :id, :liker_id, :question_id
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |hash| QuestionLikes.new(hash) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    return nil if question.length == 0
    QuestionLikes.new(question.first)
  end

  def self.find_all_by_liker_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        liker_id = ?
    SQL
    return nil if question.length == 0
    question.map { |hash| QuestionLikes.new(hash) }
  end

    def self.likers_for_question_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        users.*
      FROM
        users
        JOIN question_likes ON question_likes.liker_id = users.id
      WHERE
       question_likes.question_id = ?
    SQL
    return nil if question.length == 0
    question.map { |hash| User.new(hash) }
  end

  def self.num_like_for_question_id(id)
     question = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
      COUNT(question_likes.question_id)
     FROM
        question_likes
    WHERE
      question_likes.question_id = ?

SQL
    return nil if question.length == 0
    question.first.values.first
  end

  def self.liked_questions_for_user_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
    questions.*
    FROM
    questions
    JOIN
    question_likes ON question_likes.question_id = questions.id
    JOIN
    users ON users.id = question_likes.liker_id
    WHERE
    users.id = ?
    SQL

    return nil if question.length == 0
    question.map { |hash| Question.new(hash) }
  end

  def self.most_liked_questions(n)
    question = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      question_likes ON questions.id = question_likes.question_id
    GROUP BY
    questions.id
    ORDER BY
    COUNT(question_likes.liker_id) DESC

  SQL
  return nil if question.length == 0
  question[0...n].map { |hash| Question.new(hash) }
  end

  def initialize(options)
    @id = options['id']
    @liker_id = options['liker_id']
    @question_id = options['question_id']
  end

end
