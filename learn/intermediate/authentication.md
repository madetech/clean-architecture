---
title: Authentication
---

# Authentication

Authentication is the act of verifying identity: confirming that the person or system making a request is who they claim to be.

In Clean Architecture, authentication fits naturally as a use case backed by a gateway. The delivery mechanism handles the mechanics of extracting credentials from a request; the use case verifies them.

## Authentication as a use case

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

    token = @session_gateway.create(user_id: user[:id])
    { success: true, token: token }
  end

  private

  def valid_password?(user, password)
    BCrypt::Password.new(user[:password_digest]) == password
  end
end
```

Note that the use case returns the same error (`:invalid_credentials`) whether the email is unrecognised or the password is wrong. This is deliberate — distinguishing the two would allow an attacker to enumerate valid email addresses.

## Sessions are a gateway concern

A session token is persisted state — it belongs in a gateway:

```ruby
class SequelSessionGateway
  TOKEN_EXPIRY_SECONDS = 86_400

  def initialize(db)
    @sessions = db[:sessions]
  end

  def create(user_id:)
    token = SecureRandom.hex(32)
    @sessions.insert(
      token: token,
      user_id: user_id,
      expires_at: Time.now + TOKEN_EXPIRY_SECONDS
    )
    token
  end

  def find_by_token(token)
    @sessions.where(token: token).where { expires_at > Time.now }.first
  end

  def delete(token:)
    @sessions.where(token: token).delete
  end
end
```

A `LogOutUser` use case would call `session_gateway.delete(token:)`. Expiry is enforced by the gateway — use cases do not need to reason about it.

## The delivery mechanism handles credential extraction

The delivery mechanism is responsible for extracting credentials from the transport layer (headers, cookies, form params) and for rejecting unauthenticated requests before they reach a use case:

```ruby
# Sinatra before filter
before do
  next if request.path_info == '/session'  # login route is public

  token = request.env['HTTP_AUTHORIZATION']&.split(' ')&.last
  session = session_gateway.find_by_token(token.to_s)
  halt 401, json(errors: [:unauthenticated]) unless session

  @current_user_id = session[:user_id]
end
```

### Passing the current user as input

The simplest approach is to pass the actor's identity as a parameter to `execute`:

```ruby
post '/orders' do
  result = get_use_case(:place_order).execute(
    customer_id: @current_user_id,
    items: params[:items]
  )
  json(result)
end
```

The use case has no knowledge of tokens, headers, or sessions. It receives an ID and treats it as a fact.

### Providing the current user as a gateway

When many use cases in a system need to know who the current user is, threading `current_user_id:` through every `execute` call becomes noisy. An alternative is to provide the current user as a constructor dependency — the same pattern used for gateways.

Define a simple current user object:

```ruby
class CurrentUser
  attr_reader :id

  def initialize(id)
    @id = id
  end
end
```

Inject it into use cases that need it:

```ruby
class PlaceOrder
  def initialize(order_gateway:, current_user:)
    @order_gateway = order_gateway
    @current_user = current_user
  end

  def execute(items:)
    id = @order_gateway.save(customer_id: @current_user.id, items: items)
    { order_id: id }
  end
end
```

The delivery mechanism constructs the `CurrentUser` after authentication and passes it into the [dependency factory](./keep-your-wiring-DRY.md):

```ruby
before do
  # ... token verification ...
  @current_user = CurrentUser.new(session[:user_id])
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

In tests, inject a `CurrentUser` directly — no token, no session, no HTTP:

```ruby
let(:current_user) { CurrentUser.new(1) }
let(:use_case) { PlaceOrder.new(order_gateway: InMemoryOrderGateway.new, current_user: current_user) }
```

Both approaches keep the use case free of authentication concerns. Choose whichever keeps the `execute` interface cleaner for your system.

## What must not live in the use case

Business use cases should not verify tokens, check session expiry, or read from request headers. That is the delivery mechanism's responsibility.

A use case that begins with `session = @session_gateway.find_by_token(token)` has taken on authentication as a side concern. Token verification is the same regardless of which use case is being called — it belongs in the layer that all requests pass through before reaching any use case.

## Testing authentication

The `AuthenticateUser` use case can be tested without HTTP or real sessions:

```ruby
describe AuthenticateUser do
  let(:user_gateway) { InMemoryUserGateway.new }
  let(:session_gateway) { InMemorySessionGateway.new }
  let(:use_case) { described_class.new(user_gateway: user_gateway, session_gateway: session_gateway) }

  before do
    user_gateway.create(email: 'user@example.com', password: 'correct-password')
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
