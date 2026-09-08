---
title: Authentication
---

# Authentication

Authentication verifies identity. Authentication confirms that the person or the system that makes a request is the person or system it claims to be.

In Clean Architecture, authentication is a Use Case with a Gateway behind it. The Delivery Mechanism extracts the credentials from the request. The Use Case verifies the credentials.

## Authentication as a Use Case

```ruby
class AuthenticateUser
  def initialize(user_gateway:, session_gateway:)
    @user_gateway = user_gateway
    @session_gateway = session_gateway
  end

  def execute(email:, password:)
    user = @user_gateway.find_by_email(email)
    return { success: false, errors: [:invalid_credentials] } unless user
    return { success: false, errors: [:invalid_credentials] } unless valid_password?(user, password)

    session = @session_gateway.create(user_id: user.id)
    { success: true, token: session.token }
  end

  private

  def valid_password?(user, password)
    BCrypt::Password.new(user.password_digest) == password
  end
end
```

`find_by_email` returns a `User` [Domain](../../domain.md) object, not a row. The email address is the value that locates the `User`. The Use Case asks the `User` for its `id` and its `password_digest`. The Use Case never reads a database column.

WARNING: An error message that separates an unknown email address from a wrong password lets an attacker list the valid email addresses. The Use Case above returns the same error, `:invalid_credentials`, for both.

## Sessions are a Gateway concern

A session token is stored state, so a session token belongs in a Gateway:

```ruby
class Session
  attr_reader :token, :user_id, :expires_at

  def initialize(token:, user_id:, expires_at:)
    @token = token
    @user_id = user_id
    @expires_at = expires_at
  end
end

class SequelSessionGateway
  TOKEN_EXPIRY_SECONDS = 86_400

  def initialize(db)
    @sessions = db[:sessions]
  end

  def create(user_id:)
    session = Session.new(
      token: SecureRandom.hex(32),
      user_id: user_id,
      expires_at: Time.now + TOKEN_EXPIRY_SECONDS
    )
    @sessions.insert(token: session.token, user_id: session.user_id, expires_at: session.expires_at)
    session
  end

  def find_by_token(token)
    row = @sessions.where(token: token).where { expires_at > Time.now }.first
    return nil unless row

    Session.new(token: row[:token], user_id: row[:user_id], expires_at: row[:expires_at])
  end

  def delete(token:)
    @sessions.where(token: token).delete
  end
end
```

Both read methods return a `Session` Domain object. `create` is the one Gateway method here that takes an id instead of a Domain object, because the Gateway generates the token and the expiry, not the caller. `create` is a factory, and `create` still returns a `Session`. A Use Case asks the `Session` for everything else it needs.

A `LogOutUser` Use Case calls `session_gateway.delete(token:)`. The Gateway applies the expiry rule, so no Use Case reads the expiry.

## The Delivery Mechanism extracts the credentials

The Delivery Mechanism extracts the credentials from the transport layer, which means the headers, the cookies, or the form parameters. The Delivery Mechanism also rejects an unauthenticated request before that request reaches a Use Case:

```ruby
# Sinatra before filter
before do
  next if request.path_info == '/session'  # login route is public

  token = request.env['HTTP_AUTHORIZATION']&.split(' ')&.last
  session = session_gateway.find_by_token(token.to_s)
  halt 401, json(errors: [:unauthenticated]) unless session

  @current_user_id = session.user_id
end
```

### Passing the current user as input

The simplest approach passes the identity of the actor as a parameter to `execute`:

```ruby
post '/orders' do
  result = get_use_case(:place_order).execute(
    customer_id: @current_user_id,
    items: params[:items]
  )
  json(result)
end
```

The Use Case knows nothing about tokens, headers or sessions. The Use Case receives an id and treats that id as a fact.

### Providing the current user as a dependency

When many Use Cases need the identity of the current user, a `current_user_id:` parameter on every `execute` call adds noise. Pass the current user as a constructor dependency instead, in the same way that you pass a Gateway.

Write a simple current user object:

```ruby
class CurrentUser
  attr_reader :id

  def initialize(id)
    @id = id
  end
end
```

Inject the current user into the Use Cases that need it:

```ruby
class PlaceOrder
  def initialize(order_gateway:, current_user:)
    @order_gateway = order_gateway
    @current_user = current_user
  end

  def execute(items:)
    id = @order_gateway.save(Order.new(customer_id: @current_user.id, items: items))
    { order_id: id }
  end
end
```

The Delivery Mechanism constructs the `CurrentUser` after authentication, then passes the `CurrentUser` to the [dependency factory](./keep-your-wiring-DRY.md):

```ruby
before do
  # ... token verification ...
  @current_user = CurrentUser.new(session.user_id)
end

post '/orders' do
  result = get_use_case(:place_order).execute(items: params[:items])
  json(result)
end
```

```ruby
class Dependencies
  def initialize(db:, current_user:)
    @db = db
    @current_user = current_user
  end

  def get_use_case(name)
    case name
    when :place_order
      PlaceOrder.new(order_gateway: order_gateway, current_user: @current_user)
    end
  end
end
```

In a test, inject a `CurrentUser` directly. The test needs no token, no session and no HTTP:

```ruby
let(:current_user) { CurrentUser.new(1) }
let(:use_case) { PlaceOrder.new(order_gateway: InMemoryOrderGateway.new, current_user: current_user) }
```

Both approaches keep authentication out of the Use Case. Choose the approach that gives the simpler `execute` interface in your system.

## What must not go in the Use Case

A business Use Case does not verify a token, does not check session expiry, and does not read a request header. The Delivery Mechanism does all three.

A Use Case that starts with `session = @session_gateway.find_by_token(token)` has taken authentication as a second responsibility. Token verification is the same for every Use Case, so token verification belongs in the layer that every request passes through before the request reaches a Use Case.

## Testing authentication

Test the `AuthenticateUser` Use Case without HTTP and without a real session store:

```ruby
describe AuthenticateUser do
  let(:user_gateway) { InMemoryUserGateway.new }
  let(:session_gateway) { InMemorySessionGateway.new }
  let(:use_case) { described_class.new(user_gateway: user_gateway, session_gateway: session_gateway) }

  before do
    user_gateway.save(
      User.new(
        email: 'user@example.com',
        password_digest: BCrypt::Password.create('correct-password')
      )
    )
  end

  context 'with valid credentials' do
    it 'returns a session token' do
      result = use_case.execute(email: 'user@example.com', password: 'correct-password')
      expect(result[:success]).to be(true)
      expect(result[:token]).not_to be_nil
    end
  end

  context 'with an incorrect password' do
    it 'returns invalid_credentials' do
      result = use_case.execute(email: 'user@example.com', password: 'wrong')
      expect(result[:success]).to be(false)
      expect(result[:errors]).to include(:invalid_credentials)
    end
  end
end
```
