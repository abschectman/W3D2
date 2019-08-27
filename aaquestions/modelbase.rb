require 'sqlite3'
require 'singleton'
require 'active_support/inflector'


class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('quest.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end
class ModelBase < QuestionsDatabase
  attr_accessor :id

  def initialize(option)
    @id = option['id']
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.make_string}
      WHERE
        id = ?
    SQL
    return nil if user.length == 0
    self.send(:new, user.first)
    # user.first
  end

  def self.all
    user = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.make_string}
    SQL
    return nil if user.length == 0
    user.map { |hash| self.send(:new, hash) }
  end

  def self.make_string
    self.to_s.tableize
  end

  def self.where(options)
    k = options.keys[0]
    val = options.values[0]
    user = QuestionsDatabase.instance.execute(<<-SQL, k, val)
      SELECT
        *
      FROM
        #{self.make_string}
      WHERE
         #{self.make_string}.? = ?
    SQL
    return nil if user.length == 0
    user.map { |hash| self.send(:new, hash) }
  end

end