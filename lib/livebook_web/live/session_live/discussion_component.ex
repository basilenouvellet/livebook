defmodule LivebookWeb.SessionLive.DiscussionComponent do
  use LivebookWeb, :live_component

  alias LivebookWeb.UserHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@cell_view.id}-discussion"} class="absolute top-0 -right-12">
      <div id={"discussion_minimized_#{@cell_view.id}"} class="block flex flex-col text-xs">
        <.avatars cell_view={@cell_view} direction={:vertical} />
      </div>

      <div id={"discussion_maximized_#{@cell_view.id}"} class="hidden absolute -top-px -right-[225px] flex flex-col text-xs z-10 mr-4">
        <.avatars cell_view={@cell_view} direction={:horizontal} />
        <.comments cell_view={@cell_view} current_user={@current_user} />
        <.new_comment cell_view={@cell_view} current_user={@current_user} />
      </div>
    </div>
    """
  end

  defp avatars(assigns) do
    wrapper_class =
      case assigns.direction do
        :vertical -> "flex-col rounded"
        :horizontal -> "border border-gray-300 rounded-t"
      end

    has_comments? = not Enum.empty?(assigns.cell_view.comments)

    ~H"""
    <div
      phx-click={toggle_maximized(@cell_view.id)}
      class={"#{wrapper_class} flex items-center group hover:bg-gray-200 focus:bg-gray-200 p-2"}
    >
      <%= if has_comments? do %>
        <.stacked_avatars cell_view={@cell_view} direction={@direction} />
      <% end %>

      <.add_comment_avatar />
    </div>
    """
  end

  defp comments(assigns) do
    ~H"""
    <!-- NOTE: We display the list in reverse order with flex-col-reverse to auto scroll down once the list is displayed.
               The markup has to be in reverse order too to preserve the original order. -->
    <ul class="max-h-60 overflow-y-auto flex flex-col-reverse p-2 bg-gray-200 border-x border-gray-300 scrollbar-thin hover:scrollbar-thumb-gray-300 scrollbar-track-gray-200">
      <%= if @cell_view.comments == [] do %>
        <p class="p-2 text-gray-400">No comments yet.</p>
      <% else %>
        <%= for {%{user: user, message: message}, index} <- Enum.with_index(@cell_view.comments) do %>
          <li id={"#{user.name}-#{message}-#{index}"} class="flex items-center my-1 first:mb-0 last:mt-0">
            <.user_avatar user={user} />
            <p class="ml-2 p-2 bg-white rounded"><%= message %></p>
          </li>
        <% end %>
      <% end %>
    </ul>
    """
  end

  defp new_comment(assigns) do
    ~H"""
    <div class="flex items-center p-2 border border-gray-300 rounded-b">
      <.user_avatar user={@current_user} />
      <.new_comment_input cell_view_id={@cell_view.id} />
    </div>
    """
  end

  defp stacked_avatars(assigns) do
    stacked_class =
      case assigns.direction do
        :vertical -> "flex-col -space-y-2 mb-1"
        :horizontal -> "-space-x-2 mr-1"
      end

    ~H"""
    <div class={"#{stacked_class} flex overflow-hidden"}>
      <%= for %{user: user, message: _message} <-
        @cell_view.comments
        |> Enum.reverse()
        |> Enum.uniq_by(fn %{user: %{id: id}} -> id end) do %>
        <.user_avatar user={user} class="h-8 w-8 border-2 border-white" />
      <% end %>
    </div>
    """
  end

  defp user_avatar(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)

    ~H"""
    <UserHelpers.user_avatar user={@user} class={"#{@class} h-7 w-7 select-none"} />
    """
  end

  defp add_comment_avatar(assigns) do
    ~H"""
    <div
      aria-hidden="true"
      class="h-7 w-7 flex items-center justify-center select-none rounded-full border border-dashed border-gray-300 group-hover:border-gray-400"
    >
      <div class="text-gray-300 group-hover:text-gray-400 text-md font-semibold">+</div>
    </div>
    """
  end

  defp new_comment_input(assigns) do
    # NOTE: Server event "comment_cell" is sent by the JS hook directly.
    #       See 'assets/js/hooks/comment_input.js'.

    ~H"""
    <input
      id={"comment_input_#{@cell_view_id}"}
      class="flex-1 p-2 rounded"
      required
      autofocus
      cell_view_id={@cell_view_id}
      type="text"
      placeholder="Write a comment..."
      phx-hook="CommentInput"
    />
    """
  end

  def toggle_maximized(js \\ %JS{}, cell_view_id) do
    js
    |> JS.dispatch("phx:focus", to: "#comment_input_#{cell_view_id}")
    |> JS.toggle(to: "#discussion_minimized_#{cell_view_id}")
    |> JS.toggle(to: "#discussion_maximized_#{cell_view_id}")
  end
end