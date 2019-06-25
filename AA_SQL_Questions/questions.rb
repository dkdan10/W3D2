require 'sqlite3'
require 'singleton'


# SQLite3::Database.new( "./questions.db" ) do |db|
#   db.execute( "select * from table" ) do |row|
#     p row
#   end
# end

class QuestionsDB < SQLite3::Database
  include Singleton
  def initialize
    super('./questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_reader :id
  attr_accessor :fname, :lname
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def save 
    if !@id 
      QuestionsDB.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
      users(fname, lname)
      VALUES 
      (?, ?)
      SQL
      @id = QuestionsDB.instance.last_insert_row_id
    else
      update
    end
  end

  private
  def update 
    QuestionsDB.instance.execute(<<-SQL, @fname, @lname, @id)
    UPDATE
    users
    SET 
    fname = ?, lname = ?
    WHERE
    id = ?
    SQL
  end
  public

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users 
      WHERE
        id =?
    SQL
    data.map{|datum| User.new(datum)}.first
  end

  def self.find_by_name(fname, lname)
    data = QuestionsDB.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users 
      WHERE
        fname = ? AND lname = ?
    SQL
    data.map{|datum| User.new(datum)}.first
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end 

  def authored_replies
    QuestionReply.find_by_user_id(self.id)
  end

  def followed_questions 
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions 
    QuestionLike.liked_questions_for_user_id(self.id)
  end
    
  def average_karma 
    data = QuestionsDB.instance.execute(<<-SQL, self.id)
    SELECT
      CAST(COUNT(question_likes.user_id) AS FLOAT) / COUNT(DISTINCT questions.id) AS avg_karma
    FROM 
      questions
    LEFT OUTER JOIN question_likes
      ON question_likes.question_id = questions.id
    WHERE
      questions.author_id = ?
    SQL
    data.first['avg_karma']
  end

  # def average_karma 
  #   data = QuestionsDB.instance.execute(<<-SQL, self.id)
  #     SELECT
  #     CAST(COUNT(question_likes.user_id) AS FLOAT) / COUNT(DISTINCT questions.id) AS avg_karma
  #     FROM
  #       questions 
  #     LEFT OUTER JOIN 
  #     question_likes ON questions.id = question_likes.question_id 
  #     WHERE
  #       questions.author_id = 1
  #   SQL
  #   data.first
  # end
end

class Question
  attr_reader :id
  attr_accessor :title, :body, :author_id
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def save 
    if !@id 
      QuestionsDB.instance.execute(<<-SQL, @title, @body, @author_id)
      INSERT INTO
      questions(title, body, author_id)
      VALUES 
      (?, ?, ?)
      SQL
      @id = QuestionsDB.instance.last_insert_row_id
    else
      update
    end
  end

  private
  def update 
    QuestionsDB.instance.execute(<<-SQL, @title, @body,  @author_id, @id)
    UPDATE
    questions
    SET 
    title = ?, body = ?, author_id = ?
    WHERE
    id = ?
    SQL
  end
  public

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id =?
    SQL
    data.map{|datum| Question.new(datum)}.first
  end

  def self.find_by_title(title)
    data = QuestionsDB.instance.execute(<<-SQL, title)
      SELECT
        *
      FROM
        questions
      WHERE
        title =?
    SQL
    data.map{|datum| Question.new(datum)}
  end

  def self.find_by_author_id(author_id)
    data = QuestionsDB.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    data.map{|datum| Question.new(datum)}
  end

  def author 
    User.find_by_id(self.author_id)
  end 


  def replies 
    QuestionReply.find_by_question_id(self.id)
  end

  def followers 
    QuestionFollow.followers_for_question_id(self.id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def num_likes 
    QuestionLike.num_likes_for_question_id(self.id)
  end

  def likers 
    QuestionLike.likers_for_question_id(self.id)
  end

  def self.most_liked(n) 
    QuestionLike.most_liked_questions(n)
  end

end

class QuestionFollow
  attr_reader :id
  attr_accessor :question_id, :user_id
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id'] 
  end

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows 
      WHERE
        id =?
    SQL
    data.map{|datum| QuestionFollow.new(datum)}
  end

  def self.followers_for_question_id(question_id)
    ## Based in the question id find the users that followed the question with that id
    data = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
        DISTINCT users.*
      FROM
        question_follows 
      JOIN
        users ON
        users.id = question_follows.user_id 
      WHERE
        question_follows.question_id =?
    SQL
    data.map{|datum| User.new(datum)}
  end

  def self.followed_questions_for_user_id(user_id)
    ## Based on user id find the questions that user of that id follows the question with id
    data = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT
        DISTINCT questions.*
      FROM
        question_follows 
      JOIN
        questions ON
        questions.id = question_follows.question_id 
      WHERE
        question_follows.user_id =?
    SQL
    data.map{|datum| Question.new(datum)}
  end

  def self.most_followed_questions(n)
    ## we want to know n number of questions that are ordered by most followed
    data = QuestionsDB.instance.execute(<<-SQL, n)
      SELECT
        DISTINCT questions.*
      FROM
        question_follows 
      JOIN
        questions ON
        questions.id = question_follows.question_id 
      GROUP BY
        question_follows.question_id
      ORDER BY 
        COUNT(DISTINCT question_follows.user_id) DESC
      LIMIT ?
    SQL
    data.map{|datum| Question.new(datum)}
  end

end

class QuestionReply
  attr_reader :id
  attr_accessor :user_id, :body, :parent_id, :question_id
    def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @body = options['body']
    @parent_id = options['parent_id']
  end

  def save 
    if !@id 
      QuestionsDB.instance.execute(<<-SQL, @question_id, @user_id, @body,  @parent_id)
      INSERT INTO
      replies(question_id, user_id, body, parent_id)
      VALUES 
      (?, ?, ?, ?)
      SQL
      @id = QuestionsDB.instance.last_insert_row_id
    else
      update
    end
  end

  private
  def update 
    QuestionsDB.instance.execute(<<-SQL, @question_id, @user_id, @body,  @parent_id, @id)
    UPDATE
    replies
    SET 
    question_id = ?, user_id = ?, body = ?, parent_id = ?
    WHERE
    id = ?
    SQL
  end
  public

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies 
      WHERE
        id =?
    SQL
    data.map{|datum| QuestionReply.new(datum)}.first
  end

  def self.find_by_question_id(question_id)
    data = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies 
      WHERE
        question_id =?
    SQL
    data.map{|datum| QuestionReply.new(datum)}
  end

  def self.find_by_user_id(user_id)
    data = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies 
      WHERE
        user_id =?
    SQL
    data.map{|datum| QuestionReply.new(datum)}
  end

  def author 
    User.find_by_id(self.user_id)
  end

  def question 
    Question.find_by_id(self.question_id)
  end

  def parent_reply 
    return nil unless self.parent_id
    QuestionReply.find_by_id(self.parent_id)
  end

  def child_replies 
    data = QuestionsDB.instance.execute(<<-SQL, self.id)
      SELECT
        *
      FROM
        replies 
      WHERE
        parent_id = ?
    SQL
    data.map {|datum| QuestionReply.new(datum)}
  end
end

class QuestionLike
  attr_reader :id
  attr_accessor :user_id, :question_id
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.find_by_question_id(question_id)
    data = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies 
      WHERE
        question_id =?
    SQL
    data.map{|datum| QuestionLike.new(datum)}
  end

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes 
      WHERE
        id =?
    SQL
    data.map{|datum| QuestionLike.new(datum)}.first
  end

  def self.likers_for_question_id(question_id)
    data = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
        DISTINCT users.*
      FROM
        question_likes 
      JOIN 
        users 
      ON users.id = question_likes.user_id
      WHERE
        question_likes.question_id = ?
    SQL
    data.map{|datum| User.new(datum)}
  end

  def self.num_likes_for_question_id(question_id)
    data = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
       COUNT(DISTINCT user_id) AS num_likes
      FROM
        question_likes
      WHERE
        question_likes.question_id = ?
    SQL
    data.first['num_likes']
  end

  def self.liked_questions_for_user_id(user_id)
    data = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT 
        questions.*
      FROM 
        question_likes 
      JOIN
        questions ON 
        questions.id = question_likes.question_id 
      WHERE 
        question_likes.user_id = ?
    SQL
    data.map{|datum| Question.new(datum)}
  end

  def self.most_liked_questions(n)
    ## we want to know n number of questions that are ordered by most followed
    data = QuestionsDB.instance.execute(<<-SQL, n)
      SELECT
        DISTINCT questions.*
      FROM
        question_likes 
      JOIN
        questions ON
        questions.id = question_likes.question_id 
      GROUP BY
        question_likes.question_id
      ORDER BY 
        COUNT(DISTINCT question_likes.user_id) DESC
      LIMIT ?
    SQL
    data.map{|datum| Question.new(datum)}
  end
end