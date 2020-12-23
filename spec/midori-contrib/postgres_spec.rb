require 'midori-contrib/sequel/postgres'

RSpec.describe 'Sequel' do
  describe 'Postgres' do
    it 'do query' do
      answer = []
      Thread.new do
        Fiber.set_scheduler Evt::Scheduler.new

        Fiber.schedule do
          @postgres = Sequel.connect('postgres://postgres@localhost:5432/ci_test')
          @postgres.run <<-SQL
            DROP TABLE IF EXISTS products;
          SQL

          @postgres.run <<-SQL
            CREATE TABLE IF NOT EXISTS products (
              id SERIAL,
              title varchar(64),
              PRIMARY KEY(id)
            );
          SQL

          class Product < Sequel::Model(@postgres[:products])
          end

          product = Product.new
          product.title = 'test'
          product.save

          Product.where(title: 'test').each { |r|
            answer << r.title
          }
        end
        answer << 0
      end.join

      expect(answer).to eq([0, 'test'])
    end
  end
end
