require "test_helper"

class UserTest < ActiveSupport::TestCase

  # Email Unit Tests
  test "should not save user without a email" do
    user = User.new(password: "ValidPassword1234!", password_confirmation: "ValidPassword1234!")
    assert_not user.save, "Saved user with blank email"
  end

  test "should not save user if their email is blank" do
    user = User.new(email: "", password: "ValidPassword1234!", password_confirmation: "ValidPassword1234!")
    assert_not user.save, "Saved user with blank email"
  end

  test "should not save user if their email is not in email format" do
    user = User.new(email: "invalidemailformat", password: "ValidPassword1234!", password_confirmation: "ValidPassword1234!")
    assert_not user.save, "Saved user with email not in email format"
  end

  # Password Unit Tests
  test "should not save user without a password" do
    user = User.new(email: "testuser4@test.ca")
    assert_not user.save, "Saved user without a password and password confirmation"
  end

  test "should not save user without a password confirmation" do
    user = User.new(email: "testuser4@test.ca", password: "ValidPass123!")
    assert_not user.save, "Saved user without a password confirmation"
  end

  test "should not save user when password is blank" do
    user = User.new(email: "testuser5@test.ca", password: "", password_confirmation: "")
    assert_not user.save, "Saved user when password blank"
  end
  
  test "should not save user when password is less than 8 characters" do
    user = User.new(email: "testuser5@test.ca", password: "Sec123!", password_confirmation: "Sec123!")
    assert_not user.save, "Saved user when password is less than 8 characters"
  end

  test "should not save user when password is more than 20 characters" do
    user = User.new(email: "testuser5@test.ca", password: "MoreThan20CharactersPassword!", password_confirmation: "MoreThan20CharactersPassword!")
    assert_not user.save, "Saved user when password is more than 20 characters"
  end

  test "should not save user when password has no uppercase chars" do
    user = User.new(email: "testuser5@test.ca", password: "nouppercasechars123!", password_confirmation: "nouppercasechars123!")
    assert_not user.save, "Saved user when password has no uppercase chars"
  end

  test "should not save user when password has no lowercase chars" do
    user = User.new(email: "testuser5@test.ca", password: "NOLOWERCASECHARS123!", password_confirmation: "NOLOWERCASECHARS123!")
    assert_not user.save, "Saved user when password has no lowercase chars"
  end

  test "should not save user when password has no numbers" do
    user = User.new(email: "testuser5@test.ca", password: "NONUMBERS!", password_confirmation: "NONUMBERS!")
    assert_not user.save, "Saved user when password has numbers"
  end

  test "should not save user when password does not have a symbol" do
    user = User.new(email: "testuser5@test.ca", password: "NoSymbolPassword123", password_confirmation: "NoSymbolPassword123")
    assert_not user.save, "Saved user when password has no symbol"
  end
end
