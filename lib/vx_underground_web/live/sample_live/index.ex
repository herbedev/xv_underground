defmodule VxUndergroundWeb.SampleLive.Index do
  use VxUndergroundWeb, :live_view

  alias VxUnderground.Samples
  alias VxUnderground.Samples.Sample
  alias VxUndergroundWeb.SampleLive.SortingForm
  alias VxUndergroundWeb.SampleLive.FilterForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :samples, list_samples())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      parse_params(socket, params)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Sample")
    |> assign(:sample, Samples.get_sample!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Sample")
    |> assign(:sample, %Sample{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Samples")
    |> assign(:sample, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    sample = Samples.get_sample!(id)
    {:ok, _} = Samples.delete_sample(sample)

    {:noreply, assign(socket, :samples, list_samples())}
  end

  def handle_info({:update, opts}, socket) do
    params = merge_and_sanitize_params(socket, opts)
    path = "/samples?" <> URI.encode_query(params)

    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  defp merge_and_sanitize_params(socket, overrides \\ %{}) do
    %{sorting: sorting, filter: filter} = socket.assigns

    %{}
    |> Map.merge(sorting)
    |> Map.merge(filter)
    |> Map.merge(overrides)
    |> Map.drop([:total_count])
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp parse_params(socket, params) do
    with {:ok, sorting_opts} <- SortingForm.parse(params),
         {:ok, filter_opts} <- FilterForm.parse(params) do
      socket
      |> assign_filter(filter_opts)
      |> assign_sorting(sorting_opts)
    else
      _error ->
        socket
        |> assign_sorting()
        |> assign_filter()
        |> put_flash(:error, "Invalid filter params")
    end
  end

  defp assign_sorting(socket, overrides \\ %{}) do
    opts = Map.merge(SortingForm.default_vaules(), overrides)

    assign(socket, :sorting, opts)
  end

  defp assign_filter(socket, overrides \\ %{}) do
    assign(socket, :filter, FilterForm.default_vaules(overrides))
  end

  defp list_samples do
    Samples.list_samples()
  end
end
