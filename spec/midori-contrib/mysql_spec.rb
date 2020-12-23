require 'midori-contrib/sequel/mysql2'

RSpec.describe 'Sequel' do
  describe 'MySQL' do
    it 'do query' do
      answer = []
      Thread.new do
        Fiber.set_scheduler Evt::Scheduler.new

        Fiber.schedule do
          @mysql = Sequel.connect('mysql2://root@localhost:5432/ci_test')

          @mysql.run <<-SQL
            DROP TABLE IF EXISTS tests;
          SQL

          @mysql.run <<-SQL
            CREATE TABLE IF NOT EXISTS tests (
              id SERIAL,
              title varchar(64),
              PRIMARY KEY(id)
            );
          SQL

          class Test < Sequel::Model(@mysql[:tests])
          end

          test = Test.new
          test.title = 'test'
          test.save

          Test.where(title: 'test').each { |r|
            answer << r.title
          }
        end

        answer << 0
      end.join

      expect(answer).to eq([0, 'test'])
    end

    it 'query acync' do
      expect do
        @answer = []
        @mysql = Sequel.connect('mysql2://root@localhost:5432/ci_test')
        Thread.new do
          Fiber.set_scheduler Evt::Scheduler.new
          Fiber.schedule do
            10.times do
              @answer << (@mysql.run <<-SQL
                SELECT COUNT(*) FROM tests;
              SQL
              )
            end
          end
        end.join
      end.to_not raise_error(RuntimeError)
    end
  end
end
