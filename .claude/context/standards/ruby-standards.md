# Ruby Standards

> Ruby development standards

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Ruby](#ruby)

---

<!-- Source: standards/backend/ruby.md (v1.0.0) -->

# Ruby Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines Ruby coding standards and best practices for Rails 7 backend services, covering style, patterns, ActiveRecord, error handling, testing, and security.

## Style Guide Foundation
- **Ruby Style Guide**: Foundation for all Ruby code (community-driven)
- **Ruby 3.2+**: Use modern features (pattern matching, Data classes, Ractors)
- **Line length**: 120 characters maximum
- **RuboCop**: Enforced via `.rubocop.yml` in every project

## Code Formatting

### Imports
```ruby
# Standard library requires (rarely needed in Rails)
require "json"
require "net/http"

# Gem requires (typically handled by Bundler)
require "sidekiq"
require "redis"

# Application requires (autoloaded in Rails — avoid explicit requires)
# Rails autoloads app/, lib/ — do not add require statements for these
```

**Import Order:**
1. Standard library (`require "json"`, `require "net/http"`)
2. Third-party gems (typically via Bundler, rarely explicit)
3. Application code is autoloaded in Rails — do not use `require` for app files
4. Use `require_relative` only in non-Rails scripts or initializers

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes/Modules | PascalCase | `UserService`, `OrdersController` |
| Methods/Variables | snake_case | `find_by_email`, `order_count` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Files | snake_case | `user_service.rb`, `orders_controller.rb` |
| Database tables | snake_case plural | `users`, `order_items` |
| Predicates | snake_case with `?` | `active?`, `admin?` |
| Dangerous methods | snake_case with `!` | `save!`, `destroy!` |
| Symbols | snake_case | `:status`, `:created_at` |

## Type System

### Strong Parameters
```ruby
class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    if user.save
      render json: UserSerializer.new(user), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
```

### Value Objects with Data Class
```ruby
# Ruby 3.2+ Data class for immutable value objects
UserResponse = Data.define(:id, :name, :email, :created_at) do
  def self.from(user)
    new(
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at.iso8601,
    )
  end
end
```

## Framework Patterns

### ActiveRecord Models
```ruby
class User < ApplicationRecord
  # Associations
  has_many :orders, dependent: :destroy
  has_one :profile, dependent: :destroy
  belongs_to :organization, optional: true

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_required?

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_role, ->(role) { where(role: role) }

  # Enums
  enum :status, { active: 0, inactive: 1, suspended: 2 }, default: :active
  enum :role, { member: 0, admin: 1, owner: 2 }, default: :member

  # Callbacks — use sparingly, prefer service objects for complex logic
  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip
  end

  def password_required?
    new_record? || password.present?
  end
end
```

### Controller Pattern
```ruby
class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show update destroy]

  def index
    users = User.active.recent.page(params[:page])
    render json: UserSerializer.new(users)
  end

  def show
    render json: UserSerializer.new(@user)
  end

  def create
    result = Users::CreateService.call(user_params)

    if result.success?
      render json: UserSerializer.new(result.user), status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
```

### Service Objects
```ruby
module Users
  class CreateService
    include ActiveModel::Validations

    attr_reader :user

    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
      @user = nil
    end

    def call
      ActiveRecord::Base.transaction do
        @user = User.create!(@params)
        ProfileService.create_default!(@user)
        WelcomeMailer.welcome_email(@user).deliver_later
      end

      OpenStruct.new(success?: true, user: @user, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      OpenStruct.new(success?: false, user: nil, errors: e.record.errors.full_messages)
    end
  end
end
```

### Concerns
```ruby
# app/models/concerns/sluggable.rb
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, on: :create
    validates :slug, presence: true, uniqueness: true
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name&.parameterize
  end
end

# Usage in model
class Article < ApplicationRecord
  include Sluggable
end
```

## Error Handling

### Exception Hierarchy
```ruby
module Errors
  class ApplicationError < StandardError
    attr_reader :code, :status

    def initialize(message, code:, status: :internal_server_error)
      @code = code
      @status = status
      super(message)
    end
  end

  class NotFoundError < ApplicationError
    def initialize(resource, id)
      super("#{resource} not found: #{id}", code: :not_found, status: :not_found)
    end
  end

  class DuplicateError < ApplicationError
    def initialize(field, value)
      super("#{field} already exists: #{value}", code: :duplicate, status: :conflict)
    end
  end

  class ForbiddenError < ApplicationError
    def initialize(message = "Access denied")
      super(message, code: :forbidden, status: :forbidden)
    end
  end
end
```

### Global Exception Handler
```ruby
class ApplicationController < ActionController::API
  rescue_from Errors::ApplicationError do |e|
    render json: {
      error: { code: e.code, message: e.message, timestamp: Time.current.iso8601 },
    }, status: e.status
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: {
      error: { code: :not_found, message: e.message, timestamp: Time.current.iso8601 },
    }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: {
      error: { code: :bad_request, message: e.message, timestamp: Time.current.iso8601 },
    }, status: :bad_request
  end
end
```

### Rules
- Raise domain exceptions in service objects, not HTTP exceptions
- Never rescue `Exception` — rescue `StandardError` or more specific classes
- Always include context in exception messages
- Use `save!` and `create!` in transactions to trigger rollback on failure
- Use `rescue_from` in controllers for consistent error responses

## Testing Standards

### Unit Tests with RSpec
```ruby
RSpec.describe Users::CreateService do
  describe ".call" do
    let(:valid_params) do
      { name: "John", email: "john@example.com", password: "secure123",
        password_confirmation: "secure123" }
    end

    context "with valid params" do
      it "creates a user" do
        result = described_class.call(valid_params)

        expect(result).to be_success
        expect(result.user).to be_persisted
        expect(result.user.email).to eq("john@example.com")
      end

      it "sends a welcome email" do
        expect { described_class.call(valid_params) }
          .to have_enqueued_mail(WelcomeMailer, :welcome_email)
      end
    end

    context "with duplicate email" do
      before { create(:user, email: "john@example.com") }

      it "returns failure" do
        result = described_class.call(valid_params)

        expect(result).not_to be_success
        expect(result.errors).to include(/email/i)
      end
    end
  end
end
```

### Model Tests
```ruby
RSpec.describe User do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
  end

  describe "associations" do
    it { is_expected.to have_many(:orders).dependent(:destroy) }
    it { is_expected.to have_one(:profile).dependent(:destroy) }
  end

  describe "#active?" do
    it "returns true for active users" do
      user = build(:user, status: :active)
      expect(user).to be_active
    end
  end
end
```

### FactoryBot Factories
```ruby
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "secure123" }
    password_confirmation { "secure123" }
    status { :active }
    role { :member }

    trait :admin do
      role { :admin }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :with_orders do
      after(:create) do |user|
        create_list(:order, 3, user: user)
      end
    end
  end
end
```

## Security Best Practices

1. **Never log credentials or PII** — filter parameters in `config/initializers/filter_parameter_logging.rb`
2. **Strong parameters** on all controller inputs — never use `params.permit!`
3. **Parameterized queries** via ActiveRecord — never interpolate SQL strings
4. **Store secrets** in Rails credentials or environment variables (never in code)
5. **CORS configuration** restricted per environment via `rack-cors` gem
6. **CSRF protection** enabled for browser-facing endpoints
7. **Brakeman** static analysis in CI — zero warnings policy

## Quality Gates

```bash
# Tests
bundle exec rspec

# Lint / Style
bundle exec rubocop

# Security audit
bundle exec brakeman --no-pager

# Dependency vulnerability scan
bundle audit check --update

# Full CI check
bundle exec rspec && bundle exec rubocop && bundle exec brakeman -q
```

## References

- [Ruby Style Guide](https://rubystyle.guide/)
- [Rails Guides](https://guides.rubyonrails.org/)
- [RSpec Documentation](https://rspec.info/documentation/)
- [RuboCop Documentation](https://docs.rubocop.org/)
- [Brakeman Security Scanner](https://brakemanscanner.org/)
- [FactoryBot Getting Started](https://github.com/thoughtbot/factory_bot/blob/main/GETTING_STARTED.md)

---

*Last updated: February 2026*

---

<!-- Compilation Metadata
  domain: ruby-standards
  domain_version: 1.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 1/1
-->