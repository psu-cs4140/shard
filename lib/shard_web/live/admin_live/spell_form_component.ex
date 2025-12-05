defmodule ShardWeb.AdminLive.SpellFormComponent do
  use ShardWeb, :live_component

  alias Shard.Spells

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div style="padding-left: 3rem;">
        <.header>
          {@title}
          <:subtitle>Use this form to manage spell records in your database.</:subtitle>
        </.header>
      </div>

      <.simple_form
        for={@form}
        id="spell-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:spell_type_id]}
          type="select"
          label="Spell Type"
          prompt="Choose a type"
          options={@spell_type_options}
        />
        <.input
          field={@form[:spell_effect_id]}
          type="select"
          label="Spell Effect"
          prompt="Choose an effect"
          options={@spell_effect_options}
        />
        <.input field={@form[:mana_cost]} type="number" label="Mana Cost" />
        <.input field={@form[:damage]} type="number" label="Damage (optional)" />
        <.input field={@form[:healing]} type="number" label="Healing (optional)" />
        <.input field={@form[:level_required]} type="number" label="Level Required" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Spell</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{spell: spell} = assigns, socket) do
    changeset = Spells.change_spell(spell)

    # Load spell types and effects for dropdowns
    spell_type_options =
      Spells.list_spell_types()
      |> Enum.map(fn type -> {type.name, type.id} end)

    spell_effect_options =
      Spells.list_spell_effects()
      |> Enum.map(fn effect -> {effect.name, effect.id} end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:spell_type_options, spell_type_options)
     |> assign(:spell_effect_options, spell_effect_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"spells" => spell_params}, socket) do
    changeset =
      socket.assigns.spell
      |> Spells.change_spell(spell_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"spells" => spell_params}, socket) do
    # Convert empty values to nil
    spell_params = normalize_spell_params(spell_params)
    save_spell(socket, socket.assigns.action, spell_params)
  end

  defp normalize_spell_params(params) do
    params
    |> normalize_field("spell_type_id")
    |> normalize_field("spell_effect_id")
    |> normalize_field("damage")
    |> normalize_field("healing")
  end

  defp normalize_field(params, field) do
    case Map.get(params, field) do
      "" -> Map.put(params, field, nil)
      _ -> params
    end
  end

  defp save_spell(socket, :edit, spell_params) do
    case Spells.update_spell(socket.assigns.spell, spell_params) do
      {:ok, spell} ->
        notify_parent({:saved, spell})

        {:noreply,
         socket
         |> put_flash(:info, "Spell updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_spell(socket, :new, spell_params) do
    case Spells.create_spell(spell_params) do
      {:ok, spell} ->
        notify_parent({:saved, spell})

        {:noreply,
         socket
         |> put_flash(:info, "Spell created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
