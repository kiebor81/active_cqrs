# Active CQRS

[![Gem Version](https://badge.fury.io/rb/active_cqrs.svg)](https://badge.fury.io/rb/active_cqrs)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

`active_cqrs` is a lightweight Ruby gem that introduces **CQRS (Command Query Responsibility Segregation)** into your Rails applications. To keep with familiarity and common Rails conventions, Active CQRS builds directly on top of ActiveRecord. It intends to enforce a clean separation between commands (write operations) and queries (read operations), enabling better scalability and maintainability.

---

## What is CQRS?

**CQRS** stands for **Command Query Responsibility Segregation**, a pattern that separates read and write responsibilities into different models or services.

### CQRS vs ActiveRecord

| Feature | CQRS | ActiveRecord |
|--------|------|--------------|
| Write logic | Encapsulated in Command + Handler | In model callbacks or controllers |
| Read logic | Encapsulated in Query + Handler | Often mixed in models or controllers |
| Separation of concerns | ✅ Yes | ❌ No |
| Testability | ✅ High | ⚠️ Mixed |
| Performance tuning | ✅ Fine-grained | ⚠️ Monolithic |
| Domain logic isolation | ✅ Clear | ❌ Often leaky |

---

## Pitfalls

### ActiveRecord
- Logic is mixed in models/controllers.
- Hard to maintain as apps grow.
- Difficult to test in isolation.

### CQRS
- More boilerplate (partially solved by this gem).
- Might be overkill for simple CRUD apps.

---

## When to Use CQRS

Use CQRS if:
- You're building a large or growing Rails app.
- You want strong separation between reads/writes.
- You're scaling to microservices or event sourcing.

Avoid if:
- Your app is very small or CRUD-heavy.
- You don’t want added architectural complexity.

---

## Active CQRS Design

```plantuml
@startuml CQRS_Pattern

skinparam style strict
skinparam linetype ortho

actor User

package "Application Layer" {
  [Command] --> [Command Handler]
  [Query] --> [Query Handler]
}

package "Domain Layer" {
  [Command Handler] --> [Domain Model]
}

package "Persistence Layer" {
  [Domain Model] --> [Write Database]
  [Query Handler] --> [Read Database]
}

User --> [Command]
User <--> [Query]

@enduml

```

```plantuml
@startuml ActiveCqrs_Implementation

skinparam style strict
skinparam linetype ortho

actor User

package "Application Layer" {
  [Command]
  [Query]
}

package "Active CQRS" {
  [CommandBus]
  [QueryBus]
  [AutoRegistrar]
}

package "Domain Layer" {
  [Command Handler] --> [Domain Model]
  [Query Handler] --> [Domain Model]
}

package "Persistence Layer" {
  [Domain Model] --> [Write Database]
  [Domain Model] --> [Read Database]
}

User --> [Command]
[Command] --> [CommandBus]
[CommandBus] --> [Command Handler]

User <--> [Query]
[Query] --> [QueryBus]
[QueryBus] --> [Query Handler]

@enduml

```

---

## Installation

Add this line to your Gemfile:

```ruby
gem 'active_cqrs'
```

Then run:

```sh
bundle install
```

---

## Setup

Run the installer:

```sh
rails generate cqrs:install
```

This creates:

```ruby
# config/initializers/cqrs.rb
CQRS_COMMAND_BUS = ActiveCqrs::CommandBus.new
CQRS_QUERY_BUS   = ActiveCqrs::QueryBus.new

ActiveCqrs::AutoRegistrar.new(
  command_bus: CQRS_COMMAND_BUS,
  query_bus:   CQRS_QUERY_BUS
).call
```

### Logging

In `config/initializers/cqrs.rb`:

```ruby
ActiveCqrs::Logger.enabled = Rails.env.development?
```

You’ll see logs like:

```
[CQRS] Loaded handler file: app/handlers/commands/create_user_handler.rb
[CQRS] Registered CreateUserHandler for CreateUserCommand
```

---

## Usage

Using Active CQRS' generators will create the command/query stub and handlers. Based on your [data strategy](#practical-implementation-advice), you will need to finalise the command and query classes with your execution logic.

### Generate a Command

```sh
rails generate cqrs:command CreateUser
```

This creates:

```ruby
# app/commands/create_user_command.rb
class CreateUserCommand
  attr_reader :attributes
  def initialize(attributes = {})
    @attributes = attributes
  end
end
```

```ruby
# app/handlers/commands/create_user_handler.rb
class CreateUserHandler
  def call(command)
    # Implement your command logic here
    #
    # Access command attributes via: command.attributes[:key]
    # 
    # Example where `Record` is your Active Record model:
    # record = Record.new(command.attributes)
    # if record.save
    #   return record
    # else
    #   raise ActiveRecord::RecordInvalid, record
    # end
    raise NotImplementedError, "Define #{self.class.name}#call"
  end
end
```

### Generate a Query

```sh
rails generate cqrs:query GetUser
```

This creates:

```ruby
# app/queries/get_user_query.rb
class GetUserQuery
  attr_reader :criteria

  def initialize(criteria = {})
    @criteria = criteria
  end
end
```

```ruby
# app/handlers/queries/get_user_handler.rb
class GetUserHandler
  def call(query)
    # Implement your query logic here
    #
    # Access query criteria via: query.criteria[:key]
    #
    # Example where `Record` is your Active Record model:
    # Record.find_by(id: query.criteria[:id])
    raise NotImplementedError, "Define #{self.class.name}#call"
  end
end
```

---

### Using Active CQRS

The Command and Query buses are defined globally. This means you can seamlessly integrate Active CQRS into your architecture.

Wherever it is called from, the pattern is:

```
Create command instance -> execute with command bus
Create query instance -> execute with query bus
```

```ruby
    command = CreateUserCommand.new(
      name: params[:name],
      email: params[:email]
    )

    user = CQRS_COMMAND_BUS.call(command)
```

```ruby
    query = GetUserQuery.new(id: params[:id])
    user = CQRS_QUERY_BUS.call(query)
```

### Use Active CQRS in Your Controller

```ruby
class UsersController < ApplicationController
  def create
    command = CreateUserCommand.new(
      name: params[:name],
      email: params[:email]
    )

    user = CQRS_COMMAND_BUS.call(command)

    render json: user, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def show
    query = GetUserQuery.new(id: params[:id])
    user = CQRS_QUERY_BUS.call(query)

    if user
      render json: user
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end
end

```

### Use Active CQRS from a Service Context

```ruby
# app/services/create_user_service.rb
class CreateUserService
  def initialize(name:, email:)
    @name = name
    @email = email
  end

  def call
    command = CreateUserCommand.new(
      name: @name,
      email: @email
    )

    CQRS_COMMAND_BUS.call(command)
  rescue ActiveRecord::RecordInvalid => e
    handle_validation_failure(e)
  end

  private

  def handle_validation_failure(exception)
    # Custom error handling logic
    raise exception
  end
end

```

### Use Active CQRS in a Custom Middleware

```ruby
def dispatch_command(command)
  Rails.logger.info("Dispatching #{command.class.name}")
  CQRS_COMMAND_BUS.call(command)
rescue => e
  Rails.logger.error("Command failed: #{e.message}")
  raise
end

def execute_query(query)
  Rails.logger.info("Querying #{query.class.name}")
  CQRS_QUERY_BUS.call(query)
end

```

## Advanced CQRS Design

Active CQRS is flexible enough to expand into a more robust underlying data strategy. The developer can determine how broadly or robust separation should be implemented. By design, generated handlers are open to any implementation.

### Practical Implementation Advice

**Use Read/View Models for Queries**

```ruby
class UserView
  def self.find_by_id(id)
    User.select(:id, :name, :email).find_by(id: id)
  end
end
```

**Enforce Read-Only Model for Queries**

```ruby
class UserView < ApplicationRecord
  self.table_name = "users"
  def readonly?
    true
  end
end
```

**Use POROs, DTOs, or serialized Return Types to Obfuscate Active Record**

```ruby
def call(query)
  user = User.find_by(id: query.criteria[:id])
  return nil unless user

  OpenStruct.new(id: user.id, name: user.name, email: user.email)
end

```

**Split Concerns Across Databases**

For advanced configurations, you can fully separate read and write responsibilities by connecting your Rails application to two distinct databases. These can be kept in sync using replication or background job–based synchronization.

```yml
default: &default
  adapter: postgresql
  encoding: unicode

development:
  primary:
    <<: *default
    database: write_db

  reporting:
    <<: *default
    database: read_db
```

You can create a single base class configured to perform commands and queries separately, and use Active CQRS without any further configuration.

```ruby
class CqrsRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :primary, reading: :reporting }
end
```

Alternatively, define base classes distinctly for each database

```ruby
# app/models/write_record.rb
class WriteRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :primary }
end

# app/models/read_record.rb
class ReadRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { reading: :reporting }
end
```

Define models per DB to enforce separation

```ruby
# Write model
class User < WriteRecord
  # Used in command handlers
end

# Read model
class UserView < ReadRecord
  self.table_name = "users"
  def readonly?
    true
  end
end
```

If you’re not using native database replication, you can define a background job to synchronize write-side changes to the read database

```ruby
class SyncUserToReadDbJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    return unless user

    UserView.upsert({ id: user.id, name: user.name, email: user.email })
  end
end
```

Execute job after successful execution in the command handler

```ruby
class CreateUserHandler
  def call(command)
    user = User.create!(command.attributes)

    # Trigger sync job to propagate to read DB
    SyncUserToReadDbJob.perform(user.id)

    user
  end
end
```

Alternatively, you can move the job trigger into an `after_commit` callback on the User model for implicit syncing behaviour.

```ruby
class User < WriteRecord
  after_commit :sync_to_read_model, on: [:create, :update]

  private

  def sync_to_read_model
    SyncUserToReadDbJob.perform(id)
  end
end

```

---

### Active CQRS with DDD (_Rails-Domino_)

Active CQRS is compatible with [Rails-Domino](https://github.com/kiebor81/rails-domino).

```bash
rails generate domino user name:string email:string --with-model
```

```bash
rails generate cqrs:command CreateUser
```

The `user_service` can be injected into and used from inside the command handler.

```ruby
# app/handlers/commands/create_user_handler.rb
class CreateUserHandler
  def call(command)
    user_service.create(command.attributes)
  end

  private

  def user_service
    Domino::Container["user_service"]
  end
end
```

Similarly, we can access the `user_repository` from any query handler

```ruby
# app/handlers/queries/get_user_handler.rb
class GetUserHandler
  def call(query)
    user_repository.get(query.criteria[:id])
  end

  private

  def user_repository
    Domino::Container["user_repository"]
  end
end
```

Alternatively create a dedicated service for querying

```ruby
# app/services/user_query_service.rb
class UserQueryService
  include Domino::Import["user_repository"]

  def find_by_email(email)
    user_repository.find_by(email: email)
  end
end
```

Register it in Domino

```ruby
# config/initializers/domino_container.rb
Domino::Container.register("user_query_service", -> { UserQueryService.new })
```

Re-use the service in query handlers

```ruby
# app/handlers/queries/get_user_by_email_handler.rb
class GetUserByEmailHandler
  def call(query)
    user_query_service.find_by_email(query.criteria[:email])
  end

  private

  def user_query_service
    Domino::Container["user_query_service"]
  end
end
```

In this setup, Domino's generated controllers become defunct, but we can modify them to use our CQRS buses and maintain the DDD pattern.

```ruby
class UsersController < ApplicationController

  def index
    query = GetAllUsersQuery.new
    users = CQRS_QUERY_BUS.call(query)
    render json: UserBlueprint.render(users)
  end

  def show
    query = GetUserQuery.new(id: params[:id])
    user = CQRS_QUERY_BUS.call(query)

    if user
      render json: UserBlueprint.render(user)
    else
      head :not_found
    end
  end

  def create
    command = CreateUserCommand.new(resource_params)
    user = CQRS_COMMAND_BUS.call(command)
    render json: UserBlueprint.render(user), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def update
    command = UpdateUserCommand.new(id: params[:id], **resource_params.to_h)
    user = CQRS_COMMAND_BUS.call(command)
    render json: UserBlueprint.render(user)
  end

  def destroy
    command = DeleteUserCommand.new(id: params[:id])
    CQRS_COMMAND_BUS.call(command)
    head :no_content
  end

  private

  def resource_params
    params.require(:user).permit(:name, :email)
  end
end
```

---

## License

MIT License © kiebor81

## Contributing

Pull requests welcome!
