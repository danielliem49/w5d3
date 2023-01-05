require 'sqlite3'
require 'singleton'


class QuestionsDatabase < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end





class User
    attr_reader :id
    attr_accessor :fname, :lname

    def self.find_by_id(id)
        user = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?  
        SQL
        return nil unless user.length > 0

        User.new(user.first)
    end

    def self.find_by_name(fname, lname)
        user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
            SELECT
                *
            FROM
                users
            WHERE
                fname = ? AND lname = ?
        SQL
        return nil unless user.length > 0

        User.new(user.first)
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def authored_questions
        Question.find_by_author_id(self.id)
    end

    def authored_replies
        Reply.find_by_user_id(id)
    end

    def followed_questions
        QuestionFollows.followed_questions_for_user_id(id)
    end

    def liked_questions
        QuestionLike.liked_questions_for_user_id(id)
    end

    def average_karma
        average_question_likes = QuestionsDatabase.instance.execute(<<-SQL)

        SQL
    end
end





class Question
    attr_reader :id, :author_id
    attr_accessor :title, :body

    def self.find_by_id(id)
        question = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?  
        SQL
        return nil unless question.length > 0

        Question.new(question.first)
    end

    def self.find_by_author_id(author_id)
        questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                questions
            WHERE
                author_id = ?  
        SQL

        questions.map { |question| Question.new(question) }
    end

    def self.most_followed(n)
        QuestionFollows.most_followed_questions(n)
    end

    def self.most_liked(n)
        QuestionLike.most_liked_questions(n)
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end

    def author
        User.find_by_id(self.author_id)
    end

    def replies
        Reply.find_by_question_id(id)
    end

    def followers
        QuestionFollows.followers_for_question_id(id)
    end

    def likers
        QuestionLike.likers_for_question_id(id)
    end

    def num_likes
        QuestionLike.num_likes_for_question_id(id)
    end

end





class QuestionFollows

  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        users
      JOIN
        question_follows on users.id = question_follows.user_id
      WHERE
        question_id = ?
    SQL

    users.map { |user| User.new(user) }
  end

    def self.followed_questions_for_user_id(user_id)
        questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM
            questions
        JOIN
            question_follows on questions.id = question_follows.question_id
        WHERE
            user_id = ?
        SQL

        questions.map { |question| Question.new(question) }
    end

    def self.most_followed_questions(n)
        questions = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            *
        FROM
            questions
        JOIN
            question_follows on questions.id = question_follows.question_id
        GROUP BY
            questions.id
        ORDER BY
            COUNT(*) DESC 
        LIMIT 
            ?
        SQL
        questions.map { |question| Question.new(question) }
    end
end





class Reply
  attr_reader :id, :question_id, :parent_reply_id, :author_id
  attr_accessor :body

    def self.find_by_id(id)
        reply = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies
            WHERE
                id = ?  
        SQL
        return nil unless reply.length > 0

        Reply.new(reply.first)
    end

    def self.find_by_user_id(author_id)
        replies = QuestionsDatabase.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                replies
            WHERE
                author_id = ?
        SQL
        replies.map { |reply| Reply.new(reply) }
    end

    def self.find_by_question_id(question_id)
        replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                replies
            WHERE
                question_id = ?  
        SQL
        replies.map { |reply| Reply.new(reply) }
    end

    def self.find_by_parent_id(parent_reply_id)
        replies = QuestionsDatabase.instance.execute(<<-SQL, parent_reply_id)
            SELECT
                *
            FROM
                replies
            WHERE
                parent_reply_id = ?
        SQL
        replies.map { |reply| Reply.new(reply) }
    end

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @body = options['body']
        @parent_reply_id = options['parent_reply_id']
        @author_id = options['author_id']
    end

    def author
        User.find_by_id(self.author_id)
    end

    def question
        Question.find_by_id(question_id)
    end

    def parent_reply
        Reply.find_by_id(parent_reply_id)
    end

    def child_replies
        Reply.find_by_parent_id(self.id)
    end
end




class QuestionLike

    def self.likers_for_question_id(question_id)
        users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
          SELECT
            *
          FROM
            users
          JOIN
            question_likes on users.id = question_likes.user_id
          WHERE
            question_likes.question_id = ?
        SQL
        users.map { |user| User.new(user) }
    end

    def self.num_likes_for_question_id(question_id)
        users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
          SELECT
            COUNT(*)
          FROM
            questions
          JOIN
            question_likes on questions.id = question_likes.question_id
          WHERE
            questions.id = ?
        SQL
        users.first.values
    end

    def self.liked_questions_for_user_id(user_id)
        questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
          SELECT
            *
          FROM
            questions
          JOIN
            question_likes on questions.id = question_likes.question_id
          WHERE
            question_likes.user_id = ?
        SQL
        questions.map { |question| Question.new(question) }
    end

    def self.most_liked_questions(n)
        questions = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            *
        FROM
            questions
        JOIN
            question_likes on questions.id = question_likes.question_id
        GROUP BY
            questions.id
        ORDER BY
            COUNT(*) DESC 
        LIMIT 
            ?
        SQL
        questions.map { |question| Question.new(question) }
    end
end






class Tags
end





class QuestionTags
end