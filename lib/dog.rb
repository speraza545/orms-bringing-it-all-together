class Dog
    attr_accessor :name, :breed
    attr_reader :id

    def initialize(hash, id=nil)
        @name = hash[:name]
        @breed = hash[:breed]
        @id = id
    end

    def self.create_table
        sql = <<-SQL
            CREATE TABLE IF NOT EXISTS dogs(
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            )
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = <<-SQL 
            DROP TABLE IF EXISTS dogs
        SQL
        DB[:conn].execute(sql)
    end

    def save
        if self.id
            self.update
        else
        sql = <<-SQL
            INSERT INTO dogs(name, breed)
            VALUES(?, ?)
        SQL
        DB[:conn].execute(sql, self.name, self.breed)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    def self.create(name:, breed:)
        new_dog = self.new(name: name, breed: breed)
        new_dog.save
        new_dog
    end

    def self.new_from_db(row)
        self.new({name: row[1], breed: row[2]}, row[0])
    end

    def self.find_by_id(id)
        sql = <<-SQL
            SELECT * FROM dogs
            WHERE dogs.id = ?
            LIMIT 1
        SQL
        DB[:conn].execute(sql, id).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
            SELECT * 
            FROM dogs
            WHERE dogs.name = ? 
            AND dogs.breed = ?
            LIMIT 1
        SQL
        dog_array = DB[:conn].execute(sql, name, breed)
 
        if dog_array.empty?
            dog = self.create(name: name, breed: breed)
        else
            dog_data = dog_array[0]
            dog = self.new({name: dog_data[1], breed: dog_data[2]}, dog_data[0])
        end
        dog
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT *
            FROM dogs
            WHERE dogs.name = ?
            LIMIT 1
        SQL
        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end

    def update
        sql = <<-SQL
            UPDATE dogs 
            SET name = ?, breed = ? 
            WHERE id = ?
        SQL
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

end