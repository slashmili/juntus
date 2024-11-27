defmodule JuntoWeb.EventLive.CreateTest do
  use JuntoWeb.ConnCase, async: true

  alias JuntoWeb.EventLive.Create, as: SUT
  import Junto.AccountsFixtures
  import Phoenix.LiveViewTest

  test "renders create-event view", %{conn: conn} do
    {:ok, lv, _html} =
      conn
      |> log_in_user(user_fixture())
      |> live(~p"/create")

    assert lv.module == SUT
    assert is_pid(lv.pid)
    assert has_element?(lv, ~s/[data-role=create-event]/)
  end

  test "renders error when page is submitted with invalid input", %{conn: conn} do
    {:ok, lv, _html} =
      conn
      |> log_in_user(user_fixture())
      |> live(~p"/create")

    lv
    |> form("#createEventForm", event: %{name: ""})
    |> render_submit()

    assert has_element?(lv, "[data-role=error-event_name]")
    assert has_element?(lv, "[data-role=error-event_start_datetime]")
    assert has_element?(lv, "[data-role=error-event_end_datetime]")
    assert has_element?(lv, "[data-role=error-event_timezone]")
  end
end
