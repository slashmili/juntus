defmodule Junto.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Junto.Accounts` context.
  """

  alias Junto.Accounts.User
  alias Junto.Repo

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def external_auth_user_github(attrs \\ %{}) do
    default = %{
      "email" => "user@localhost.com",
      "email_verified" => true,
      "name" => "User",
      "picture" => "https://avatars.githubusercontent.com/u/1?v=4",
      "preferred_username" => "username",
      "profile" => "https://github.com/username",
      "sub" => 1,
      "provider" => "github"
    }

    %{
      user: Junto.Accounts.ExternalAuthUser.new(Map.merge(default, attrs))
    }
  end

  def external_auth_user_fixture(attrs \\ %{}) do
    external_auth_user_github(attrs)[:user]
  end

  def external_user_fixtrue(attrs \\ %{}) do
    user = attrs[:user] || attrs["user"] || user_fixture()
    external_auth_user = external_auth_user_fixture(attrs)
    {:ok, external_user} = Junto.Accounts.create_external_user(user, external_auth_user)
    external_user
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Junto.Accounts.register_user()

    if attrs[:confirmed_at] do
      user
      |> User.confirm_changeset()
      |> Repo.update!()
    else
      user
    end
  end

  def user_otp_token_fixture(user, otp_token \\ nil) do
    {otp_token, user_token} = Junto.Accounts.UserToken.build_otp_token(user, "otp", otp_token)
    Junto.Repo.insert!(user_token)
    otp_token
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def fetch_otp_token do
    import Swoosh.TestAssertions
    import ExUnit.Assertions
    test_pid = self()

    assert_email_sent(fn email ->
      otp_pattern = ~r/One-Time-Code:\s*\n\s*(\w+)\s*\n/
      token_pattern = ~r{confirm/([\w-]+)\n\n}

      [[_, otp_code]] = Regex.scan(otp_pattern, email.text_body)

      [[_, otp_token]] = Regex.scan(token_pattern, email.text_body)
      send(test_pid, {:otp_code, otp_code})
      send(test_pid, {:otp_token, otp_token})
    end)

    assert_received({:otp_code, otp_code})
    assert_received({:otp_token, otp_token})
    {otp_code, otp_token}
  end
end
