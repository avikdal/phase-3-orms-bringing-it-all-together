class Dog

    attr_accessor :name, :breed, :id

    def initialize (name:, breed:, id: nil)
        @id = id
        @name = name
        @breed = breed
    end

    def self.drop_table
        sql = <<-SQL
            DROP TABLE IF EXISTS dogs
        SQL

        DB[:conn].execute(sql)
    end

    def self.create_table
        sql = <<-SQL
            CREATE TABLE IF NOT EXISTS dogs (
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            )
        SQL

        DB[:conn].execute(sql)
    end

    def save
        sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES(?, ?)
        SQL

        # insert the dog attributes
        DB[:conn].execute(sql, self.name, self.breed)

        #get the dog ID from the database and save it to the Ruby instance
        self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]

        #return instance
        self
    end

    def better_save
        # expand #saves functionality! You should change it so that it handles these two cases: 1. If called on a Dog instance that doesn't have an ID assigned, insert a new row into the database, and return the saved Dog instance. 2. If called on a Dog instance that does have an ID assigned, use the #update method to update the existing dog in the database, and return the updated Dog instance.
        
        if self.id
            self.update
          else
            sql = <<-SQL
              INSERT INTO dogs (name, breed)
              VALUES (?, ?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
          end
          self
    end

    def self.create (name:, breed:)
        dog = Dog.new(name: name, breed: breed)
        dog.save
    end

    def self.new_from_db(row)

        # The database is going to return an array representing a dog's data. We need a way to cast that data into the appropriate attributes of a dog. This method encapsulates that functionality. You can even think of it as new_from_array. Methods like this, that return instances of the class (a row of the table), are known as constructors, just like .new, except that they extend the functionality of .new without overwriting initialize.

            # self.new is equivalent to Dog.new
        self.new(id: row[0], name: row[1], breed: row[2])
    end

    def self.all
        sql = <<-SQL
          SELECT *
          FROM dogs
        SQL
    
        DB[:conn].execute(sql).map do |row|
          self.new_from_db(row)
        end
      end

      def self.find_by_name(name)
        # The spec for this method will first insert a dog into the database and then attempt to find it by calling the find_by_name method. The expectations are that an instance of the dog class that has all the properties of a dog is returned, not primitive data.

        # Internally, what will the .find_by_name method do to find a dog; which SQL statement must it run? Additionally, what method might .find_by_name use internally to quickly take a row and create an instance to represent that data?

        # Note: You may be tempted to use the Dog.all method to help solve this one. While we applaud your intuition to try and keep your code DRY, in this case, reusing that code is actually not the best approach. Why? Remember, with Dog.all, we're loading all the records from the dogs table and converting them to an array of Ruby objects, which are stored in our program's memory. What if our dogs table had 10,000 rows? That's a lot of extra Ruby objects! In cases like these, it's better to use SQL to only return the dogs we're looking for, since SQL is extremely well-equipped to work with large sets of data.

        sql = <<-SQL
          SELECT *
          FROM dogs
          WHERE name = ?
          LIMIT 1
        SQL
    
        DB[:conn].execute(sql, name).map do |row|
          self.new_from_db(row)
        end.first
        
        # Don't be freaked out by that #first method chained to the end of the DB[:conn].execute(sql, name).map block. The return value of the #map method is an array, and we're simply grabbing the #first element from the returned array. Chaining is cool!
      end

      def self.find(id)
        # This class method takes in an ID, and should return a single Dog instance for the corresponding record in the dogs table with that same ID. It behaves similarly to the .find_by_name method above.

        sql = <<-SQL
            SELECT * 
            FROM dogs
            WHERE dogs.id = ?
            LIMIT 1
        SQL

        DB[:conn].execute(sql, id).map do |row|
            self.new_from_db(row)
        end.first
      end

      def self.find_or_create_by(name:, breed:)
        # This method takes a name and a breed as keyword arguments. If there is already a dog in the database with the name and breed provided, it returns that dog. Otherwise, it inserts a new dog into the database, and returns the newly created dog.

        sql = <<-SQL
          SELECT *
          FROM dogs
          WHERE name = ?
          AND breed = ?
          LIMIT 1
        SQL
    
        row = DB[:conn].execute(sql, name, breed).first
    
        if row
          self.new_from_db(row)
        else
          self.create(name: name, breed: breed)
        end
      end
    
      def update
        # The spec for this method will create and insert a dog, and afterwards, it will change the name of the dog instance and call update. The expectations are that after this operation, there is no dog left in the database with the old name. If we query the database for a dog with the new name, we should find that dog and the ID of that dog should be the same as the original, signifying this is the same dog, they just changed their name. The SQL you'll need to write for this method will involve using the UPDATE keyword.

        sql = <<-SQL
          UPDATE dogs 
          SET 
            name = ?, 
            breed = ?  
          WHERE id = ?;
        SQL
        
        DB[:conn].execute(sql, self.name, self.breed, self.id)
      end
end
