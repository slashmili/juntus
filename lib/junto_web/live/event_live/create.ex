defmodule JuntoWeb.EventLive.Create do
  use JuntoWeb, :live_view
  alias JuntoWeb.CoreComponentsBackup

  @event_scopes %{
    public: %{
      order: 0,
      type: :public,
      title: "Public",
      icon: "hero-globe-alt",
      desc: "Show on your group. Could be listed and suggested "
    },
    private: %{
      order: 1,
      type: :private,
      title: "Private",
      icon: "hero-sparkles-solid",
      desc: "Unlisted. Only people with the link can register"
    }
  }
  @impl true
  def mount(_params, _session, socket) do
    event_params = create_params()

    {:ok,
     assign(socket,
       form: to_form(event_params, as: :event),
       gmap_suggested_places: [],
       place: nil,
       selected_scope: :public,
       force_rerender_map: false
     )}
  end

  defp group_dropdown(assigns) do
    ~H"""
    <.header_dropdown id="groupDropdown">
      <:title>
        <div class="min-w-0 truncate">
          Personal Event
        </div>
      </:title>
      <div
        class="ml-[20px] sm:ml-[60px] p-2 w-60 create-event-dropdown-menu-style outline-white/80 select-none"
        style="background-color: #222a"
      >
        <div class="text-xs opacity-50">Choose the group of the event</div>
        <.group_dropdown_menu_items />
      </div>
    </.header_dropdown>
    """
  end

  defp group_dropdown_menu_items(assigns) do
    all_groups = ["Personal Event", "Group A", "Group B"]
    assigns = Map.put(assigns, :all_groups, all_groups)

    ~H"""
    <.dropdown_list_button>
      <:item :for={group <- @all_groups}>
        <div class="flex p-2 create-event-dropdown-menu-group-selector ">
          <%= group %>
        </div>
      </:item>
      <:item>
        <div class="my-auto p-2 text-left dark:text-slate-400 text-slate-500 hover:bg-gray-700/10  rounded-md cursor-pointer opacity-50">
          <.icon name="hero-plus" class="w-4 h-4 " /> Create Group
        </div>
      </:item>
    </.dropdown_list_button>
    """
  end

  defp scope_dropdown(assigns) do
    assigns = Map.put(assigns, :event_scopes, @event_scopes)

    ~H"""
    <.header_dropdown id="scopeDropdown">
      <:title>
        <div class="whitespace-nowrap">
          <.icon name={@event_scopes[@selected_scope].icon} class="w-4 h-4" /> <%= @event_scopes[
            @selected_scope
          ].title %>
        </div>
      </:title>
      <div class="!ml-[-15px] select-none z-50 pt-2 pb-2 px-1 w-72 create-event-dropdown-menu-style select-none">
        <.scope_dropdown_menu_items selected_scope={@selected_scope} event_scopes={@event_scopes} />
      </div>
    </.header_dropdown>
    """
  end

  def scope_dropdown_menu_items(assigns) do
    ~H"""
    <.dropdown_list_button>
      <:item
        :for={{_, scope} <- Enum.sort_by(@event_scopes, &elem(&1, 1).order)}
        custom-phx-select={JS.push("select-scope", value: scope, loading: "#scopeDropdownBtn")}
        class="dark:hover:bg-white/5"
      >
        <div class="flex p-2">
          <div class="my-auto w-6"><.icon name={scope.icon} class="w-4 h4" /></div>
          <div class="text-sm pl-2 text-left">
            <div class="dark:text-slate-100 text-slate-900"><%= scope.title %></div>
            <div><%= scope.desc %></div>
          </div>
          <div class="my-auto w-6">
            <.icon :if={@selected_scope == scope.type} name="hero-check" class="w-4 h4" />
          </div>
        </div>
      </:item>
    </.dropdown_list_button>
    """
  end

  defp event_title_input(assigns) do
    ~H"""
    <div class="min-h-12">
      <pre class="w-60">
    </pre>
      <div class="sr-only">Event name</div>
      <textarea
        id={@form[:name].id}
        name={@form[:name].name}
        autofocus
        autocapitalize="words"
        spellcheck="false"
        class="h-12 w-full create-event-textarea-style"
        placeholder="Event Name"
        onInput="this.parentNode.dataset.clonedVal = this.value"
        row="2"
      ><%= @form[:name].value %></textarea>
      <%= if @form[:name].errors != [] do %>
        <div data-role={"error-#{@form[:name].id}"} class="sr-only">Error: fill in name</div>
      <% end %>
      <script>
        const textarea = document.getElementById('event_name');
        //TODO: move it out of here
        textarea.addEventListener('input', () => {
        if (textarea.scrollHeight < 50) return;
            textarea.style.height = 'auto';
            textarea.style.height = `${textarea.scrollHeight}px`;
        });
            
      </script>
    </div>
    """
  end

  defp datepick(assigns) do
    ~H"""
    <button
      class="flex gap-2 w-full px-3 py-2  animated create-event-button-style sm:hidden outline-none focus:outline-none"
      phx-click={show_modal("datepickModal")}
    >
      <div class="-z-[1]"><.icon name="hero-clock" class="w-4 h-4" /></div>
      <div class="min-w-0 text-left">
        <div class="font-medium truncate">Tuesday, 12 November</div>
        <div class="text-sm truncate">07:00 -- 08:00</div>
      </div>
    </button>
    <.datepick_modal />
    """
  end

  defp datepick_modal(assigns) do
    ~H"""
    <.modal id="datepickModal">
      <div class="w-full max-w-2xl max-h-full bg-transparent">
        <div class="relative rounded-lg shadow-lg shadow-black bg-white/90 dark:bg-neutral-900/70 backdrop-blur-lg dark:text-white">
          <div class="p-4 flex flex-col gap-2">
            <div class="">
              <div class="font-semibold text-lg">Event Time</div>
            </div>
            <.datepick_date label="Start" />
            <.datepick_date label="End" />
            <.datepick_timezone />
          </div>
        </div>
      </div>
    </.modal>
    """
  end

  defp datepick_timezone(assigns) do
    ~H"""
    <div class="flex flex-row text-sm">
      <div class="flex items-center opacity-60">Timezone</div>
      <div class="pl-3 grow flex justify-end"></div>
      <CoreComponentsBackup.dropdown id="timezoneDropdown">
        <:button
          id="timezoneDropdownBtnBtn"
          dropdown-toggle="timezoneDropdown"
          class="bg-transparent border-black/10 hover:border-black/40 dark:border-white/10 dark:hover:border-white/80 border rounded  px-1 py-2 focus:ring-0 focus:outline-none focus:border-black/40 dark:focus:border-white/80"
        >
          <div class="min-w-0 flex gap-2 m">
            <div class="dark:text-white/50">GMT+01:00</div>
            <div class="inline truncate">Berlin</div>
            <div><.icon name="hero-chevron-down " class="h-4 w-4" /></div>
          </div>
        </:button>
        <div class="dark:bg-black/50 backdrop-blur-lg rounded-md w-80 shadow-black shadow-lg">
          <div class="bg-black/10 dark:bg-white/10 w-full rounded-t-md">
            <input
              tabindex="-1"
              type="text"
              class="bg-transparent dark:placeholder-white/40 text-sm outline-none focus:ring-0 border-none focus:outline-none focus:ring-0"
              placeholder="Search for a timzone"
            />
          </div>

          <div class="max-h-44 overflow-auto">
            <ul class="p-1">
              <li :for={{zone_name, offset} <- get_list_of_timezones()}>
                <button class="flex text-left w-full hover:bg-black/10 dark:hover:bg-white/10 rounded-md py-1 px-2">
                  <div class="truncate grow"><%= zone_name %></div>
                  <div class="text-black/50 dark:text-white/50 base-1 flex justify-end">
                    <%= offset %>
                  </div>
                </button>
              </li>
            </ul>
          </div>
        </div>
      </CoreComponentsBackup.dropdown>
    </div>
    """
  end

  defp datepick_date(assigns) do
    ~H"""
    <div class="flex flex-row">
      <div class="flex items-center text-sm opacity-60"><%= @label %></div>
      <div class="pl-3 grow flex justify-end">
        <input
          class="bg-transparent border-black/10 hover:border-black/40 dark:border-white/10 dark:hover:border-white/80  border rounded-l-md outline-pink-500  focus:ring-0 focus:outline-none focus:border-black/40 dark:focus:border-white/80"
          type="date"
          value="2024-05-23"
        />
        <input
          class="bg-transparent border-black/10 hover:border-black/40 dark:border-white/10 dark:hover:border-white/80 border rounded-r-md outline-none focus:ring-0 focus:outline-none focus:border-black/40 dark:focus:border-white/80 -ml-[2px] "
          type="time"
          value="21:00"
          required
        />
      </div>
    </div>
    """
  end

  defp location(assigns) do
    ~H"""
    <button
      class="flex gap-2 w-full px-3 py-2  animated create-event-button-style outline-none focus:outline-none"
      phx-click={show_modal("locationModal")}
    >
      <div><.icon name="hero-map-pin" class="w-5 h-5" /></div>
      <div :if={is_nil(@place)}>
        <div class="text-left">Add Event Location</div>
        <div class="text-sm text-left">Offline location or virutal link</div>
      </div>
      <div :if={@place} class="grow">
        <div class="text-left font-medium"><%= @place["name"] %></div>
        <div class="text-left text-sm"><%= @place["address"] %></div>
      </div>
      <div :if={@place} class="pt-1 pr-1" phx-click="deselect-place" role="button">
        <div class="flex items-center justify-center rounded-full p-1 hover-block-custom">
          <.icon name="hero-x-mark" class="w-5 h-5 " />
        </div>
        <div class="sr-only">close</div>
      </div>
    </button>
    <.location_modal gmap_suggested_places={@gmap_suggested_places} />
    <div :if={@place && @force_rerender_map != true}>
      <div
        data-place={Jason.encode!(@place)}
        data-map-id={get_gmaps_id()}
        id="google-map"
        class="h-32"
        phx-hook="Gmaps"
        data-api-key={get_gmaps_api_key()}
        phx-update="ignore"
      >
      </div>
    </div>
    """
  end

  def location_modal(assigns) do
    ~H"""
    <.modal id="locationModal">
      <div class="dark:bg-black/50 backdrop-blur-lg rounded-md shadow-black shadow-lg">
        <div
          id="gmap-new-event-lookup2"
          class="input-container -mt-2 -mx-1 rounded-t-md pb-1"
          phx-hook="GmapLookup"
          data-api-key={get_gmaps_api_key()}
        >
          <input
            type="text"
            id="locationModalTextarea"
            class="bg-black/20 dark:bg-white/10 w-full rounded-t-md dark:placeholder-white/40 outline-none focus:ring-0 border-none focus:outline-none focus:ring-0 w-full"
            placeholder="Enter Location"
          />
          <div :if={@gmap_suggested_places == []}>&nbsp;</div>
          <div :if={@gmap_suggested_places}>
            <menu class="gmap-suggested-places">
              <li :for={place <- @gmap_suggested_places}>
                <button
                  class="text-left w-full create-event-dropdown-menu-group-selector"
                  tabindex="0"
                  phx-click={JS.push("select-place", value: place) |> hide_modal("locationModal")}
                >
                  <.event_place_item name={place["name"]} location={place["address"]} />
                </button>
              </li>
            </menu>
          </div>
        </div>
      </div>
    </.modal>
    """
  end

  defp event_place_item(assigns) do
    ~H"""
    <div class="flex p-2 dark:text-slate-400 text-slate-500 hover:bg-gray-700/10 rounded-md cursor-pointer">
      <div class="my-auto w-6"><.icon name="hero-map-pin" class="w-5 h5" /></div>
      <div class="pl-2">
        <div class="dark:text-slate-100 text-slate-900"><%= @name %></div>
        <div class="text-sm max-w-md"><%= @location %></div>
      </div>
    </div>
    """
  end

  defp description(assigns) do
    ~H"""
    <button
      class="flex gap-2 w-full px-3 py-2  animated create-event-button-style outline-none focus:outline-none"
      phx-click={show_modal("eventDescriptionModal")}
      type="button"
    >
      <div>
        <.icon name="hero-document-text" class="w-5 h-5" />
      </div>
      <div>
        <div class="text-left">Event Description</div>
        <div class="text-sm text-left"></div>
      </div>
    </button>
    <.modal id="eventDescriptionModal">
      <div class="w-full max-w-2xl max-h-full bg-transparent shadow-lg backdrop-blur-lg shadow-black   bg-white/90 dark:bg-neutral-900/70  dark:text-white">
        <div class="rounded-t-lg">
          <div class="p-4 flex flex-col gap-2">
            <div class="flex flex-row">
              <div class="font-semibold text-lg">Event Description</div>
              <button
                type="button"
                class="rounded-full p-1 hover-block-custom text-gray-400 bg-transparent rounded-lg text-sm w-8 h-8 ms-auto inline-flex justify-center items-center "
                phx-click={hide_modal("eventDescriptionModal")}
              >
                <.icon name="hero-x-mark" class="w-4 h-4" />
                <span class="sr-only">Close modal</span>
              </button>
            </div>
          </div>
        </div>
        <div class="p-4 md:p-5 space-y-4 bg-gray-950">
          <.text_editor
            name="desc"
            placeholder="What's event about?"
            class="prose prose-sm sm:prose lg:prose-lg xl:prose-2xl mx-auto focus:outline-none prose max-w-none min-h-20 max-h-64 overflow-y-auto "
          />
        </div>
        <div class="rounded-b-2xl">
          <div class="p-4">
            <.button class="dark:bg-white bg-black dark:text-black text-white rounded-lg font-medium px-3 py-2">
              Done
            </.button>
          </div>
        </div>
      </div>
    </.modal>
    """
  end

  ### Reusable components

  def modal2(assigns) do
    ~H"""
    """
  end

  attr :id, :string, required: true
  attr :class, :string, required: false, default: ""
  slot :title, required: true
  slot :inner_block, required: true

  def header_dropdown(assigns) do
    ~H"""
    <CoreComponentsBackup.dropdown id={@id}>
      <:button id={@id <> "Btn"} dropdown-toggle={@id} class={@class <> "min-w-0"}>
        <div class="flex w-fit-d gap-2 px-4 py-1 items-center text-sm font-medium animated create-event-dropdown-style">
          <%= render_slot(@title) %>

          <div class="-mt-[4px]">
            <.icon name="hero-chevron-down text-sm font-medium" class="h-4 w-4" />
          </div>
        </div>
      </:button>
      <div
        id={@id <> "NavigatorWrapper"}
        phx-hook="ListNavigator"
        data-list-navigator-button-id={@id <> "Btn"}
      >
        <%= render_slot(@inner_block) %>
      </div>
    </CoreComponentsBackup.dropdown>
    """
  end

  slot :item, required: true do
    attr :class, :string, required: false
    attr :"custom-phx-select", :string, required: false
  end

  def dropdown_list_button(assigns) do
    ~H"""
    <menu class="rounded-sm">
      <li :for={item <- @item} class={[item[:class], "rounded-md outline-none focus:bg-gray-700/10"]}>
        <button
          class="w-full"
          tabindex="0"
          phx-click={item[:"custom-phx-select"]}
          phx-keydown={item[:"custom-phx-select"]}
          phx-key="Enter"
        >
          <%= render_slot(item) %>
        </button>
      </li>
    </menu>
    """
  end

  defp get_list_of_timezones(datetime \\ nil) do
    # TODO: extract it this with some known timezones
    datetime = datetime || DateTime.utc_now()

    iso_days =
      Calendar.ISO.naive_datetime_to_iso_days(
        datetime.year,
        datetime.month,
        datetime.day,
        datetime.hour,
        datetime.minute,
        datetime.second,
        datetime.microsecond
      )

    for zone_name <- Tzdata.zone_list() do
      {:ok, tzone} =
        Tzdata.TimeZoneDatabase.time_zone_period_from_utc_iso_days(iso_days, zone_name)

      {zone_name, tzone[:utc_offset]}
    end
    |> Enum.sort(fn zone1, zone2 ->
      elem(zone1, 1) < elem(zone2, 1)
    end)
    |> Enum.map(fn {zone_name, utc_offset} ->
      minutes = div(utc_offset, 60)
      hours = abs(div(minutes, 60))
      hours = String.pad_leading("#{hours}", 2, "0")
      remaingin_minutes = rem(minutes, 60)

      sign =
        if utc_offset < 0 do
          "-"
        else
          "+"
        end

      {zone_name, "GMT #{sign}#{hours}:#{remaingin_minutes}"}
    end)
  end

  @impl true
  def handle_event("select-scope", %{"type" => type}, socket) do
    {:noreply, assign(socket, :selected_scope, String.to_existing_atom(type))}
  end

  @impl true
  def handle_event("gmap-suggested-places", places, socket) do
    {:noreply, assign(socket, :gmap_suggested_places, places)}
  end

  @impl true
  def handle_event("select-place", place, socket) do
    send(self(), :reset_map_rerender)
    {:noreply, assign(socket, place: place, force_rerender_map: true)}
  end

  @impl true
  def handle_event("select-place-update-address", place, socket) do
    {:noreply, assign(socket, place: place)}
  end

  @impl true
  def handle_event("deselect-place", _, socket) do
    {:noreply, assign(socket, :place, nil)}
  end

  @impl true
  def handle_event("create-event", %{"event" => event_params}, socket) do
    form = to_form(event_params, as: :event, errors: [name: {"Invalid", []}])
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_info(:reset_map_rerender, socket) do
    {:noreply, assign(socket, :force_rerender_map, false)}
  end

  defp get_gmaps_api_key do
    # TODO: to delete dev key
    "AIzaSyCCubqJSWvbLIQJdsZXyMj7olwYanekI6M"
  end

  defp get_gmaps_id do
    "300ffa0564ebe9c7"
  end

  defp create_params do
    now = DateTime.utc_now()
    later = DateTime.add(now, 1, :hour)

    %{
      "name" => nil,
      "scope" => :public,
      "start_datetime" => now,
      "end_datetime" => later,
      "timezone" => "UTC",
      "description" => ""
    }
  end
end
